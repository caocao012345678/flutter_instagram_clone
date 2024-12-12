import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import '../screen/profile_screen.dart';
import 'message_actions.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;

  const ChatDetailScreen({
    Key? key,
    required this.chatId,
    required this.otherUserId,
  }) : super(key: key);

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToBottomButton = false;
  String? _replyingTo;
  String lastMessageTime = '';
  String getStatusIcon(String status) {
    switch (status) {
      case 'sent':
        return ' Đã gửi'; // Đã gửi
      case 'delivered':
        return 'Đã nhận'; // Đã nhận
      case 'read':
        return 'Đã xem'; // Đã xem
      default:
        return 'Chưa gửi';
    }
  }


  @override
  void initState() {
    super.initState();
    _loadDraftMessage();
    _scrollController.addListener(_onScroll);
    FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .where('status', isEqualTo: 'sent')
        .get()
        .then((snapshot) {
      for (var doc in snapshot.docs) {
        doc.reference.update({'status': 'delivered'});
      }
    });
  }

  @override
  void dispose() {
    _saveDraftMessage();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }


  void _onScroll() {
    if (_scrollController.offset > 200) {
      setState(() {
        _showScrollToBottomButton = true;
      });
    } else {
      setState(() {
        _showScrollToBottomButton = false;
      });
    }
  }

  void _saveDraftMessage() {
    FirebaseFirestore.instance.collection('chats').doc(widget.chatId).update({
      'draft': _messageController.text,
    });
  }

  void _loadDraftMessage() {
    FirebaseFirestore.instance.collection('chats').doc(widget.chatId).get().then((snapshot) {
      if (snapshot.exists && snapshot.data()!['draft'] != null) {
        _messageController.text = snapshot.data()!['draft'];
      }
    });
  }
  void _markMessagesAsRead() {
    FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .where('status', isEqualTo: 'delivered')
        .get()
        .then((snapshot) {
      for (var doc in snapshot.docs) {
        doc.reference.update({'status': 'read'});
      }
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    final messageData = {
      'senderId': currentUserId,
      'content': message,
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'text',
      'status': 'sent', // Thêm trạng thái ban đầu
    };



    if (_replyingTo != null) {
      messageData['replyTo'] = _replyingTo!;
      _replyingTo = null;
    }

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .add(messageData);

    await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).update({
      'lastMessage': message,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });

    _messageController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Timer(
        const Duration(milliseconds: 300),
            () => _scrollController.jumpTo(_scrollController.position.minScrollExtent),
      );
      _markMessagesAsRead(); // Đánh dấu tin nhắn là đã xem
    }
  }

  Future<void> _sendImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final ref = FirebaseStorage.instance.ref().child('chat_images/$fileName.jpg');

      await ref.putFile(file);
      final downloadUrl = await ref.getDownloadURL();

      final currentUserId = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .add({
        'senderId': currentUserId,
        'content': downloadUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'image',
      });
    }
  }

  Future<void> _recallMessage(DocumentSnapshot message) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid; // Lấy ID người dùng hiện tại
    final senderId = message['senderId']; // Lấy ID người gửi từ tin nhắn
    final currentTime = DateTime.now();
    final messageTime = message['timestamp'].toDate();
    final difference = currentTime.difference(messageTime);


    // Kiểm tra nếu người dùng hiện tại không phải người gửi
    if (currentUserId != senderId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bạn không thể thu hồi tin nhắn của người khác.')),
      );
      return;
    }

    // Kiểm tra thời gian quá 1 phút
    if (difference.inMinutes > 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể thu hồi, tin nhắn đã gửi quá 1 phút.')),
      );
      return;
    }

    // Cập nhật nội dung tin nhắn thành "đã bị thu hồi"
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .doc(message.id)
        .update({'content': 'Tin nhắn đã bị thu hồi', 'type': 'recalled'});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Tin nhắn đã được thu hồi.')),
    );
  }


  void _replyToMessage(String content) {
    setState(() {
      _replyingTo = content;
    });
  }


  Future<void> _copyImageFromFirebase(String imageUrl) async {
    try {
      final ref = FirebaseStorage.instance.refFromURL(imageUrl);
      final bytes = await ref.getData();
      if (bytes == null) throw Exception('Không thể tải ảnh xuống');

      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/copied_image.png';
      final file = File(imagePath);
      await file.writeAsBytes(bytes);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hình ảnh đã được sao chép vào thiết bị!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể sao chép hình ảnh: $e')),
      );
    }
  }

  Widget _buildReplyBanner() {
    if (_replyingTo == null) return SizedBox.shrink();
    return Container(
      color: Colors.green[100], // Đổi màu nền thành xanh lá nhạt
      padding: EdgeInsets.all(10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              'Trả lời: $_replyingTo',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.green[900], // Đổi màu chữ đậm hơn để nổi bật
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.green[900]), // Đổi màu icon
            onPressed: () {
              setState(() {
                _replyingTo = null;
              });
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    String formatTimestamp(Timestamp? timestamp) {
      if (timestamp == null) return 'Không xác định'; // Xử lý nếu giá trị null
      final dateTime = timestamp.toDate();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(Duration(days: 1));

      if (dateTime.isAfter(today)) {
        return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
      } else if (dateTime.isAfter(yesterday)) {
        return 'Hôm qua ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    }


    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileScreen(Uid: widget.otherUserId),
              ),
            );
          },
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(widget.otherUserId).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Text("Đang tải...");
              final userData = snapshot.data!.data() as Map<String, dynamic>;
              return Row(
                children: [
                  CircleAvatar(
                    backgroundImage: userData['profile'] != null
                        ? NetworkImage(userData['profile'])
                        : const AssetImage('assets/default_avatar.png') as ImageProvider,
                  ),
                  const SizedBox(width: 10),
                  Text(userData['username'] ?? "Người dùng"),
                ],
              );
            },
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!.docs;
                String lastMessageTime = 'lastMessageTime'; // Khai báo biến để chứa thời gian tin nhắn cuối cùng

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final messageData = messages[index].data() as Map<String, dynamic>;
                    final isMe = messageData['senderId'] == currentUserId;
                    final isImage = messageData['type'] == 'image';
                    final timestamp = messageData['timestamp'] as Timestamp?;
                    String formattedTime = formatTimestamp(timestamp);
                    if (messageData['timestamp'] != null) {
                      lastMessageTime = formatTimestamp(messageData['timestamp']);
                    } else {
                      lastMessageTime = 'Unknown time'; // Or any fallback value
                    }

                    return GestureDetector(
                      onLongPress: () {
                        MessageActions.showMessageMenu(
                          context: context,
                          onReply: () => _replyToMessage(messageData['content']),
                          onRecall: () => _recallMessage(messages[index]),
                          onCopy: () {
                            if (isImage) {
                              _copyImageFromFirebase(messageData['content']);
                            } else {
                              Clipboard.setData(
                                ClipboardData(text: messageData['content']),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Đã sao chép tin nhắn!')),
                              );
                            }
                          },
                          isImage: isImage,
                          contentOrUrl: messageData['content'],
                          timestamp: messageData['timestamp'],
                        );
                      },
                      child: Column(
                        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          if (messageData.containsKey('replyTo'))
                            Container(
                              margin: const EdgeInsets.only(left: 50, bottom: 5),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                messageData['replyTo'],
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          isImage
                              ? Image.network(
                            messageData['content'],
                            width: 200,
                            height: 300,
                            fit: BoxFit.cover,
                          )
                              : Container(
                            margin: const EdgeInsets.symmetric(
                              vertical: 5,
                              horizontal: 10, // Khoảng cách cách 2 bên màn hình
                            ),
                            padding: const EdgeInsets.all(8),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.42, // Độ rộng tối đa 75% màn hình
                            ),
                            decoration: BoxDecoration(
                              color: isMe ? Colors.blue[100] : Colors.grey[300],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  messageData['content'],
                                  style: const TextStyle(fontSize: 14),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Hiển thị thời gian
                                    Text(
                                      formatTimestamp(messageData['timestamp']),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    if (isMe)
                                    // Hiển thị trạng thái gửi/nhận/xem
                                      Text(
                                        getStatusIcon(messageData['status'] ?? ''),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Hiển thị thời gian tin nhắn cuối cùng của cả 2 người
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  lastMessageTime,  // Hiển thị thời gian tin nhắn cuối cùng
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),






  _buildReplyBanner(), // Phần trả lời tin nhắn
          Divider(
            color: Colors.grey, // Màu của đường kẻ
            thickness: 1, // Độ dày
            height: 3, // Giảm khoảng cách giữa đường kẻ và các phần tử
          ), // Đường kẻ ngang
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3), // Giảm khoảng cách
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.image),
                  onPressed: () => _sendImage(ImageSource.gallery),
                ),
                IconButton(
                  icon: const Icon(Icons.camera_alt),
                  onPressed: () => _sendImage(ImageSource.camera),
                ),
                Expanded(
                  child: SizedBox(
                    height: 55, // Giảm chiều cao khung nhập tin nhắn
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: "Nhập tin nhắn...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 8, // Giảm khoảng cách bên trong TextField
                          horizontal: 10,
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),


      floatingActionButton: _showScrollToBottomButton
          ? AnimatedPadding(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.only(
          bottom: _replyingTo != null ? 120 : 60, // Dịch lên khi đang trả lời
        ),
        child: FloatingActionButton(
          mini: true,
          backgroundColor: Colors.blueAccent,
          onPressed: _scrollToBottom,
          child: const Icon(Icons.arrow_downward),
        ),
      )
          : null,
    );
  }

}




import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'groupchat_detail_information_screen.dart';
import 'message_actions.dart';

class GroupChatDetailScreen extends StatefulWidget {
  final String chatId;
  final String groupName;
  final String groupImage;
  final String currentUserId;
  final String otherUserId;

  const GroupChatDetailScreen({
    Key? key,
    required this.chatId,
    required this.groupName,
    required this.groupImage,
    required this.currentUserId,
    required this.otherUserId,

  }) : super(key: key);

  @override
  State<GroupChatDetailScreen> createState() => _GroupChatDetailScreenState();
}

class _GroupChatDetailScreenState extends State<GroupChatDetailScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _messageController = TextEditingController();
  List<String> pinnedMessages = [];
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToBottomButton = false;
  String? _replyingTo;
  String lastMessageTime = '';
  bool _isUploading = false;



  String getStatusIcon(String status) {
    switch (status) {
      case 'sent':
        return ' Đã gửi🕑'; // Đã gửi
      case 'delivered':
        return 'Đã nhận✔️'; // Đã nhận
      case 'read':
        return 'Đã xem👁️'; // Đã xem
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
  bool isAdminOrMod() {
    // Điều kiện kiểm tra nếu người dùng là trưởng nhóm hoặc phó nhóm
    return true; // Thay logic kiểm tra quyền tại đây
  }
  Future<void> _fetchPinnedMessages() async {
    DocumentSnapshot chatDoc = await _firestore.collection('chats').doc(
        widget.chatId).get();
    if (chatDoc.exists) {
      setState(() {
        pinnedMessages = List<String>.from(chatDoc['pinnedMessages'] ?? []);
      });
    }
  }

  Future<void> sendMessage(String message) async {
    if (message
        .trim()
        .isEmpty) return;

    await _firestore.collection('chats/${widget.chatId}/messages').add({
      'senderId': widget.currentUserId,
      'text': message.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    _messageController.clear();
  }

  Future<void> togglePinMessage(String messageId) async {
    DocumentSnapshot chatDoc = await _firestore.collection('chats').doc(
        widget.chatId).get();
    if (!chatDoc.exists) return;

    List<String> pinned = List<String>.from(chatDoc['pinnedMessages'] ?? []);

    if (pinned.contains(messageId)) {
      pinned.remove(messageId);
    } else {
      pinned.add(messageId);
    }

    await _firestore.collection('chats').doc(widget.chatId).update(
        {'pinnedMessages': pinned});
    _fetchPinnedMessages();
  }



  void dispose() {
    _saveDraftMessage();
    _messageController.dispose();
    _scrollController.removeListener(_onScroll);
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
    FirebaseFirestore.instance.collection('chats').doc(widget.chatId)
        .get()
        .then((snapshot) {
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

  Future<void> _sendMessage(String text) async {
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

    await FirebaseFirestore.instance.collection('chats')
        .doc(widget.chatId)
        .update({
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
            () => _scrollController.jumpTo(
            _scrollController.position.minScrollExtent),
      );
      _markMessagesAsRead(); // Đánh dấu tin nhắn là đã xem
    }
  }

  Future<void> _sendImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _isUploading = true; // Bắt đầu tải lên
      });

      try {
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

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred while loading the image: $e')),
        );
      } finally {
        setState(() {
          _isUploading = false; // Hoàn thành tải lên
        });
      }
    }
  }


  Future<void> _recallMessage(DocumentSnapshot message) async {
    final currentUserId = FirebaseAuth.instance.currentUser
        ?.uid; // Lấy ID người dùng hiện tại
    final senderId = message['senderId']; // Lấy ID người gửi từ tin nhắn
    final currentTime = DateTime.now();
    final messageTime = message['timestamp'].toDate();
    final difference = currentTime.difference(messageTime);


    // Kiểm tra nếu người dùng hiện tại không phải người gửi
    if (currentUserId != senderId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('You cannot recall other peoples messages.')),
      );
      return;
    }

    // Kiểm tra thời gian quá 1 phút
    if (difference.inMinutes > 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Cannot be recalled, message sent more than 1 minute ago.')),
      );
      return;
    }

    // Cập nhật nội dung tin nhắn thành "đã bị thu hồi"
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .doc(message.id)
        .update({'content': 'Message has been revoked', 'type': 'recalled'});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('The message has been recalled.')),
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
      if (bytes == null) throw Exception('Unable to download image');

      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/copied_image.png';
      final file = File(imagePath);
      await file.writeAsBytes(bytes);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image has been copied to the device!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to copy image: $e')),
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
              'Reply: $_replyingTo',
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
      if (timestamp == null) {
        return 'Not sent yet'; // Fallback string for null timestamps
      }

      final dateTime = timestamp.toDate();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(Duration(days: 1));

      if (dateTime.isAfter(today)) {
        return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
      } else if (dateTime.isAfter(yesterday)) {
        return 'Yesterday ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    }



    return Stack(
        children: [
          Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.grey.shade100,
              title: Row(
                children: [
                  CircleAvatar(
                    backgroundImage: widget.groupImage.isNotEmpty
                        ? NetworkImage(widget.groupImage)
                        : AssetImage('assets/default_group.png') as ImageProvider,
                  ),
                  const SizedBox(width: 8),
                  Text(widget.groupName),
                ],
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.info),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GroupChatDetailInformationScreen(
                          chatId: widget.chatId,
                          currentUserId: widget.currentUserId,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
      body: Column(
        children: [
          // Display pinned messages
          if (pinnedMessages.isNotEmpty)
            Container(
              color: Colors.yellow[100],
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  const Text(
                    "Pinned messages:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  for (String messageId in pinnedMessages)
                    FutureBuilder<DocumentSnapshot>(
                      future: _firestore
                          .collection('chats/${widget.chatId}/messages')
                          .doc(messageId)
                          .get(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }
                        if (!snapshot.hasData || !snapshot.data!.exists) {
                          return const SizedBox();
                        }

                        String text = snapshot.data!['text'];
                        return ListTile(
                          title: Text(text),
                        );
                      },
                    ),
                ],
              ),


    ),
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
                String lastMessageTime = ''; // Store last message time

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final messageData = messages[index].data() as Map<String, dynamic>;
                    final isMe = messageData['senderId'] == currentUserId;
                    final isImage = messageData['type'] == 'image';
                    final senderId = messageData['senderId'];
                    final timestamp = messageData['timestamp'] is Timestamp
                        ? messageData['timestamp'] as Timestamp
                        : null;

                    if (timestamp != null) {
                      lastMessageTime = formatTimestamp(timestamp);
                    } else {
                      lastMessageTime = 'Unknown time';
                    }

                    return GestureDetector(
                      key: ValueKey(messageData['id'] ?? index),
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
                                const SnackBar(content: Text('Message copied!')),
                              );
                            }
                          },
                          isImage: isImage,
                          contentOrUrl: messageData['content'],
                          timestamp: messageData['timestamp'],
                        );
                      },
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                        children: [
                          if (!isMe)
                            StreamBuilder<DocumentSnapshot>(
                              stream: FirebaseFirestore.instance.collection('users').doc(senderId).snapshots(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) return const SizedBox.shrink();
                                final userData = snapshot.data!.data() as Map<String, dynamic>;

                                return Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundImage: userData['profile'] != null
                                          ? NetworkImage(userData['profile'])
                                          : const AssetImage('assets/default_avatar.png') as ImageProvider,
                                    ),
                                    const SizedBox(width: 10),
                                  ],
                                );
                              },
                            ),
                          Flexible(
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isMe ? Colors.blue[100] : Colors.grey[300],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: StreamBuilder<DocumentSnapshot>(
                                stream: FirebaseFirestore.instance.collection('users').doc(senderId).snapshots(),
                                builder: (context, snapshot) {
                                  String senderName = 'Unknown';
                                  if (snapshot.hasData) {
                                    final userData = snapshot.data!.data() as Map<String, dynamic>;
                                    senderName = userData['username'] ?? 'Unknown';
                                  }
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (!isMe)
                                        Text(
                                          senderName,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      if (isImage)
                                        Image.network(
                                          messageData['content'],
                                          width: 200,
                                          height: 300,
                                          fit: BoxFit.cover,
                                        )
                                      else
                                        Text(
                                          messageData['content'],
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      const SizedBox(height: 5),
                                      Text(
                                        formatTimestamp(timestamp),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
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

          // Show last message time
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  lastMessageTime,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          _buildReplyBanner(), // Part for replying to messages
          Divider(color: Colors.grey, thickness: 1, height: 3),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
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
                    height: 55,
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: "Enter message...",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 10),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _sendMessage(_messageController.text),
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
    ),
  ]
    );
  }
}

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'groupchat_detail_screen.dart';

class CreateGroupScreen extends StatefulWidget {
  final String currentUserId; // Nhận userId của người tạo
  const CreateGroupScreen({Key? key, required this.currentUserId}) : super(key: key);

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _groupNameController = TextEditingController();
  List<String> selectedUserIds = [];
  File? _groupImage;
  bool _isCreatingGroup = false;

  @override
  void initState() {
    super.initState();
    selectedUserIds.add(widget.currentUserId); // Thêm người tạo làm nhóm trưởng
  }

  Future<void> pickGroupImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _groupImage = File(pickedFile.path);
      });
    }
  }

  Future<void> createGroupChat() async {
    if (_groupNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập tên nhóm!")),
      );
      return;
    }

    if (_groupImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng chọn ảnh nhóm!")),
      );
      return;
    }

    if (selectedUserIds.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng chọn ít nhất 2 người dùng khác để tạo nhóm!")),
      );
      return;
    }

    setState(() {
      _isCreatingGroup = true;
    });

    try {
      String groupImageUrl = await uploadImageToStorage(_groupImage!);

      // Lưu thông tin nhóm vào Firestore và nhận lại document ID (chatId)
      DocumentReference groupDoc = await _firestore.collection('chats').add({
        'type': 'group',
        'users': selectedUserIds,
        'groupName': _groupNameController.text.trim(),
        'groupImage': groupImageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageTime': null,
        'admin': widget.currentUserId,
        'pinnedMessages': [], // Danh sách tin nhắn đã ghim
      });


      // Chuyển hướng sang màn hình chi tiết nhóm
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => GroupChatDetailScreen(
            chatId: groupDoc.id,
            groupName: _groupNameController.text.trim(),
            groupImage: groupImageUrl,
            currentUserId: widget.currentUserId, otherUserId: '',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: $e")),
      );
    } finally {
      setState(() {
        _isCreatingGroup = false;
      });
    }
  }




  Future<String> uploadImageToStorage(File image) async {
    try {
      // Kiểm tra file trước khi tải lên
      if (!image.existsSync()) {
        throw Exception("Tệp không tồn tại hoặc không hợp lệ.");
      }

      // Tạo đường dẫn lưu ảnh trên Firebase Storage
      String fileName = 'group_images/${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference ref = FirebaseStorage.instance.ref().child(fileName);

      // Tải ảnh lên
      UploadTask uploadTask = ref.putFile(image);
      TaskSnapshot snapshot = await uploadTask;

      // Kiểm tra trạng thái tải lên
      if (snapshot.state == TaskState.success) {
        // Lấy URL của ảnh sau khi tải lên
        String downloadUrl = await snapshot.ref.getDownloadURL();
        return downloadUrl;
      } else {
        throw Exception("Tải ảnh lên không thành công.");
      }
    } catch (e) {
      // Log chi tiết lỗi
      print("Lỗi khi tải ảnh lên Firebase Storage: $e");
      throw Exception("Lỗi khi tải ảnh lên Firebase Storage: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade100,
        title: const Text("Tạo nhóm"),
        actions: [
          IconButton(
            icon: const Icon(Icons.done),
            onPressed: _isCreatingGroup ? null : createGroupChat,
          ),
        ],
      ),
      body: _isCreatingGroup
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          GestureDetector(
            onTap: pickGroupImage,
            child: Container(
              margin: const EdgeInsets.all(16.0),
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: _groupImage != null
                    ? DecorationImage(
                  image: FileImage(_groupImage!),
                  fit: BoxFit.cover,
                )
                    : null,
                color: Colors.grey[300],
              ),
              child: _groupImage == null
                  ? const Icon(Icons.add_a_photo, size: 40, color: Colors.grey)
                  : null,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _groupNameController,
              decoration: const InputDecoration(
                labelText: "Tên nhóm",
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Không có người dùng nào."));
                }

                // Lọc danh sách, loại bỏ người tạo nhóm
                List<QueryDocumentSnapshot> filteredUsers = snapshot.data!.docs.where((doc) {
                  return doc.id != widget.currentUserId; // Loại người tạo nhóm
                }).toList();

                if (filteredUsers.isEmpty) {
                  return const Center(child: Text("Không còn người dùng nào để thêm vào nhóm."));
                }


                return ListView.builder(
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    var userDoc = filteredUsers[index];
                    var userData = userDoc.data() as Map<String, dynamic>;
                    String userId = userDoc.id;
                    String username = userData['username'] ?? 'Người dùng';
                    String avatarUrl = userData['profile'] ?? '';

                    return StatefulBuilder(
                      builder: (context, setStateCheckbox) {
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: avatarUrl.isNotEmpty
                                ? NetworkImage(avatarUrl)
                                : const AssetImage('assets/default_avatar.png') as ImageProvider,
                          ),
                          title: Text(username),
                          trailing: Checkbox(
                            value: selectedUserIds.contains(userId),
                            onChanged: (bool? value) {
                              setStateCheckbox(() {
                                if (value == true) {
                                  selectedUserIds.add(userId);
                                } else {
                                  selectedUserIds.remove(userId);
                                }
                              });
                            },
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

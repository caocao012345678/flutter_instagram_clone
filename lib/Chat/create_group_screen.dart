import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({Key? key}) : super(key: key);

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _groupNameController = TextEditingController();
  List<String> selectedUserIds = [];
  File? _groupImage;
  bool _isCreatingGroup = false;

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

    if (selectedUserIds.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng chọn ít nhất 2 người dùng để tạo nhóm!")),
      );
      return;
    }

    setState(() {
      _isCreatingGroup = true;
    });

    try {
      // Upload hình ảnh lên Firestore (giả sử bạn có một phương thức `uploadImage` để tải ảnh)
      String groupImageUrl = await uploadImageToStorage(_groupImage!);

      // Lưu thông tin nhóm vào Firestore
      await _firestore.collection('chats').add({
        'type': 'group',
        'users': selectedUserIds,
        'groupName': _groupNameController.text.trim(),
        'groupImage': groupImageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageTime': null,
      });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nhóm đã được tạo thành công!")),
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
    // Đây là nơi bạn triển khai việc tải ảnh lên Firebase Storage
    // Trả về URL của ảnh đã tải lên
    return "https://example.com/your-uploaded-image.jpg"; // Thay bằng URL thật
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var userDoc = snapshot.data!.docs[index];
                    var userData = userDoc.data() as Map<String, dynamic>;
                    String userId = userDoc.id;
                    String username = userData['username'] ?? 'Người dùng';
                    String avatarUrl = userData['profile'] ?? '';

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
                          setState(() {
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
            ),
          ),
        ],
      ),
    );
  }
}

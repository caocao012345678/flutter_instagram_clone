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

  Future<bool> isGroupNameTaken(String groupName) async {
    QuerySnapshot snapshot = await _firestore
        .collection('chats')
        .where('type', isEqualTo: 'group')
        .where('groupName', isEqualTo: groupName)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  Future<void> createGroupChat() async {
    if (_groupNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a group name!")),
      );
      return;
    }

    if (_groupImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a group photo!")),
      );
      return;
    }

    if (selectedUserIds.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one other user to create a group!")),
      );
      return;
    }

    bool groupNameExists = await isGroupNameTaken(_groupNameController.text.trim());
    if (groupNameExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Group name already exists! Please choose a different name.")),
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
            currentUserId: widget.currentUserId,
            otherUserId: '',
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
      String fileName = 'group_images/${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference ref = FirebaseStorage.instance.ref().child(fileName);

      UploadTask uploadTask = ref.putFile(image);
      TaskSnapshot snapshot = await uploadTask;

      if (snapshot.state == TaskState.success) {
        return await snapshot.ref.getDownloadURL();
      } else {
        throw Exception("Image upload failed.");
      }
    } catch (e) {
      throw Exception("Error uploading image to Firebase Storage: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Create a group"),
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
                      ? const Icon(
                      Icons.add_a_photo, size: 40, color: Colors.grey)
                      : null,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: _groupNameController,
                  decoration: const InputDecoration(
                    labelText: "Group name",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              Expanded(
                child: Column(
                  children: [
                    // Hiển thị thông tin của nhóm trưởng
                    ListTile(
                      leading: CircleAvatar(
                        backgroundImage: const AssetImage(
                            'assets/default_avatar.png'),
                      ),
                      title: const Text("Bạn (Trưởng nhóm)"),
                      subtitle: const Text("Không thể loại bỏ"),
                    ),
                    const Divider(),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: _firestore.collection('users').snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return const                                                                                                                                              Center(child: Text(
                                "Không có người dùng nào khả dụng."));
                          }

                          // Lọc danh sách để loại trừ currentUserId
                          List<QueryDocumentSnapshot> filteredUsers = snapshot
                              .data!.docs.where((doc) {
                            return doc.id != widget.currentUserId;
                          }).toList();

                          if (filteredUsers.isEmpty) {
                            return const Center(child: Text(
                                "Không có người dùng nào khác."));
                          }

                          return ListView.builder(
                            itemCount: filteredUsers.length,
                            itemBuilder: (context, index) {
                              var userDoc = filteredUsers[index];
                              var userData = userDoc.data() as Map<
                                  String,
                                  dynamic>;
                              String userId = userDoc.id;
                              String username = userData['username'] ??
                                  'Người dùng';
                              String avatarUrl = userData['profile'] ?? '';

                              return StatefulBuilder(
                                builder: (context, setStateCheckbox) {
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundImage: avatarUrl.isNotEmpty
                                          ? NetworkImage(avatarUrl)
                                          : const AssetImage(
                                          'assets/default_avatar.png') as ImageProvider,
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
              )
            ]
        )
    );
  }
}


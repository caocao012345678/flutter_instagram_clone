import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GroupChatScreen extends StatefulWidget {
  const GroupChatScreen({super.key});

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<String> _selectedUserIds = [];

  void _createGroupChat() async {
    if (_selectedUserIds.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chọn ít nhất 2 người dùng để tạo nhóm!')),
      );
      return;
    }

    final groupChat = await _firestore.collection('chats').add({
      'isGroup': true,
      'users': _selectedUserIds,
      'createdAt': Timestamp.now(),
    });

    Navigator.pop(context);
    Navigator.pushNamed(context, '/chat_detail', arguments: {
      'chatId': groupChat.id,
      'isGroup': true,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Tạo nhóm chat"),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _createGroupChat,
          ),
        ],
      ),
      body: StreamBuilder(
        stream: _firestore.collection('users').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var user = snapshot.data!.docs[index];
              String userId = user.id;
              String username = user['username'] ?? 'Người dùng';
              String avatarUrl = user['profile'] ?? '';

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: avatarUrl.isNotEmpty
                      ? CachedNetworkImageProvider(avatarUrl)
                      : const AssetImage('assets/default_avatar.png') as ImageProvider,
                ),
                title: Text(username),
                trailing: Checkbox(
                  value: _selectedUserIds.contains(userId),
                  onChanged: (selected) {
                    setState(() {
                      if (selected == true) {
                        _selectedUserIds.add(userId);
                      } else {
                        _selectedUserIds.remove(userId);
                      }
                    });
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

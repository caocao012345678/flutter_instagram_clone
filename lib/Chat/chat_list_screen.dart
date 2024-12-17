import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'groupchat_detail_screen.dart';

class ChatListScreen extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ChatListScreen({super.key});

  String formatTimestamp(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (dateTime.isAfter(today)) {
      return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (dateTime.isAfter(yesterday)) {
      return 'Hôm qua ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _auth.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Chat list"),
        backgroundColor: Colors.grey.shade100,
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add),
            onPressed: () {
              Navigator.pushNamed(context, '/create_group_chat');
            },
          ),
        ],
      ),
      body: StreamBuilder(
        stream: _firestore
            .collection('chats')
            .where('users', arrayContains: currentUserId)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("There is no conversation."));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var chatData = snapshot.data!.docs[index];
              var chatMap = chatData.data() as Map<String, dynamic>?;

              String chatType = chatMap?['type'] ?? 'personal';
              String lastMessage = chatMap != null && chatMap.containsKey('lastMessage')
                  ? chatMap['lastMessage']
                  : 'Không có tin nhắn.';
              Timestamp? lastMessageTimestamp = chatMap != null && chatMap.containsKey('lastMessageTime')
                  ? chatMap['lastMessageTime'] as Timestamp?
                  : null;

              if (chatType == 'group') {
                // Hiển thị nhóm chat
                String groupName = chatMap?['groupName'] ?? 'Group';
                String groupImage = chatMap?['groupImage'] ?? '';

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: groupImage.isNotEmpty
                        ? NetworkImage(groupImage)
                        : const AssetImage('assets/default_group_avatar.png') as ImageProvider,
                  ),
                  title: Text(groupName),
                  subtitle: Text(lastMessage),
                  trailing: Text(
                    lastMessageTimestamp != null
                        ? formatTimestamp(lastMessageTimestamp)
                        : '',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GroupChatDetailScreen(
                          chatId: chatData.id,
                          groupName: groupName,
                          groupImage: groupImage,
                          currentUserId: currentUserId, otherUserId: '',
                        ),
                      ),
                    );
                  },
                );
              } else {
                // Hiển thị cuộc trò chuyện cá nhân
                List<dynamic> users = chatMap?['users'] ?? [];
                String otherUserId = users.firstWhere(
                      (userId) => userId != currentUserId,
                  orElse: () => '',
                );

                if (otherUserId.isEmpty || chatData.id.isEmpty) {
                  return const SizedBox(); // Bỏ qua các trường hợp dữ liệu không hợp lệ
                }

                return StreamBuilder<DocumentSnapshot>(
                  stream: _firestore.collection('users').doc(otherUserId).snapshots(),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox();
                    }

                    if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                      return const SizedBox();
                    }

                    var userData = userSnapshot.data!.data() as Map<String, dynamic>;
                    String username = userData['username'] ?? 'User';
                    String avatarUrl = userData['profile'] ?? '';

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: avatarUrl.isNotEmpty
                            ? NetworkImage(avatarUrl)
                            : const AssetImage('assets/default_avatar.png') as ImageProvider,
                      ),
                      title: Text(username),
                      subtitle: Text(lastMessage),
                      trailing: Text(
                        lastMessageTimestamp != null
                            ? formatTimestamp(lastMessageTimestamp)
                            : '',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/chat_detail',
                          arguments: {
                            'chatId': chatData.id,
                            'otherUserId': otherUserId,
                          },
                        );
                      },
                    );
                  },
                );
              }
            },
          );
        },
      ),
    );
  }
}

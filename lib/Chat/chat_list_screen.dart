
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatListScreen extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = _auth.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Danh sách chat"),
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
            return const Center(child: Text("Không có cuộc trò chuyện nào."));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var chatData = snapshot.data!.docs[index];
              String otherUserId = chatData['users']
                  .firstWhere((userId) => userId != currentUserId);
              String lastMessage = chatData['lastMessage'] ?? '';
              DateTime? lastMessageTime = (chatData['lastMessageTime'] as Timestamp?)?.toDate();

              // Truy vấn thông tin người dùng từ collection 'users'
              return FutureBuilder<DocumentSnapshot>(
                future: _firestore.collection('users').doc(otherUserId).get(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                    return const SizedBox(); // Nếu không tìm thấy dữ liệu người dùng, không làm gì
                  }

                  var userData = userSnapshot.data!.data() as Map<String, dynamic>;
                  String username = userData['username'] ?? 'Người dùng';
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
                      lastMessageTime != null
                          ? "${lastMessageTime.hour}:${lastMessageTime.minute}"
                          : '',
                      style: const TextStyle(fontSize: 12),
                    ),
                    onTap: () {
                      // Điều hướng đến màn hình chat chi tiết
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
            },
          );
        },
      ),
    );
  }
}


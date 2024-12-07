// //
// // import 'package:flutter/material.dart';
// // import 'package:cloud_firestore/cloud_firestore.dart';
// // import 'package:firebase_auth/firebase_auth.dart';
// //
// // class ChatListScreen extends StatelessWidget {
// //   final FirebaseAuth _auth = FirebaseAuth.instance;
// //   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
// //
// //   ChatListScreen({super.key});
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     final currentUserId = _auth.currentUser!.uid;
// //
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: const Text("Danh sách chat"),
// //       ),
// //       body: StreamBuilder(
// //         stream: _firestore
// //             .collection('chats')
// //             .where('users', arrayContains: currentUserId)
// //             .snapshots(),
// //         builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
// //           if (snapshot.connectionState == ConnectionState.waiting) {
// //             return const Center(child: CircularProgressIndicator());
// //           }
// //
// //           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
// //             return const Center(child: Text("Không có cuộc trò chuyện nào."));
// //           }
// //
// //           return ListView.builder(
// //             itemCount: snapshot.data!.docs.length,
// //             itemBuilder: (context, index) {
// //               var chatData = snapshot.data!.docs[index];
// //               String otherUserId = chatData['users']
// //                   .firstWhere((userId) => userId != currentUserId);
// //               String lastMessage = chatData['lastMessage'] ?? '';
// //               DateTime? lastMessageTime = (chatData['lastMessageTime'] as Timestamp?)?.toDate();
// //
// //               // Truy vấn thông tin người dùng từ collection 'users'
// //               return FutureBuilder<DocumentSnapshot>(
// //                 future: _firestore.collection('users').doc(otherUserId).get(),
// //                 builder: (context, userSnapshot) {
// //                   if (userSnapshot.connectionState == ConnectionState.waiting) {
// //                     return const Center(child: CircularProgressIndicator());
// //                   }
// //
// //                   if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
// //                     return const SizedBox(); // Nếu không tìm thấy dữ liệu người dùng, không làm gì
// //                   }
// //
// //                   var userData = userSnapshot.data!.data() as Map<String, dynamic>;
// //                   String username = userData['username'] ?? 'Người dùng';
// //                   String avatarUrl = userData['profile'] ?? '';
// //
// //                   return ListTile(
// //                     leading: CircleAvatar(
// //                       backgroundImage: avatarUrl.isNotEmpty
// //                           ? NetworkImage(avatarUrl)
// //                           : const AssetImage('assets/default_avatar.png') as ImageProvider,
// //                     ),
// //                     title: Text(username),
// //                     subtitle: Text(lastMessage),
// //                     trailing: Text(
// //                       lastMessageTime != null
// //                           ? "${lastMessageTime.hour}:${lastMessageTime.minute}"
// //                           : '',
// //                       style: const TextStyle(fontSize: 12),
// //                     ),
// //                     onTap: () {
// //                       // Điều hướng đến màn hình chat chi tiết
// //                       Navigator.pushNamed(
// //                         context,
// //                         '/chat_detail',
// //                         arguments: {
// //                           'chatId': chatData.id,
// //                           'otherUserId': otherUserId,
// //                         },
// //                       );
// //                     },
// //                   );
// //                 },
// //               );
// //             },
// //           );
// //         },
// //       ),
// //     );
// //   }
// // }
// //
// //
//
//
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
//
// class ChatListScreen extends StatelessWidget {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//
//   ChatListScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final currentUserId = _auth.currentUser!.uid;
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Danh sách chat"),
//       ),
//       body: StreamBuilder(
//         stream: _firestore
//             .collection('chats')
//             .where('users', arrayContains: currentUserId)
//             .snapshots(),
//         builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//
//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return const Center(child: Text("Không có cuộc trò chuyện nào."));
//           }
//
//           return ListView.builder(
//             itemCount: snapshot.data!.docs.length,
//             itemBuilder: (context, index) {
//               var chatData = snapshot.data!.docs[index];
//
//               // Ép kiểu Object? -> Map<String, dynamic>
//               var chatMap = chatData.data() as Map<String, dynamic>?;
//
//               String lastMessage = chatMap != null && chatMap.containsKey('lastMessage')
//                   ? chatMap['lastMessage']
//                   : 'Không có tin nhắn.';
//               DateTime? lastMessageTime = chatMap != null && chatMap.containsKey('lastMessageTime')
//                   ? (chatMap['lastMessageTime'] as Timestamp?)?.toDate()
//                   : null;
//
//               String otherUserId = chatMap != null
//                   ? chatMap['users']
//                   .firstWhere((userId) => userId != currentUserId)
//                   : '';
//
//               return StreamBuilder<DocumentSnapshot>(
//                 stream: _firestore.collection('users').doc(otherUserId).snapshots(),
//                 builder: (context, userSnapshot) {
//                   if (userSnapshot.connectionState == ConnectionState.waiting) {
//                     return const SizedBox();
//                   }
//
//                   if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
//                     return const SizedBox(); // Không hiển thị nếu không có dữ liệu người dùng
//                   }
//
//                   var userData = userSnapshot.data!.data() as Map<String, dynamic>;
//                   String username = userData['username'] ?? 'Người dùng';
//                   String avatarUrl = userData['profile'] ?? '';
//
//                   return ListTile(
//                     leading: CircleAvatar(
//                       backgroundImage: avatarUrl.isNotEmpty
//                           ? NetworkImage(avatarUrl)
//                           : const AssetImage('assets/default_avatar.png') as ImageProvider,
//                     ),
//                     title: Text(username),
//                     subtitle: Text(lastMessage),
//                     trailing: Text(
//                       lastMessageTime != null
//                           ? "${lastMessageTime.hour}:${lastMessageTime.minute.toString().padLeft(2, '0')}"
//                           : '',
//                       style: const TextStyle(fontSize: 12, color: Colors.grey),
//                     ),
//                     onTap: () {
//                       Navigator.pushNamed(
//                         context,
//                         '/chat_detail',
//                         arguments: {
//                           'chatId': chatData.id,
//                           'otherUserId': otherUserId,
//                         },
//                       );
//                     },
//                   );
//                 },
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      appBar: AppBar(
        title: const Text("Danh sách chat"),
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
            return const Center(child: Text("Không có cuộc trò chuyện nào."));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var chatData = snapshot.data!.docs[index];
              var chatMap = chatData.data() as Map<String, dynamic>?;

              String lastMessage = chatMap != null && chatMap.containsKey('lastMessage')
                  ? chatMap['lastMessage']
                  : 'Không có tin nhắn.';
              Timestamp? lastMessageTimestamp = chatMap != null && chatMap.containsKey('lastMessageTime')
                  ? chatMap['lastMessageTime'] as Timestamp?
                  : null;

              String otherUserId = chatMap != null
                  ? chatMap['users']
                  .firstWhere((userId) => userId != currentUserId)
                  : '';

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
            },
          );
        },
      ),
    );
  }
}

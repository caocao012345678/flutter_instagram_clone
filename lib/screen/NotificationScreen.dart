import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_instagram_clone/util/image_cached.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'PostDetailScreen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  /// Đánh dấu thông báo là đã đọc
  Future<void> _markAsRead(String notificationId) async {
    try {
      await _firebaseFirestore
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notification',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firebaseFirestore
            .collection('notifications')
            .where('receiverId', isEqualTo: currentUserId)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No notifications"));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final notificationData = snapshot.data!.docs[index];
              final Map<String, dynamic> notification =
              notificationData.data() as Map<String, dynamic>;

              return FutureBuilder<DocumentSnapshot>(
                future: _firebaseFirestore
                    .collection('users')
                    .doc(notification['senderId'])
                    .get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData || userSnapshot.data == null) {
                    return const ListTile(
                      title: Text("User does not exist"),
                    );
                  }

                  final userData =
                  userSnapshot.data!.data() as Map<String, dynamic>;
                  final senderName = userData['username'];
                  final senderProfileImage =
                      userData['profile'] ?? '';

                  final bool isRead = notification['read'] ?? false;

                  return ListTile(
                    leading: ClipOval(
                      child: SizedBox(
                        width: 50.w,
                        height: 50.h,
                        child: CachedImage(senderProfileImage),
                      ),
                    ),
                    title: Text(
                      notification['type'] == 'like'
                          ? '$senderName liked your post'
                          : '$senderName commented: ${notification['commentText'] ?? ''}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      _formatTimestamp(notification['timestamp']),
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey),
                    ),
                    onTap: () async {
                      if (notification['postId'] != null) {
                        // Cập nhật trạng thái đã đọc
                        await _markAsRead(notificationData.id);

                        // Điều hướng đến chi tiết bài viết
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PostDetailScreen(
                              postId: notification['postId'],
                            ),
                          ),
                        );
                      }
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

  /// Định dạng thời gian từ Firestore
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown time';
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }
}

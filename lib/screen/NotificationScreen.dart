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
      backgroundColor: Colors.white,
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
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Colors.black,
                      ),
                    );
                  }

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
                      formatTimestamp(notification['timestamp']),
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey),
                    ),
                    onTap: () {
                      if (notification['postId'] != null) {
                        _markAsRead(notificationData.id);

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

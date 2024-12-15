import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:date_format/date_format.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_instagram_clone/data/firebase_service/firestore.dart';
import 'package:flutter_instagram_clone/util/image_cached.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Comment extends StatefulWidget {
  String type;
  String uid;
  Comment(this.type, this.uid, {super.key});

  @override
  State<Comment> createState() => _CommentState();
}

class _CommentState extends State<Comment> {
  final comment = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late String currentUserId;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser!.uid;
  }

  Future<void> _sendCommentNotification(String postId, String postOwnerUid, String commentText) async {
    try {
      // Thêm thông báo vào Firestore
      await FirebaseFirestore.instance.collection('notifications').add({
        'postId': postId,
        'senderId': currentUserId,
        'receiverId': postOwnerUid,
        'type': 'comment',
        'commentText': commentText,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      // Lấy thông tin người gửi
      final senderSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();

      if (!senderSnapshot.exists) {
        print("Người dùng không tồn tại.");
        return;
      }

      final senderData = senderSnapshot.data()!;
      final senderName = senderData['username'];

      // Lấy token và gửi thông báo đẩy
      final deviceToken = await Firebase_Firestor().getUserDeviceToken(postOwnerUid);
      if (deviceToken != null && deviceToken.isNotEmpty) {
        await Firebase_Firestor().sendPushNotification(
            deviceToken: deviceToken,
            title: "New Comment!",
            body: "$senderName comment your post: "+commentText,
            type: "comment"
        );
      }
    } catch (e) {
      print("Error sending notification: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(25.r),
        topRight: Radius.circular(25.r),
      ),
      child: Container(
        color: Colors.white,
        height: 200.h,
        child: Stack(
          children: [
            Positioned(
              top: 8.h,
              left: 140.w,
              child: Container(
                width: 100.w,
                height: 3.h,
                color: Colors.black,
              ),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection(widget.type)
                  .doc(widget.uid)
                  .collection('comments')
                  .snapshots(),
              builder: (context, snapshot) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.h),
                  child: ListView.builder(
                    itemBuilder: (context, index) {
                      if (!snapshot.hasData) {
                        return CircularProgressIndicator();
                      }
                      return comment_item(snapshot.data!.docs[index].data());
                    },
                    itemCount:
                        snapshot.data == null ? 0 : snapshot.data!.docs.length,
                  ),
                );
              },
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200, // Màu nền xám
                    borderRadius: BorderRadius.circular(15.r), // Bo góc
                  ),
                  height: 60.h,
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 10.w),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: comment,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText: 'Add a comment',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          if (comment.text.isNotEmpty && !isLoading) {
                            setState(() {
                              isLoading = true;
                            });

                            try {
                              // Lưu bình luận vào Firestore
                              await Firebase_Firestor().Comments(
                                comment: comment.text,
                                type: widget.type,
                                uidd: widget.uid,
                              );

                              // Lấy thông tin bài viết
                              final postSnapshot = await FirebaseFirestore.instance
                                  .collection(widget.type)
                                  .doc(widget.uid)
                                  .get();

                              if (postSnapshot.exists) {
                                final postOwnerUid = postSnapshot.data()!['uid'];

                                // Gửi thông báo nếu không phải là chủ bài viết
                                if (postOwnerUid != currentUserId) {
                                  await _sendCommentNotification(
                                    widget.uid,
                                    postOwnerUid,
                                    comment.text,
                                  );
                                }
                              }

                              setState(() {
                                comment.clear();
                                isLoading = false;
                              });

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Comment added successfully')),
                              );
                            } catch (e) {
                              setState(() {
                                isLoading = false;
                              });

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Failed to add comment: $e')),
                              );
                            }
                          }
                        },

                        /// Hiển thị icon hoặc loading
                        child: isLoading
                            ? SizedBox(
                          width: 20.w,
                          height: 20.h,
                          child: const CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2,
                          ),
                        )
                            : const Icon(Icons.send, color: Colors.black),
                      ),
                    ],
                  ),
                ),

              ),
            ),

          ],
        ),
      ),
    );
  }

  Widget comment_item(final snapshot) {
    return ListTile(
      leading: ClipOval(
        child: SizedBox(
          height: 35.h,
          width: 35.w,
          child: CachedImage(
            snapshot['profileImage'],
          ),
        ),
      ),
      title: Text(
        snapshot['username'],
        style: TextStyle(
          fontSize: 13.sp,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      subtitle: Text(
        snapshot['comment'],
        style: TextStyle(
          fontSize: 13.sp,
          color: Colors.black,
        ),
      ),
    );
  }
}

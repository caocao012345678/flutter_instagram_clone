import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_instagram_clone/data/firebase_service/firestor.dart';
import 'package:flutter_instagram_clone/screen/profile_screen.dart';
import 'package:flutter_instagram_clone/util/image_cached.dart';
import 'package:flutter_instagram_clone/widgets/comment.dart';
import 'package:flutter_instagram_clone/widgets/like_animation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:date_format/date_format.dart';

import '../Chat/chat_detail_screen.dart';

class PostWidget extends StatefulWidget {
  final Map<String, dynamic> snapshot;
  const PostWidget(this.snapshot, {super.key});

  @override
  State<PostWidget> createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  bool isAnimating = false;
  late String currentUserId;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    currentUserId = _auth.currentUser!.uid;
  }
  Future<int> _getCommentCount() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.snapshot['postId'])
        .collection('comments')
        .get();
    return snapshot.docs.length;
  }
  // Gửi thông báo khi có người like bài viết
  Future<void> _sendLikeNotification(String postId, String postOwnerUid) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'postId': postId,
        'senderId': currentUserId,
        'receiverId': postOwnerUid,
        'type': 'like',
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });
    } catch (e) {
      print("Error: $e");
    }
  }

  // Like bài viết và gửi thông báo nếu cần
  void _likePost() {
    final postOwnerUid = widget.snapshot['uid'];
    Firebase_Firestor().like(
      like: widget.snapshot['like'],
      type: 'posts',
      uid: currentUserId,
      postId: widget.snapshot['postId'],
    );
    if (postOwnerUid == currentUserId) {
      return;
    }
    if (!widget.snapshot['like'].contains(currentUserId)) {
      _sendLikeNotification(
        widget.snapshot['postId'],
        postOwnerUid,
      );
    }
  }

  // Xóa bài viết
  void _deletePost() async {
    try {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.snapshot['postId'])
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post has been deleted.')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete post failed: $error')),
      );
    }
  }

  // Chỉnh sửa caption bài viết
  void _editPost() {
    final TextEditingController captionController = TextEditingController();
    captionController.text = widget.snapshot['caption'];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit post caption'),
          content: TextField(
            controller: captionController,
            decoration: const InputDecoration(hintText: 'Write new caption'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                String newCaption = captionController.text.trim();
                if (newCaption.isNotEmpty) {
                  try {
                    await FirebaseFirestore.instance
                        .collection('posts')
                        .doc(widget.snapshot['postId'])
                        .update({'caption': newCaption});

                    setState(() {
                      widget.snapshot['caption'] = newCaption;
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Update successful'),
                      ),
                    );
                    Navigator.pop(context);
                  } catch (error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Update failed: $error'),
                      ),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Thông tin người đăng bài
        ListTile(
          leading: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileScreen(Uid: widget.snapshot['uid']),
                ),
              );
            },
            child: ClipOval(
              child: SizedBox(
                width: 40.w,
                height: 40.h,
                child: CachedImage(widget.snapshot['profileImage']),
              ),
            ),
          ),
          title: Text(
            widget.snapshot['username'],
            style: TextStyle(fontSize: 13.sp),
          ),
          trailing: PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz),
            onSelected: (value) async {
              switch (value) {
                case 'Delete':
                  _deletePost();
                  break;
                case 'Edit Caption':
                  _editPost();
                  break;
                case 'Chat':
                  try {
                    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
                    final otherUserId = widget.snapshot['uid'];

                    final chatId = currentUserId.hashCode <= otherUserId.hashCode
                        ? '$currentUserId\_$otherUserId'
                        : '$otherUserId\_$currentUserId';

                    final chatRef = FirebaseFirestore.instance
                        .collection('chats')
                        .doc(chatId);

                    await chatRef.set({
                      'users': [currentUserId, otherUserId],
                      'lastMessage': '',
                      'lastMessageTime': FieldValue.serverTimestamp(),
                    }, SetOptions(merge: true));

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatDetailScreen(
                          chatId: chatId,
                          otherUserId: otherUserId,
                        ),
                      ),
                    );
                  } catch (e) {
                    print('Error creating or navigating to chat: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Error creating or opening chat!')),
                    );
                  }
                  break;
                case 'Block':
                  ();
                  break;
                default:
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error')),
                  );
              }
            },
            itemBuilder: (context) {
              // Kiểm tra người dùng có phải là chủ bài viết không
              bool isOwner = widget.snapshot['uid'] == currentUserId;

              return [
                if (isOwner) ...[
                  const PopupMenuItem<String>(
                    value: 'Delete',
                    child: Text('Delete post'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'Edit Caption',
                    child: Text('Edit Caption'),
                  ),
                ] else ...[
                  const PopupMenuItem<String>(
                    value: 'Chat',
                    child: Text('Chat'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'Block',
                    child: Text('Block'),
                  ),
                ]
              ];
            },
          ),
        ),

        // Ảnh bài viết và hiệu ứng like
        GestureDetector(
          onDoubleTap: () {
            _likePost();
            setState(() => isAnimating = true);
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              CachedImage(widget.snapshot['postImage']),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 400),
                opacity: isAnimating ? 1 : 0,
                child: LikeAnimation(
                  child: Icon(Icons.favorite, size: 100.w, color: Colors.red),
                  isAnimating: isAnimating,
                  duration: const Duration(milliseconds: 400),
                  iconlike: false,
                  End: () => setState(() => isAnimating = false),
                ),
              ),
            ],
          ),
        ),

        // Tương tác và thông tin bài viết
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Lượt thích
              Row(
                children: [
                  LikeAnimation(
                    child: IconButton(
                      icon: Icon(
                        widget.snapshot['like'].contains(currentUserId)
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: widget.snapshot['like'].contains(currentUserId)
                            ? Colors.red
                            : Colors.black,
                        size: 26.w,
                      ),
                      onPressed: _likePost,
                    ),
                    isAnimating: widget.snapshot['like'].contains(currentUserId),
                  ),
                  Text("${widget.snapshot['like'].length}",
                    style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(width: 10.w),
                  GestureDetector(
                    onTap: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      isDismissible: true,
                      enableDrag: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => DraggableScrollableSheet(
                        maxChildSize: 0.6,
                        initialChildSize: 0.6,
                        minChildSize: 0.2,
                        builder: (context, scrollController) {
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(25.r),
                                topRight: Radius.circular(25.r),
                              ),
                            ),
                            child: Comment('posts', widget.snapshot['postId']),
                          );
                        },
                      ),
                    ),
                    child: Image.asset(
                      'assets/images/comment.webp',
                      height: 30.h,
                    ),
                  ),
                  SizedBox(width: 5.w),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('posts')
                        .doc(widget.snapshot['postId'])
                        .collection('comments')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Text(
                          "...",
                          style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w500),
                        );
                      }
                      if (snapshot.hasError || !snapshot.hasData) {
                        return Text(
                          "0",
                          style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w500),
                        );
                      }
                      final int commentCount = snapshot.data!.docs.length;
                      return Text(
                        "$commentCount",
                        style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w500),
                      );
                    },
                  )
                ],
              ),

              Padding(
                padding: EdgeInsets.only(top: 5.h),
                child: Text("${widget.snapshot['caption']}", style: TextStyle(fontSize: 13.sp)),
              ),
              Text(formatDate(widget.snapshot['time'].toDate(), [dd, '-', mm, '-', yyyy]), style: TextStyle(fontSize: 11.sp, color: Colors.grey)),
            ],
          ),
        ),
        SizedBox(
          height: 50.h, // Chiều cao cụ thể
          child: Stack(
            children: [
              Positioned(
                top: 8.h, // Vị trí dọc
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  height: 9.h,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

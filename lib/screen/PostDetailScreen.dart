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

class PostDetailScreen extends StatefulWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isAnimating = false;
  String userId = '';
  Map<String, dynamic>? post;

  @override
  void initState() {
    super.initState();
    userId = _auth.currentUser!.uid;
    _loadPostData();
  }

  Future<void> _loadPostData() async {
    DocumentSnapshot doc = await _firebaseFirestore
        .collection('posts')
        .doc(widget.postId)
        .get();

    if (doc.exists) {
      setState(() {
        post = doc.data() as Map<String, dynamic>;
      });
    }
  }

  void _likePost() async {
    if (post == null) return;

    Firebase_Firestor().like(
      like: post!['like'],
      type: 'posts',
      uid: userId,
      postId: widget.postId,
    );

    if (!post!['like'].contains(userId)) {
      await _sendLikeNotification(widget.postId, post!['uid']);
    }
  }

  Future<void> _sendLikeNotification(String postId, String postOwnerUid) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'postId': postId,
        'senderId': userId, // UID của người đã like
        'receiverId': postOwnerUid, // UID chủ bài viết
        'type': 'like',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Lỗi khi gửi thông báo: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (post == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Chi tiết bài viết", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: 375.w,
              height: 54.h,
              color: Colors.white,
              child: ListTile(
                leading: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileScreen(Uid: post!['uid']),
                      ),
                    );
                  },
                  child: ClipOval(
                    child: SizedBox(
                      width: 35.w,
                      height: 35.h,
                      child: CachedImage(post!['profileImage']),
                    ),
                  ),
                ),
                title: Text(
                  post!['username'],
                  style: TextStyle(fontSize: 13.sp),
                ),
                subtitle: Text(
                  post!['location'],
                  style: TextStyle(fontSize: 11.sp),
                ),
              ),
            ),
            GestureDetector(
              onDoubleTap: () {
                _likePost();
                setState(() {
                  isAnimating = true;
                });
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 375.w,
                    height: 375.h,
                    child: CachedImage(post!['postImage']),
                  ),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isAnimating ? 1 : 0,
                    child: LikeAnimation(
                      child: Icon(
                        Icons.favorite,
                        size: 100.w,
                        color: Colors.red,
                      ),
                      isAnimating: isAnimating,
                      duration: const Duration(milliseconds: 400),
                      iconlike: false,
                      End: () {
                        setState(() {
                          isAnimating = false;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 375.w,
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: _likePost,
                        icon: Icon(
                          post!['like'].contains(userId)
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: post!['like'].contains(userId)
                              ? Colors.red
                              : Colors.black,
                          size: 24.w,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          showBottomSheet(
                            backgroundColor: Colors.transparent,
                            context: context,
                            builder: (context) {
                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: MediaQuery.of(context).viewInsets.bottom,
                                ),
                                child: DraggableScrollableSheet(
                                  maxChildSize: 0.6,
                                  initialChildSize: 0.6,
                                  minChildSize: 0.2,
                                  builder: (context, scrollController) {
                                    return Comment(
                                      'posts',
                                      widget.postId,
                                    );
                                  },
                                ),
                              );
                            },
                          );
                        },
                        child: Image.asset(
                          'assets/images/comment.webp',
                          height: 28.h,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 30.w, top: 4.h, bottom: 8.h),
                    child: Text(
                      "${post!['like'].length} lượt thích",
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 15.w),
                    child: Text(
                      "${post!['username']} :  ${post!['caption']}",
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 15.w, top: 20.h, bottom: 8.h),
                    child: Text(
                      formatDate(post!['time'].toDate(), [yyyy, '-', mm, '-', dd]),
                      style: TextStyle(fontSize: 11.sp, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

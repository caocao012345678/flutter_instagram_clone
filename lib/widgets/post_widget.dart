import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:date_format/date_format.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_instagram_clone/data/firebase_service/firestor.dart';
import 'package:flutter_instagram_clone/screen/profile_screen.dart';
import 'package:flutter_instagram_clone/util/image_cached.dart';
import 'package:flutter_instagram_clone/widgets/comment.dart';
import 'package:flutter_instagram_clone/widgets/like_animation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PostWidget extends StatefulWidget {
  final snapshot;
  PostWidget(this.snapshot, {super.key});

  @override
  State<PostWidget> createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  @override
  bool isAnimating = false;
  String user = '';
  final FirebaseAuth _auth = FirebaseAuth.instance;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    user = _auth.currentUser!.uid;
  }
  void _deletePost() {
    FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.snapshot['postId'])
        .delete()
        .then((value) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Post deleted')));
    })
        .catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete post: $error')));
    });
  }
  void _editPost() {
    final TextEditingController captionController = TextEditingController();
    captionController.text = widget.snapshot['caption'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Caption'),
          content: TextField(
            controller: captionController,
            decoration: const InputDecoration(hintText: 'Enter new caption'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Đóng hộp thoại
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                String newCaption = captionController.text.trim();
                if (newCaption.isNotEmpty) {
                  // Cập nhật caption trong Firestore
                  FirebaseFirestore.instance
                      .collection('posts')
                      .doc(widget.snapshot['postId'])
                      .update({'caption': newCaption}).then((_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Caption updated successfully')),
                    );
                    setState(() {
                      widget.snapshot['caption'] = newCaption;
                    });
                    Navigator.pop(context); // Đóng hộp thoại
                  }).catchError((error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update caption: $error')),
                    );
                  });
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 375.w,
          height: 54.h,
          color: Colors.white,
          child: Center(
              child: ListTile(
                leading: GestureDetector(
                  onTap: () {
                    String userUid = widget.snapshot['uid'];
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileScreen(Uid: userUid),
                      ),
                    );
                  },
                  child: ClipOval(
                    child: SizedBox(
                      width: 35.w,
                      height: 35.h,
                      child: CachedImage(widget.snapshot['profileImage']),
                    ),
                  ),
                ),
                title: Text(
                  widget.snapshot['username'],
                  style: TextStyle(fontSize: 13.sp),
                ),
                subtitle: Text(
                  widget.snapshot['location'],
                  style: TextStyle(fontSize: 11.sp),
                ),
                trailing: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz),
                  onSelected: (String value) {
                    switch (value) {
                      case 'Delete':
                        _deletePost();
                        break;
                      case 'Edit':
                        _editPost();
                        break;
                      case 'Block':
                        break;
                      case 'Message':
                        break;
                      default:
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    bool isOwner = widget.snapshot['uid'] == FirebaseAuth.instance.currentUser!.uid;

                    return [
                      if (isOwner)
                        const PopupMenuItem<String>(
                          value: 'Delete',
                          child: Text('Delete'),
                        ),
                      if (isOwner)
                        const PopupMenuItem<String>(
                          value: 'Edit',
                          child: Text('Edit'),
                        ),
                      if (!isOwner)
                        const PopupMenuItem<String>(
                          value: 'Block',
                          child: Text('Block'),
                        ),
                      if (!isOwner)
                        const PopupMenuItem<String>(
                          value: 'Message',
                          child: Text('Message'),
                        ),
                    ];
                  },
                ),
              )
          ),
        ),
        GestureDetector(
          onDoubleTap: () {
            Firebase_Firestor().like(
                like: widget.snapshot['like'],
                type: 'posts',
                uid: user,
                postId: widget.snapshot['postId']);
            setState(() {
              isAnimating = true;
            });
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 375.w,
                height: 375.h,
                child: CachedImage(
                  widget.snapshot['postImage'],
                ),
              ),
              AnimatedOpacity(
                duration: Duration(milliseconds: 200),
                opacity: isAnimating ? 1 : 0,
                child: LikeAnimation(
                  child: Icon(
                    Icons.favorite,
                    size: 100.w,
                    color: Colors.red,
                  ),
                  isAnimating: isAnimating,
                  duration: Duration(milliseconds: 400),
                  iconlike: false,
                  End: () {
                    setState(() {
                      isAnimating = false;
                    });
                  },
                ),
              )
            ],
          ),
        ),
        Container(
          width: 375.w,
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 14.h),
              Row(
                children: [
                  SizedBox(width: 14.w),
                  LikeAnimation(
                    child: IconButton(
                      onPressed: () {
                        Firebase_Firestor().like(
                            like: widget.snapshot['like'],
                            type: 'posts',
                            uid: user,
                            postId: widget.snapshot['postId']);
                      },
                      icon: Icon(
                        widget.snapshot['like'].contains(user)
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: widget.snapshot['like'].contains(user)
                            ? Colors.red
                            : Colors.black,
                        size: 24.w,
                      ),
                    ),
                    isAnimating: widget.snapshot['like'].contains(user),
                  ),
                  SizedBox(width: 17.w),
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
                                    'posts', widget.snapshot['postId']);
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
                  // SizedBox(width: 17.w),
                  // Image.asset(
                  //   'assets/images/send.jpg',
                  //   height: 28.h,
                  // ),
                  // const Spacer(),
                  // Padding(
                  //   padding: EdgeInsets.only(right: 15.w),
                  //   child: Image.asset(
                  //     'assets/images/save.png',
                  //     height: 28.h,
                  //   ),
                  // ),
                ],
              ),
              Padding(
                padding: EdgeInsets.only(
                  left: 30.w,
                  top: 4.h,
                  bottom: 8.h,
                ),
                child: Text(
                  widget.snapshot['like'].length.toString(),
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 15.w),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.snapshot['username'] +
                            ' :  ' +
                            widget.snapshot['caption'],
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 15.w, top: 20.h, bottom: 8.h),
                child: Text(
                  formatDate(widget.snapshot['time'].toDate(),
                      [yyyy, '-', mm, '-', dd]),
                  style: TextStyle(fontSize: 11.sp, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
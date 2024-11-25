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
  final Map<String, dynamic> snapshot; // Khai báo kiểu dữ liệu rõ ràng
  const PostWidget(this.snapshot, {super.key});

  @override
  State<PostWidget> createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  bool isAnimating = false;
  late String user; // Thêm "late" để đảm bảo biến này được khởi tạo trong initState
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    user = _auth.currentUser!.uid;
  }

  void _deletePost() async {
    try {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.snapshot['postId'])
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post deleted')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete post: $error')),
      );
    }
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
                      const SnackBar(content: Text('Caption updated successfully')),
                    );
                    Navigator.pop(context);
                  } catch (error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update caption: $error')),
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
                    builder: (context) => ProfileScreen(Uid: widget.snapshot['uid']),
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
                  // TODO: Implement Block
                    break;
                  case 'Message':
                  // TODO: Implement Message
                    break;
                }
              },
              itemBuilder: (BuildContext context) {
                bool isOwner = widget.snapshot['uid'] == user;

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
          ),
        ),
        GestureDetector(
          onDoubleTap: () {
            Firebase_Firestor().like(
              like: widget.snapshot['like'],
              type: 'posts',
              uid: user,
              postId: widget.snapshot['postId'],
            );
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
                child: CachedImage(widget.snapshot['postImage']),
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
        // Remaining widget code
      ],
    );
  }
}

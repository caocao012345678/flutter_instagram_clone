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
      print("Lỗi khi gửi thông báo: $e");
    }
  }

  // Like bài viết và gửi thông báo nếu cần
  void _likePost() {
    Firebase_Firestor().like(
      like: widget.snapshot['like'],
      type: 'posts',
      uid: currentUserId,
      postId: widget.snapshot['postId'],
    );

    if (!widget.snapshot['like'].contains(currentUserId)) {
      _sendLikeNotification(
        widget.snapshot['postId'],
        widget.snapshot['uid'],
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
        const SnackBar(content: Text('Bài viết đã bị xóa')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Xóa bài viết thất bại: $error')),
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
          title: const Text('Chỉnh sửa bài viết'),
          content: TextField(
            controller: captionController,
            decoration: const InputDecoration(hintText: 'Nhập caption mới'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
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
                        content: Text('Cập nhật thành công'),
                      ),
                    );
                    Navigator.pop(context);
                  } catch (error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Cập nhật thất bại: $error'),
                      ),
                    );
                  }
                }
              },
              child: const Text('Lưu'),
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
            onSelected: (value) {
              switch (value) {
                case 'Xóa':
                  _deletePost();
                  break;
                case 'Chỉnh sửa':
                  _editPost();
                  break;
                case 'Nhắn tin':
                  ();
                  break;
                case 'Chặn':
                  ();
                  break;
                default:
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tùy chọn không hợp lệ')),
                  );
              }
            },
            itemBuilder: (context) {
              // Kiểm tra người dùng có phải là chủ bài viết không
              bool isOwner = widget.snapshot['uid'] == currentUserId;

              return [
                if (isOwner) ...[
                  const PopupMenuItem<String>(
                    value: 'Xóa',
                    child: Text('Xóa bài viết'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'Chỉnh sửa',
                    child: Text('Chỉnh sửa bài viết'),
                  ),
                ] else ...[
                  const PopupMenuItem<String>(
                    value: 'Nhắn tin',
                    child: Text('Nhắn tin'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'Chặn',
                    child: Text('Chặn người dùng'),
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
                        size: 24.w,
                      ),
                      onPressed: _likePost,
                    ),
                    isAnimating: widget.snapshot['like'].contains(currentUserId),
                  ),
                  SizedBox(width: 10.w),
                  GestureDetector(
                    onTap: () => showBottomSheet(
                      context: context,
                      builder: (context) => DraggableScrollableSheet(
                        maxChildSize: 0.6,
                        initialChildSize: 0.6,
                        minChildSize: 0.2,
                        builder: (context, scrollController) {
                          return Comment('posts', widget.snapshot['postId']);
                        },
                      ),
                    ),
                    child: Image.asset(
                      'assets/images/comment.webp',
                      height: 28.h,
                    ),
                  ),
                ],
              ),

              // Caption và ngày đăng
              Text("${widget.snapshot['like'].length} lượt thích", style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500)),
              Padding(
                padding: EdgeInsets.only(top: 5.h),
                child: Text("${widget.snapshot['username']} : ${widget.snapshot['caption']}", style: TextStyle(fontSize: 13.sp)),
              ),
              Text(formatDate(widget.snapshot['time'].toDate(), [dd, '-', mm, '-', yyyy]), style: TextStyle(fontSize: 11.sp, color: Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }
}

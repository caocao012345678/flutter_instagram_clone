import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_instagram_clone/data/firebase_service/firestore.dart';
import 'package:flutter_instagram_clone/data/firebase_service/storage.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../widgets/navigation.dart';
import 'home.dart';

class AddPostTextScreen extends StatefulWidget {
  final File _file;
  AddPostTextScreen(this._file, {super.key});

  @override
  State<AddPostTextScreen> createState() => _AddPostTextScreenState();
}

class _AddPostTextScreenState extends State<AddPostTextScreen> {
  final caption = TextEditingController();
  final location = TextEditingController();
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // Tránh tràn khung khi bàn phím xuất hiện
      backgroundColor: Colors.white,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.black),
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'New post',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(
          child: CircularProgressIndicator(color: Colors.black),
        )
            : SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 10.w,
            right: 10.w,
            top: 10.h,
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(
                child: Container(
                  width: 250.w,
                  height: 250.h,
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    image: DecorationImage(
                      image: FileImage(widget._file),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20.h),

              // Vùng nhập Caption
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 15.w),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300, // Màu nền xám
                    borderRadius: BorderRadius.circular(10.r), // Bo góc
                  ),
                  padding: EdgeInsets.symmetric(
                      horizontal: 10.w, vertical: 5.h),
                  child: TextField(
                    controller: caption,
                    decoration: const InputDecoration(
                      hintText: 'Write something...',
                      border: InputBorder.none, // Xóa đường viền gốc
                    ),
                    maxLines: null, // Cho phép nhiều dòng
                    style: TextStyle(fontSize: 14.sp),
                  ),
                ),
              ),
              SizedBox(height: 10.h),

              // Nút "Đăng bài"
              Center(
                child: GestureDetector(
                  onTap: () async {
                    setState(() {
                      isLoading = true;
                    });
                    try {
                      String postUrl =
                      await StorageMethod().uploadImageToStorage(
                        'post',
                        widget._file,
                      );
                      await Firebase_Firestor().CreatePost(
                        postImage: postUrl,
                        caption: caption.text,
                        location: location.text,
                      );
                      setState(() {
                        isLoading = false;
                      });
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const Navigations_Screen(),
                        ),
                            (route) => false,
                      );

                    } catch (e) {
                      setState(() {
                        isLoading = false;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Posting failed: $e')),
                      );
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 30.w,
                      vertical: 12.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Text(
                      'Post',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

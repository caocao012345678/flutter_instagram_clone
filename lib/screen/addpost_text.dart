import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_instagram_clone/data/firebase_service/firestor.dart';
import 'package:flutter_instagram_clone/data/firebase_service/storage.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AddPostTextScreen extends StatefulWidget {
  File _file;
  AddPostTextScreen(this._file, {super.key});

  @override
  State<AddPostTextScreen> createState() => _AddPostTextScreenState();
}

class _AddPostTextScreenState extends State<AddPostTextScreen> {
  final caption = TextEditingController();
  final location = TextEditingController();
  bool islooding = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.black),
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Bài đăng mới',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: islooding
            ? Center(
          child: CircularProgressIndicator(
            color: Colors.black,
          ),
        )
            : Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Ảnh bài đăng
                  Container(
                    width: 65.w,
                    height: 65.h,
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      image: DecorationImage(
                        image: FileImage(widget._file),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  // Vùng nhập caption
                  Expanded(
                    child: TextField(
                      controller: caption,
                      decoration: const InputDecoration(
                        hintText: 'Hãy viết gì đấy...',
                        border: InputBorder.none,
                      ),
                      maxLines: null,
                      style: TextStyle(fontSize: 14.sp),
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () async {
                    setState(() {
                      islooding = true;
                    });
                    String post_url = await StorageMethod()
                        .uploadImageToStorage('post', widget._file);
                    await Firebase_Firestor().CreatePost(
                      postImage: post_url,
                      caption: caption.text,
                      location: location.text,
                    );
                    setState(() {
                      islooding = false;
                    });
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    margin: EdgeInsets.only(top: 10.h),
                    padding: EdgeInsets.symmetric(
                        horizontal: 20.w, vertical: 10.h),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Text(
                      'Đăng bài',
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
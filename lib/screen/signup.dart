import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_instagram_clone/data/firebase_service/firebase_auth.dart';
import 'package:flutter_instagram_clone/util/dialog.dart';
import 'package:flutter_instagram_clone/util/exeption.dart';
import 'package:flutter_instagram_clone/util/imagepicker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path_provider/path_provider.dart';

class SignupScreen extends StatefulWidget {
  final VoidCallback show;
  SignupScreen(this.show, {super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  bool _isLoading = false;
  final email = TextEditingController();
  FocusNode email_F = FocusNode();
  final password = TextEditingController();
  FocusNode password_F = FocusNode();
  final passwordConfirme = TextEditingController();
  FocusNode passwordConfirme_F = FocusNode();
  final username = TextEditingController();
  FocusNode username_F = FocusNode();
  final bio = TextEditingController();
  FocusNode bio_F = FocusNode();
  File? _imageFile;
  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    email.dispose();
    password.dispose();
    passwordConfirme.dispose();
    username.dispose();
    bio.dispose();
  }

  Future<File> getDefaultImage() async {
    final byteData = await rootBundle.load('assets/images/person.png');
    final file = File('${(await getTemporaryDirectory()).path}/person.png');
    await file.writeAsBytes(byteData.buffer.asUint8List());
    return file;
  }

  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: 100.h),
          child: Column(
            children: [
              SizedBox(width: 96.w, height: 10.h),
              Center(
                child: Image.asset('assets/images/logo.jpg'),
              ),
              SizedBox(width: 96.w, height: 70.h),
              InkWell(
                onTap: () async {
                  File _imagefilee = await ImagePickerr().uploadImage('gallery');
                  setState(() {
                    _imageFile = _imagefilee;
                  });
                },
                child: CircleAvatar(
                  radius: 50.r,
                  backgroundColor: Colors.grey,
                  child: _imageFile == null
                      ? CircleAvatar(
                          radius: 50.r,
                          backgroundImage: AssetImage('assets/images/person.png'),
                          backgroundColor: Colors.grey.shade200,
                        )
                      : CircleAvatar(
                          radius: 50.r,
                          backgroundImage: Image.file(
                            _imageFile!,
                            fit: BoxFit.cover,
                          ).image,
                          backgroundColor: Colors.grey.shade200,
                        ),
                ),
              ),
              SizedBox(height: 40.h),
              Textfild(email, email_F, 'Email', Icons.email),
              SizedBox(height: 15.h),
              Textfild(username, username_F, 'username', Icons.person),
              SizedBox(height: 15.h),
              Textfild(bio, bio_F, 'bio', Icons.abc),
              SizedBox(height: 15.h),
              Textfild(password, password_F, 'Password', Icons.lock, isPassword: true),
              SizedBox(height: 15.h),
              Textfild(passwordConfirme, passwordConfirme_F, 'Password Confirme',
                  Icons.lock,isPassword: true),
              SizedBox(height: 15.h),
              Signup(),
              SizedBox(height: 15.h),
              Have()
            ],
          ),
        ),
      )
    );
  }

  Widget Have() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            "Don you have account?  ",
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey,
            ),
          ),
          GestureDetector(
            onTap: widget.show,
            child: Text(
              "Login ",
              style: TextStyle(
                  fontSize: 15.sp,
                  color: Colors.blue,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget Signup() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      child: InkWell(
        onTap: () async {
          if (email.text.isEmpty || password.text.isEmpty || username.text.isEmpty) {
            dialogBuilder(context, "Vui lòng điền đầy đủ thông tin.");
            return;
          }

          setState(() {
            _isLoading = true;
          });

          try {
            final defaultImage = await getDefaultImage(); // Giả sử có hàm tạo file ảnh mặc định
            await Authentication().Signup(
              email: email.text.trim(),
              password: password.text.trim(),
              passwordConfirme: passwordConfirme.text.trim(),
              username: username.text.trim(),
              bio: bio.text.trim(),
              profile: _imageFile ?? defaultImage,
            );
            // Nếu đăng ký thành công
            Navigator.of(context).pop(); // Điều hướng đến trang khác
          } on exceptions catch (e) {
            dialogBuilder(context, e.message);
          } finally {
            setState(() {
              _isLoading = false;
            });
          }
        },
        child: Container(
          alignment: Alignment.center,
          width: double.infinity,
          height: 44.h,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(
            'Đăng ký',
            style: TextStyle(
              fontSize: 23.sp,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }



  Padding Textfild(TextEditingController controll, FocusNode focusNode,
      String typename, IconData icon, {bool isPassword = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      child: Container(
        height: 44.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5.r),
        ),
        child: TextField(
          style: TextStyle(fontSize: 18.sp, color: Colors.black),
          controller: controll,
          focusNode: focusNode,
          obscureText: isPassword,
          decoration: InputDecoration(
            hintText: typename,
            prefixIcon: Icon(
              icon,
              color: focusNode.hasFocus ? Colors.black : Colors.grey[600],
            ),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 15.w, vertical: 15.h),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5.r),
              borderSide: BorderSide(
                width: 2.w,
                color: Colors.grey,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5.r),
              borderSide: BorderSide(
                width: 2.w,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

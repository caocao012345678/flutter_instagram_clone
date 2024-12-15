import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_instagram_clone/data/firebase_service/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../data/firebase_service/firestore.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback show;
  LoginScreen(this.show, {super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isLoading = false;
  final email = TextEditingController();
  FocusNode email_F = FocusNode();
  final password = TextEditingController();
  FocusNode password_F = FocusNode();

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    email_F.dispose();
    password_F.dispose();
    super.dispose();
  }

  Future<void> _handleLoginSuccess(String userId) async {
    final deviceToken = await FirebaseMessaging.instance.getToken();
    if (deviceToken != null) {
      await Firebase_Firestor().saveDeviceToken(userId, deviceToken);
    }
  }

  Future<void> _forgotPassword() async {
    final emailText = email.text.trim();  // Sử dụng biến email đã khai báo trước

    if (emailText.isEmpty) {
      _showSnackbar("Please enter your email.");
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: emailText);
      _showSnackbar("Password reset email sent!");
    } on FirebaseAuthException catch (e) {
      _showSnackbar("Error: ${e.message}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 1.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 100.h),
                Center(
                  child:
                  SizedBox(
                    height: 60.h,
                    child: Image.asset('assets/images/Vibe_Logo.png'),
                  ),
                ),
                SizedBox(height: 80.h),
                Textfild(email, email_F, 'Email', Icons.email),
                SizedBox(height: 15.h),
                Textfild(password, password_F, 'Password', Icons.lock, isPassword: true),
                SizedBox(height: 15.h),
                forget(),
                SizedBox(height: 15.h),
                login(),
                SizedBox(height: 15.h),
                Have(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget Have() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            "Don't have an account?  ",
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey,
            ),
          ),
          GestureDetector(
            onTap: widget.show,
            child: Text(
              "Sign up",
              style: TextStyle(
                fontSize: 15.sp,
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.redAccent,
      ),
    );
  }
  Widget login() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      child: InkWell(
        onTap: () async {
          if (email.text.isEmpty || password.text.isEmpty) {
            _showSnackbar("Please fill in all information.");
            return;
          }

          setState(() {
            isLoading = true;
          });

          try {
            // Gọi phương thức đăng nhập
            await Authentication().Login(
              email: email.text.trim(),
              password: password.text.trim(),
            );

            // Lấy ID người dùng hiện tại
            String userId = FirebaseAuth.instance.currentUser!.uid;

            // Lưu token thiết bị vào Firestore
            await _handleLoginSuccess(userId);

            // Hiển thị thông báo thành công
            _showSnackbar("Login successful!");
          } catch (e) {
            String errorMessage = e.toString().replaceAll("Exception:", "").trim();
            _showSnackbar(errorMessage);
          } finally {
            setState(() {
              isLoading = false;
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
          child: isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(
            'Sign in',
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


  Padding forget() {
    return Padding(
      padding: EdgeInsets.only(left: 230.w),
      child: GestureDetector(
        onTap: _forgotPassword,
        child: Text(
          'Forgot password?',
          style: TextStyle(
            fontSize: 13.sp,
            color: Colors.blue,
            fontWeight: FontWeight.w500,
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

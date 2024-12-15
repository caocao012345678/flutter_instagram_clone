import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_instagram_clone/screen/explore.dart';
import 'package:flutter_instagram_clone/screen/home.dart';
import 'package:flutter_instagram_clone/screen/profile_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../Chat/chat_list_screen.dart';
import '../screen/PostDetailScreen.dart';
import '../screen/add_screen.dart';

class Navigations_Screen extends StatefulWidget {
  const Navigations_Screen({super.key});

  @override
  State<Navigations_Screen> createState() => _Navigations_ScreenState();
}

int _currentIndex = 0;

class _Navigations_ScreenState extends State<Navigations_Screen> {

  late PageController pageController;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  @override
  void initState() {
    super.initState();
    pageController = PageController();
  }

  @override
  void dispose() {
    super.dispose();
    pageController.dispose();
  }

  onPageChanged(int page) {
    setState(() {
      _currentIndex = page;
    });
  }

  navigationTapped(int page) {
    pageController.jumpToPage(page);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Container(
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey,
          currentIndex: _currentIndex,
          onTap: navigationTapped,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: '',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: '',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.camera),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Image.asset(
                'assets/images/comment.webp',
                height: 27.h,
              ),
              label: '',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: '',
            ),
          ],
        ),
      ),
      body: PageView(
        controller: pageController,
        onPageChanged: onPageChanged,
        children: [
          HomeScreen(),
          ExploreScreen(),
          AddScreen(),
          ChatListScreen(),
          ProfileScreen(
            Uid: _auth.currentUser?.uid ?? '', // Trả về chuỗi rỗng nếu currentUser là null
          ),
        ],
      ),
    );
  }
}

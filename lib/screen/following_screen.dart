import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_instagram_clone/screen/profile_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_instagram_clone/data/firebase_service/firestor.dart';
import 'package:flutter_instagram_clone/data/model/usermodel.dart';
import 'package:flutter_instagram_clone/util/image_cached.dart'; // Đảm bảo import đúng file CachedImage

class FollowingScreen extends StatefulWidget {
  const FollowingScreen({super.key});

  @override
  State<FollowingScreen> createState() => _FollowingScreenState();
}

class _FollowingScreenState extends State<FollowingScreen> {
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;
  List followingList = []; // List of people the user is following

  @override
  void initState() {
    super.initState();
    _loadFollowingData();
  }

  // Lấy danh sách người dùng mà hiện tại người dùng đang theo dõi
  _loadFollowingData() async {
    DocumentSnapshot userDoc = await _firebaseFirestore
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();

    setState(() {
      followingList = List.from(userDoc['following']);
    });
  }

  // Hàm unfollow, sẽ xóa người dùng khỏi danh sách following
  _unfollowUser(String uidToUnfollow) async {
    final userUid = FirebaseAuth.instance.currentUser!.uid;

    // Cập nhật danh sách "following" trong Firestore
    await _firebaseFirestore.collection('users').doc(userUid).update({
      'following': FieldValue.arrayRemove([uidToUnfollow]),
    });

    // Cập nhật lại danh sách local
    setState(() {
      followingList.remove(uidToUnfollow);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Following'),
        backgroundColor: Colors.white,
      ),
      body: ListView.builder(
        itemCount: followingList.length,
        itemBuilder: (context, index) {
          return FutureBuilder<DocumentSnapshot>(
            future: _firebaseFirestore.collection('users').doc(followingList[index]).get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data == null) {
                return Container();
              }

              Usermodel user = Usermodel.fromMap(snapshot.data!.data() as Map<String, dynamic>);

              return ListTile(
                leading: ClipOval(
                  child: SizedBox(
                    width: 50.w,
                    height: 50.h,
                    child: CachedImage(user.profile),
                  ),
                ),
                title: Text(user.username),
                subtitle: Text(user.bio),
                trailing: IconButton(
                  icon: Icon(Icons.remove_circle, color: Colors.red),
                  onPressed: () {
                    _unfollowUser(followingList[index]);
                  },
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(Uid: followingList[index]),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

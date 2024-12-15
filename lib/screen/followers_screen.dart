import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_instagram_clone/screen/profile_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_instagram_clone/data/firebase_service/firestore.dart';
import 'package:flutter_instagram_clone/data/model/usermodel.dart';
import 'package:flutter_instagram_clone/util/image_cached.dart'; // Đảm bảo import đúng file CachedImage

class FollowersScreen extends StatefulWidget {
  const FollowersScreen({super.key});

  @override
  State<FollowersScreen> createState() => _FollowersScreenState();
}

class _FollowersScreenState extends State<FollowersScreen> {
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;
  List followersList = []; // List of people who follow the user

  @override
  void initState() {
    super.initState();
    _loadFollowersData();
  }

  // Lấy danh sách "followers" của người dùng
  _loadFollowersData() async {
    DocumentSnapshot userDoc = await _firebaseFirestore
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();

    setState(() {
      followersList = List.from(userDoc['followers']);
    });
  }

  // Hàm unfollow, sẽ xóa người dùng khỏi danh sách followers
  _unfollowUser(String uidToUnfollow) async {
    final userUid = FirebaseAuth.instance.currentUser!.uid;

    // Cập nhật danh sách "followers" trong Firestore của người dùng
    await _firebaseFirestore.collection('users').doc(userUid).update({
      'followers': FieldValue.arrayRemove([uidToUnfollow]),
    });

    // Cập nhật danh sách local
    setState(() {
      followersList.remove(uidToUnfollow);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Followers'),
        backgroundColor: Colors.white,
      ),
      body: ListView.builder(
        itemCount: followersList.length,
        itemBuilder: (context, index) {
          return FutureBuilder<DocumentSnapshot>(
            future: _firebaseFirestore.collection('users').doc(followersList[index]).get(),
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
                    _unfollowUser(followersList[index]);
                  },
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(Uid: followersList[index]),
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

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_instagram_clone/util/image_cached.dart';
import 'package:flutter_instagram_clone/data/firebase_service/firestor.dart';

class EditProfileScreen extends StatefulWidget {
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  String _profileImageUrl = '';
  bool _isImagePicked = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Load user data from Firestore
  _loadUserData() async {
    DocumentSnapshot userDoc = await _firebaseFirestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .get();

    setState(() {
      _usernameController.text = userDoc['username'];
      _bioController.text = userDoc['bio'];
      _profileImageUrl = userDoc['profileImage'] ?? '';
    });
  }

  _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _profileImageUrl = image.path;
        _isImagePicked = true;
      });
    }
  }

  // Save changes to Firestore
  _saveChanges() async {
    await _firebaseFirestore.collection('users').doc(_auth.currentUser!.uid).update({
      'username': _usernameController.text,
      'bio': _bioController.text,
      'profileImage': _profileImageUrl,  // Update the profile image URL
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.save, color: Colors.black),
            onPressed: _saveChanges,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: ListView(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 60.w,
                backgroundImage: _profileImageUrl.isNotEmpty
                    ? NetworkImage(_profileImageUrl)
                    : AssetImage('assets/default_avatar.png') as ImageProvider<Object>?,
              ),
            ),


            SizedBox(height: 16.h),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: _bioController,
              decoration: InputDecoration(labelText: 'Bio'),
            ),
            SizedBox(height: 20.h),
            ElevatedButton(
              onPressed: _saveChanges,
              child: Text('Save Changes'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
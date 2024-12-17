import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_instagram_clone/util/image_cached.dart';

import '../data/firebase_service/storage.dart';

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

  _loadUserData() async {
    DocumentSnapshot userDoc = await _firebaseFirestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .get();

    setState(() {
      _usernameController.text = userDoc['username'];
      _bioController.text = userDoc['bio'];
      _profileImageUrl = userDoc['profile'];
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


  _saveChanges() async {
    String profileImageUrlToSave;

    if (_isImagePicked) {
      File file = File(_profileImageUrl);
      profileImageUrlToSave = await StorageMethod().uploadImageToStorage('Profile', file);
      await _firebaseFirestore.collection('users').doc(_auth.currentUser!.uid).update({
        'username': _usernameController.text,
        'bio': _bioController.text,
        'profile': profileImageUrlToSave,
      });
    } else {
      await _firebaseFirestore.collection('users').doc(_auth.currentUser!.uid).update({
        'username': _usernameController.text,
        'bio': _bioController.text,
      });
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Edit Profile'),
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: ListView(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 60.w,
                backgroundColor: Colors.grey[200],
                child: _isImagePicked ?
                  ClipOval(
                    child:
                    Image.file(
                      File(_profileImageUrl),
                      fit: BoxFit.cover,
                      width: 120.w,
                      height: 120.h,
                    ),
                  )
                 :
                  ClipOval(
                    child: _profileImageUrl != ''
                        ? SizedBox(
                            width: 120.w,
                            height: 130.h,
                            child: CachedImage(_profileImageUrl),
                          )
                        : Image.asset(
                      'assets/images/person.png',
                      fit: BoxFit.cover,
                      width: 120.w,
                      height: 120.h,
                    ),
                  )
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

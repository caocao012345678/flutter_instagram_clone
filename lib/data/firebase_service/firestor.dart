import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_instagram_clone/data/model/usermodel.dart';
import 'package:flutter_instagram_clone/util/exeption.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
class Firebase_Firestor {
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> CreateUser({
    required String email,
    required String username,
    required String bio,
    required String profile,
  }) async {
    await _firebaseFirestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .set({
      'email': email,
      'username': username,
      'bio': bio,
      'profile': profile,
      'followers': [],
      'following': [],
    });
    return true;
  }

  Future<Usermodel> getUser({String? UID}) async {
    try {
      final user = await _firebaseFirestore
          .collection('users')
          .doc(UID != null ? UID : _auth.currentUser!.uid)
          .get();
      final snapuser = user.data()!;
      return Usermodel(
          snapuser['bio'],
          snapuser['email'],
          snapuser['followers'],
          snapuser['following'],
          snapuser['profile'],
          snapuser['username']);
    } on FirebaseException catch (e) {
      throw exceptions(e.message.toString());
    }
  }

  Future<bool> CreatePost({
    required String postImage,
    required String caption,
    required String location,
  }) async {
    var uid = Uuid().v4();
    DateTime data = new DateTime.now();
    Usermodel user = await getUser();
    await _firebaseFirestore.collection('posts').doc(uid).set({
      'postImage': postImage,
      'username': user.username,
      'profileImage': user.profile,
      'caption': caption,
      'location': location,
      'uid': _auth.currentUser!.uid,
      'postId': uid,
      'like': [],
      'time': data
    });
    return true;
  }

  Future<bool> CreatReels({
    required String video,
    required String caption,
  }) async {
    var uid = Uuid().v4();
    DateTime data = new DateTime.now();
    Usermodel user = await getUser();
    await _firebaseFirestore.collection('reels').doc(uid).set({
      'reelsvideo': video,
      'username': user.username,
      'profileImage': user.profile,
      'caption': caption,
      'uid': _auth.currentUser!.uid,
      'postId': uid,
      'like': [],
      'time': data
    });
    return true;
  }

  Future<bool> Comments({
    required String comment,
    required String type,
    required String uidd,
  }) async {
    var uid = Uuid().v4();
    Usermodel user = await getUser();
    await _firebaseFirestore
        .collection(type)
        .doc(uidd)
        .collection('comments')
        .doc(uid)
        .set({
      'comment': comment,
      'username': user.username,
      'profileImage': user.profile,
      'CommentUid': uid,
    });
    return true;
  }

  Future<String> like({
    required List like,
    required String type,
    required String uid,
    required String postId,
  }) async {
    String res = 'some error';
    try {
      if (like.contains(uid)) {
        _firebaseFirestore.collection(type).doc(postId).update({
          'like': FieldValue.arrayRemove([uid])
        });
      } else {
        _firebaseFirestore.collection(type).doc(postId).update({
          'like': FieldValue.arrayUnion([uid])
        });
      }
      res = 'seccess';
    } on Exception catch (e) {
      res = e.toString();
    }
    return res;
  }

  Future<void> flollow({
    required String uid,
  }) async {
    DocumentSnapshot snap = await _firebaseFirestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .get();
    List following = (snap.data()! as dynamic)['following'];
    try {
      if (following.contains(uid)) {
        _firebaseFirestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .update({
          'following': FieldValue.arrayRemove([uid])
        });
        await _firebaseFirestore.collection('users').doc(uid).update({
          'followers': FieldValue.arrayRemove([_auth.currentUser!.uid])
        });
      } else {
        _firebaseFirestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .update({
          'following': FieldValue.arrayUnion([uid])
        });
        _firebaseFirestore.collection('users').doc(uid).update({
          'followers': FieldValue.arrayUnion([_auth.currentUser!.uid])
        });
      }
    } on Exception catch (e) {
      print(e.toString());
    }
  }

  Future<void> saveDeviceToken(String userId, String token) async {
    await _firestore.collection('users').doc(userId).update({
      'deviceToken': token,
    });
  }

  // Lấy token của người nhận
  Future<String?> getUserDeviceToken(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    return userDoc['deviceToken'];
  }

  // Gửi thông báo đẩy
  Future<void> sendPushNotification({
    required String deviceToken,
    required String title,
    required String body,
  }) async {
    const String accessToken = 'ya29.c.c0ASRK0Gb-1-o1bVypsyQnhD5srYRGycSoPeEwF_18LIeLf85OzVW4CSP5ROq3gquhALrk6VORAjwYAY25hyQiOTs5fdPzUhnHdOU5tcKaRuLIMH71jhKLMux4lqJGfSRnt8cfs0TRsg-Jq-RFrY656pYEq5tfEPAIXUEJBijsPZXvntPvpyi06-jSMFyBcqYqYjRwnerW7alqffzJHhyDvB0hTm_V0ysasI7BF220zLPoeHRBG8J_XiU5f4TsAkmHw3NeGLwFwkBMJw94BrndvlkHbW_lV7sAmPJRLajm9bEmxLQBPLNVYFp7Hi7TYYxIAF6jFdpDqzu_dsxeFOMjBv9iBUHFbIiPvPcbxrScZzbh0o1_zA_AsjsT384Dwrsq9ndIUUMz-3V0fWRv0hFBzcqduj-ZYecheuMr9bUlQx4dWMWVB7ZaUdmM4yVMxaeMdsI-Q6SieYf0qzJWnBRam5XJwSBI_SygvSqjj5XtFQFe7b2Oy5f7xhkcXlXZ1j0gSmuxcuJ3pIdB6zd0o7prinQBnrk6Iufdyss-ObSVVlu3kdbQj8d_vfv_oe3qe29-FoBqWO_UR0zo7Wf9-buiviVVwZJeUfqhfnMQmh1_ob0x5XfzakQ22rqMFQylZO21eOuykeXeOVQ3-Yukl3bhto2wIR5S-kmtZ2qF6t7iVuZocr5y8VBRjafyMov7k2QsviukvrnJSaVW_boJisvjdRc0cubVrM6to7W--WJdvj-QBeMmaV7fMvjeS1ibhyFyi1_2RpkOZmV9s-ls-RX-Yd2yXjUlnu85y7BB5-O2Ol1hyohwfZzMc5fusUqvgpOzuFk70U3slylS8b48FWZmV1z7eVkmjXXSJ7Rmh-l__dJMmIyVF5mfVMmrS9ISook5jVU63x0-O3mmvUJs2xrvBgioZrktJvuWtZRd-OgJypceWz3nRd3FppIgOIzusJiewYymOnOokJ1xkziX080ywhuQ4k-s_7jXU13i-phOrlIRqeMW5pOrQjl';

    final url = Uri.parse(
        'https://fcm.googleapis.com/v1/projects/testvisa-6edb9/messages:send');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({
        "message": {
          "token": deviceToken,
          "notification": {
            "title": title,
            "body": body,
          },
          "android": {
            "priority": "high",
            "notification": {
              "channel_id": "high_importance_channel",
            }
          }
        }
      }),
    );

    if (response.statusCode == 200) {
      print("Thông báo đẩy đã được gửi.");
    } else {
      print("Gửi thông báo đẩy thất bại: ${response.statusCode}");
      print("Chi tiết lỗi: ${response.body}");
    }
  }

}

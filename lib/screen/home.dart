import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_instagram_clone/widgets/post_widget.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../Chat/chat_list_screen.dart';
//
// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});
//
//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }
//
// class _HomeScreenState extends State<HomeScreen> {
//   FirebaseAuth _auth = FirebaseAuth.instance;
//   FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       resizeToAvoidBottomInset: false,
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         centerTitle: true,
//         elevation: 0,
//         title: SizedBox(
//           width: 105.w,
//           height: 28.h,
//           child: Image.asset('assets/images/instagram.jpg'),
//         ),
//         leading: Image.asset('assets/images/camera.jpg'),
//         actions: [
//           const Icon(
//             Icons.favorite_border_outlined,
//             color: Colors.black,
//             size: 25,
//           ),
//           Image.asset('assets/images/send.jpg'),
//         ],
//         backgroundColor: const Color(0xffFAFAFA),
//       ),
//       body: CustomScrollView(
//         slivers: [
//           StreamBuilder(
//             stream: _firebaseFirestore
//                 .collection('posts')
//                 .orderBy('time', descending: true)
//                 .snapshots(),
//             builder: (context, snapshot) {
//               return SliverList(
//                 delegate: SliverChildBuilderDelegate(
//                   (context, index) {
//                     if (!snapshot.hasData) {
//                       return Center(child: CircularProgressIndicator());
//                     }
//                     return PostWidget(snapshot.data!.docs[index].data());
//                   },
//                   childCount:
//                       snapshot.data == null ? 0 : snapshot.data!.docs.length,
//                 ),
//               );
//             },
//           )
//         ],
//       ),
//     );
//   }
// }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        title: SizedBox(
          width: 105.w,
          height: 28.h,
          child: Image.asset('assets/images/instagram.jpg'),
        ),
        leading: Image.asset('assets/images/camera.jpg'),
        actions: [
          const Icon(
            Icons.favorite_border_outlined,
            color: Colors.black,
            size: 25,
          ),
          IconButton(
            icon: Icon(Icons.send, color: Colors.black, size: 25),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChatListScreen()),
              );
            },
          ),
        ],
        backgroundColor: const Color(0xffFAFAFA),
      ),
      body: CustomScrollView(
        slivers: [
          StreamBuilder(
            stream: _firebaseFirestore
                .collection('posts')
                .orderBy('time', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    if (!snapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }
                    return PostWidget(snapshot.data!.docs[index].data());
                  },
                  childCount:
                  snapshot.data == null ? 0 : snapshot.data!.docs.length,
                ),
              );
            },
          )
        ],
      ),
    );
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_instagram_clone/widgets/post_widget.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../Chat/chat_list_screen.dart';
import 'NotificationScreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;
  late FirebaseMessaging messaging;

  @override
  void initState() {
    super.initState();
    setupFirebaseMessaging();
  }

  // Cấu hình Firebase Messaging
  void setupFirebaseMessaging() async {
    messaging = FirebaseMessaging.instance;

    // Yêu cầu quyền thông báo
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print("Quyền thông báo đã được cấp!");

      // Nhận token thiết bị
      messaging.getToken().then((token) {
        print("Token người dùng: $token");
      });

      // Lắng nghe thông báo khi ứng dụng đang mở
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print("Nhận thông báo khi ứng dụng đang mở: ${message.notification?.title}");
        _showNotificationDialog(
          message.notification?.title ?? "Thông báo",
          message.notification?.body ?? "Không có nội dung",
        );
      });

      // Khi người dùng nhấn vào thông báo để mở ứng dụng
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print("Người dùng mở ứng dụng từ thông báo: ${message.notification?.title}");
      });
    } else {
      print("Quyền thông báo bị từ chối.");
    }
  }

  // Hiển thị hộp thoại thông báo
  void _showNotificationDialog(String title, String body) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            child: const Text("Đóng"),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

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
          // Hiển thị số lượng thông báo chưa đọc
          StreamBuilder<QuerySnapshot>(
            stream: _firebaseFirestore
                .collection('notifications')
                .where('receiverId', isEqualTo: _auth.currentUser!.uid)
                .where('read', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              int unreadCount = snapshot.hasData ? snapshot.data!.docs.length : 0;

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationScreen(),
                    ),
                  );
                },
                child: Stack(
                  clipBehavior: Clip.none, // Cho phép phần tử nổi ra ngoài
                  children: [
                    const Icon(
                      Icons.favorite_border_outlined,
                      color: Colors.black,
                      size: 30, // Tăng kích thước để cân đối hơn
                    ),

                    // Bong bóng thông báo
                    if (unreadCount > 0)
                      Positioned(
                        right: -5, // Nổi ra bên ngoài bên phải
                        top: -5,   // Nổi lên trên
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );

            },
          ),

          IconButton(
            icon: const Icon(Icons.send, color: Colors.black, size: 25),
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
          StreamBuilder<QuerySnapshot>(
            stream: _firebaseFirestore
                .collection('posts')
                .orderBy('time', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return PostWidget(snapshot.data!.docs[index].data() as Map<String, dynamic>);
                  },
                  childCount: snapshot.data!.docs.length,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_instagram_clone/routes/chat_routes.dart';
import 'package:flutter_instagram_clone/screen/PostDetailScreen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'auth/mainpage.dart';
import 'firebase_options.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Nhận thông báo nền: ${message.notification?.title}");
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final FirebaseMessaging _messaging;

  @override
  void initState() {
    super.initState();
    _setupFirebaseMessaging();
  }

  Future<void> _setupFirebaseMessaging() async {
    _messaging = FirebaseMessaging.instance;

    // Cấu hình thông báo nền
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Yêu cầu quyền thông báo
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Lắng nghe thông báo khi ứng dụng mở
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Thông báo nhận khi mở app: ${message.notification?.title}");
      _showNotification(
        title: message.notification?.title ?? 'No Title',
        body: message.notification?.body ?? 'No Body',
      );
    });

    // Lắng nghe khi người dùng nhấn vào thông báo
    // FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    //   print("Ứng dụng mở từ thông báo: ${message.notification?.title}");
    //   final type = message.data['type'] ?? '';
    //   final postId = message.data['postId'] ?? '';
    //
    //   if ((type == "like" || type == "comment") && postId.isNotEmpty) {
    //     Navigator.push(
    //       context,
    //       MaterialPageRoute(
    //         builder: (context) => PostDetailScreen(postId: postId),
    //       ),
    //     );
    //   } else {
    //     print("Thông báo không cần điều hướng: $type");
    //   }
    // });
  }

  Future<void> _showNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ScreenUtilInit(
        designSize: const Size(375, 812),
        child: const MainPage(),
      ),
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}

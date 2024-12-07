import 'package:flutter/material.dart';
import '../Chat/chat_detail_screen.dart';
import '../Chat/chat_list_screen.dart';
import '../Chat/create_group_screen.dart';


class AppRoutes {
  static const String chatList = '/chat_list';
  static const String chatDetail = '/chat_detail';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case chatList:
        return MaterialPageRoute(builder: (_) => ChatListScreen());
      case chatDetail:
        final args = settings.arguments as Map?;
        if (args != null) {
          return MaterialPageRoute(
            builder: (_) => ChatDetailScreen(
              chatId: args['chatId'],
              otherUserId: args['otherUserId'],
            ),

          );
        }
        return _errorRoute();
      case '/create_group_chat':
        return MaterialPageRoute(builder: (context) => const CreateGroupScreen());
      default:
        return _errorRoute();
    }
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text("Error")),
        body: const Center(child: Text("Error: Page not found")),
      ),
    );
  }
}



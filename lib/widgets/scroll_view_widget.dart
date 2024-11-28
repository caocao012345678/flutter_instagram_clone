import 'package:flutter/material.dart';

class ScrollViewWidget extends StatelessWidget {
  final List<Widget> children;
  final ScrollController scrollController;
  final Function onScrollToBottom;

  const ScrollViewWidget({
    Key? key,
    required this.children,
    required this.scrollController,
    required this.onScrollToBottom,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ScrollView chứa các tin nhắn
        ListView(
          controller: scrollController,
          reverse: true, // Đảo ngược danh sách để hiển thị tin nhắn mới nhất ở dưới
          children: children,
        ),
        // Nút cuộn xuống dưới
        Positioned(
          bottom: 10,
          right: 10,
          child: FloatingActionButton(
            onPressed: () {
              // Cuộn xuống dòng tin nhắn mới nhất
              scrollController.animateTo(
                scrollController.position.maxScrollExtent,
                duration: Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
              onScrollToBottom();
            },
            child: Icon(Icons.arrow_downward),
          ),
        ),
      ],
    );
  }
}

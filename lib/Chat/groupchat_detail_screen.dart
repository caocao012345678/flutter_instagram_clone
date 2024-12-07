import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class GroupChatDetailScreen extends StatefulWidget {
  final String chatId;

  const GroupChatDetailScreen({
    Key? key,
    required this.chatId,
  }) : super(key: key);

  @override
  State<GroupChatDetailScreen> createState() => _GroupChatDetailScreenState();
}

class _GroupChatDetailScreenState extends State<GroupChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _replyingTo;

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    final messageData = {
      'senderId': currentUserId,
      'content': message,
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'text',
    };

    if (_replyingTo != null) {
      messageData['replyTo'] = _replyingTo!;
      _replyingTo = null;
    }

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .add(messageData);

    _messageController.clear();
  }

  Widget _buildMessageItem(Map<String, dynamic> messageData) {
    final senderId = messageData['senderId'];

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(senderId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final senderData = snapshot.data!.data() as Map<String, dynamic>;
        final senderName = senderData['username'] ?? "Người dùng";
        final senderAvatar = senderData['profile'] ?? "";

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundImage: senderAvatar.isNotEmpty
                  ? NetworkImage(senderAvatar)
                  : const AssetImage('assets/default_avatar.png') as ImageProvider,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(senderName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(messageData['content']),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('groups').doc(widget.chatId).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Text("Đang tải...");
            final groupData = snapshot.data!.data() as Map<String, dynamic>;
            final groupName = groupData['name'] ?? "Nhóm";
            final groupAvatar = groupData['avatar'] ?? "";

            return Row(
              children: [
                CircleAvatar(
                  backgroundImage: groupAvatar.isNotEmpty
                      ? NetworkImage(groupAvatar)
                      : const AssetImage('assets/default_avatar.png') as ImageProvider,
                ),
                const SizedBox(width: 10),
                Text(groupName),
              ],
            );
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final messageData = messages[index].data() as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: _buildMessageItem(messageData),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: "Nhập tin nhắn...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

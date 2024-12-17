
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MemberListScreen extends StatefulWidget {
  final String chatId; // ID của nhóm
  final String currentUserId; // ID của người hiện tại (có thể là nhóm trưởng)

  const MemberListScreen({
    Key? key,
    required this.chatId,
    required this.currentUserId,
  }) : super(key: key);

  @override
  _MemberListScreenState createState() => _MemberListScreenState();
}

class _MemberListScreenState extends State<MemberListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Lấy thông tin nhóm từ Firestore
  Future<DocumentSnapshot> _getGroupInfo() async {
    return await _firestore.collection('chats').doc(widget.chatId).get();
  }

  // Xóa thành viên khỏi nhóm
  Future<void> _removeMember(String userId) async {
    try {
      // Lấy thông tin nhóm từ Firestore
      DocumentSnapshot groupDoc = await _getGroupInfo();
      List<dynamic> users = groupDoc['users'];

      if (users.contains(userId)) {
        // Loại bỏ thành viên khỏi danh sách
        users.remove(userId);

        // Cập nhật lại danh sách thành viên trong nhóm
        await _firestore.collection('chats').doc(widget.chatId).update({
          'users': users,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Member removed from group")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade100,
        title: const Text('Member List'),
      ),
      body: StreamBuilder<DocumentSnapshot>( // Sử dụng StreamBuilder để lắng nghe thay đổi
        stream: _firestore.collection('chats').doc(widget.chatId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Lỗi: ${snapshot.error}"));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Group does not exist"));
          }

          var groupData = snapshot.data!.data() as Map<String, dynamic>;
          List<dynamic> users = groupData['users'] ?? []; // Xử lý trường hợp users null
          String adminId = groupData['admin'] ?? ''; // Xử lý trường hợp admin null

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              String userId = users[index];

              // Kiểm tra userId có phải là chuỗi rỗng hay không
              if (userId.isNotEmpty) {
                return FutureBuilder<DocumentSnapshot>(
                  future: _firestore.collection('users').doc(userId).get(),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (userSnapshot.hasError) {
                      return Center(child: Text("Error: ${userSnapshot.error}"));
                    }

                    if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                      return const SizedBox.shrink(); // Hoặc hiển thị thông báo lỗi
                    }

                    var userData = userSnapshot.data!.data() as Map<String, dynamic>;
                    String username = userData['username'] ?? 'User';
                    String avatarUrl = userData['profile'] ?? '';

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: avatarUrl.isNotEmpty
                            ? NetworkImage(avatarUrl)
                            : const AssetImage('assets/default_avatar.png') as ImageProvider,
                      ),
                      title: Row(
                        children: [
                          Text(username),
                          if (userId == adminId) ...[
                            const SizedBox(width: 8),
                            const Text(
                              'Admin',
                              style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ],
                      ),
                      trailing: (userId == widget.currentUserId || userId == adminId)
                          ? null
                          : IconButton(
                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () {
                          _removeMember(userId);
                        },
                      ),
                    );
                  },
                );
              } else {
                return const SizedBox.shrink(); // Hoặc hiển thị thông báo lỗi nếu userId rỗng
              }
            },
          );
        },
      ),
    );
  }
}
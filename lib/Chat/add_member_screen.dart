// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
//
// class AddMemberScreen extends StatefulWidget {
//   final String chatId;
//
//   const AddMemberScreen({Key? key, required this.chatId}) : super(key: key);
//
//   @override
//   _AddMemberScreenState createState() => _AddMemberScreenState();
// }
//
// class _AddMemberScreenState extends State<AddMemberScreen> {
//   final TextEditingController _searchController = TextEditingController();
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   List<Map<String, dynamic>> searchResults = [];
//   List<String> currentMembers = [];
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchCurrentMembers();
//   }
//
//   // Lấy danh sách thành viên hiện tại của nhóm
//   Future<void> _fetchCurrentMembers() async {
//     DocumentSnapshot groupDoc = await _firestore.collection('chats').doc(widget.chatId).get();
//     List<dynamic> users = groupDoc['users'] ?? [];
//
//     setState(() {
//       currentMembers = List<String>.from(users);
//     });
//   }
//
//   // Tìm kiếm người dùng không thuộc nhóm
//   Future<void> _searchUsers(String query) async {
//     if (query.isEmpty) {
//       setState(() {
//         searchResults = [];
//       });
//       return;
//     }
//
//     QuerySnapshot snapshot = await _firestore
//         .collection('users')
//         .where('username', isGreaterThanOrEqualTo: query)
//         .where('username', isLessThanOrEqualTo: query + '\\uf8ff')
//         .get();
//
//     // Loại bỏ các user đã là thành viên của nhóm
//     List<Map<String, dynamic>> results = snapshot.docs.map((doc) {
//       return {'id': doc.id, 'username': doc['username']};
//     }).where((user) => !currentMembers.contains(user['id'])).toList();
//
//     setState(() {
//       searchResults = results;
//     });
//   }
//
//   // Thêm user vào nhóm
//   Future<void> _addMember(String userId) async {
//     await _firestore.collection('chats').doc(widget.chatId).update({
//       'users': FieldValue.arrayUnion([userId]),
//     });
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('Member added.')),
//     );
//     _fetchCurrentMembers(); // Cập nhật danh sách thành viên sau khi thêm
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Add member'),
//       ),
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: TextField(
//               controller: _searchController,
//               decoration: const InputDecoration(
//                 labelText: 'Search for users',
//                 border: OutlineInputBorder(),
//               ),
//               onSubmitted: _searchUsers,
//             ),
//           ),
//           Expanded(
//             child: ListView.builder(
//               itemCount: searchResults.length,
//               itemBuilder: (context, index) {
//                 final user = searchResults[index];
//                 return ListTile(
//                   title: Text(user['username']),
//                   trailing: IconButton(
//                     icon: const Icon(Icons.add, color: Colors.green),
//                     onPressed: () => _addMember(user['id']),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddMemberScreen extends StatefulWidget {
  final String chatId;

  const AddMemberScreen({Key? key, required this.chatId}) : super(key: key);

  @override
  _AddMemberScreenState createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> searchResults = [];
  List<String> currentMembers = [];

  @override
  void initState() {
    super.initState();
    _fetchCurrentMembers();
    _fetchAllUsers();
  }

  // Lấy danh sách thành viên hiện tại của nhóm
  Future<void> _fetchCurrentMembers() async {
    DocumentSnapshot groupDoc = await _firestore.collection('chats').doc(widget.chatId).get();
    List<dynamic> users = groupDoc['users'] ?? [];

    setState(() {
      currentMembers = List<String>.from(users);
    });
  }

  // Lấy tất cả user và loại bỏ những người đã là thành viên của nhóm
  Future<void> _fetchAllUsers() async {
    QuerySnapshot snapshot = await _firestore.collection('users').get();

    List<Map<String, dynamic>> results = snapshot.docs.map((doc) {
      return {
        'id': doc.id,
        'username': doc['username'],
        'profile': doc['profile'] ?? ''
      };
    }).where((user) => !currentMembers.contains(user['id'])).toList();

    setState(() {
      searchResults = results;
    });
  }

  // Tìm kiếm người dùng không thuộc nhóm
  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      _fetchAllUsers(); // Hiển thị lại tất cả nếu không có từ khóa
      return;
    }

    QuerySnapshot snapshot = await _firestore
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: query)
        .where('username', isLessThanOrEqualTo: query + '\\uf8ff')
        .get();

    // Loại bỏ các user đã là thành viên của nhóm
    List<Map<String, dynamic>> results = snapshot.docs.map((doc) {
      return {
        'id': doc.id,
        'username': doc['username'],
        'profile': doc['profile'] ?? ''
      };
    }).where((user) => !currentMembers.contains(user['id'])).toList();

    setState(() {
      searchResults = results;
    });
  }

  // Thêm user vào nhóm
  Future<void> _addMember(String userId) async {
    await _firestore.collection('chats').doc(widget.chatId).update({
      'users': FieldValue.arrayUnion([userId]),
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Member added.')),
    );
    _fetchCurrentMembers(); // Cập nhật danh sách thành viên sau khi thêm
    _fetchAllUsers(); // Cập nhật lại danh sách user khả dụng
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade100,
        title: const Text('Add member'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search for users',
                border: OutlineInputBorder(),
              ),
              onChanged: _searchUsers, // Tìm kiếm ngay khi nhập
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: searchResults.length,
              itemBuilder: (context, index) {
                final user = searchResults[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: user['profile'].isNotEmpty
                        ? NetworkImage(user['profile'])
                        : const AssetImage('assets/default_avatar.png') as ImageProvider,
                  ),
                  title: Text(user['username']),
                  trailing: IconButton(
                    icon: const Icon(Icons.add, color: Colors.green),
                    onPressed: () => _addMember(user['id']),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

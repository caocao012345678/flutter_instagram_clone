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

  Future<void> _searchUsers(String query) async {
    QuerySnapshot snapshot = await _firestore
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: query)
        .where('username', isLessThanOrEqualTo: query + '\uf8ff')
        .get();

    setState(() {
      searchResults = snapshot.docs.map((doc) {
        return {'id': doc.id, 'username': doc['username']};
      }).toList();
    });
  }

  Future<void> _addMember(String userId) async {
    await _firestore.collection('chats').doc(widget.chatId).update({
      'users': FieldValue.arrayUnion([userId]),
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã thêm thành viên.')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm thành viên'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Tìm kiếm người dùng',
                border: OutlineInputBorder(),
              ),
              onSubmitted: _searchUsers,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: searchResults.length,
              itemBuilder: (context, index) {
                final user = searchResults[index];
                return ListTile(
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

//
//
// import 'dart:io';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
//
// import 'add_member_screen.dart';
// import 'member_list_screen.dart';
//
// class GroupChatDetailInformationScreen extends StatefulWidget {
//   final String chatId;
//   final String currentUserId;
//
//   const GroupChatDetailInformationScreen({
//     Key? key,
//     required this.chatId,
//     required this.currentUserId,
//   }) : super(key: key);
//
//   @override
//   _GroupChatDetailInformationScreenState createState() =>
//       _GroupChatDetailInformationScreenState();
// }
//
// class _GroupChatDetailInformationScreenState
//     extends State<GroupChatDetailInformationScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   File? _newGroupImage;
//   bool _isLoading = false;
//   bool isAdmin = false; // Whether the current user is the admin
//   String groupName = "";
//   String groupImage = "";
//   List<Map<String, dynamic>> members = [];
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchGroupDetails();
//   }
//
//   // Fetching group details from Firestore
//   Future<void> _fetchGroupDetails() async {
//     setState(() {
//       _isLoading = true;
//     });
//
//     try {
//       DocumentSnapshot groupSnapshot =
//       await _firestore.collection('chats').doc(widget.chatId).get();
//
//       if (!groupSnapshot.exists) {
//         print('Group document does not exist');
//         setState(() {
//           _isLoading = false;
//         });
//         return;
//       }
//
//       Map<String, dynamic> groupData =
//       groupSnapshot.data() as Map<String, dynamic>;
//       List<String> memberIds = List<String>.from(groupData['users']);
//
//       List<Map<String, dynamic>> memberDetails = [];
//       for (String id in memberIds) {
//         DocumentSnapshot userSnapshot =
//         await _firestore.collection('users').doc(id).get();
//         memberDetails.add({
//           'id': id,
//           'username': userSnapshot['username'],
//           'isAdmin': id == groupData['admin'],
//         });
//       }
//
//       setState(() {
//         groupName = groupData['groupName'] ?? "";
//         groupImage = groupData['groupImage'] ?? "";
//         members = memberDetails;
//         isAdmin = groupData['admin'] == widget.currentUserId;
//         _isLoading = false;
//       });
//     } catch (e) {
//       print('Error fetching group details: $e');
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }
//
//   /// Picking a new group image
//   Future<void> _pickNewGroupImage() async {
//     if (!isAdmin) return; // Chỉ cho phép admin chọn ảnh mới
//
//     final picker = ImagePicker();
//     final pickedFile = await picker.pickImage(source: ImageSource.gallery);
//
//     if (pickedFile != null) {
//       setState(() {
//         _newGroupImage = File(pickedFile.path);
//       });
//     }
//   }
//
// // Dialog to change the group name
//   Future<void> _updateGroupNameDialog() async {
//     if (!isAdmin) return; // Chỉ cho phép admin đổi tên nhóm
//
//     TextEditingController controller = TextEditingController(text: groupName);
//
//     // ... (Code hiển thị dialog)
//   }
//   // Updating the group image
//   Future<void> _updateGroupImage() async {
//     if (_newGroupImage == null) return;
//
//     setState(() {
//       _isLoading = true;
//     });
//
//     try {
//       String fileName =
//           'group_images/${DateTime.now().millisecondsSinceEpoch}.jpg';
//       Reference ref = FirebaseStorage.instance.ref().child(fileName);
//       UploadTask uploadTask = ref.putFile(_newGroupImage!);
//       TaskSnapshot snapshot = await uploadTask;
//       String newImageUrl = await snapshot.ref.getDownloadURL();
//
//       await _firestore.collection('chats').doc(widget.chatId).update({
//         'groupImage': newImageUrl,
//       });
//
//       setState(() {
//         groupImage = newImageUrl;
//         _newGroupImage = null;
//         _isLoading = false;
//       });
//
//       _fetchGroupDetails(); // Reload group details after updating the image
//     } catch (e) {
//       setState(() {
//         _isLoading = false;
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Lỗi: $e")),
//       );
//     }
//   }
//
//   // Updating the group name
//   Future<void> _updateGroupName(String newName) async {
//     if (newName.trim().isEmpty) return;
//
//     setState(() {
//       _isLoading = true;
//     });
//
//     await _firestore.collection('chats').doc(widget.chatId).update({
//       'groupName': newName.trim(),
//     });
//
//     setState(() {
//       groupName = newName.trim();
//       _isLoading = false;
//     });
//   }
//
//
//   // Leaving the group
//   Future<void> _leaveGroup() async {
//     try {
//       await _firestore.collection('chats').doc(widget.chatId).update({
//         'users': FieldValue.arrayRemove([widget.currentUserId]),
//       });
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Bạn đã rời nhóm')),
//       );
//
//       Navigator.pop(context);
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Lỗi khi rời nhóm: $e")),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Thông tin nhóm"),
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Displaying group image with option to change it if admin
//             StreamBuilder<DocumentSnapshot>(
//               stream: _firestore
//                   .collection('chats')
//                   .doc(widget.chatId)
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (snapshot.hasError) {
//                   return const Center(
//                       child: Text('Something went wrong'));
//                 }
//
//                 if (snapshot.connectionState ==
//                     ConnectionState.waiting) {
//                   return const Center(
//                       child: CircularProgressIndicator());
//                 }
//
//                 if (!snapshot.hasData || !snapshot.data!.exists) {
//                   return const Center(child: Text('Group not found'));
//                 }
//
//                 Map<String, dynamic> groupData =
//                 snapshot.data!.data() as Map<String, dynamic>;
//                 groupImage = groupData['groupImage'] ?? "";
//                 groupName = groupData['groupName'] ?? ""; // Lấy groupName từ groupData
//
//                 return GestureDetector(
//                   onTap: isAdmin ? _pickNewGroupImage : null,
//                   child: Column( // Sử dụng Column để hiển thị ảnh và tên nhóm
//                     children: [
//                       Center(
//                         child: CircleAvatar(
//                           radius: 60,
//                           backgroundImage: groupImage.isNotEmpty
//                               ? NetworkImage(groupImage)
//                               : AssetImage('assets/default_group.png')
//                           as ImageProvider,
//                           child: groupImage.isEmpty
//                               ? const Icon(Icons.add_a_photo, size: 40)
//                               : null,
//                         ),
//                       ),
//                       const SizedBox(height: 10),
//                       // Group name below the image
//                       Center(
//                         child: Text(
//                           groupName, // Hiển thị groupName
//                           style: const TextStyle(
//                               fontSize: 18, fontWeight: FontWeight.bold),
//                         ),
//                       ),
//                     ],
//                   ),
//                 );
//               },
//             ),
//             const SizedBox(height: 10),
//
//
//             ListView.builder(
//               shrinkWrap: true,
//               physics: const NeverScrollableScrollPhysics(),
//               itemCount: members.length,
//               itemBuilder: (context, index) {
//                 final member = members[index];
//                 return ListTile(
//                   title: Text(
//                     member['username'] +
//                         (member['isAdmin'] ? " (Nhóm trưởng)" : ""),
//                   ),
//                   trailing: isAdmin && !member['isAdmin']
//                       ? IconButton(
//                     icon: const Icon(Icons.remove_circle),
//                     onPressed: () {
//                       _removeMember(member['id']);
//                     },
//                   )
//                       : null,
//                 );
//               },
//             ),
//             const Divider(),
//             ListTile(
//               leading: const Icon(Icons.groups),
//               title: const Text("Danh sách thành viên"),
//               onTap: () => Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => MemberListScreen(
//                     chatId: widget.chatId,
//                     currentUserId: '',
//                   ),
//                 ),
//               ),
//             ),
//             ListTile(
//               leading: const Icon(Icons.person_add),
//               title: const Text("Thêm thành viên"),
//               onTap: () => Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) =>
//                       AddMemberScreen(chatId: widget.chatId),
//                 ),
//               ),
//             ),
//             if (!isAdmin)
//               ListTile(
//                 leading: const Icon(Icons.exit_to_app),
//                 title: const Text("Rời nhóm"),
//                 onTap: _leaveGroup,
//               ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // Removing a member from the group
//   Future<void> _removeMember(String memberId) async {
//     try {
//       await _firestore.collection('chats').doc(widget.chatId).update({
//         'users': FieldValue.arrayRemove([memberId]),
//       });
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Đã xóa thành viên khỏi nhóm!')),
//       );
//       setState(() {
//         members.removeWhere((member) => member['id'] == memberId);
//       });
//     } catch (e) {
//       print("Error removing member: $e");
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Lỗi khi xóa thành viên: $e")),
//       );
//     }
//   }
// }
//
//
//
//
//


import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'add_member_screen.dart';
import 'member_list_screen.dart';

class GroupChatDetailInformationScreen extends StatefulWidget {
  final String chatId;
  final String currentUserId;

  const GroupChatDetailInformationScreen({
    Key? key,
    required this.chatId,
    required this.currentUserId,
  }) : super(key: key);

  @override
  _GroupChatDetailInformationScreenState createState() =>
      _GroupChatDetailInformationScreenState();
}

class _GroupChatDetailInformationScreenState
    extends State<GroupChatDetailInformationScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  File? _newGroupImage;
  bool _isLoading = false;
  bool isAdmin = false; // Whether the current user is the admin
  String groupName = "";
  String groupImage = "";
  List<Map<String, dynamic>> members = [];

  @override
  void initState() {
    super.initState();
    _fetchGroupDetails();
  }

  // Fetching group details from Firestore
  Future<void> _fetchGroupDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      DocumentSnapshot groupSnapshot =
      await _firestore.collection('chats').doc(widget.chatId).get();

      if (!groupSnapshot.exists) {
        print('Group document does not exist');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      Map<String, dynamic> groupData =
      groupSnapshot.data() as Map<String, dynamic>;
      List<String> memberIds = List<String>.from(groupData['users']);

      List<Map<String, dynamic>> memberDetails = [];
      for (String id in memberIds) {
        DocumentSnapshot userSnapshot =
        await _firestore.collection('users').doc(id).get();
        memberDetails.add({
          'id': id,
          'username': userSnapshot['username'],
          'isAdmin': id == groupData['admin'],
        });
      }

      setState(() {
        groupName = groupData['groupName'] ?? "";
        groupImage = groupData['groupImage'] ?? "";
        members = memberDetails;
        isAdmin = groupData['admin'] == widget.currentUserId;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching group details: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Picking a new group image
  Future<void> _pickNewGroupImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _newGroupImage = File(pickedFile.path);
        _updateGroupImage();
      });
    }
  }

  // Updating the group image
  Future<void> _updateGroupImage() async {
    if (_newGroupImage == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String fileName =
          'group_images/${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference ref = FirebaseStorage.instance.ref().child(fileName);
      UploadTask uploadTask = ref.putFile(_newGroupImage!);
      TaskSnapshot snapshot = await uploadTask;
      String newImageUrl = await snapshot.ref.getDownloadURL();

      await _firestore.collection('chats').doc(widget.chatId).update({
        'groupImage': newImageUrl,
      });

      setState(() {
        groupImage = newImageUrl;
        _newGroupImage = null;
        _isLoading = false;
      });

      _fetchGroupDetails();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: $e")),
      );
    }
  }

  // Updating the group name
  Future<void> _updateGroupName(String newName) async {
    if (newName.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    await _firestore.collection('chats').doc(widget.chatId).update({
      'groupName': newName.trim(),
    });

    setState(() {
      groupName = newName.trim();
      _isLoading = false;
    });
  }

  // Dialog to change the group name
  Future<void> _updateGroupNameDialog() async {
    TextEditingController controller = TextEditingController(text: groupName);

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Rename group"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: "New group name"),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                _updateGroupName(controller.text);
                Navigator.pop(context);
              },
              child: const Text("Rename"),
            ),
          ],
        );
      },
    );
  }

  // Leaving the group
  Future<void> _leaveGroup() async {
    try {
      await _firestore.collection('chats').doc(widget.chatId).update({
        'users': FieldValue.arrayRemove([widget.currentUserId]),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You have left the group')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error when leaving group: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade100,
        title: const Text("Group information"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Displaying group image with option to change it if admin
            StreamBuilder<DocumentSnapshot>(
              stream: _firestore
                  .collection('chats')
                  .doc(widget.chatId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                      child: Text('Something went wrong'));
                }

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text('Group not found'));
                }

                Map<String, dynamic> groupData =
                snapshot.data!.data() as Map<String, dynamic>;
                groupImage = groupData['groupImage'] ?? "";
                groupName = groupData['groupName'] ?? "";

                return GestureDetector(
                  onTap: _pickNewGroupImage, // Tất cả thành viên đều có thể chọn ảnh
                  child: Column(
                    children: [
                      Center(
                        child: CircleAvatar(
                          radius: 60,
                          backgroundImage: groupImage.isNotEmpty
                              ? NetworkImage(groupImage)
                              : AssetImage('assets/default_group.png')
                          as ImageProvider,
                          child: groupImage.isEmpty
                              ? const Icon(Icons.add_a_photo, size: 40)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Group name below the image
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              groupName,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            IconButton( // Tất cả thành viên đều có thể đổi tên
                              onPressed: _updateGroupNameDialog,
                              icon: const Icon(Icons.edit),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 10),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: members.length,
              itemBuilder: (context, index) {
                final member = members[index];
                return ListTile(
                  title: Text(
                    member['username'] +
                        (member['isAdmin'] ? " (Admin)" : ""),
                  ),
                  trailing: isAdmin && !member['isAdmin']
                      ? IconButton(
                    icon: const Icon(Icons.remove_circle),
                    onPressed: () {
                      _removeMember(member['id']);
                    },
                  )
                      : null,
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.groups),
              title: const Text("Member List"),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MemberListScreen(
                    chatId: widget.chatId,
                    currentUserId: '',
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text("Add member"),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AddMemberScreen(chatId: widget.chatId),
                ),
              ),
            ),
            if (!isAdmin)
              ListTile(
                leading: const Icon(Icons.exit_to_app),
                title: const Text("Leave group"),
                onTap: _leaveGroup,
              ),
          ],
        ),
      ),
    );
  }

  // Removing a member from the group
  Future<void> _removeMember(String memberId) async {
    try {
      await _firestore.collection('chats').doc(widget.chatId).update({
        'users': FieldValue.arrayRemove([memberId]),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Member removed from group!')),
      );
      setState(() {
        members.removeWhere((member) => member['id'] == memberId);
      });
    } catch (e) {
      print("Error removing member: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error while deleting member: $e")),
      );
    }
  }
}
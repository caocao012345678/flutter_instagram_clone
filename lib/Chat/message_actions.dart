//
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart'; // Để sử dụng Clipboard
// import 'package:firebase_storage/firebase_storage.dart'; // Để tải ảnh từ Firebase
// import 'dart:io'; // Để lưu ảnh xuống thiết bị
// import 'package:path_provider/path_provider.dart'; // Để lấy đường dẫn lưu trữ
//
// class MessageActions {
//   static void showMessageMenu({
//     required BuildContext context,
//     required VoidCallback onReply,
//     required Future<void> Function() onRecall,
//     required VoidCallback onCopy,
//     required bool isImage,
//     required String contentOrUrl,
//     required Timestamp timestamp,
//   }) {
//     showModalBottomSheet(
//       context: context,
//       builder: (context) {
//         return Wrap(
//           children: [
//             ListTile(
//               leading: Icon(Icons.reply),
//               title: Text('Trả lời tin nhắn'),
//               onTap: () {
//                 Navigator.pop(context); // Đóng menu
//                 onReply();
//               },
//             ),
//             ListTile(
//               leading: Icon(Icons.undo),
//               title: Text('Thu hồi tin nhắn'),
//               onTap: () async {
//                 Navigator.pop(context);
//                 await onRecall();
//               },
//             ),
//             ListTile(
//               leading: Icon(Icons.copy),
//               title: Text(isImage ? 'Sao chép hình ảnh' : 'Sao chép tin nhắn'),
//               onTap: () async {
//                 if (isImage) {
//                   await _copyImageFromFirebase(context, contentOrUrl);
//                 } else {
//                   Clipboard.setData(ClipboardData(text: contentOrUrl));
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(content: Text('Đã sao chép tin nhắn!')),
//                   );
//                 }
//                 Navigator.pop(context); // Đóng menu
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   static Future<void> _copyImageFromFirebase(
//       BuildContext context, String imageUrl) async {
//     try {
//       final ref = FirebaseStorage.instance.refFromURL(imageUrl);
//       final bytes = await ref.getData();
//
//       if (bytes == null) throw Exception('Không thể tải ảnh xuống');
//
//       final directory = await getTemporaryDirectory();
//       final imagePath = '${directory.path}/copied_image.png';
//       final file = File(imagePath);
//       await file.writeAsBytes(bytes);
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Hình ảnh đã được sao chép vào thiết bị!')),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Không thể sao chép hình ảnh: $e')),
//       );
//     }
//   }
// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Để tải ảnh từ Firebase
import 'dart:io'; // Để lưu ảnh xuống thiết bị
import 'package:path_provider/path_provider.dart'; // Để lấy đường dẫn lưu trữ
 // Để lưu ảnh vào thư viện

class MessageActions {
  static void showMessageMenu({
    required BuildContext context,
    required VoidCallback onReply,
    required Future<void> Function() onRecall,
    required VoidCallback onCopy,
    required bool isImage,
    required String contentOrUrl,
    required Timestamp timestamp,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.reply),
              title: Text('Reply to message'),
              onTap: () {
                Navigator.pop(context); // Đóng menu
                onReply();
              },
            ),
            ListTile(
              leading: Icon(Icons.undo),
              title: Text('Recall message'),
              onTap: () async {
                Navigator.pop(context);
                await onRecall();
              },
            ),
            ListTile(
              leading: Icon(Icons.copy),
              title: Text(isImage ? 'Copy image URL' : 'Copy message'),
              onTap: () async {
                if (isImage) {
                  await _copyImageUrlToClipboard(context, contentOrUrl);
                } else {
                  Clipboard.setData(ClipboardData(text: contentOrUrl));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Message copied!')),
                  );
                }
                Navigator.pop(context); // Đóng menu
              },
            ),
            if (isImage)
              ListTile(
                leading: Icon(Icons.save_alt),
                title: Text('Save image to gallery'),
                onTap: () async {
                  // await _saveImageToGallery(context, contentOrUrl);
                  Navigator.pop(context); // Đóng menu
                },
              ),
          ],
        );
      },
    );
  }

  /// Sao chép URL ảnh vào clipboard
  static Future<void> _copyImageUrlToClipboard(BuildContext context,
      String imageUrl) async {
    try {
      Clipboard.setData(ClipboardData(text: imageUrl));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image URL copied to clipboard!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot copy URL: $e')),
      );
    }
  }

  // /// Lưu hình ảnh xuống thư viện
  // static Future<void> _saveImageToGallery(BuildContext context,
  //     String imageUrl) async {
  //   try {
  //     // Lấy dữ liệu ảnh từ Firebase Storage
  //     final ref = FirebaseStorage.instance.refFromURL(imageUrl);
  //     final bytes = await ref.getData();
  //
  //     if (bytes == null) throw Exception('Không thể tải ảnh từ URL');
  //
  //     // Lưu ảnh vào thư viện
  //     final result = await ImageGallerySaver.saveImage(
  //       bytes,
  //       quality: 100,
  //       name: 'image_${DateTime
  //           .now()
  //           .millisecondsSinceEpoch}',
  //     );
  //
  //     if (result['isSuccess'] == true) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Hình ảnh đã được lưu vào thư viện!')),
  //       );
  //     } else {
  //       throw Exception('Không thể lưu ảnh vào thư viện');
  //     }
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Lỗi khi lưu ảnh: $e')),
  //     );
  //   }
  // }
}



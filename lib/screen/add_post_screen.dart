import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_instagram_clone/screen/addpost_text.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photo_manager/photo_manager.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final List<Widget> _mediaList = [];
  final List<File> path = [];
  File? _file;
  int currentPage = 0;
  int? lastPage;

  @override
  void initState() {
    super.initState();
    requestPermissionAndFetchMedia();
  }

  Future<void> requestPermissionAndFetchMedia() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (ps.isAuth) {
      await _fetchNewMedia();
    } else if (!ps.isAuth) {
      showPermissionDeniedDialog();
    }
  }

  void showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Permission denied'),
        content: Text(
          'The app needs photo access to upload photos. Please grant permission to continue.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              requestPermissionAndFetchMedia(); // Thử lại yêu cầu quyền
            },
            child: Text('Try again'),
          ),
        ],
      ),
    );
  }

  void showPermanentPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Permission Permanently Denied'),
        content: Text(
          'You have permanently denied photo access. Go to settings and grant permission to the app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await PhotoManager.openSetting(); // Mở cài đặt ứng dụng
            },
            child: Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchNewMedia() async {
    lastPage = currentPage;
    List<AssetPathEntity> album =
    await PhotoManager.getAssetPathList(type: RequestType.image);
    List<AssetEntity> media =
    await album[0].getAssetListPaged(page: currentPage, size: 60);

    for (var asset in media) {
      if (asset.type == AssetType.image) {
        final file = await asset.file;
        if (file != null) {
          path.add(File(file.path));
          _file = path[0];
        }
      }
    }
    List<Widget> temp = [];
    for (var asset in media) {
      temp.add(
        FutureBuilder(
          future: asset.thumbnailDataWithSize(ThumbnailSize(200, 200)),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return Container(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.memory(
                        snapshot.data!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ),
              );
            }
            return Container();
          },
        ),
      );
    }
    setState(() {
      _mediaList.addAll(temp);
      currentPage++;
    });
  }

  int indexx = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'New Post',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: false,
        actions: [
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              child: GestureDetector(
                onTap: () {
                  if (_file != null) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => AddPostTextScreen(_file!),
                      ),
                    );
                  }
                },
                child: Text(
                  'Next',
                  style: TextStyle(fontSize: 15.sp, color: Colors.blue),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Hình Ảnh Được Chọn
            SizedBox(
              height: 375.h,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(), // Không cuộn riêng
                itemCount: _mediaList.isEmpty ? 0 : 1,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 1,
                  mainAxisSpacing: 1,
                  crossAxisSpacing: 1,
                ),
                itemBuilder: (context, index) {
                  return _mediaList[indexx];
                },
              ),
            ),

            // Tiêu Đề "Recent"
            Container(
              width: double.infinity,
              height: 40.h,
              color: Colors.white,
              child: Row(
                children: [
                  SizedBox(width: 10.w),
                  Text(
                    'Recent',
                    style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: Colors.grey.shade300, // Đặt màu nền xám
                child: GridView.builder(
                  itemCount: _mediaList.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 2,
                    crossAxisSpacing: 2,
                  ),
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          indexx = index;
                          _file = path[index];
                        });
                      },
                      child: _mediaList[index],
                    );
                  },
                ),
              ),
            ),

          ],
        ),
      ),

    );
  }
}

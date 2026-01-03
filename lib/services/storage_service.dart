import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 处理 Firebase Storage 上传逻辑的服务
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// 上传头像并返回下载 URL
  /// 路径格式: avatars/{userId}.jpg
  Future<String> uploadAvatar({
    required String userId,
    required File file,
  }) async {
    try {
      final ref = _storage.ref().child('avatars').child('$userId.jpg');

      // 设置元数据
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'userId': userId},
      );

      // 执行上传
      final uploadTask = await ref.putFile(file, metadata);

      // 获取下载 URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('文件上传失败: $e');
    }
  }
}

final storageServiceProvider = Provider((ref) => StorageService());

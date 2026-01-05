import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post.dart';

/// Feed 帖子数据 Provider
/// [Phase 5.0] 增强错误处理和日志输出
final postsProvider = FutureProvider<List<Post>>((ref) async {
  debugPrint('[postsProvider] 开始加载 Firestore posts...');

  try {
    final snapshot = await FirebaseFirestore.instance.collection('posts').get();
    debugPrint('[postsProvider] ✅ 成功加载 ${snapshot.docs.length} 条帖子');
    return snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
  } catch (e, stackTrace) {
    debugPrint('[postsProvider] ❌ 加载失败: $e');
    debugPrint('[postsProvider] StackTrace: $stackTrace');
    rethrow;
  }
});

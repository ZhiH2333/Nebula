import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  // 文本控制器
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  // 加载状态
  bool _isLoading = false;

  Future<void> _submitPost() async {
    // 简单校验
    if (_titleController.text.trim().isEmpty ||
        _bodyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写标题和正文')),
      );
      return;
    }

    // 获取当前用户
    var user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先登录')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 获取用户昵称逻辑：
      // 1. 优先使用 Auth 中的 displayName
      // 2. 如果为空，尝试 reload 后再次获取
      // 3. 仍然为空，从 Firestore users 集合获取
      String authorName = user.displayName ?? '';

      if (authorName.isEmpty) {
        try {
          await user.reload(); // 尝试刷新
          user = ref.read(firebaseAuthProvider).currentUser; // 重新获取实例
          authorName = user?.displayName ?? '';
        } catch (e) {
          // 忽略 reload 失败（如 PigeonUserInfo 类型错误），直接降级到 Firestore 获取
          debugPrint('User reload failed: $e');
        }
      }

      if (authorName.isEmpty && user != null) {
        // Fallback: 从 Firestore 读取
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          authorName = userDoc.data()?['displayName'] ?? 'Unknown';
        } else {
          authorName = 'Unknown';
        }
      }

      // 写入 Firestore
      await FirebaseFirestore.instance.collection('posts').add({
        'title': _titleController.text.trim(),
        'body': _bodyController.text.trim(),
        'author': authorName,
        'authorId': user!.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'isRemote': false,
        'source': 'local',
      });

      if (mounted) {
        // 发送成功，返回上一页
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('发布成功！')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('发布失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('发布新帖子'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 标题输入框
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '标题',
                hintText: '写一个有趣的标题...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // 正文输入框
            TextField(
              controller: _bodyController,
              decoration: const InputDecoration(
                labelText: '正文',
                hintText: '分享你的想法...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 6,
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: 24),
            // 发布按钮
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: _isLoading ? null : _submitPost,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send),
                label: Text(_isLoading ? '发送中...' : '发布'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

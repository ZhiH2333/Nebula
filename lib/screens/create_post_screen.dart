import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
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

    setState(() {
      _isLoading = true;
    });

    try {
      // 写入 Firestore
      // 对应 Phase 5 需求：isRemote: false, source: 'nebula-local'
      await FirebaseFirestore.instance.collection('posts').add({
        'title': _titleController.text.trim(),
        'body': _bodyController.text.trim(),
        'author': 'Me', // 暂时硬编码，后续对接 Auth
        'createdAt': FieldValue.serverTimestamp(), // 服务端时间戳
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

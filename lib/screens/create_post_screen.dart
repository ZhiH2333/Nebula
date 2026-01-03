import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../providers/auth_provider.dart';
import '../models/post.dart';
import '../models/actor_model.dart';
import '../services/actor_service.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  final Post? editPost;

  const CreatePostScreen({super.key, this.editPost});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  // 文本控制器
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  // identities (actors) 列表
  List<Actor> _actors = [];
  Actor? _selectedActor;
  bool _preview = false;

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
      final data = {
        'title': _titleController.text.trim(),
        'body': _bodyController.text.trim(),
        'author': authorName,
        'authorId': user!.uid,
        'actorHandle': _selectedActor?.handle ??
            '${user.uid.substring(0, 6)}@nebula.local',
        'createdAt': FieldValue.serverTimestamp(),
        'isRemote': false,
        'source': 'local',
        'actor': _selectedActor?.toMap() ?? {},
      };

      if (widget.editPost != null) {
        // 编辑已发布的本地帖子
        await FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.editPost!.id)
            .update(data);
      } else {
        await FirebaseFirestore.instance.collection('posts').add(data);
      }

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
  void initState() {
    super.initState();
    // 如果是编辑模式，预填充（只做一次）
    if (widget.editPost != null) {
      _titleController.text = widget.editPost!.title;
      _bodyController.text = widget.editPost!.body;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 如果是编辑模式，预填充
    if (widget.editPost != null) {
      _titleController.text = widget.editPost!.title;
      _bodyController.text = widget.editPost!.body;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editPost != null ? '编辑帖子' : '发布新帖子'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 身份选择器
            FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(ref.read(firebaseAuthProvider).currentUser?.uid)
                  .get(),
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  // don't block UI; show placeholder
                  return const SizedBox.shrink();
                }
                final data = snap.data?.data();
                final raw = (data?['actors'] as List<dynamic>?) ?? [];
                _actors = raw
                    .map((e) =>
                        Actor.fromMap(Map<String, dynamic>.from(e as Map)))
                    .toList();

                // 如果没有 actors，则使用临时回退显示并在后台触发初始化
                if (_actors.isEmpty) {
                  final fallbackHandle = (data?['displayName'] as String?) ??
                      (data?['username'] as String?) ??
                      'me';
                  final fallback = Actor(
                      handle: '$fallbackHandle@nebula.local',
                      displayName: fallbackHandle,
                      type: 'Person');
                  _actors = [fallback];
                  final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
                  if (uid != null) {
                    Future.microtask(() async {
                      try {
                        await ActorService.ensureDefaultActorsForUser(
                          uid: uid,
                          displayName: data?['displayName'] ?? '',
                          username: (data?['username'] as String?) ?? uid,
                        );
                      } catch (_) {}
                    });
                  }
                }

                _selectedActor ??= _actors.first;

                // 优雅的身份切换器：ChoiceChip 横向展示
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('以哪个身份发布', style: TextStyle(fontSize: 13)),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _actors.map((a) {
                          final selected = _selectedActor?.handle == a.handle;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(a.displayName,
                                  style: TextStyle(
                                      color: selected
                                          ? Colors.white
                                          : Colors.black)),
                              selected: selected,
                              onSelected: (_) =>
                                  setState(() => _selectedActor = a),
                              selectedColor: Colors.black,
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: Colors.black12),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
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
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _bodyController,
                      decoration: const InputDecoration(
                        labelText: '正文',
                        hintText: '支持 Markdown（预览在下方）',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: null,
                      expands: true,
                      keyboardType: TextInputType.multiline,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Checkbox(
                        value: _preview,
                        onChanged: (v) => setState(() => _preview = v ?? false),
                      ),
                      const Text('显示 Markdown 预览'),
                      const Spacer(),
                      SizedBox(
                        height: 44,
                        child: FilledButton.icon(
                          onPressed: _isLoading ? null : _submitPost,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.send),
                          label: Text(_isLoading
                              ? '发送中...'
                              : (widget.editPost != null ? '保存' : '发布')),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_preview)
                    Expanded(
                      child: Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: MarkdownBody(data: _bodyController.text),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

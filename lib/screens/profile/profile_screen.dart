import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';

/// 个人中心页面 (修正版)：极简风格，仅限文字操作
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isProcessing = false;

  User? get _currentUser => ref.read(firebaseAuthProvider).currentUser;

  /// --- 1. 获取“我的发布”数量 ---
  Stream<int> _getMyPostsCount() {
    final userId = _currentUser?.uid;
    if (userId == null) return Stream.value(0);
    return FirebaseFirestore.instance
        .collection('posts')
        .where('authorId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// --- 2. 修改昵称逻辑 (仅文字) ---
  Future<void> _handleUpdateDisplayName() async {
    final controller = TextEditingController(text: _currentUser?.displayName);

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title:
            const Text('修改昵称', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '输入新昵称',
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.black12)),
            focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.black)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('确定',
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (newName == null ||
        newName.isEmpty ||
        newName == _currentUser?.displayName) return;

    setState(() => _isProcessing = true);
    try {
      // 1. 更新 Firebase Auth Profile
      await _currentUser!.updateDisplayName(newName);

      // 2. 更新 Firestore (使用 set merge 防止文档不存在报错)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .set({'displayName': newName}, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('昵称已更新')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('修改失败: $e')));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  /// --- 3. 退出登录 ---
  Future<void> _handleSignOut() async {
    try {
      await ref.read(firebaseAuthProvider).signOut();
      if (mounted) {
        // 彻底清空并回退到主路由，由 AuthWrapper 处理跳转
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('退出失败: $e')));
    }
  }

  /// --- 4. 注销账号 ---
  Future<void> _handleDeleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('确认注销账号？',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('此操作将永久删除您的账号和所有数据，且无法恢复。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消', style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('确认注销'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);
    try {
      final userId = _currentUser?.uid;

      // 1. 先删除 Firestore 数据
      if (userId != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .delete();
      }

      // 2. 再删除 Auth 账号
      await _currentUser?.delete();

      if (mounted) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        if (mounted) {
          _showErrorDialog('安全提示', '为了安全，注销操作需要最近的登录记录。请重新登录后再试。');
        }
      } else {
        if (mounted)
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('操作失败: ${e.message}')));
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('发生错误: $e')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showErrorDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(content),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('知道了', style: TextStyle(color: Colors.black))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('个人空间',
            style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: authState.when(
        data: (user) {
          if (user == null) return const SizedBox();
          final initial = user.displayName?.isNotEmpty == true
              ? user.displayName![0].toUpperCase()
              : (user.email?.isNotEmpty == true
                  ? user.email![0].toUpperCase()
                  : '?');

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                // 文字头像占位符
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.black,
                  child: Text(
                    initial,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.w300),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  user.displayName ?? '未设置昵称',
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email ?? '',
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
                const SizedBox(height: 32),

                // 数据统计
                StreamBuilder<int>(
                  stream: _getMyPostsCount(),
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 20, horizontal: 40),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text('$count',
                              style: const TextStyle(
                                  fontSize: 28, fontWeight: FontWeight.bold)),
                          const Text('我的发布',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 48),

                // 功能列表
                _buildActionRow(
                  icon: Icons.edit_outlined,
                  title: '修改昵称',
                  onTap: _handleUpdateDisplayName,
                ),
                const Divider(height: 1, color: Colors.black12),
                _buildActionRow(
                  icon: Icons.logout_outlined,
                  title: '退出登录',
                  onTap: _handleSignOut,
                ),
                const Divider(height: 1, color: Colors.black12),
                _buildActionRow(
                  icon: Icons.person_remove_outlined,
                  title: '注销账号',
                  isDestructive: true,
                  onTap: _handleDeleteAccount,
                ),

                if (_isProcessing)
                  const Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: CircularProgressIndicator(
                        color: Colors.black, strokeWidth: 2),
                  ),
              ],
            ),
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator(color: Colors.black)),
        error: (e, _) => Center(child: Text('加载失败: $e')),
      ),
    );
  }

  Widget _buildActionRow({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      onTap: _isProcessing ? null : onTap,
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: Icon(icon,
          color: isDestructive ? Colors.red : Colors.black87, size: 22),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : Colors.black87,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
      ),
      trailing:
          const Icon(Icons.chevron_right, color: Colors.black12, size: 18),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isLoading = false;

  void _setLoading(bool value) {
    if (mounted) {
      setState(() {
        _isLoading = value;
      });
    }
  }

  Future<void> _signOut() async {
    try {
      _setLoading(true);
      await ref.read(authServiceProvider).signOut();
      if (mounted) {
        // Pop profile screen first, though AuthWrapper will likely rebuild the entire app tree
        // Navigator.of(context).pop();
        // Actually AuthWrapper handles the switch to login screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('退出失败: $e')),
        );
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _deleteAccount() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认注销账号?'),
        content: const Text('此操作不可逆，您的所有数据将被永久删除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('确认注销'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        _setLoading(true);
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await user.delete();
          // Deletion triggers auth state change potentially, or we force sign out
          // await ref.read(authServiceProvider).signOut();
        }
      } on FirebaseAuthException catch (e) {
        if (mounted) {
          String message = '注销失败: ${e.message}';
          if (e.code == 'requires-recent-login') {
            message = '为了安全，请重新登录后再尝试注销。';
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('未知错误: $e')),
          );
        }
      } finally {
        _setLoading(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch current user for updates
    final userAsync = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('个人中心'),
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('未登录'));
          }
          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: user.photoURL != null
                          ? NetworkImage(user.photoURL!)
                          : null,
                      child: user.photoURL == null
                          ? Text(
                              user.displayName?.isNotEmpty == true
                                  ? user.displayName![0].toUpperCase()
                                  : '?',
                              style: const TextStyle(fontSize: 40))
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      user.displayName ?? '未命名用户',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  Center(
                    child: Text(
                      user.email ?? '',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('退出登录'),
                    onTap: _isLoading ? null : _signOut,
                  ),
                  ListTile(
                    leading:
                        const Icon(Icons.delete_forever, color: Colors.red),
                    title:
                        const Text('注销账号', style: TextStyle(color: Colors.red)),
                    onTap: _isLoading ? null : _deleteAccount,
                  ),
                ],
              ),
              if (_isLoading)
                Container(
                  color: Colors.black12,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('加载失败: $e')),
      ),
    );
  }
}

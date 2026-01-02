import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _isLogin = true; // 默认为登录模式
  bool _isLoading = false;

  // 控制器
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  // 提交表单
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authService = ref.read(authServiceProvider);

    try {
      if (_isLogin) {
        await authService.login(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      } else {
        await authService.register(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          username: _usernameController.text.trim(),
          displayName: _displayNameController.text.trim(),
        );
      }
      // 成功后由 authStateProvider 自动导航
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? '登录 Nebula' : '注册 Nebula')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 邮箱输入
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: '邮箱'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => value!.contains('@') ? null : '请输入有效邮箱',
                ),
                const SizedBox(height: 16),

                // 密码输入
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: '密码'),
                  obscureText: true,
                  validator: (value) => value!.length >= 6 ? null : '密码至少6位',
                ),

                // 注册时额外显示的字段
                if (!_isLogin) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(labelText: '用户名 (唯一ID)'),
                    validator: (value) => value!.isNotEmpty ? null : '请输入用户名',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _displayNameController,
                    decoration: const InputDecoration(labelText: '显示昵称'),
                    validator: (value) => value!.isNotEmpty ? null : '请输入昵称',
                  ),
                ],

                const SizedBox(height: 24),

                // 提交按钮
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : Text(_isLogin ? '登录' : '注册账号'),
                ),

                const SizedBox(height: 16),

                // 切换模式按钮
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isLogin = !_isLogin;
                      _formKey.currentState?.reset();
                    });
                  },
                  child: Text(_isLogin ? '没有账号？去注册' : '已有账号？去登录'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:firebase_core/firebase_core.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 Firebase
  // [LOCAL MODE] 暂时禁用 Firebase，使用 FakeAuthService
  // await Firebase.initializeApp();

  runApp(
    const ProviderScope(
      child: NebulaApp(),
    ),
  );
}

class NebulaApp extends StatelessWidget {
  const NebulaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nebula',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

/// 认证包装器
/// 监听认证状态，决定显示登录页还是主页
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          // 已登录: 显示主页 (暂用 Placeholder 代替)
          return Scaffold(
            appBar: AppBar(
              title: const Text('Nebula 主页'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.exit_to_app),
                  onPressed: () => ref.read(authServiceProvider).logout(),
                ),
              ],
            ),
            body: const Center(child: Text('欢迎来到 Nebula (UI 开发中)')),
          );
        }
        // 未登录: 显示登录页
        return const LoginScreen();
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, trace) => Scaffold(body: Center(child: Text('错误: $e'))),
    );
  }
}

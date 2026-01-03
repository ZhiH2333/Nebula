import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nebula/main.dart';
import 'package:nebula/providers/auth_provider.dart';

// 简单 Mock User (如果需要)
// class MockUser extends Mock implements User {}

void main() {
  testWidgets('App renders smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // Wrap in ProviderScope for Riverpod
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // 模拟 Auth 状态为 "未登录"，这样主页会显示 LoginScreen
          authStateProvider.overrideWith((ref) => Stream.value(null)),
        ],
        child: const NebulaApp(),
      ),
    );

    // 等待 AsyncValue 加载完成
    await tester.pumpAndSettle();

    // Verify that the login screen appears
    // 注意：LoginScreen 目前根据 _isLogin 状态显示 '登录 Nebula' 或 '注册 Nebula'
    // 默认是登录模式
    expect(find.text('登录 Nebula'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });
}

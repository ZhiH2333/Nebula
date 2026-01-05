import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/fake_auth_service.dart';
import '../models/user.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 🔐 Phase 6.1
// Firebase 当前登录用户（监听状态变化）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/// Firebase 当前登录用户（监听状态变化）
/// - 返回一个 `Stream<User?>`，当登录状态变化时自动更新
/// - 仅作状态监听，不包含额外业务逻辑
final firebaseUserProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// [LOCAL MODE] 使用 FakeAuthService 替代真实的 AuthService
final authServiceProvider = Provider((ref) => FakeAuthService());

// [LOCAL MODE] 监听 FakeAuthService 的流
final authStateProvider = StreamProvider<AppUser?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

// [LOCAL MODE] 直接返回 authStateProvider 的数据
// 因为 FakeAuthService 的流直接给出了 AppUser 对象，不像 Firebase 只给 User 对象
final currentUserProvider = FutureProvider<AppUser?>((ref) async {
  final authState = ref.watch(authStateProvider);
  return authState.value;
});

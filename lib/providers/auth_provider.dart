import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/fake_auth_service.dart';
import '../models/user.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 🔐 [Phase 5.0] Firebase Auth 当前用户 (只读)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/// 直接暴露 FirebaseAuth.instance.currentUser
/// - 返回值可能为 null（未登录或初始化中）
/// - 不涉及任何业务逻辑，仅供后续功能使用
/// - 当前 UI 不依赖此 Provider
final firebaseUserProvider = Provider<User?>((ref) {
  return FirebaseAuth.instance.currentUser;
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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/fake_auth_service.dart';
import '../models/user.dart';

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

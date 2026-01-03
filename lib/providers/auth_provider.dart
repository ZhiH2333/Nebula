import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 暴露 FirebaseAuth 实例
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// 暴露 Firestore 实例
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// 监听当前用户的登录状态
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

/// 认证服务类：处理登录、注册、注销
class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthService(this._auth, this._firestore);

  /// 邮箱密码注册 (原子性：创建 Auth 账户 + 写入 Firestore User 文档)
  Future<void> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      // 1. 在 Firebase Auth 创建用户
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;
      if (user == null) {
        throw Exception("Auth created but user is null");
      }

      // 2. 更新 Auth 这里的 displayName (可选，为了方便直接获取)
      if (displayName != null && displayName.isNotEmpty) {
        await user.updateDisplayName(displayName);
        await user.reload(); // 刷新用户信息
      }

      // 3. 在 Firestore 创建 User Profile
      // 原子性要求：如果这里失败了，理想情况应该回滚 Auth，但 Firebase 跨服务事务较复杂。
      // 实践中通常确保这一步尽可能成功，或者在登录时检查补充。
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': email,
        'displayName': displayName ?? 'Unknown',
        'avatarUrl': null, // 预留头像
        'bio': 'Hey there! I am using Nebula.',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseAuthException catch (e) {
      // 处理特定的 Auth 错误
      if (e.code == 'weak-password') {
        throw Exception('密码太弱。');
      } else if (e.code == 'email-already-in-use') {
        throw Exception('该邮箱已被注册。');
      }
      throw Exception(e.message ?? '注册失败');
    } catch (e) {
      throw Exception('注册发生未知错误: $e');
    }
  }

  /// 邮箱密码登录
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('未找到该用户。');
      } else if (e.code == 'wrong-password') {
        throw Exception('密码错误。');
      }
      throw Exception(e.message ?? '登录失败');
    }
  }

  /// 注销
  Future<void> signOut() async {
    await _auth.signOut();
  }
}

/// 暴露 AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    ref.watch(firebaseAuthProvider),
    ref.watch(firestoreProvider),
  );
});

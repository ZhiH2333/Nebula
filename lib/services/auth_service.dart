import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../core/constants.dart';

/// 认证服务 - 处理用户登录注册
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 获取当前登录用户 (Firebase User)
  User? get currentUser => _auth.currentUser;

  /// 用户注册
  /// [email] 邮箱
  /// [password] 密码
  /// [username] 用户名
  /// [displayName] 显示名称
  Future<AppUser?> register({
    required String email,
    required String password,
    required String username,
    required String displayName,
  }) async {
    try {
      // 1. 检查用户名是否已被使用
      final usernameQuery = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .get();

      if (usernameQuery.docs.isNotEmpty) {
        throw Exception('用户名已被使用');
      }

      // 2. 创建 Firebase 认证账号
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) throw Exception('创建用户失败');

      // 3. 生成 ActivityPub Actor ID (暂用占位符, 实际应为 https://域名/users/用户名)
      // 注意：AppConstants.activityPubHost 指向配置的域名
      final actorId = 'https://${AppConstants.activityPubHost}/users/$username';

      // 4. 创建用户文档
      final newUser = AppUser(
        id: user.uid,
        username: username,
        displayName: displayName,
        createdAt: DateTime.now(),
        actorId: actorId,
        isRemote: false, // 本地注册用户
        host: null, // 本地用户 host 为空
      );

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(newUser.toFirestore());

      return newUser;
    } catch (e) {
      print('注册失败: $e');
      rethrow;
    }
  }

  /// 用户登录
  Future<AppUser?> login(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) return null;

      // 获取用户数据
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        // 如果 Firebase Auth 存在但 Firestore 没有数据 (极端情况)
        throw Exception('用户数据不存在');
      }

      return AppUser.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      print('登录失败: $e');
      rethrow;
    }
  }

  /// 登出
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// 根据 ID 获取用户详细信息
  Future<AppUser?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;
      return AppUser.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      print('获取用户失败: $e');
      return null;
    }
  }
}

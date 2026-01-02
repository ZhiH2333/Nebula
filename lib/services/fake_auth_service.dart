import 'dart:async';
import '../models/user.dart';

/// 本地模拟认证服务 (无 Firebase)
/// 职责：提供假的用户登录、注册、状态管理，让界面能跑起来
class FakeAuthService {
  // 模拟一个简单的内存用户存储
  AppUser? _currentUser;

  // 用于通知状态变化的流控制器
  final _authStateController = StreamController<AppUser?>.broadcast();

  // 获取状态变更流
  // 修改：订阅时立即把当前状态发出去，否则 UI 会一直转圈圈
  Stream<AppUser?> get authStateChanges async* {
    yield _currentUser;
    yield* _authStateController.stream;
  }

  // 获取当前用户
  AppUser? get currentUser => _currentUser;

  /// 模拟登录
  /// 只要邮箱和密码不为空，就视为登录成功
  Future<AppUser?> login(String email, String password) async {
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 800));

    if (email.isEmpty || password.isEmpty) {
      throw Exception('邮箱或密码不能为空');
    }

    // 创建一个假用户
    final fakeUser = AppUser(
      id: 'fake-user-001',
      username: 'tester',
      displayName: '测试员',
      createdAt: DateTime.now(),
      actorId: 'https://example.com/users/tester',
      isRemote: false,
    );

    _currentUser = fakeUser;
    _authStateController.add(fakeUser); // 通知所有人：登录成功了
    return fakeUser;
  }

  /// 模拟注册
  /// 逻辑和登录一样，直接成功
  Future<AppUser?> register({
    required String email,
    required String password,
    required String username,
    required String displayName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    if (username.isEmpty) throw Exception('用户名不能为空');

    final newUser = AppUser(
      id: 'fake-user-${DateTime.now().millisecondsSinceEpoch}',
      username: username,
      displayName: displayName,
      createdAt: DateTime.now(),
      actorId: 'https://example.com/users/$username',
      isRemote: false,
    );

    _currentUser = newUser;
    _authStateController.add(newUser);
    return newUser;
  }

  /// 模拟登出
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _currentUser = null;
    _authStateController.add(null); // 通知所有人：变回未登录状态
  }

  /// 模拟获取数据
  Future<AppUser?> getUserById(String id) async {
    if (_currentUser != null && _currentUser!.id == id) {
      return _currentUser;
    }
    return null; // 找不到其他人
  }
}

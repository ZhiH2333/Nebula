import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// 用户数据模型
class AppUser extends Equatable {
  final String id; // 用户 ID (Firebase UID 或 远程 ID)
  final String username; // 用户名 (唯一)
  final String displayName; // 显示名称
  final String? bio; // 个人简介
  final String? avatarUrl; // 头像地址
  final DateTime createdAt; // 创建时间

  // ActivityPub 相关
  final String actorId; // ActivityPub Actor ID (URI字符串)
  final String? publicKey; // 公钥 (用于签名验证)

  // 联邦相关区分
  final bool isRemote; // 是否为远程用户
  final String? host; // 所在实例域名 (本地用户为 null)

  const AppUser({
    required this.id,
    required this.username,
    required this.displayName,
    this.bio,
    this.avatarUrl,
    required this.createdAt,
    required this.actorId,
    this.publicKey,
    this.isRemote = false,
    this.host,
  });

  /// 从 Firestore 文档转换为用户对象
  factory AppUser.fromFirestore(Map<String, dynamic> data, String id) {
    return AppUser(
      id: id,
      username: data['username'] ?? '',
      displayName: data['displayName'] ?? '',
      bio: data['bio'],
      avatarUrl: data['avatarUrl'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      actorId: data['actorId'] ?? '',
      publicKey: data['publicKey'],
      isRemote: data['isRemote'] ?? false,
      host: data['host'],
    );
  }

  /// 转换为 Firestore 文档格式
  Map<String, dynamic> toFirestore() {
    return {
      'username': username,
      'displayName': displayName,
      'bio': bio,
      'avatarUrl': avatarUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'actorId': actorId,
      'publicKey': publicKey,
      'isRemote': isRemote,
      'host': host,
    };
  }

  /// 空用户 (用于占位)
  static final empty = AppUser(
      id: '',
      username: '',
      displayName: '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      actorId: '');

  @override
  List<Object?> get props => [
        id,
        username,
        displayName,
        bio,
        avatarUrl,
        createdAt,
        actorId,
        publicKey,
        isRemote,
        host
      ];
}

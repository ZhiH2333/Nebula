import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// 帖子数据模型
class Post extends Equatable {
  final String id; // 帖子 ID
  final String authorId; // 作者 ID
  final String content; // 内容
  final List<String> imageUrls; // 图片 URL 列表
  final DateTime createdAt; // 创建时间
  final int likeCount; // 点赞数
  final int replyCount; // 回复数

  // ActivityPub 相关
  final String? activityPubId; // ActivityPub 对象 ID

  // 联邦相关区分
  final bool isRemote; // 是否为远程帖子
  final String? host; // 来源实例域名 (本地为空)

  const Post({
    required this.id,
    required this.authorId,
    required this.content,
    this.imageUrls = const [],
    required this.createdAt,
    this.likeCount = 0,
    this.replyCount = 0,
    this.activityPubId,
    this.isRemote = false,
    this.host,
  });

  /// 从 Firestore 转换
  factory Post.fromFirestore(Map<String, dynamic> data, String id) {
    return Post(
      id: id,
      authorId: data['authorId'] ?? '',
      content: data['content'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      likeCount: data['likeCount'] ?? 0,
      replyCount: data['replyCount'] ?? 0,
      activityPubId: data['activityPubId'],
      isRemote: data['isRemote'] ?? false,
      host: data['host'],
    );
  }

  /// 转换为 Firestore 格式
  Map<String, dynamic> toFirestore() {
    return {
      'authorId': authorId,
      'content': content,
      'imageUrls': imageUrls,
      'createdAt': Timestamp.fromDate(createdAt),
      'likeCount': likeCount,
      'replyCount': replyCount,
      'activityPubId': activityPubId,
      'isRemote': isRemote,
      'host': host,
    };
  }

  /// 转换为 ActivityPub Note 格式 (预留)
  Map<String, dynamic> toActivityPub(String actorUrl) {
    return {
      '@context': 'https://www.w3.org/ns/activitystreams',
      'type': 'Note',
      'id': activityPubId ?? 'https://TODO-domain/posts/$id',
      'attributedTo': actorUrl,
      'content': content,
      'published': createdAt.toIso8601String(),
      'to': ['https://www.w3.org/ns/activitystreams#Public'],
    };
  }

  @override
  List<Object?> get props => [
        id,
        authorId,
        content,
        imageUrls,
        createdAt,
        likeCount,
        replyCount,
        activityPubId,
        isRemote,
        host
      ];
}

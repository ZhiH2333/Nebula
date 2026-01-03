import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String title;
  final String body;
  final String author;
  final String authorId; // 新增：用户 ID，用于权限控制
  final String? actorHandle; // 新增：发布时所用的 actor handle
  final Map<String, dynamic>? actor; // 可选：actor 的元数据
  final DateTime createdAt;
  final bool isRemote;
  final String? source;

  const Post({
    required this.id,
    required this.title,
    required this.body,
    required this.author,
    required this.authorId,
    required this.createdAt,
    this.actorHandle,
    this.actor,
    this.isRemote = false,
    this.source,
  });

  factory Post.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Post(
      id: doc.id,
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      author: data['author'] as String? ?? '',
      authorId: data['authorId'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      actorHandle: data['actorHandle'] as String?,
      actor: (data['actor'] as Map<String, dynamic>?)?.cast<String, dynamic>(),
      isRemote: data['isRemote'] as bool? ?? false,
      source: data['source'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'body': body,
      'author': author,
      'authorId': authorId,
      'actorHandle': actorHandle,
      'actor': actor,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRemote': isRemote,
      'source': source,
    };
  }
}

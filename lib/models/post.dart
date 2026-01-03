import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String title;
  final String body;
  final String author;
  final DateTime createdAt;

  const Post({
    required this.id,
    required this.title,
    required this.body,
    required this.author,
    required this.createdAt,
  });

  factory Post.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Post(
      id: doc.id,
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      author: data['author'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}

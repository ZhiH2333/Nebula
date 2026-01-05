import 'package:cloud_firestore/cloud_firestore.dart';

class PostService {
  Future<void> createPost({
    required String title,
    required String body,
    required String authorId,
    required String authorName,
  }) async {
    await FirebaseFirestore.instance.collection('posts').add({
      'title': title,
      'body': body,
      'authorId': authorId,
      'authorName': authorName,
      'createdAt': Timestamp.now(),
    });
  }
}

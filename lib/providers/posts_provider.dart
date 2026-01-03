import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post.dart';

final postsProvider = FutureProvider<List<Post>>((ref) async {
  final snapshot = await FirebaseFirestore.instance.collection('posts').get();
  return snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
});

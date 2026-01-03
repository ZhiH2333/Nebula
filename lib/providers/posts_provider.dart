import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post.dart';
import '../data/mock_posts.dart';

final postsProvider = FutureProvider<List<Post>>((ref) async {
  await Future.delayed(const Duration(seconds: 2));
  return mockPosts;
});

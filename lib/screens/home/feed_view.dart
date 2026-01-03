import 'package:flutter/material.dart';
import '../../../models/post.dart';
import 'widgets/post_card.dart';

class FeedView extends StatelessWidget {
  final List<Post> posts;

  const FeedView({
    super.key,
    required this.posts,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: posts.length,
      itemBuilder: (context, index) {
        return PostCard(post: posts[index]);
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/posts_provider.dart';
import 'feed_view.dart';
import '../post/create_post_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(postsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nebula'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Create Post',
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CreatePostScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: postsAsync.when(
        data: (posts) => FeedView(posts: posts),
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) {
          debugPrint('Feed Error: $error');
          debugPrint('Stack: $stack');
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SelectableText(
                'Error loading feed:\n$error',
                textAlign: TextAlign.center,
              ),
            ),
          );
        },
      ),
    );
  }
}

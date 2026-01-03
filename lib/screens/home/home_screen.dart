import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/posts_provider.dart';
import 'feed_view.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(postsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nebula'),
        centerTitle: true,
      ),
      body: postsAsync.when(
        data: (posts) => FeedView(posts: posts),
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) {
          debugPrint('Feed Error: $error');
          debugPrint(stack.toString());
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SelectableText(
                'Error: $error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        },
      ),
    );
  }
}

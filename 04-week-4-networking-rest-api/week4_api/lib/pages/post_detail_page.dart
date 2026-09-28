import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/providers.dart';
import '../data/network_errors.dart';

class PostDetailPage extends ConsumerWidget {
  const PostDetailPage({required this.postId, super.key});

  final int postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(postListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Post')),
      body: postsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text(friendlyErrorMessage(err)),
        ),
        data: (posts) {
          final post = posts.firstWhere(
            (p) => p.id == postId,
            orElse: () => throw Exception('Post tidak ditemukan'),
          );
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Text(post.body, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          );
        },
      ),
    );
  }
}
import 'api_client.dart';
import 'repositories/note_repository.dart';

/// Cache-first: baca cache dulu, refresh di background
Future<List<Map<String, dynamic>>> loadPostsCacheFirst() async {
  final repo = NoteRepository();
  final cached = await repo.readCachedPosts();
  refreshPostsInBackground();
  return cached;
}

Future<void> refreshPostsInBackground() async {
  try {
    final dio = createDio();
    final repo = NoteRepository();
    final response = await dio.get<List>('/posts');
    final data = response.data ?? [];
    final posts = data.whereType<Map<String, dynamic>>().toList();
    await repo.savePostsToCache(posts);
  } catch (e) {
    // Offline: diamkan saja
  }
}

/// Simulasi sync catatan dirty
Future<int> syncNotes(NoteRepository repo) async {
  final dirtyCount = await repo.countDirty();
  if (dirtyCount == 0) return 0;
  await Future.delayed(const Duration(seconds: 1));
  await repo.markAllSynced();
  return dirtyCount;
}
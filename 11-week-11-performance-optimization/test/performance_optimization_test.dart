import 'package:flutter_test/flutter_test.dart';
import 'package:campus_performance_optimization/data/optimized_repository.dart';

void main() {
  group('OptimizedNoteRepository SWR & Pagination Tests', () {
    late OptimizedNoteRepository repository;

    setUp(() {
      repository = OptimizedNoteRepository(cacheTtl: const Duration(minutes: 5));
    });

    test('getNotesPaginated mengambil data halaman 1 dengan limit pageSize', () async {
      final page1 = await repository.getNotesPaginated(page: 1, pageSize: 20);

      expect(page1.length, equals(20));
      expect(page1.first.id, equals('note_1'));
      expect(page1.last.id, equals('note_20'));
      expect(repository.networkRequests, equals(1));
      expect(repository.cacheHits, equals(0));
    });

    test('getNotesPaginated memanfaatkan SWR cache pada panggilan kedua', () async {
      // Panggilan pertama (cache miss -> network/db fetch)
      await repository.getNotesPaginated(page: 1, pageSize: 20);
      expect(repository.networkRequests, equals(1));

      // Panggilan kedua (cache hit -> langsung dari memori tanpa network request)
      final cachedPage = await repository.getNotesPaginated(page: 1, pageSize: 20);

      expect(cachedPage.length, equals(20));
      expect(repository.networkRequests, equals(1)); // Tetap 1, tidak bertambah!
      expect(repository.cacheHits, equals(1));       // Cache hit bertambah!
    });

    test('getNotesPaginated halaman ke-2 mengembalikan data offset berikutnya', () async {
      await repository.getNotesPaginated(page: 1, pageSize: 20);
      final page2 = await repository.getNotesPaginated(page: 2, pageSize: 20);

      expect(page2.length, equals(20));
      expect(page2.first.id, equals('note_21'));
      expect(page2.last.id, equals('note_40'));
    });

    test('forceRefresh mengabaikan cache dan memperbarui data', () async {
      await repository.getNotesPaginated(page: 1, pageSize: 20);
      expect(repository.networkRequests, equals(1));

      // Force refresh dipanggil (pull-to-refresh)
      await repository.getNotesPaginated(page: 1, pageSize: 20, forceRefresh: true);
      expect(repository.networkRequests, equals(2)); // Bertambah karena bypass cache
    });

    test('togglePin memperbarui status pin tanpa error', () async {
      await repository.getNotesPaginated(page: 1, pageSize: 20);
      repository.togglePin('note_1');

      final page = await repository.getNotesPaginated(page: 1, pageSize: 20);
      final note1 = page.firstWhere((n) => n.id == 'note_1');

      // note_1 awalnya isPinned=true, setelah di-toggle harus jadi false
      expect(note1.isPinned, isFalse);
    });
  });
}

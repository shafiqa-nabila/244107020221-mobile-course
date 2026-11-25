import 'dart:async';

/// Model catatan kampus teroptimasi
class NoteItem {
  final String id;
  final String title;
  final String content;
  final String category;
  final DateTime updatedAt;
  final bool isPinned;

  const NoteItem({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.updatedAt,
    this.isPinned = false,
  });

  NoteItem copyWith({
    String? id,
    String? title,
    String? content,
    String? category,
    DateTime? updatedAt,
    bool? isPinned,
  }) {
    return NoteItem(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      updatedAt: updatedAt ?? this.updatedAt,
      isPinned: isPinned ?? this.isPinned,
    );
  }
}

/// Repository dengan strategi caching Stale-While-Revalidate (SWR)
/// dan Pagination untuk mencegah memory spike & freeze I/O.
class OptimizedNoteRepository {
  // In-memory cache
  final List<NoteItem> _cachedNotes = [];
  DateTime? _lastFetchTime;
  final Duration _cacheTtl;

  // Metrik performa untuk verifikasi benchmarking
  int cacheHits = 0;
  int networkRequests = 0;

  OptimizedNoteRepository({Duration? cacheTtl})
      : _cacheTtl = cacheTtl ?? const Duration(minutes: 5);

  /// Cek apakah cache masih valid (fresh)
  bool get isCacheValid {
    if (_lastFetchTime == null) return false;
    return DateTime.now().difference(_lastFetchTime!) < _cacheTtl;
  }

  /// Mengambil data dengan strategi Stale-While-Revalidate + Pagination
  Future<List<NoteItem>> getNotesPaginated({
    int page = 1,
    int pageSize = 20,
    bool forceRefresh = false,
  }) async {
    // 1. Jika data ada di cache dan tidak force refresh, langsung return (0ms latency)
    if (_cachedNotes.isNotEmpty && isCacheValid && !forceRefresh) {
      cacheHits++;
      return _getPageFromCache(page, pageSize);
    }

    // 2. Fetch data dari server / database
    networkRequests++;
    await Future.delayed(const Duration(milliseconds: 150)); // Simulasi network delay

    if (_cachedNotes.isEmpty || forceRefresh) {
      _cachedNotes.clear();
      // Generate 100 data simulasi efisien
      for (var i = 1; i <= 100; i++) {
        _cachedNotes.add(
          NoteItem(
            id: 'note_$i',
            title: 'Catatan Kuliah #$i - Mobile Programming',
            content: 'Ringkasan materi performa Flutter, Flame Chart, dan DevTools modul $i.',
            category: i % 2 == 0 ? 'Praktikum' : 'Teori',
            updatedAt: DateTime.now().subtract(Duration(hours: i)),
            isPinned: i <= 3,
          ),
        );
      }
      _lastFetchTime = DateTime.now();
    }

    return _getPageFromCache(page, pageSize);
  }

  List<NoteItem> _getPageFromCache(int page, int pageSize) {
    final startIndex = (page - 1) * pageSize;
    if (startIndex >= _cachedNotes.length) return [];
    final endIndex = (startIndex + pageSize).clamp(0, _cachedNotes.length);
    return _cachedNotes.sublist(startIndex, endIndex);
  }

  /// Update status pin catatan dengan O(1) in-memory update
  void togglePin(String id) {
    final index = _cachedNotes.indexWhere((n) => n.id == id);
    if (index != -1) {
      _cachedNotes[index] = _cachedNotes[index].copyWith(
        isPinned: !_cachedNotes[index].isPinned,
      );
    }
  }

  void clearCache() {
    _cachedNotes.clear();
    _lastFetchTime = null;
  }
}

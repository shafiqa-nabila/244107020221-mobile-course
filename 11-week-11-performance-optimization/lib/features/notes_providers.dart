import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/optimized_repository.dart';

/// State immutable untuk daftar catatan kampus teroptimasi
class NotesState {
  final List<NoteItem> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final String selectedCategory;

  const NotesState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.selectedCategory = 'Semua',
  });

  NotesState copyWith({
    List<NoteItem>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    String? selectedCategory,
  }) {
    return NotesState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      selectedCategory: selectedCategory ?? this.selectedCategory,
    );
  }
}

/// Provider singleton untuk repository
final noteRepositoryProvider = Provider<OptimizedNoteRepository>((ref) {
  return OptimizedNoteRepository();
});

/// Notifier utama untuk mengelola list catatan secara teroptimasi
class NotesNotifier extends Notifier<NotesState> {
  late final OptimizedNoteRepository _repo;

  @override
  NotesState build() {
    _repo = ref.watch(noteRepositoryProvider);
    // Muat data awal secara asinkron
    Future.microtask(() => loadInitial());
    return const NotesState(isLoading: true);
  }

  Future<void> loadInitial({bool forceRefresh = false}) async {
    state = state.copyWith(isLoading: true);
    final notes = await _repo.getNotesPaginated(
      page: 1,
      pageSize: 20,
      forceRefresh: forceRefresh,
    );
    state = state.copyWith(
      items: notes,
      isLoading: false,
      currentPage: 1,
      hasMore: notes.length >= 20,
    );
  }

  /// Pagination infinite scroll: hanya memuat chunk berikutnya
  Future<void> loadNextPage() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);
    final nextPage = state.currentPage + 1;
    final nextNotes = await _repo.getNotesPaginated(
      page: nextPage,
      pageSize: 20,
    );

    if (nextNotes.isEmpty) {
      state = state.copyWith(isLoadingMore: false, hasMore: false);
    } else {
      state = state.copyWith(
        items: [...state.items, ...nextNotes],
        currentPage: nextPage,
        isLoadingMore: false,
        hasMore: nextNotes.length >= 20,
      );
    }
  }

  void togglePin(String id) {
    _repo.togglePin(id);
    state = state.copyWith(
      items: state.items.map((note) {
        if (note.id == id) {
          return note.copyWith(isPinned: !note.isPinned);
        }
        return note;
      }).toList(),
    );
  }

  void setCategory(String category) {
    state = state.copyWith(selectedCategory: category);
  }
}

final notesStateProvider =
    NotifierProvider<NotesNotifier, NotesState>(NotesNotifier.new);

// =========================================================================
// OPTIMASI: Provider Granular dengan Riverpod .select()
// Mencegah widget me-rebuild bila bagian state lain yang berubah.
// =========================================================================

/// Hanya me-rebuild widget counter saat jumlah item total berubah
final notesTotalCountProvider = Provider<int>((ref) {
  return ref.watch(notesStateProvider.select((s) => s.items.length));
});

/// Hanya me-rebuild widget header saat jumlah catatan di-pin berubah
final pinnedCountProvider = Provider<int>((ref) {
  return ref.watch(
    notesStateProvider.select(
      (s) => s.items.where((n) => n.isPinned).length,
    ),
  );
});

/// Hanya me-rebuild indikator footer pagination saat status hasMore berubah
final hasMorePaginationProvider = Provider<bool>((ref) {
  return ref.watch(notesStateProvider.select((s) => s.hasMore));
});

/// Hanya me-rebuild indikator saat loading state berubah
final isInitialLoadingProvider = Provider<bool>((ref) {
  return ref.watch(notesStateProvider.select((s) => s.isLoading));
});

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/optimized_repository.dart';
import 'notes_providers.dart';

class OptimizedNotesPage extends ConsumerStatefulWidget {
  const OptimizedNotesPage({super.key});

  @override
  ConsumerState<OptimizedNotesPage> createState() => _OptimizedNotesPageState();
}

class _OptimizedNotesPageState extends ConsumerState<OptimizedNotesPage> {
  // Controller diinisialisasi dan wajib di-dispose untuk mencegah memory leak
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    // PEMBERSIHAN MEMORI: Lepas listener dan buang controller
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Infinite scroll trigger saat mendekati 200px dari dasar list
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(notesStateProvider.notifier).loadNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(isInitialLoadingProvider);
    final notes = ref.watch(notesStateProvider.select((s) => s.items));
    final hasMore = ref.watch(hasMorePaginationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Optimized Campus Notes', style: TextStyle(fontSize: 18)),
            Text(
              'ListView.builder + RepaintBoundary + SWR Cache',
              style: TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: const [
          // Widget terisolasi yang hanya mengamati counter total (Riverpod .select)
          _OptimizedTotalCounterBadge(),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref
              .read(notesStateProvider.notifier)
              .loadInitial(forceRefresh: true);
        },
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Widget header metrik terisolasi
                  const _HeaderMetricsCard(),

                  // List teroptimasi
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      // OPTIMASI: itemExtent menetapkan tinggi pasti (88px)
                      // Menghindari kalkulasi layout berulang saat scroll cepat (O(1) layout time)
                      itemExtent: 88.0,
                      itemCount: notes.length + (hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == notes.length) {
                          return const _LoadingMoreTile();
                        }
                        final note = notes[index];
                        // OPTIMASI: Bungkus dalam RepaintBoundary agar repaint
                        // pada satu item tidak memicu repaint seluruh layer viewport list
                        return RepaintBoundary(
                          key: ValueKey(note.id),
                          child: _OptimizedNoteCard(
                            note: note,
                            onPinToggle: () {
                              ref
                                  .read(notesStateProvider.notifier)
                                  .togglePin(note.id);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// OPTIMASI EKSTRAK WIDGET: Badge counter terisolasi di AppBar
/// Hanya rebuild jika jumlah item berubah, tidak me-rebuild seluruh AppBar
class _OptimizedTotalCounterBadge extends ConsumerWidget {
  const _OptimizedTotalCounterBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(notesTotalCountProvider);
    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count Catatan',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

/// OPTIMASI EKSTRAK WIDGET: Header statistik performa
class _HeaderMetricsCard extends ConsumerWidget {
  const _HeaderMetricsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinnedCount = ref.watch(pinnedCountProvider);

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          const _MetricItem(label: 'Target FPS', value: '60 FPS'),
          _MetricItem(label: 'Dipin', value: '$pinnedCount'),
          const _MetricItem(label: 'Cache Policy', value: 'SWR 5m'),
        ],
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final String label;
  final String value;

  const _MetricItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
      ],
    );
  }
}

/// OPTIMASI EKSTRAK WIDGET & CONST CONSTRUCTOR: Item kartu catatan
class _OptimizedNoteCard extends StatelessWidget {
  final NoteItem note;
  final VoidCallback onPinToggle;

  const _OptimizedNoteCard({
    required this.note,
    required this.onPinToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: note.category == 'Praktikum'
              ? Colors.teal.shade100
              : Colors.indigo.shade100,
          child: Icon(
            note.category == 'Praktikum' ? Icons.code : Icons.menu_book,
            color: note.category == 'Praktikum'
                ? Colors.teal.shade800
                : Colors.indigo.shade800,
            size: 20,
          ),
        ),
        title: Text(
          note.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          note.content,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12),
        ),
        trailing: IconButton(
          icon: Icon(
            note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
            color: note.isPinned ? Colors.amber.shade800 : Colors.grey,
            size: 20,
          ),
          onPressed: onPinToggle,
        ),
      ),
    );
  }
}

/// OPTIMASI: Indikator loading footer untuk pagination
class _LoadingMoreTile extends StatelessWidget {
  const _LoadingMoreTile();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

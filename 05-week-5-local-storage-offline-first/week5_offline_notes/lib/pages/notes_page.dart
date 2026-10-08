import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local/note.dart';
import '../data/repositories/note_repository.dart';

final noteRepositoryProvider =
    Provider<NoteRepository>((ref) => NoteRepository());

final notesProvider = FutureProvider<List<Note>>((ref) async {
  return ref.watch(noteRepositoryProvider).fetchNotes();
});

final dirtyCountProvider = FutureProvider<int>((ref) async {
  return ref.watch(noteRepositoryProvider).countDirty();
});

class NotesPage extends ConsumerWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesProvider);
    final dirtyAsync = ref.watch(dirtyCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan Offline'),
        actions: [
          dirtyAsync.when(
            loading: () => const SizedBox(),
            error: (_, _) => const SizedBox(),
            data: (count) => count > 0
                ? Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Chip(
                      avatar: const Icon(Icons.cloud_off, size: 18),
                      label: Text('$count'),
                    ),
                  )
                : const SizedBox(),
          ),
        ],
      ),
      body: notesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (notes) {
          if (notes.isEmpty) {
            return const Center(child: Text('Belum ada catatan'));
          }
          return ListView.builder(
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return ListTile(
                leading: CircleAvatar(
                  child: note.dirty
                      ? const Icon(Icons.cloud_off)
                      : const Icon(Icons.cloud_done),
                ),
                title: Text(note.title),
                subtitle: Text(
                  note.body.isEmpty ? '(tanpa isi)' : note.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    if (note.id != null) {
                      await ref
                          .read(noteRepositoryProvider)
                          .deleteNote(note.id!);
                      ref.invalidate(notesProvider);
                      ref.invalidate(dirtyCountProvider);
                    }
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Catatan Baru'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Judul'),
              autofocus: true,
            ),
            TextField(
              controller: bodyController,
              decoration: const InputDecoration(labelText: 'Isi'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              if (titleController.text.trim().isNotEmpty) {
                await ref.read(noteRepositoryProvider).addNote(
                      title: titleController.text.trim(),
                      body: bodyController.text.trim(),
                    );
                ref.invalidate(notesProvider);
                ref.invalidate(dirtyCountProvider);
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}
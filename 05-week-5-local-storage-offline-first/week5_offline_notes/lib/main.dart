import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local/note.dart';
import '../data/providers.dart';
import '../data/sync.dart';
import '../widgets/note_tile.dart';

class NotesPage extends ConsumerStatefulWidget {
  const NotesPage({super.key});

  @override
  ConsumerState<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends ConsumerState<NotesPage> {
  List<Note> _notes = [];
  bool _loading = true;
  int _dirtyCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    setState(() => _loading = true);
    final repo = ref.read(noteRepositoryProvider);
    final notes = await repo.fetchNotes();
    final dirty = await repo.countDirty();
    setState(() {
      _notes = notes;
      _dirtyCount = dirty;
      _loading = false;
    });
  }

  Future<void> _addNote() async {
    await ref
        .read(noteRepositoryProvider)
        .addNote(title: 'Catatan ${_notes.length + 1}');
    _loadNotes();
  }

  Future<void> _deleteNote(int id) async {
    await ref.read(noteRepositoryProvider).deleteNote(id);
    _loadNotes();
  }

  Future<void> _syncNotes() async {
    final repo = ref.read(noteRepositoryProvider);
    final synced = await syncNotes(repo);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$synced catatan berhasil disinkron')),
      );
    }
    _loadNotes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan Offline'),
        actions: [
          if (_dirtyCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                avatar: const Icon(Icons.cloud_off, size: 18),
                label: Text('$_dirtyCount'),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: _syncNotes,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notes.isEmpty
              ? const Center(child: Text('Belum ada catatan'))
              : ListView.builder(
                  itemCount: _notes.length,
                  itemBuilder: (context, index) {
                    final note = _notes[index];
                    return NoteTile(
                      note: note,
                      onDelete: () {
                        if (note.id != null) _deleteNote(note.id!);
                      },
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNote,
        child: const Icon(Icons.add),
      ),
    );
  }
}
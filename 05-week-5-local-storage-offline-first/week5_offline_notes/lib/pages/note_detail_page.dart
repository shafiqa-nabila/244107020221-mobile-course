import 'package:flutter/material.dart';
import '../data/local/note.dart';
import '../data/repositories/note_repository.dart';

class NoteDetailPage extends StatefulWidget {
  const NoteDetailPage({required this.noteId, super.key});

  final int noteId;

  @override
  State<NoteDetailPage> createState() => _NoteDetailPageState();
}

class _NoteDetailPageState extends State<NoteDetailPage> {
  Note? _note;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNote();
  }

  Future<void> _loadNote() async {
    final repo = NoteRepository();
    final notes = await repo.fetchNotes();
    final note = notes.firstWhere(
      (n) => n.id == widget.noteId,
      orElse: () => throw Exception('Catatan tidak ditemukan'),
    );
    setState(() {
      _note = note;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_note == null) {
      return const Scaffold(
        body: Center(child: Text('Catatan tidak ditemukan')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Catatan'),
        actions: [
          Icon(
            _note!.dirty ? Icons.cloud_off : Icons.cloud_done,
            color: _note!.dirty ? Colors.orange : Colors.green,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _note!.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Diperbarui: ${_note!.updatedAt.toLocal()}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Divider(height: 24),
            Text(_note!.body.isEmpty ? '(tanpa isi)' : _note!.body),
          ],
        ),
      ),
    );
  }
}
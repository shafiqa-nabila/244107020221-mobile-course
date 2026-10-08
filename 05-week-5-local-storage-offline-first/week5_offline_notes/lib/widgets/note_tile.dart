import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/local/note.dart';

class NoteTile extends StatelessWidget {
  const NoteTile({
    required this.note,
    required this.onDelete,
    super.key,
  });

  final Note note;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        note.dirty ? Icons.cloud_off : Icons.cloud_done,
        color: note.dirty ? Colors.orange : Colors.green,
      ),
      title: Text(note.title),
      subtitle: Text(
        note.body.isEmpty ? '(tanpa isi)' : note.body,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete),
        onPressed: onDelete,
      ),
      onTap: () => context.push('/note/${note.id}'),
    );
  }
}
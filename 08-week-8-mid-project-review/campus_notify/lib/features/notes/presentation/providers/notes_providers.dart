import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/local/db.dart';
import '../../data/repositories/note_repository_impl.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';
import '../../domain/usecases/add_note.dart';
import '../../domain/usecases/get_notes.dart';

// Data layer
final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return NoteRepositoryImpl(openDb: openNotesDb);
});

// Domain layer
final getNotesProvider = Provider<GetNotes>((ref) {
  return GetNotes(ref.watch(noteRepositoryProvider));
});

final addNoteProvider = Provider<AddNote>((ref) {
  return AddNote(ref.watch(noteRepositoryProvider));
});

// Presentation layer
final notesProvider = FutureProvider<List<Note>>((ref) async {
  final result = await ref.watch(getNotesProvider).call();
  if (result.failure != null) {
    throw result.failure!;     
  }
  return result.notes;
});

final dirtyCountProvider = FutureProvider<int>((ref) async {
  final notes = await ref.watch(notesProvider.future);
  return notes.where((n) => n.dirty).length;
});
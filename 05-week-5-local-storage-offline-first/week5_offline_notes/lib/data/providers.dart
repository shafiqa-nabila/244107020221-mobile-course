import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';
import 'local/note.dart';
import 'repositories/note_repository.dart';

final dioProvider = Provider<Dio>((ref) => createDio());
final noteRepositoryProvider =
    Provider<NoteRepository>((ref) => NoteRepository());

final notesProvider = FutureProvider<List<Note>>((ref) async {
  return ref.watch(noteRepositoryProvider).fetchNotes();
});
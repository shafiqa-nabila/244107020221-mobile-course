import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/notes/presentation/pages/notes_page.dart';

void main() => runApp(const ProviderScope(child: MyApp()));

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Week 7 - Clean Architecture',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const NotesPage(),
    );
  }
}
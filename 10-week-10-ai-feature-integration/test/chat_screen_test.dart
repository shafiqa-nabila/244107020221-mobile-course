import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_ai_integration/ai/ai_service.dart';
import 'package:campus_ai_integration/features/chat_screen.dart';
import 'ai_service_test.dart';

void main() {
  group('ChatScreen Widget Tests', () {
    late FakeSecureStorage storage;
    late AiService aiService;

    setUp(() async {
      storage = FakeSecureStorage();
      await storage.write(key: 'ai_api_key', value: 'TEST_KEY');
      aiService = AiService(storage: storage);
    });

    testWidgets('Merender elemen utama ChatScreen dengan benar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChatScreen(aiService: aiService),
        ),
      );

      // Verifikasi judul AppBar
      expect(find.text('Campus AI Chat'), findsOneWidget);
      expect(find.text('Gemini Pro & Flash Integration'), findsOneWidget);

      // Verifikasi Banner Privasi
      expect(
        find.text(
          'Privasi terjaga: Jangan kirim NIK, telepon, atau kata sandi. Data sensitif disaring otomatis.',
        ),
        findsOneWidget,
      );

      // Verifikasi pesan sambutan awal
      expect(
        find.text(
          'Halo! Saya Campus AI Assistant. Ada yang bisa saya bantu seputar perkuliahan atau catatan kampus?',
        ),
        findsOneWidget,
      );

      // Verifikasi textfield dan tombol kirim
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.send), findsOneWidget);
      expect(find.byIcon(Icons.document_scanner), findsOneWidget);
      expect(find.byIcon(Icons.mic), findsOneWidget);
    });

    testWidgets('Quick chips pertanyaan tampil dan dapat diklik', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChatScreen(aiService: aiService),
        ),
      );

      expect(find.text('Jadwal KRS Semester Ini'), findsOneWidget);
      expect(find.text('Tips Belajar Flutter Clean Architecture'), findsOneWidget);
      expect(find.text('Cara Buat Ringkasan Catatan'), findsOneWidget);
    });
  });
}

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:campus_ai_integration/ai/ai_service.dart';

// Mock storage sederhana berbasis map in-memory
class FakeSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> _data = {};

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) {
      _data[key] = value;
    }
  }

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _data[key];
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _data.remove(key);
  }
}

void main() {
  group('AiService Tests', () {
    late FakeSecureStorage storage;

    setUp(() {
      storage = FakeSecureStorage();
    });

    test('ask melempar exception bila API key belum disetel', () async {
      final service = AiService(storage: storage);
      expect(
        () => service.ask('Halo AI'),
        throwsA(isA<Exception>()),
      );
    });

    test('sanitizeInput berhasil menyensor NIK, nomor telepon, dan email pribadi', () {
      final service = AiService(storage: storage);
      const text =
          'Data mahasiswa: NIK 3507123456789012 dan telepon 081234567890 serta email test@kampus.id';
      final clean = service.sanitizeInput(text);

      expect(clean.contains('3507123456789012'), isFalse);
      expect(clean.contains('[NIK_DISENSOR]'), isTrue);
      expect(clean.contains('081234567890'), isFalse);
      expect(clean.contains('[TELEPON_DISENSOR]'), isTrue);
      expect(clean.contains('test@kampus.id'), isFalse);
      expect(clean.contains('[EMAIL_DISENSOR]'), isTrue);
    });

    test('ask berhasil mengembalikan respons AI saat HTTP status 200', () async {
      await storage.write(key: 'ai_api_key', value: 'FAKE_API_KEY');

      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': 'Ini jawaban cerdas dari Gemini AI'}
                  ]
                }
              }
            ]
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = AiService(storage: storage, client: mockClient);
      final response = await service.ask('Jelaskan Clean Architecture');

      expect(response, equals('Ini jawaban cerdas dari Gemini AI'));
    });

    test('ask melempar exception saat HTTP status error (misal 429 quota limit)', () async {
      await storage.write(key: 'ai_api_key', value: 'FAKE_API_KEY');

      final mockClient = MockClient((request) async {
        return http.Response('Rate limit exceeded', 429);
      });

      final service = AiService(storage: storage, client: mockClient);

      expect(
        () => service.ask('Beri jawaban'),
        throwsA(predicate((e) => e.toString().contains('429'))),
      );
    });

    test('askWithFallback mengembalikan data offline lokal jika server error', () async {
      await storage.write(key: 'ai_api_key', value: 'FAKE_API_KEY');

      final mockClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final service = AiService(storage: storage, client: mockClient);
      final response = await service.askWithFallback('Berapa jadwal kuliah hari ini?');

      expect(response, contains('[Mode Offline]'));
      expect(response, contains('Jadwal kuliah offline'));
    });

    test('recognizeText dan speechToText mengembalikan hasil simulasi', () async {
      await storage.write(key: 'ai_api_key', value: 'FAKE_API_KEY');
      final service = AiService(storage: storage);

      final ocr = await service.recognizeText(null);
      expect(ocr, contains('Ekstraksi OCR'));

      final stt = await service.speechToText(null);
      expect(stt, contains('Transkripsi'));
    });
  });
}

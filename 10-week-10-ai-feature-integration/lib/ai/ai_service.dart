import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

/// Layanan AI menggunakan Google Gemini API via REST
class AiService {
  final FlutterSecureStorage _storage;
  final http.Client _client;
  final String _apiUrl;

  // In-memory cache untuk menghemat biaya dan kuota request
  final Map<String, String> _cache = {};

  AiService({
    FlutterSecureStorage? storage,
    http.Client? client,
    String? apiUrl,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _client = client ?? http.Client(),
        _apiUrl = apiUrl ??
            'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  /// Menyimpan API Key ke storage aman
  Future<void> saveApiKey(String key) async {
    await _storage.write(key: 'ai_api_key', value: key.trim());
  }

  /// Membaca API Key yang tersimpan
  Future<String?> getApiKey() async {
    return await _storage.read(key: 'ai_api_key');
  }

  /// Menghapus API Key (untuk logout atau reset)
  Future<void> clearApiKey() async {
    await _storage.delete(key: 'ai_api_key');
  }

  /// Sanitasi data sensitif sebelum dikirim ke AI API (Proteksi Privasi Pengguna)
  String sanitizeInput(String input) {
    var sanitized = input;
    // Sensor NIK (16 digit nomor identitas kependudukan)
    sanitized = sanitized.replaceAll(RegExp(r'\b\d{16}\b'), '[NIK_DISENSOR]');
    // Sensor nomor telepon seluler Indonesia (08xx atau +628xx)
    sanitized = sanitized.replaceAll(
      RegExp(r'(\+62|62|0)8[1-9][0-9]{6,10}'),
      '[TELEPON_DISENSOR]',
    );
    // Sensor format email pribadi
    sanitized = sanitized.replaceAll(
      RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'),
      '[EMAIL_DISENSOR]',
    );
    return sanitized;
  }

  /// Mengirim pertanyaan ke Gemini API
  Future<String> ask(String question) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API key tidak tersedia. Silakan atur di pengaturan.');
    }

    // Sanitasi data privasi pengguna
    final safePrompt = sanitizeInput(question);

    // Cek cache lokal terlebih dahulu (Hemat Biaya & Kuota)
    if (_cache.containsKey(safePrompt)) {
      return _cache[safePrompt]!;
    }

    final response = await _client.post(
      Uri.parse('$_apiUrl?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': safePrompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 800,
        }
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final answer = data['candidates'][0]['content']['parts'][0]['text'] as String;
      // Simpan ke cache lokal
      _cache[safePrompt] = answer;
      return answer;
    } else if (response.statusCode == 400) {
      throw Exception('Permintaan tidak valid atau API Key salah (400).');
    } else if (response.statusCode == 429) {
      throw Exception('Batas kuota request terlampaui / Rate limit (429).');
    } else {
      throw Exception('Gagal memanggil AI API: HTTP ${response.statusCode}');
    }
  }

  /// Streaming respons simulasi/typing effect untuk UX mobile yang lebih responsif
  Stream<String> askStream(String question) async* {
    final fullAnswer = await ask(question);
    final words = fullAnswer.split(' ');
    var current = '';

    for (var i = 0; i < words.length; i++) {
      await Future.delayed(const Duration(milliseconds: 35));
      current += (i == 0 ? '' : ' ') + words[i];
      yield current;
    }
  }

  /// Panggilan dengan mekanisme Fallback cerdas saat jaringan offline / API error
  Future<String> askWithFallback(String question) async {
    try {
      return await ask(question);
    } catch (e) {
      // Fallback ke offline knowledge base
      final fallback = _getLocalOfflineFallback(question);
      if (fallback != null) {
        return '[Mode Offline]: $fallback';
      }
      rethrow;
    }
  }

  /// Basis pengetahuan lokal sederhana untuk mode offline / fallback
  String? _getLocalOfflineFallback(String query) {
    final lower = query.toLowerCase();
    if (lower.contains('jadwal') || lower.contains('kuliah')) {
      return 'Jadwal kuliah offline: Senin - Jumat pukul 07.30 - 16.00 WIB. Silakan cek SIAKAD untuk detail lengkap.';
    }
    if (lower.contains('krs') || lower.contains('semester')) {
      return 'Pengisian KRS semester ini dibuka pada tanggal 1-10 setiap awal semester melalui portal akademik.';
    }
    if (lower.contains('ruang') || lower.contains('kelas')) {
      return 'Informasi ruangan kelas dapat dilihat pada papan pengumuman lantai 1 gedung jurusan.';
    }
    return null;
  }

  /// Ekstraksi teks dari gambar (OCR - Optical Character Recognition)
  Future<String> recognizeText(dynamic imageFile) async {
    // Simulasi integrasi OCR dengan ekstraksi AI Vision
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API key tidak tersedia untuk OCR.');
    }
    // Simulasi hasil ekstraksi teks dokumen/KTM
    await Future.delayed(const Duration(milliseconds: 800));
    return 'Ekstraksi OCR: Nama Mahasiswa: Shafiqa Nabila | NIM: 244107020221 | Prodi: TI';
  }

  /// Konversi rekaman suara menjadi teks (Speech-to-Text)
  Future<String> speechToText(dynamic audioFile) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API key tidak tersedia untuk Speech-to-Text.');
    }
    // Simulasi hasil transkripsi audio
    await Future.delayed(const Duration(milliseconds: 600));
    return 'Transkripsi: Kapan batas akhir pengumpulan tugas besar pemrograman mobile?';
  }
}

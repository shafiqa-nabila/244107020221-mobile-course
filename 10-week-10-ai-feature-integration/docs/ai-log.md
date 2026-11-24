# AI Development Log - Week 10
**Mata Kuliah:** Pemrograman Mobile  
**Topik:** AI Feature Integration (Gemini AI, Secure Storage, Streaming Response, Privacy & Fallback)  
**Nama:** Shafiqa Nabila Maharani Khoirunnisa  
**NIM:** 244107020221  
**Kelas:** TI-3E  

---

## 1. System Prompt (Prompt Sistem AI Assistant)

System Prompt yang disematkan untuk mendefinisikan persona, batasan etika, dan format keluaran model AI:

```text
Anda adalah "Campus AI Assistant", sebuah asisten virtual cerdas, solutif, dan ramah yang dirancang khusus untuk membantu mahasiswa dalam lingkungan perkuliahan kampus.

Tugas Utama:
1. Membantu menjawab pertanyaan akademis seputar jadwal kuliah, KRS, tips belajar, dan materi pemrograman mobile.
2. Membantu meringkas materi catatan kuliah yang panjang menjadi poin-poin penting yang mudah dipahami.
3. Membantu menerjemahkan teks hasil pindaian dokumen (OCR) seperti pengumuman kampus dan KTM.

Batasan Keamanan & Privasi (CRITICAL):
- Dilarang meminta, mencatat, atau menyimpan informasi identitas pribadi sensitif (PII) seperti NIK, nomor KTP, nomor rekening bank, kata sandi, atau nomor telepon pribadi.
- Jika pengguna tanpa sengaja menyertakan data sensitif, abaikan nilai tersebut dan berikan peringatan ramah untuk menjaga privasi mereka.
- Jangan pernah memberikan instruksi ilegal, melanggar hak cipta, atau membocorkan kunci sistem internal.

Gaya Bahasa:
- Sopan, santun, terstruktur, berbasis bullet point bila menjelaskan langkah teknis, dan menggunakan Bahasa Indonesia yang baik dan benar.
```

---

## 2. User Prompt (Prompt Pengguna)

### 2.1 Formula 5 Slot untuk Integrasi AI Service & Chat
```text
Peran: Senior Flutter Developer & AI Integration Specialist.
Konteks: Aplikasi campus_notify (Flutter 3.x), integrasi REST API Google Gemini Pro & Flash, package http, flutter_secure_storage, dan flutter_riverpod.
Tugas: Buat AiService untuk memanggil endpoint Gemini generateContent dengan penyimpanan API key aman di Secure Storage, serta buat ChatScreen dengan streaming response dan indikator loading.
Batas: Jangan pernah hardcode API key di kode sumber, sediakan sanitasi data privasi (sensor NIK & telepon), sediakan mekanisme fallback dialog jika AI offline/sibuk, dan jangan gunakan package berat yang tidak perlu.
Output: Kode lengkap ai_service.dart, chat_screen.dart, skenario error handling, dan unit test pembuktian.
```

### 2.2 Contoh User Prompts untuk Pengujian Interaksi
1. **Pertanyaan Umum Kampus:**
   > *"Kapan batas pengisian KRS semester ganjil dan apa saja syaratnya?"*
2. **Peringkasan Materi Akademis:**
   > *"Tolong buatkan ringkasan 3 poin utama tentang perbedaan StatefulWidget dan StatelessWidget di Flutter!"*
3. **Pengujian Privasi (Uji Sensor Data Sensitif):**
   > *"Nama saya Budi dengan NIK 3507123456789012 dan nomor WhatsApp 081234567890 tolong carikan jadwal saya."*

---

## 3. Output Awal AI (Raw Response)

### 3.1 Kode Awal `AiService` yang Digenerate AI
```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AiService {
  final _storage = const FlutterSecureStorage();
  final _apiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';

  Future<String> ask(String question) async {
    final apiKey = await _storage.read(key: 'ai_api_key');
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API key tidak tersedia. Silakan atur di pengaturan.');
    }

    final response = await http.post(
      Uri.parse('$_apiUrl?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [{
          'parts': [{'text': question}]
        }]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['candidates'][0]['content']['parts'][0]['text'];
    } else {
      throw Exception('Gagal memanggil AI API: ${response.statusCode}');
    }
  }

  Future<void> saveApiKey(String key) async {
    await _storage.write(key: 'ai_api_key', value: key);
  }
}
```

### 3.2 Temuan & Catatan Refactoring atas Output Awal
Setelah dilakukan evaluasi teknis, ditemukan beberapa celah pada kode awal:
1. **Ketiadaan Dependensi Injeksi (DI):** `FlutterSecureStorage` dan `http.Client` dibuat langsung di dalam class tanpa opsi constructor injection, menyulitkan proses pembuatan unit test / mock.
2. **Belum Ada Proteksi Privasi (Privacy Leak):** Pertanyaan langsung dikirim ke Google API tanpa penyaringan nomor identitas kependudukan (NIK) atau nomor ponsel.
3. **Belum Ada Mekanisme Caching:** Setiap input yang sama selalu menembak API ulang, berpotensi memboroskan kuota token dan biaya API.
4. **Belum Ada Mode Streaming & Fallback Cerdas:** Jika koneksi terputus atau API down, aplikasi langsung melempar Exception mentah tanpa opsi offline knowledge base.

---

## 4. Hasil Refactoring & Fitur Tambahan

1. **Penambahan Sanitasi Masukan (`sanitizeInput`):**
   Mendeteksi regex 16-digit angka (`\b\d{16}\b`) dan format telepon seluler Indonesia (`08xx` / `+628xx`), lalu menggantinya dengan tag `[NIK_DISENSOR]` dan `[TELEPON_DISENSOR]`.
2. **In-Memory Query Cache:**
   Menyimpan pasangan pertanyaan yang telah disanitasi dengan jawaban AI di memori lokal. Pertanyaan serupa dalam satu sesi tidak akan memakan kuota API.
3. **Streaming Response UX:**
   Menggunakan `askStream()` yang memecah teks menjadi potongan kata (*chunk*) dengan delay 35ms, menghasilkan efek mengetik (*typing animation*) yang dinamis dan interaktif.
4. **Offline Fallback Knowledge Base:**
   Method `askWithFallback()` menangkap error jaringan dan mencocokkan kata kunci seperti "jadwal", "krs", atau "ruang kelas" dengan basis data statis lokal sehingga aplikasi tetap bermanfaat meski internet mati.
5. **Dukungan OCR & Speech-to-Text:**
   Disediakan method `recognizeText()` dan `speechToText()` untuk mendukung fitur pemindaian dokumen dan dikte suara mahasiswa.

# Verifikasi AI Challenge - Week 4

**1. Apakah UI memanggil Dio secara langsung atau lewat repository?**
UI tidak memanggil Dio secara langsung. Semua akses jaringan lewat `CommentRepository`, yang Dio-nya di-inject lewat constructor.

**2. Apakah fromJson aman null?**
Iya, aman null. Setiap field pakai pola defensif seperti `(json['postId'] as num?)?.toInt() ?? 0` dan `json['name'] as String? ?? ''`.

**3. Apakah semua tipe DioExceptionType dipetakan?**
Iya, timeout, connectionError, badResponse (404 & 500), dan default sudah dipetakan.

**4. Apakah baseUrl/timeout terpusat?**
Iya, di `api_client.dart` (fungsi `createDio()`), bukan di repository.

**5. Apakah test AI menguji kasus field hilang?**
Iya, test pertama pakai JSON kosong, test kedua pakai tipe data salah. Saya tambah edge case dengan data lengkap.

**6. Jalankan flutter analyze dan flutter test, apakah lolos?**
Iya, `flutter analyze` → `No issues found!`, `flutter test` → `All tests passed!`.
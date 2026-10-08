# AI Prompt Challenge - Week 4

## Prompt 1: Repository Layer untuk Comments

Buatkan repository layer Flutter untuk endpoint GET /comments?postId={id}
dari JSONPlaceholder menggunakan Dio + flutter_riverpod.

Requirements:
- Model Comment dengan fromJson aman null (postId, id, name, email, body).
- CommentRepository dengan method fetchComments(postId) + timeout 10 detik.
- AsyncNotifierProvider dengan penanganan error otomatis (AsyncError)
  dan fungsi pesan error ramah pengguna untuk timeout, connection error, 404, dan 500.
- Satu unit test untuk fromJson dengan field yang hilang.
Jelaskan setiap bagian kode dalam komentar.

## Prompt 2: Verifikasi
Periksa kembali kode repository layer di atas:

1. Apakah UI memanggil Dio secara langsung atau lewat repository?
2. Apakah fromJson aman null, atau masih memakai cast langsung yang bisa crash?
3. Apakah semua tipe DioExceptionType (timeout, connectionError, badResponse) dipetakan ke pesan pengguna?
4. Apakah baseUrl/timeout terpusat di satu client, bukan tersebar di tiap method?
5. Apakah test AI benar-benar menguji kasus field hilang, atau hanya happy path?
6. Apakah kode ini sudah lolos flutter analyze dan flutter test?

Jelaskan temuan Anda untuk setiap poin, dan tunjukkan bagian kode yang relevan.
## Jobsheet 6
*Nama:* Shafiqa Nabila Maharani Khoirunnisa
*NIM:* 244107020221
*Kelas:* TI-3E

## Langkah-langkah beserta bukti Screenshoot:
### LAPORAN PRAKTIKUM WEEK06

<details>
<summary><h3>JOBSHEET 6</h3></summary>

<blockquote>

### Langkah Praktikum :

## Praktikum 1: Login + secure storage + token refresh

Siapkan project
![Langkah](screenshot/1.png)
![Langkah](screenshot/2.png)
![Langkah](screenshot/3.png)

Struktur folder:
![Langkah](screenshot/4.png)

1. Penyimpanan token yang aman
Buat lib/data/token_store.dart. Seluruh token hanya keluar-masuk lewat kelas ini:
![Langkah](screenshot/5.png)


2. Repository auth (mock yang siap diganti Firebase Auth)
Buat lib/data/auth_repository.dart:
![Langkah](screenshot/6.png)

3. Dio dengan refresh otomatis
Buat lib/data/api_client.dart. Interceptor mencoba refresh satu kali saat menerima 401, lalu mengulang request:
![Langkah](screenshot/7.png)

4. Provider auth + guard route
Contoh lib/providers/auth_provider.dart dan pengaman GoRouter di main.dart:
![Langkah](screenshot/8.png)
![Langkah](screenshot/9.png)

## Praktikum 2: FCM, permission, dan token lifecycle

# 1. Daftarkan aplikasi ke Firebase
1. Buat project di Firebase Console, tambahkan aplikasi Android dengan package name sesuai applicationId Anda.
2. Unduh google-services.json ke android/app/ dan ikuti panduan FCM Flutter client (terapkan plugin google-services dan dependensi). Untuk iOS tambahkan GoogleService-Info.plist.
3. Pastikan firebase_core diinisialisasi sebelum runApp: await Firebase.initializeApp().
![Langkah](screenshot/10.png)
![Langkah](screenshot/11.png)
![Langkah](screenshot/12.png)
![Langkah](screenshot/13.png)
![Langkah](screenshot/14.png)
![Langkah](screenshot/15.png)
![Langkah](screenshot/16.jpeg)

# 2. Minta izin notifikasi
Android 13+ dan iOS wajib meminta izin runtime. Buat lib/messaging/push_service.dart:
![Langkah](screenshot/17.png)

# 3. Token lifecycle: ambil, kirim ke backend, pantau perubahan
![Langkah](screenshot/18.png)
![Langkah](screenshot/19.jpeg)

## Praktikum 3: Payload, tiga app state, klik dan topik
1. Background handler wajib top-level
Handler background harus fungsi top-level (bukan method kelas) karena berjalan di isolate terpisah:
![Langkah](screenshot/20.png)

2. Tiga handler + contoh payload gabungan
Payload yang dikirim backend (contoh JSON via FCM HTTP v1):
![Langkah](screenshot/21.png)

3. Matriks pengujian wajib
Uji ketiga state dengan payload yang sama dan isi tabel ini di README:
Foreground : 
![Langkah](screenshot/22.png)
![Langkah](screenshot/23.jpeg)

background :
![Langkah](screenshot/24.png)
![Langkah](screenshot/25.jpeg)

Terminated :
![Langkah](screenshot/26.png)
![Langkah](screenshot/27.jpeg)

## AI Challenge
OUTPUT DARI AI


# AI Verification Checklist

1. Apakah background handler berupa fungsi top-level dengan @pragma('vm:entry-point')? (tolak jika berupa method kelas).
- 
2. Apakah onTokenRefresh benar-benar mengirim token baru ke backend, bukan hanya dicetak ke log?
3. Apakah foreground memakai local notification manual? (tanpa ini banner tidak muncul saat aplikasi terbuka).
4. Apakah klik dari ketiga state (foreground/background/terminated) masuk ke rute yang benar? Buktikan dengan tabel pengujian.
5. Apakah token/secret tidak di-hardcode dan tidak di-log penuh? Perbaiki bila AI melanggarnya.
6. Keputusan final dan alasan teknis Anda, boleh berbeda dari saran AI selama berargumen.

## Refactoring, testing, dan error umum\

# Refactoring Challenge
1. Pindahkan semua string rute (/login, /pengumuman/:id) ke satu file lib/routes.dart agar deep link dari FCM dan GoRouter memakai konstanta yang sama.
![Langkah](screenshot/29.png)
![Langkah](screenshot/30.png)
![Langkah](screenshot/31.png)
![Langkah](screenshot/32.png)

2. Ekstrak parsing RemoteMessage -> route ke fungsi murni routeFromMessage(Map<String, dynamic> data) agar bisa diunit-test tanpa Firebase.
![Langkah](screenshot/33.png)
![Langkah](screenshot/34.png)

3. Pindahkan pemetaan DioException -> pesan ramah pengguna (401, timeout, offline) ke lib/data/api_errors.dart agar UI hanya menerima pesan, bukan exception mentah.
![Langkah](screenshot/35.png)
![Langkah](screenshot/36.png)
![Langkah](screenshot/37.png)
![Langkah](screenshot/38.png)
![Langkah](screenshot/39.png)

# Testing: unit test tanpa Firebase sungguhan
![Langkah](screenshot/40.png)
![Langkah](screenshot/41.png)

## Tugas, refleksi, dan referensi

# Mini project / Industry Challenge
Bangun Campus Notification App (kembangkan project codelab atau buat baru):

1. Login (mock/Firebase Auth) dengan guard route: belum login selalu diarahkan ke /login.
2. Token disimpan di secure storage; Dio otomatis refresh sekali saat 401 dan logout bila refresh mati.
3. FCM terintegrasi: permission, getToken + onTokenRefresh terkirim ke backend (atau didokumentasikan endpoint POST /devices), dan subscribe topik pengumuman-kampus.
4. Notifikasi gabungan notification + data; klik membuka /pengumuman/:id pada ketiga app state. Isi tabel pengujian foreground/background/terminated di README.
5. Screenshot bukti (token terpotong, banner tiap state, halaman tujuan deep link) di folder screenshots/.
6. Sertakan minimal 2 test yang lulus (parsing route + logika sesi/refresh).
7. Kerjakan AI Challenge dan dokumentasikan prompt, output awal AI, perbaikan manual, dan alasan teknis di docs/.
8. Push ke repository portfolio pada folder 06-week-6-authentication-security-fcm/ dengan struktur lib/, test/, docs/, README.md, dan screenshots/. README menjelaskan tujuan, fitur utama, stack teknologi, cara menjalankan, dan hasil yang dicapai.

# Refleksi
1. Mengapa refresh token tidak boleh disimpan di SharedPreferences? Apa risikonya bila bocor?
- Refresh token tidak boleh disimpan di SharedPreferences karena tidak terenkripsi — datanya cuma file XML biasa yang bisa dibaca kalau HP di-root atau di-backup. Kalau bocor, penyerang bisa membuat access token baru tanpa login ulang, karena refresh token berlaku lama. Akibatnya, data pribadi seperti nilai dan tagihan bisa diambil, dan korban tidak sadar akunnya disalahgunakan. Makanya, refresh token wajib disimpan di flutter_secure_storage yang terenkripsi.

2. Apa yang rusak bila onTokenRefresh diabaikan selama satu semester perkuliahan?
- Kalau onTokenRefresh diabaikan, backend akan terus menyimpan token basi. Padahal token FCM bisa berubah karena reinstall, clear data, atau restore. Akibatnya, notifikasi tidak sampai ke mahasiswa, dan pengumuman penting seperti jadwal ujian bisa terlewat. Tanpa listener ini, sistem notifikasi kampus rusak perlahan tapi pasti.

3. Kapan memakai topik dan kapan memakai token perangkat? Beri contoh pesan kampus untuk masing-masing.
- Topik dipakai untuk broadcast massal, misalnya pengumuman-kampus untuk semua mahasiswa, atau kelas-ti-3e untuk satu kelas. Contohnya: "Jadwal kuliah besok libur". Sedangkan token perangkat dipakai untuk pesan personal, seperti nilai ujian atau tagihan UKT. Contohnya: "Nilai UAS Anda sudah keluar". Kalau pakai topik untuk pesan personal, semua orang yang subscribe akan menerima pesan orang lain — itu pelanggaran privasi.

4. Bagian mana dari draf AI yang Anda tolak atau perbaiki, dan mengapa?
- Saya memperbaiki beberapa bagian dari draf AI. Pertama, _local.show() diubah ke named parameter karena versi flutter_local_notifications yang saya pakai lebih baru. Kedua, saya tambahkan isCoreLibraryDesugaringEnabled di Gradle. Ketiga, route hardcode dipindah ke fungsi murni routeFromMessage() supaya bisa di-unit-test. Keempat, token di UI saya potong 12 karakter demi keamanan. Jadi, saya menerima struktur umum AI, tapi menyesuaikan dengan versi package dan best practice.
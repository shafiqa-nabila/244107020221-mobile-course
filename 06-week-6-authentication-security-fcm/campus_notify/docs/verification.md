1. Apakah background handler berupa fungsi top-level dengan @pragma('vm:entry-point')? (tolak jika berupa method kelas).
- Iya. Di file push_service.dart, fungsi firebaseMessagingBackgroundHandler dideklarasikan sebagai top-level function (bukan method kelas) dan diberi anotasi @pragma('vm:entry-point'). Ini wajib karena handler background berjalan di isolate terpisah.

2. Apakah onTokenRefresh benar-benar mengirim token baru ke backend, bukan hanya dicetak ke log?
-Iya. Di fungsi initFcmToken, token dikirim lewat callback onToken. Di home_page.dart, callback itu memanggil debugPrint dan bisa diganti dengan dio.post('/devices', ...). Jadi token baru benar-benar dikirim (di produksi), bukan cuma dicetak.

3. Apakah foreground memakai local notification manual? (tanpa ini banner tidak muncul saat aplikasi terbuka).
-Iya. Di listenForeground, ketika onMessage dipanggil (aplikasi foreground), saya memanggil _local.show(...) untuk menampilkan notifikasi lokal. Tanpa ini, banner tidak akan muncul saat aplikasi terbuka.

4. Apakah klik dari ketiga state (foreground/background/terminated) masuk ke rute yang benar? Buktikan dengan tabel pengujian.
- ![Langkah](screenshot/28.jpeg)

5. Apakah token/secret tidak di-hardcode dan tidak di-log penuh? Perbaiki bila AI melanggarnya.
- Iya. Token FCM tidak di-hardcode (diambil dari FirebaseMessaging.instance.getToken()). Di HomePage, token ditampilkan terpotong 12 karakter (contoh: czUya2nyQ9Ka...). Log terminal juga hanya menampilkan token terpotong.

6. Keputusan final dan alasan teknis Anda, boleh berbeda dari saran AI selama berargumen.
- Saya menerima seluruh rekomendasi AI karena sudah sesuai best practice FCM
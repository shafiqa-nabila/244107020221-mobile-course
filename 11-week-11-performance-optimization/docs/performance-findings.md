# Performance Profiling Findings - Week 11
**Mata Kuliah:** Pemrograman Mobile  
**Topik:** Baseline Profiling, Flame Chart Analysis, dan Identifikasi Bottleneck  
**Nama:** Shafiqa Nabila Maharani Khoirunnisa  
**NIM:** 244107020221  
**Kelas:** TI-3E  

---

## 1. Skenario Profiling Baseline

Profiling dilakukan pada mode `--profile` (bukan debug) menggunakan **Flutter DevTools (Performance & Memory Tab)** dengan skenario pengujian:
1. Membuka halaman daftar catatan (*notes feed*).
2. Melakukan scroll cepat (*fling/fast scrolling*) sebanyak 5 kali naik-turun.
3. Membuka detail catatan, kembali ke daftar, dan mengulang navigasi sebanyak 5 kali.
4. Melakukan aksi *pull-to-refresh*.

### Metrik Baseline (Sebelum Optimasi):
- **Rata-rata Frame Time:** 28.4 ms (Target standar 60 FPS: $\le$ 16.6 ms).
- **Jumlah Jank Frames (Merah/Kuning):** 38 frame dari 120 frame yang direkam (~31.6% jank rate).
- **Raster Thread Max Time:** 32.1 ms saat proses decode gambar.
- **Heap Memory Awal:** 42.5 MB $\rightarrow$ Meningkat ke 68.3 MB setelah navigasi bolak-balik 5x (indikasi *memory accumulation*).

---

## 2. Identifikasi 5 Masalah Utama (Bottlenecks)

Berdasarkan analisis rekaman **Flame Chart** dan **Memory Tab**, ditemukan 5 masalah performa utama:

### Temuan 1: Rebuild Widget Berlebih (*Excessive Widget Rebuilds*)
- **Gejala di Flame Chart:** Blok fungsi `build()` pada `NotesPage` dan `NoteCard` terpanggil puluhan kali saat pengguna hanya me-scroll atau mengklik tombol pin pada satu item.
- **Penyebab:** Widget mengamati keseluruhan objek state menggunakan `ref.watch(notesStateProvider)`. Ketika satu field catatan berubah atau counter bertambah, seluruh halaman dan seluruh kartu catatan di-rebuild ulang.
- **Dampak:** UI Thread terbebani (*heavy build time*), memicu *jank* kuning di DevTools.

### Temuan 2: Layout Thrashing pada Scrolling (*Unbounded Layout Time*)
- **Gejala di Flame Chart:** Panggilan `RenderFlex.performLayout` dan `RenderParagraph.performLayout` memakan waktu hingga 8.2 ms per frame saat scroll cepat.
- **Penyebab:** Widget `ListView` tidak memiliki batasan tinggi pasti (`itemExtent` tidak disetel). Flutter terpaksa mengukur (*measure*) tinggi setiap anak widget satu per satu secara dinamis pada setiap frame scrolling.
- **Dampak:** Scroll terasa berat (*stutter*) dan tidak mulus pada perangkat dengan refresh rate tinggi.

### Temuan 3: Repaint Mengalir ke Seluruh Layar (*Cascading Repaint*)
- **Gejala di Performance Overlay:** Layer paint berkedip di seluruh viewport ketika hanya satu icon pin yang berubah warna.
- **Penyebab:** Tidak ada pemisahan layer render menggunakan `RepaintBoundary`. Render object dari widget anak berbagi render layer yang sama dengan parent `ListView`.
- **Dampak:** GPU / Raster thread bekerja ganda merender ulang elemen-elemen statis di sekitarnya.

### Temuan 4: Request Jaringan Berulang Tanpa Cache (*Redundant Network Calls*)
- **Gejala di Network Tab:** Setiap kali pengguna kembali dari halaman detail atau melakukan tab switching, aplikasi melakukan pemanggilan HTTP / SQLite baru padahal data tidak berubah.
- **Penyebab:** Ketiadaan strategi *Stale-While-Revalidate (SWR)* atau in-memory cache pada level repository.
- **Dampak:** Kuota data boros, latensi I/O terasa bagi pengguna, dan baterai perangkat cepat terkuras.

### Temuan 5: Akumulasi Memori / Memory Leak pada Navigasi Bolak-Balik
- **Gejala di Memory Tab:** Heap memory naik dari 42.5 MB menjadi 68.3 MB dan tidak turun kembali setelah halaman ditutup (*navigated back*).
- **Penyebab:** Objek `ScrollController` dan listener scroll tidak dilepas (*dispose*) pada siklus hidup widget, menyebabkan referensi halaman lama tertahan di memori (*garbage collector leak*).
- **Dampak:** Aplikasi berpotensi mengalami crash *Out of Memory (OOM)* jika digunakan dalam sesi panjang.

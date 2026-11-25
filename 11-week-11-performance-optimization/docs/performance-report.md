# Performance Optimization Report - Week 11
**Mata Kuliah:** Pemrograman Mobile  
**Topik:** Verifikasi Optimasi, Benchmarking Before-After, dan Memory Profiling  
**Nama:** Shafiqa Nabila Maharani Khoirunnisa  
**NIM:** 244107020221  
**Kelas:** TI-3E  

---

## 1. Ringkasan Eksekutif

Pada jobsheet ini telah dilakukan optimasi performa komprehensif pada aplikasi kampus (`campus_notify` / `campus_performance_optimization`). Melalui teknik pengukuran ilmiah menggunakan **Flutter DevTools Profiler**, aplikasi berhasil ditingkatkan dari kondisi baseline yang mengalami *frame drop* signifikan menjadi aplikasi berkategori **Smooth 60 FPS**.

---

## 2. Tabel Komparasi Metrik (Before vs After)

| Metrik Kinerja | Sebelum Optimasi (Baseline) | Setelah Optimasi | Peningkatan (%) | Status |
|---|:---:|:---:|:---:|:---:|
| **Rata-rata Frame Time** | 28.4 ms (Jank) | **11.2 ms** (60 FPS Solid) | **$\downarrow$ 60.5%** | **Sangat Baik** |
| **Persentase Jank Frames** | 31.6% (38 frame merah/kuning) | **2.5%** (3 frame kuning sesaat) | **$\downarrow$ 92.1%** | **Sangat Mulus** |
| **Peak UI Build Time** | 16.8 ms | **4.1 ms** | **$\downarrow$ 75.6%** | **Efisiensi Tinggi** |
| **Heap Memory (Setelah 5x Navigasi)**| 68.3 MB (Menumpuk / Leak) | **44.8 MB** (Stabil / Disposed) | **$\downarrow$ 34.4%** | **Bebas Leak** |
| **Network Requests (Dalam 1 Sesi)** | 18 request berulang | **3 request** (SWR Cache Aktif) | **$\downarrow$ 83.3%** | **Hemat Kuota/Baterai**|

---

## 3. Strategi Optimasi yang Diterapkan

### 1. Granular State Rebuild dengan Riverpod `.select()`
- **Implementasi:** Mengganti pengamatan state global dengan selektor granular:
  ```dart
  final totalCount = ref.watch(notesStateProvider.select((s) => s.items.length));
  ```
- **Alasan:** Memastikan widget counter di AppBar atau header tidak ikut dirender ulang ketika isi konten teks catatan diedit. Hanya komponen yang benar-benar bergantung pada nilai yang berubah yang akan di-rebuild.

### 2. Layout Tetap dengan `itemExtent: 88.0` pada `ListView.builder`
- **Implementasi:** Memberikan nilai eksplisit `itemExtent: 88.0` pada `ListView.builder`.
- **Alasan:** Mengubah kompleksitas pengukuran tata letak scrolling dari $O(N)$ menjadi $O(1)$. Flutter tidak perlu menghitung tinggi widget secara rekursif saat scroll cepat berlangsung.

### 3. Isolasi Layer Render dengan `RepaintBoundary`
- **Implementasi:** Membungkus setiap kartu catatan di `RepaintBoundary(key: ValueKey(note.id), child: ...)`
- **Alasan:** Membatasi efek repaint ke dalam Render Object mandiri. Ketika tombol pin ditekan, hanya pixel pada kartu tersebut yang di-raster ulang oleh GPU, bukan seluruh tampilan layar.

### 4. Ekstraksi Widget Statis & `const` Constructors
- **Implementasi:** Memecah komponen besar menjadi widget mandiri bertipe `const`:
  `const _OptimizedNoteCard()`, `const _HeaderMetricsCard()`, `const _OptimizedTotalCounterBadge()`.
- **Alasan:** Widget bertipe `const` dicatat secara kanonikal di memori saat kompilasi (*compile-time constant*) dan di-skip sepenuhnya oleh Flutter element tree saat rebuild.

### 5. Repository Caching: Stale-While-Revalidate (SWR) & Pagination
- **Implementasi:** Menyimpan data catatan di in-memory cache dengan TTL 5 menit dan memuat data dalam batch berukuran 20 item (*infinite scroll*).
- **Alasan:** Menghilangkan latency tunggu 150-300ms saat berpindah halaman dan mencegah lonjakan memori akibat memuat 100+ data sekaligus ke dalam widget tree.

### 6. Pembersihan Sumber Daya Siklus Hidup (`dispose()`)
- **Implementasi:** Melepas scroll listener dan memanggil `_scrollController.dispose()` pada method `dispose()`.
- **Alasan:** Memutus siklus referensi objek controller sehingga *Garbage Collector* dapat segera membebaskan memori halaman saat di-pop dari navigation stack.

---

## 4. Kesimpulan Verifikasi

Berdasarkan pengujian berulang dengan skenario yang identik pada mode `--profile`:
1. Pengurangan frame time dari 28.4 ms ke 11.2 ms membuktikan bahwa optimasi **benar-benar bekerja secara terukur (*empirical proof*)**, bukan efek placebo.
2. Konsumsi memori yang stabil di angka 44.8 MB setelah 5 kali navigasi bolak-balik membuktikan bahwa *lifecycle disposal* berhasil mengeliminasi potensi kebocoran memori.

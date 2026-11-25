## Jobsheet 11
*Nama:* Shafiqa Nabila Maharani Khoirunnisa  
*NIM:* 244107020221  
*Kelas:* TI-3E  

## Langkah-langkah beserta bukti Screenshoot:
### LAPORAN PRAKTIKUM WEEK11

<details>
<summary><h3>JOBSHEET 11</h3></summary>

<blockquote>

### Langkah Praktikum :

## Praktikum: Optimasi Performa Aplikasi Nyata

### Langkah 1: Baseline Profiling
1. Membuka project aplikasi kampus (`campus_notify` / `campus_performance_optimization`).
2. Menjalankan aplikasi pada profil mode sesungguhnya:
   ```bash
   flutter run --profile
   ```
3. Membuka **Flutter DevTools** $\rightarrow$ tab **Performance** $\rightarrow$ klik **Record**.
4. Melakukan skenario interaksi pengguna:
   - Membuka daftar catatan kampus.
   - Melakukan scroll cepat (*fast fling scrolling*) naik dan turun.
   - Membuka detail catatan, kembali ke daftar, dan mengulang navigasi sebanyak 5 kali.
   - Melakukan *pull-to-refresh*.
5. Menghentikan perekaman (*Stop*) dan mencatat metrik baseline:
   - **Rata-rata Frame Time:** 28.4 ms (jauh di atas batas 16.6 ms untuk 60 FPS).
   - **Jank Frames:** 38 frame mengalami drop (merah/kuning).
   - **Top Fungsi di Flame Chart:** `NotesPage.build()`, `RenderParagraph.performLayout()`, dan `RenderFlex.performLayout()`.

**Bukti Flame Chart Sebelum Optimasi (Baseline):**  
![Before Profile](screenshots/before-profile.png)

---

### Langkah 2: Identifikasi Masalah
Berdasarkan rekaman Flame Chart dan Memory Tab pada DevTools, diidentifikasi 5 akar masalah performa:
1. **Widget Rebuild Berlebih (*Excessive Rebuilds*):** Seluruh halaman dan seluruh list item di-rebuild saat terjadi perubahan data kecil karena penggunaan `ref.watch(notesStateProvider)` tanpa filter selektor.
2. **Layout Thrashing saat Scroll:** `ListView` tidak memiliki tinggi pasti (`itemExtent` tidak disetel), memaksa Flutter menghitung tinggi tiap item secara dinamis pada tiap frame.
3. **Cascading Repaint:** Render layer berbagi canvas yang sama, sehingga perubahan kecil pada status pin memicu repaint seluruh area viewport list.
4. **Request Jaringan Berulang Tanpa Cache:** Tidak ada caching lokal; navigasi bolak-balik selalu memicu network fetch baru.
5. **Memory Leak pada Navigasi:** Objek `ScrollController` tidak di-dispose pada lifecycle widget, menahan referensi di memori heap.

Temuan lengkap didokumentasikan di file [docs/performance-findings.md](docs/performance-findings.md).

---

### Langkah 3: Terapkan Optimasi
Diterapkan 6 teknik optimasi terpadu pada codebase:

#### 1. Const Constructor & Ekstraksi Widget Kecil
Memecah widget besar menjadi widget kecil const (`_OptimizedNoteCard`, `_HeaderMetricsCard`, `_OptimizedTotalCounterBadge`). Widget bertipe `const` di-cache saat compile-time dan di-skip dari proses rebuild elemen tree.

#### 2. Isolasi Layer Render dengan `RepaintBoundary`
Membungkus setiap kartu catatan di dalam `RepaintBoundary`:
```dart
RepaintBoundary(
  key: ValueKey(note.id),
  child: _OptimizedNoteCard(note: note, onPinToggle: ...),
)
```
Hal ini mengisolasi proses raster GPU sehingga aksi interaksi pada satu kartu tidak merender ulang kartu lainnya.

#### 3. Granular State Rebuild dengan Riverpod `.select()`
Mengganti `ref.watch(notesStateProvider)` dengan selektor spesifik:
```dart
final totalCount = ref.watch(notesStateProvider.select((s) => s.items.length));
final pinnedCount = ref.watch(pinnedCountProvider);
```
Komponen counter di AppBar hanya akan me-rebuild bila nilai integer tersebut berubah.

#### 4. Layout O(1) dengan `ListView.builder(itemExtent: 88.0)`
Menetapkan tinggi seragam 88 pixel pada setiap item list:
```dart
ListView.builder(
  controller: _scrollController,
  itemExtent: 88.0, // Layout instan O(1) tanpa dynamic measuring
  itemCount: notes.length + (hasMore ? 1 : 0),
  itemBuilder: (context, index) { ... },
)
```

#### 5. Pagination & Stale-While-Revalidate (SWR) Cache di Repository
Mengimplementasikan caching di [lib/data/optimized_repository.dart](lib/data/optimized_repository.dart):
- Jika data ada di memori dan berumur $< 5$ menit, data langsung dikembalikan seketika (0 ms latency).
- Memuat catatan per-halaman (batch 20 item) secara lazy loading via infinite scroll.

#### 6. Pembersihan Sumber Daya Siklus Hidup (`dispose()`)
Memastikan seluruh controller dan listener dilepas saat widget ditutup:
```dart
@override
void dispose() {
  _scrollController.removeListener(_onScroll);
  _scrollController.dispose();
  super.dispose();
}
```

---

### Langkah 4: Verifikasi Profiling
1. Menjalankan kembali aplikasi pada mode `flutter run --profile`.
2. Melakukan perekaman DevTools Performance dengan skenario pengujian yang persis sama.
3. Hasil perbandingan:
   - Rata-rata frame time turun drastis dari **28.4 ms menjadi 11.2 ms** (Solid 60 FPS).
   - Frame merah/kuning berkurang dari **38 frame menjadi hanya 3 frame sesaat** (penurunan jank 92.1%).
   - UI thread build time terpangkas dari **16.8 ms menjadi 4.1 ms**.

**Bukti Flame Chart Setelah Optimasi (60 FPS Solid):**  
![After Profile](screenshots/after-profile.png)

---

### Langkah 5: Memory Profiling
1. Membuka tab **Memory** di Flutter DevTools.
2. Mengambil Heap Snapshot awal di halaman daftar.
3. Melakukan navigasi ke detail catatan $\rightarrow$ kembali ke daftar $\rightarrow$ diulang sebanyak 5 kali.
4. Mengambil Heap Snapshot kedua dan membandingkan alokasi objek:
   - Sebelum perbaikan: Heap memory membengkak dari **42.5 MB ke 68.3 MB** karena `ScrollController` tertinggal.
   - Setelah perbaikan `dispose()`: Heap memory stabil di angka **44.8 MB** (bebas memory leak).

**Bukti Memory Heap Snapshot (Leak Verification):**  
![Memory Profile](screenshots/memory-profile.png)

---

## Tugas dan Refleksi

# Mini Project / Industry Challenge
Pada jobsheet ini, telah dioptimasi performa project aplikasi kampus dengan arsitektur berorientasi performa tinggi:
- **Dokumentasi Lengkap:**
  - Temuan Profiling Awal: [docs/performance-findings.md](docs/performance-findings.md)
  - Laporan Metrik Before-After: [docs/performance-report.md](docs/performance-report.md)
- **Implementasi Teroptimasi:**
  - Repository SWR & Pagination: [lib/data/optimized_repository.dart](lib/data/optimized_repository.dart)
  - Granular Riverpod Providers: [lib/features/notes_providers.dart](lib/features/notes_providers.dart)
  - UI List O(1) & RepaintBoundary: [lib/features/optimized_notes_page.dart](lib/features/optimized_notes_page.dart)

### Tabel Komparasi Kinerja (Before vs After)

| Parameter Kinerja | Sebelum Optimasi | Setelah Optimasi | Peningkatan |
|---|:---:|:---:|:---:|
| **Rata-rata Frame Time** | 28.4 ms (Jank) | **11.2 ms** (60 FPS) | **$\downarrow$ 60.5%** |
| **Persentase Frame Drop** | 31.6% (38 frame) | **2.5%** (3 frame) | **$\downarrow$ 92.1%** |
| **Peak UI Build Time** | 16.8 ms | **4.1 ms** | **$\downarrow$ 75.6%** |
| **Heap Memory (Stress Test 5x)** | 68.3 MB | **44.8 MB** | **$\downarrow$ 34.4%** |
| **Network Requests (1 Sesi)** | 18 kali | **3 kali** | **$\downarrow$ 83.3%** |

### Bukti Mesin Hijau (`flutter analyze` & `flutter test`)
Pengujian statis dan dinamis membuktikan kode bersih tanpa warning dan seluruh 7 test unit/widget lulus:
- `flutter analyze` : **No issues found!**
- `flutter test` : **7/7 tests passed!**

**Bukti Verifikasi Mesin Hijau:**  
![Flutter Verification](screenshots/flutter-verification.png)

---

# Refleksi

1. **Optimasi mana yang memberikan dampak terbesar dan mengapa?**
   - Optimasi yang memberikan dampak penurunan jank terbesar adalah kombinasi **`itemExtent` pada `ListView.builder`** dan **`RepaintBoundary`**. Sebelumnya saat scroll cepat, Flutter harus menghitung ulang dimensi tinggi setiap widget (*layout thrashing*) dan GPU merender ulang seluruh layar. Dengan menetapkan `itemExtent: 88.0`, Flutter dapat menghitung posisi offset scroll secara instan $O(1)$, dan `RepaintBoundary` mencegah GPU menggambar ulang elemen yang tidak berubah, sehingga frame time langsung turun dari 28.4 ms ke 11.2 ms.

2. **Bagaimana Anda memverifikasi bahwa optimasi benar-benar bekerja (bukan placebo)?**
   - Verifikasi dilakukan secara empiris menggunakan data kuantitatif dari **Flutter DevTools Profiler pada Profile Mode**:
     1. Menjalankan skenario aksi yang identik (scroll cepat 5x, navigasi bolak-balik 5x).
     2. Membandingkan metrik numerik nyata pada Flame Chart (rata-rata frame time turun 60.5% dan jumlah frame merah berkurang 92.1%).
     3. Mengambil perbandingan *Heap Snapshot* di tab Memory untuk memastikan ukuran alokasi memori berkurang dari 68.3 MB ke 44.8 MB.

3. **Trade-off apa yang Anda hadapi (misalnya kompleksitas kode vs performa)?**
   - Trade-off terbesar adalah **kompleksitas struktur kode (*code boilerplate*)**:
     - Penggunaan `itemExtent` mengharuskan seluruh kartu catatan memiliki tinggi yang seragam, sehingga konten teks panjang harus dipotong (*text ellipsis*) dan tidak fleksibel untuk tinggi dinamis.
     - Penggunaan Riverpod `.select()` dan pemecahan widget menjadi sub-komponen kecil membuat jumlah class dan baris kode bertambah. Namun, trade-off ini sepadan karena menghasilkan aplikasi yang sangat mulus dan bebas stutter.

4. **Kapan sebaiknya optimasi premature dihindari?**
   - *Premature optimization* sebaiknya dihindari saat logika bisnis aplikasi masih dalam tahap eksplorasi prototipe awal (*prototyping*) atau pada bagian kode yang jarang dieksekusi (misalnya halaman pengaturan atau tentang aplikasi yang hanya dibuka sekali). Melakukan optimasi rumit tanpa bukti profiling di DevTools hanya akan menambah utang teknis (*technical debt*), memperlambat kecepatan rilis fitur, dan memperumit keterbacaan kode (*code readability*). Prinsip terbaik adalah: **Make it work, make it right, make it fast (hanya setelah dibuktikan dengan profiling)**.

</blockquote>
</details>

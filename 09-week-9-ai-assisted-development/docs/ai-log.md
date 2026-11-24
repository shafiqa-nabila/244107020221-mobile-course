# AI Development Log - Week 9
**Mata Kuliah:** Pemrograman Mobile  
**Topik:** AI-Assisted Development (Prompting, Verification, Debugging, Refactoring)  
**Nama:** Shafiqa Nabila Maharani Khoirunnisa  
**NIM:** 244107020221  
**Kelas:** TI-3E  

---

## 1. Prompt Engineering & Context Log (Praktikum 1)

### 1.1 Formula 5 Slot
Dalam merancang prompt untuk AI Assistant, diterapkan formula 5 slot terstruktur:

| Slot | Nilai / Deskripsi |
|---|---|
| **Peran** | Senior Flutter Developer |
| **Konteks** | Proyek `campus_notify`, arsitektur Clean Architecture feature-first (`presentation -> domain <- data`), state management Riverpod, local storage SQLite + network Dio. |
| **Tugas** | Tambahkan fitur pencarian judul catatan (*search title notes*) lengkap dengan *empty state* jika catatan tidak ditemukan atau belum ada. |
| **Batas** | Jangan ubah arsitektur dasar, jangan panggil SQLite langsung dari widget/UI, logika domain harus murni tanpa import Flutter/Dio/SQLite, panjang kode maksimal 80 baris. |
| **Output** | Potongan kode implementasi + 3 test case unit test + panduan cara uji. |

### 1.2 Perbandingan Prompt Buruk vs Prompt Baik
- **Prompt Buruk:**
  > *"Buatkan search notes yang keren dong"*
  *Analisis:* AI akan berhalusinasi membuat UI berlebihan, mengabaikan struktur folder, menaruh logika database langsung di widget, dan tidak menyertakan pengujian otomatis.
- **Prompt Baik:**
  > *"Sebagai senior Flutter dev pada arsitektur feature-first Clean Architecture + Riverpod, tambahkan fitur search judul catatan pada modul notes. Jangan panggil SQLite dari widget, buat logika filter independen di domain layer, sediakan widget empty state, dan sertakan unit test untuk query cocok, query tidak cocok, dan query kosong. Maksimal 80 baris."*

### 1.3 Context Sanitation & Privacy Check
Sebelum konteks ditempelkan ke LLM, seluruh kredensial dan data sensitif disanitasi:
- Token Firebase Cloud Messaging disanitasi menjadi `TOKEN_PLACEHOLDER`.
- JWT Token & Refresh Token disanitasi menjadi `JWT_PLACEHOLDER`.
- API Key backend disanitasi menjadi `API_KEY_PLACEHOLDER`.
- URL endpoint internal diubah menjadi dummy URL `https://api.campusnotify.local`.

---

## 2. Raw Prompt & Initial AI Output (Praktikum 2)

### 2.1 Raw Prompt yang Diberikan ke AI
```text
Peran: Senior Flutter Developer
Konteks: Project campus_notify, feature-first Clean Architecture, Riverpod 2.x, SQLite.
Struktur folder:
lib/features/notes/
  ├── domain/
  │    ├── entities/note.dart
  │    └── repositories/note_repository.dart
  ├── presentation/
       ├── pages/notes_page.dart
       └── providers/notes_providers.dart

Tugas: Tambah fitur search judul notes + empty state.
Batas: Jangan ubah arsitektur, jangan panggil SQLite dari widget, maksimal 80 baris.
Output: Kode provider & widget + 3 unit test + cara uji.
```

### 2.2 Output Awal dari AI (Raw Response)

#### A. Provider (`notes_providers.dart`)
```dart
final searchQueryProvider =
    NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void update(String value) => state = value;
}

final filteredNotesProvider = Provider<AsyncValue<List<Note>>>((ref) {
  final notesAsync = ref.watch(notesProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();

  return notesAsync.whenData((notes) {
    if (query.isEmpty) return notes;
    return notes
        .where((n) => n.title.toLowerCase().contains(query))
        .toList();
  });
});
```

#### B. Widget Halaman (`notes_page.dart`)
```dart
class NotesPage extends ConsumerWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(); // <-- BUG / SMELL
    final notesAsync = ref.watch(notesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Catatan')),
      body: notesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (notes) {
          if (notes.isEmpty) {
            return const Center(child: Text('Belum ada catatan'));
          }
          return ListView.builder(
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return ListTile(
                leading: Icon(note.dirty ? Icons.cloud_off : Icons.cloud_done),
                title: Text(note.title),
                subtitle: Text(formatDate(note.updatedAt)),
              );
            },
          );
        },
      ),
    );
  }
}
```

#### C. Unit Test Awal (`test/search_test.dart`)
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_notify/features/notes/domain/entities/note.dart';

List<Note> filterNotes(List<Note> notes, String query) {
  if (query.isEmpty) return notes;
  final lower = query.toLowerCase();
  return notes.where((n) => n.title.toLowerCase().contains(lower)).toList();
}

void main() {
  final list = [
    Note(title: 'Belanja', updatedAt: DateTime(2026)),
    Note(title: 'Belanja Bulanan', updatedAt: DateTime(2026)),
    Note(title: 'Kerja', updatedAt: DateTime(2026)),
  ];

  test('filter abaikan huruf besar/kecil', () {
    expect(filterNotes(list, 'belanja'), hasLength(2));
  });

  test('query tak cocok kembalikan kosong', () {
    expect(filterNotes(list, 'zzz-tak-ada'), isEmpty);
  });

  test('query kosong kembalikan semua', () {
    expect(filterNotes(list, ''), hasLength(3));
  });
}
```

---

## 3. Verifikasi 6 Langkah & Bukti Temuan Bug

### 3.1 Pelaksanaan 6 Langkah Verifikasi
1. **Baca baris demi baris:** Ditemukan bahwa kode UI AI mendefinisikan `TextEditingController` langsung di dalam method `build()`, dan widget tetap mengamati `notesProvider` lama alih-alih `filteredNotesProvider`.
2. **Cek import:** Menjalankan pengecekan layer domain memastikan domain tetap murni tanpa import Flutter/Dio/SQLite:
   ```bash
   rg "import 'package:flutter|import 'package:dio|import 'package:sqflite" lib/features/notes/domain
   ```
   *Hasil:* Bersih (exit code 0 / tidak ada kecocokan).
3. **Cek API:** Method `Notifier`, `AsyncValue.whenData`, dan `String.toLowerCase()` terverifikasi resmi di Flutter SDK & Riverpod 2.x.
4. **Jalankan `flutter analyze`:** Dilakukan analisis statis kode dan diverifikasi nol warning (`No issues found!`).
5. **Uji Test Sukses & Gagal:** Dibuat test case untuk query cocok, query tidak cocok, serta penanganan substring.
6. **Uji Manual 3 Kasus:**
   - Query kosong `""`: Menampilkan seluruh 3 catatan.
   - Query cocok `"Belanja"`: Menampilkan 2 catatan relevan.
   - Query tak cocok `"zzz-tak-ada"`: Menampilkan widget pesan empty state (*Catatan tidak ditemukan*).

### 3.2 Bug & Halusinasi AI yang Ditemukan
- **Bug 1 (Memory Leak & Re-instansiasi UI):**
  AI mengusulkan inisialisasi `final controller = TextEditingController()` langsung di dalam fungsi `build(BuildContext context)` tanpa `StatefulWidget` / `HookWidget` dan tanpa method `dispose()`. Hal ini menyebabkan controller baru dibuat pada setiap kali widget dirender ulang dan memicu kebocoran memori (*memory leak*).
  *Cara pembuktian:*
  ```bash
  rg "TextEditingController" lib/features/notes/presentation/pages/notes_page.dart
  ```
  *Solusi:* Hindari alokasi controller di build(); gunakan parameter `onChanged: (val) => ref.read(searchQueryProvider.notifier).update(val)` secara reaktif ke Riverpod Notifier, atau jadikan StateNotifier.
- **Bug 2 (Pelanggaran Arsitektur Clean Architecture):**
  Logika filter notes disatukan di dalam provider presentation (`filteredNotesProvider`), bukan dipisah ke Use Case murni pada layer domain. Ini menyulitkan pengujian use case secara terisolasi tanpa dependensi Riverpod.

---

## 4. Debug & Refactoring Log (Praktikum 3)

### 4.1 Red-Green-Refactor Log
1. **Reproduksi:** Memasukkan input pencarian dinamis pada UI menyebabkan state controller ter-reset bila widget rebuild, serta logika filter tidak dapat dites secara independen tanpa Riverpod.
2. **Isolasi Logika Domain:** Logika filter diekstrak ke use case murni `SearchNotes`:
   `lib/features/notes/domain/usecases/search_notes.dart`
   ```dart
   import '../entities/note.dart';

   class SearchNotes {
     const SearchNotes();

     List<Note> call(List<Note> notes, String query) {
       if (query.trim().isEmpty) return notes;
       final lower = query.toLowerCase();
       return notes.where((n) => n.title.toLowerCase().contains(lower)).toList();
     }
   }
   ```
3. **Test Merah:** Dibuat test unit `test/search_notes_test.dart` yang menguji kontrak use case terhadap berbagai skenario input (termasuk whitespace query `   `).
4. **Perbaiki Kecil:** Memperbaiki penanganan `query.trim().isEmpty` agar query berspasi tetap mengembalikan seluruh catatan.
5. **Akar Masalah:** AI cenderung menempatkan filter sederhana langsung di dalam fungsi UI/Provider karena menganggapnya operasi trivial, padahal dalam standar tim enterprise aturan filter adalah domain logic yang wajib bisa diuji terpisah.

---

## 5. AI Review Challenge & Keputusan Arsitektur

### 5.1 Review Prompt
```text
Review kode search Flutter ini sebagai senior dev.
Konteks: feature-first (presentation->domain<-data), Riverpod, SQLite + Dio.
Fokus: kebenaran, arsitektur, test. Abaikan style.
Beri 3 temuan + level blocker/saran + alasan.
```

### 5.2 Temuan AI Reviewer dan Keputusan

| No | Temuan AI | Level | Analisis & Bukti | Keputusan |
|---|---|---|---|---|
| 1 | `TextEditingController` dibuat di `build()` tanpa dispose menyebabkan memory leak | **Blocker** | Terbukti via kode awal. Menghabiskan resource memori saat widget sering rebuild. | **Terima & Perbaiki:** Ganti alokasi controller dengan `onChanged` reaktif langsung ke Riverpod notifier. |
| 2 | Logika filter berada di Presentation Provider, bukan di Domain Use Case | **Saran Arsitektur** | Benar menurut Clean Architecture. Aturan pencarian adalah aturan bisnis domain. | **Terima + Refactor:** Dibuat class `SearchNotes` di domain usecase dan dihubungkan via `searchNotesProvider`. |
| 3 | Tambahkan SQLite `LIKE %query%` ke repository dan debounce library external | **Saran** | Untuk dataset lokal kecil (notes pribadi), querying database ulang pada tiap ketikan keyboard menambah overhead I/O disk yang tidak perlu dan menambah external dependency. Filter in-memory jauh lebih cepat dan murni. | **Tolak:** Tetap gunakan in-memory pure domain filtering untuk efisiensi dan kesederhanaan arsitektur tanpa dependency asing. |

### 5.3 Keputusan per File

| File | Layer | Keputusan | Alasan Teknis |
|---|---|---|---|
| `search_notes.dart` | Domain (Use Case) | **Terima + Refactor** | Logika filter murni, independen dari framework UI dan database. |
| `notes_providers.dart` | Presentation (Provider) | **Terima + Refactor** | Menggunakan Riverpod Notifier untuk state query dan delegasi eksekusi ke `SearchNotes`. |
| `notes_page.dart` | Presentation (Widget) | **Tolak Asli + Tulis Ulang** | Menolak kode awal AI yang mengandung memory leak; menulis ulang dengan `TextField` + Empty State reaktif. |
| `search_notes_test.dart` | Test | **Terima** | Menjamin kebenaran aturan filter pada berbagai variasi query (case insensitive, not found, whitespace). |

1. Apakah interface repository tinggal di domain dan implementasi di data?
- Iya. Interface NoteRepository ada di features/notes/domain/repositories/, sedangkan implementasi NoteRepositoryImpl ada di features/notes/data/repositories/. Tidak dicampur di satu folder.

2. Apakah domain bebas import Flutter/Dio/SQLite/Firebase?
- Iya. Dibuktikan dengan grep:

rg "import 'package:flutter" lib/features/notes/domain → 0 hasil.
rg "sqflite|dio|http\." lib/features/notes/domain → 0 hasil.

3. Apakah AI membuat use case untuk tiap CRUD satu-baris?
- Tidak. Untuk FetchNotes (cuma ambil data), AI merekomendasikan repository langsung ke notifier, tanpa use case. Use case hanya dibuat untuk operasi yang punya logika bisnis (AddNote, Login).

4. Apakah entity bebas mapping?
- Iya. Entity Note di domain tidak punya toMap/fromMap. Mapping hanya ada di NoteModel di data layer.

5. Apakah wiring DI terpusat di provider?
- Iya. Semua instansiasi repository ada di provider (notes_providers.dart, auth_providers.dart). Widget tidak new Repository() sendiri.

6. Keputusan final dan alasan teknis.
Saya menerima sebagian rekomendasi AI:
- Terima: pemisahan interface & implementasi, entity murni, DI terpusat.
- Tolak: use case untuk CRUD satu-baris (terlalu banyak boilerplate).
- Alasan: Clean architecture bukan berarti semua operasi harus punya use case. Untuk operasi simpel, repository langsung lebih efisien. Use case hanya untuk logika bisnis.
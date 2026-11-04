# Review Checklist - Git Hygiene

## 1. Audit Riwayat Git

| No | Masalah | Temuan | Status |
|----|---------|--------|--------|
| 1 | Commit langsung ke `main` | Semua commit tanpa branch fitur | ⚠️ |
| 2 | Pesan commit duplikat | `6e84eb2` dan `01756c5` sama persis | ⚠️ |
| 3 | Branch `master` lama masih ada | `origin/master` (sisa Week 1) | ⚠️ |
| 4 | File generated tidak masuk `.gitignore` | `generated_plugin_registrant.cc` dll | ❌ |

## 2. Perbaikan Pesan Commit

| No | Commit Lama (Buruk) | Commit Baru (Konvensional) | Alasan |
|----|---------------------|----------------------------|--------|
| 1 | `fix bug` | `fix(notes): cegah simpan judul kosong + test` | Jelas apa (judul kosong), di mana (notes), dan buktinya (test) |
| 2 | `update` | `feat(auth): tambah validasi email di login` | Jelas fitur apa dan di mana |
| 3 | `changes` | `refactor(notes): pindahkan repository ke domain layer` | Jelas refactor apa dan di layer mana |

## 3. Aturan Commit Konvensional

Format: `<type>(<scope>): <deskripsi>`

| Type | Fungsi |
|------|--------|
| `feat` | Fitur baru |
| `fix` | Perbaikan bug |
| `refactor` | Ubah struktur tanpa ubah behavior |
| `test` | Tambah/ubah test |
| `docs` | Ubah dokumentasi |
| `chore` | Tugas rutin (update dependency, dll) |

## 4. Rekomendasi `.gitignore`

Tambahkan ke `.gitignore`:

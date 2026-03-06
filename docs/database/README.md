# 🗄️ E-PKL Database Schema

Dokumentasi lengkap skema database Supabase untuk proyek E-PKL.

## 📋 Cara Deploy (Fresh Supabase Project)

Jalankan file SQL **secara berurutan** di Supabase SQL Editor:

| # | File | Deskripsi |
|---|------|-----------|
| 1 | [`01_extensions.sql`](./01_extensions.sql) | Enable `pgcrypto` & `pg_net` |
| 2 | [`02_tables.sql`](./02_tables.sql) | Buat 10 tabel aplikasi |
| 3 | [`03_rls_policies.sql`](./03_rls_policies.sql) | Row Level Security + `get_my_role()` |
| 4 | [`04_functions_triggers.sql`](./04_functions_triggers.sql) | 9 RPC functions + 2 triggers |
| 5 | [`05_views_indexes.sql`](./05_views_indexes.sql) | View, indexes, realtime |
| 6 | [`06_storage.sql`](./06_storage.sql) | Storage buckets + policies |
| 7 | [`07_seed_data.sql`](./07_seed_data.sql) | Default config values |

> **⚠️ PENTING:** Di file `04_functions_triggers.sql`, ganti `<YOUR_PROJECT_ID>` dengan ID proyek Supabase Anda (untuk URL Edge Function WhatsApp).

## 📊 Diagram Relasi (ERD)

```
auth.users ──1:1──▶ profiles
                       │
                       ├──1:N──▶ placements ──N:1──▶ companies
                       │              │                    │
                       │              ├──1:N──▶ attendance_logs
                       │              └──1:N──▶ daily_journals
                       │
                       ├──1:N──▶ supervisor_assignments ──N:1──▶ companies
                       ├──1:N──▶ notifications
                       ├──1:N──▶ announcements (as author)
                       └──1:N──▶ audit_logs (as actor)

app_config (standalone key-value store)
```

## 🏗️ Tabel

| Tabel | Deskripsi | Kolom Kunci |
|-------|-----------|-------------|
| `profiles` | Data user (siswa, guru, admin) | `role`, `status`, `class_name`, `device_id` |
| `companies` | Data DUDI tempat PKL | `latitude`, `longitude`, `radius` |
| `placements` | Penempatan siswa ↔ perusahaan | `student_id`, `company_id`, `status` |
| `attendance_logs` | Log kehadiran harian | `check_in_time`, `check_out_time`, `status` |
| `daily_journals` | Jurnal aktivitas siswa | `activities`, `evidence_url`, `is_approved` |
| `supervisor_assignments` | Guru pembimbing ↔ perusahaan | `teacher_id`, `company_id` |
| `announcements` | Pengumuman sekolah | `target_role`, `is_active` |
| `notifications` | Notifikasi in-app | `user_id`, `type`, `is_read` |
| `app_config` | Konfigurasi aplikasi | `key`, `value` |
| `audit_logs` | Jejak audit admin | `action`, `table_name`, `details` |

## ⚡ RPC Functions

| Function | Dipanggil Dari | Deskripsi |
|----------|---------------|-----------|
| `get_my_role()` | RLS Policies | Helper: ambil role user saat ini |
| `handle_new_user()` | Trigger auth.users | Auto-create profile on signup |
| `notify_admins_of_new_student()` | Trigger profiles | Notif admin saat siswa baru daftar |
| `create_teacher_user()` | Admin Web | Buat akun guru/supervisor |
| `check_attendance_violations()` | Admin Web (Bell) | Cek siswa bolos >3 hari + jurnal kosong |
| `count_attendance_by_grade()` | Dashboard | Statistik kehadiran per grade |
| `get_attendance_trend_by_grade()` | Dashboard | Tren kehadiran 90 hari |
| `get_class_attendance_summary()` | Dashboard | Ringkasan per kelas |
| `get_students_by_attendance_status()` | Attendance Page | List siswa + status per tanggal |
| `get_distinct_classes()` | Report/Attendance | Daftar kelas unik |

## 🪣 Storage Buckets

| Bucket | Public | Deskripsi |
|--------|--------|-----------|
| `attendances` | ✅ | Foto selfie check-in/out |
| `journal_evidence` | ✅ | Bukti jurnal (foto) |

## 📝 Catatan Migrasi

File di `supabase/migrations/` adalah riwayat perubahan incremental yang sudah diterapkan. **Jangan jalankan ulang** migration files tersebut — gunakan file setup di folder ini untuk fresh deployment.

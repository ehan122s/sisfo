# 📚 E-PKL Documentation

Folder ini berisi dokumentasi teknis proyek E-PKL.

## 📂 Struktur

```
docs/
├── README.md                    ← Anda di sini
├── SETUP.md                     ← ⭐ Panduan Setup, Instalasi & Deploy
├── database/                    ← Skema database Supabase
│   ├── README.md                ← Panduan deploy database
│   ├── 01_extensions.sql        ← PostgreSQL extensions
│   ├── 02_tables.sql            ← 10 tabel aplikasi
│   ├── 03_rls_policies.sql      ← Row Level Security
│   ├── 04_functions_triggers.sql← 9 RPC functions + triggers
│   ├── 05_views_indexes.sql     ← View, indexes, realtime
│   ├── 06_storage.sql           ← Storage buckets
│   └── 07_seed_data.sql         ← Default config values
├── prd.md                       ← Product Requirement Document
└── changelog.md                 ← Riwayat perubahan
```

## 🚀 Mulai dari Mana?

**Baru pertama kali deploy?** Baca [**SETUP.md**](./SETUP.md) — panduan lengkap dari nol.

**Hanya perlu setup database?** Baca [**database/README.md**](./database/README.md).


# 🚀 Panduan Setup, Instalasi & Deploy — E-PKL

Panduan lengkap untuk menyiapkan dan men-deploy seluruh ekosistem E-PKL di lingkungan baru.

---

## 📋 Daftar Isi

1. [Prasyarat](#-prasyarat)
2. [Arsitektur Sistem](#-arsitektur-sistem)
3. [TAHAP 1 — Setup Supabase](#-tahap-1--setup-supabase)
4. [TAHAP 2 — Setup Admin Web (Vercel)](#-tahap-2--setup-admin-web-vercel)
5. [TAHAP 3 — Setup Flutter App (Android)](#-tahap-3--setup-flutter-app-android)
6. [TAHAP 4 — Setup Flutter App (iOS)](#-tahap-4--setup-flutter-app-ios)
7. [TAHAP 5 — Deploy Edge Functions](#-tahap-5--deploy-edge-functions)
8. [Post-Deploy Checklist](#-post-deploy-checklist)
9. [Konfigurasi Opsional](#-konfigurasi-opsional)
10. [Troubleshooting](#-troubleshooting)

---

## 📦 Prasyarat

### Akun & Layanan

| Layanan | Kegunaan | Link |
|---------|----------|------|
| **Supabase** | Database, Auth, Storage, Edge Functions | [supabase.com](https://supabase.com) |
| **Vercel** | Hosting admin web | [vercel.com](https://vercel.com) |
| **GitHub** | Source code repository | [github.com](https://github.com) |
| **Google Cloud** | Google Maps API Key | [console.cloud.google.com](https://console.cloud.google.com) |
| **Google Play Console** | Publish Android app | [play.google.com/console](https://play.google.com/console) |
| **Apple Developer** | Publish iOS app (opsional) | [developer.apple.com](https://developer.apple.com) |
| **Fonnte** | WhatsApp Gateway (opsional) | [fonnte.com](https://fonnte.com) |

### Software Lokal

```bash
# Cek semua tool yang dibutuhkan
node -v          # >= 18.x
npm -v           # >= 9.x
flutter --version # >= 3.22.x (Dart SDK >= 3.10.4)
git --version     # >= 2.x
supabase --version # Supabase CLI (opsional, untuk Edge Functions)
```

| Tool | Versi Minimal | Instalasi |
|------|---------------|-----------|
| **Node.js** | 18.x | [nodejs.org](https://nodejs.org) |
| **Flutter SDK** | 3.22.x | [flutter.dev/docs/get-started](https://flutter.dev/docs/get-started/install) |
| **Android Studio** | Hedgehog+ | [developer.android.com/studio](https://developer.android.com/studio) |
| **Xcode** | 15+ (macOS only) | App Store |
| **Supabase CLI** | Latest | `npm install -g supabase` |

---

## 🏗️ Arsitektur Sistem

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   Flutter App    │     │   Admin Web      │     │   Supabase       │
│  (Android/iOS)   │────▶│   (Vercel)       │────▶│   (Backend)      │
│                  │     │                  │     │                  │
│  • Siswa         │     │  • React + Vite  │     │  • PostgreSQL DB │
│  • Guru          │     │  • TailwindCSS   │     │  • Auth          │
│  • Check-in/out  │     │  • Dashboard     │     │  • Storage       │
│  • Jurnal        │     │  • Manage Users  │     │  • Edge Functions│
│  • GPS Validate  │     │  • Reports       │     │  • Realtime      │
└─────────────────┘     └─────────────────┘     └─────────────────┘
                                                         │
                                                    ┌────┴────┐
                                                    │ Fonnte  │
                                                    │WhatsApp │
                                                    │ Gateway │
                                                    └─────────┘
```

---

## 🗄️ TAHAP 1 — Setup Supabase

### 1.1 Buat Project Baru

1. Login ke [supabase.com](https://supabase.com)
2. Klik **"New Project"**
3. Isi:
   - **Name**: `e-pkl` (atau nama klien)
   - **Database Password**: **simpan baik-baik!** (untuk akses langsung ke DB)
   - **Region**: pilih yang terdekat (misal: `Southeast Asia (Singapore)`)
4. Tunggu hingga project status `ACTIVE_HEALTHY`

### 1.2 Catat Kredensial

Buka **Project Settings** → **API**, catat:

| Variabel | Lokasi di Dashboard | Dibutuhkan Oleh |
|----------|---------------------|-----------------|
| `Project URL` | Settings → API → URL | Admin Web, Flutter |
| `anon public key` | Settings → API → anon key | Admin Web, Flutter |
| `service_role key` | Settings → API → service_role | Edge Functions (jangan expose!) |
| `Project ID` | Settings → General | Edge Functions deployment |

> **⚠️ PENTING:** `service_role key` adalah kunci rahasia! Jangan pernah commit ke repository atau expose ke client-side.

### 1.3 Jalankan Schema SQL

Buka **SQL Editor** di Supabase Dashboard, jalankan file secara **berurutan**:

```
docs/database/01_extensions.sql    ← Enable pgcrypto & pg_net
docs/database/02_tables.sql        ← Buat 10 tabel
docs/database/03_rls_policies.sql  ← Row Level Security
docs/database/04_functions_triggers.sql  ← Functions & Triggers
docs/database/05_views_indexes.sql ← Views, Indexes, Realtime
docs/database/06_storage.sql       ← Storage Buckets
docs/database/07_seed_data.sql     ← Default Config
```

> **📝 Catatan:** Di file `04_functions_triggers.sql`, cari dan ganti semua `<YOUR_PROJECT_ID>` dengan Project ID Supabase Anda.

### 1.4 Buat Admin Pertama

1. Buka **Authentication** → **Users** → **Add user** → **Create new user**
2. Isi email dan password admin
3. Buka **SQL Editor**, jalankan:

```sql
-- Ganti 'admin@email.com' dengan email admin yang baru dibuat
UPDATE profiles
SET role = 'admin', full_name = 'Admin Utama', status = 'active'
WHERE id = (SELECT id FROM auth.users WHERE email = 'admin@email.com');
```

### 1.5 Enable Realtime (Opsional)

Jika langkah `05_views_indexes.sql` gagal untuk realtime:

1. Buka **Database** → **Replication**
2. Aktifkan tabel `attendance_logs` di **Realtime**

---

## 🌐 TAHAP 2 — Setup Admin Web (Vercel)

### 2.1 Push ke GitHub

```bash
# Clone atau fork repository
git clone <url-repository> e-pkl
cd e-pkl

# Pastikan admin-web ada
ls admin-web/
```

### 2.2 Buat File Environment

Buat file `admin-web/.env` (atau `.env.local`) — **jangan commit file ini!**

```env
VITE_SUPABASE_URL=https://<project-id>.supabase.co
VITE_SUPABASE_ANON_KEY=<anon-public-key-dari-supabase>
VITE_GOOGLE_MAPS_API_KEY=<google-maps-api-key>
```

> Tambahkan `.env` dan `.env.local` ke `.gitignore` admin-web jika belum ada.

### 2.3 Test Lokal

```bash
cd admin-web
npm install
npm run dev
# Buka http://localhost:5173
# Login dengan akun admin yang dibuat di Tahap 1.4
```

### 2.4 Deploy ke Vercel

#### Opsi A: Via Vercel Dashboard (Disarankan)

1. Login ke [vercel.com](https://vercel.com)
2. Klik **"Add New..."** → **"Project"**
3. Import repository GitHub
4. Setting:
   - **Framework Preset**: `Vite`
   - **Root Directory**: `admin-web`
   - **Build Command**: `npm run build`
   - **Output Directory**: `dist`
5. Tambahkan **Environment Variables** (klik Configure):

   | Key | Value |
   |-----|-------|
   | `VITE_SUPABASE_URL` | `https://<project-id>.supabase.co` |
   | `VITE_SUPABASE_ANON_KEY` | `<anon-public-key>` |
   | `VITE_GOOGLE_MAPS_API_KEY` | `<google-maps-api-key>` |

6. Klik **Deploy**

#### Opsi B: Via Vercel CLI

```bash
npm i -g vercel
cd admin-web
vercel
# Ikuti prompt, pilih root directory = admin-web
# Tambahkan env variables di dashboard Vercel
```

### 2.5 Setup Custom Domain (Opsional)

1. Di Vercel Dashboard → project → **Settings** → **Domains**
2. Tambahkan custom domain
3. Update DNS record sesuai instruksi Vercel

---

## 📱 TAHAP 3 — Setup Flutter App (Android)

### 3.1 Update Kredensial Supabase

Edit file `lib/src/services/supabase_config.dart`:

```dart
class SupabaseConfig {
  // ← GANTI dengan kredensial Supabase project baru
  static const String supabaseUrl = 'https://<project-id>.supabase.co';
  static const String supabaseAnonKey = '<anon-public-key>';

  static Future<void> initialize() async {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }
}
```

### 3.2 Update Google Maps API Key

Edit file `android/app/src/main/AndroidManifest.xml`:

```xml
<meta-data android:name="com.google.android.geo.API_KEY"
       android:value="<GOOGLE_MAPS_API_KEY_ANDA>"/>
```

> **📝 Google Maps API Key:**
> 1. Buka [Google Cloud Console](https://console.cloud.google.com)
> 2. Buat project baru atau pilih yang ada
> 3. Enable **Maps SDK for Android**, **Maps SDK for iOS**, dan **Maps JavaScript API**
> 4. Buat API Key di **Credentials**
> 5. (Disarankan) Batasi key hanya untuk package name / bundle ID Anda

### 3.3 Update Identitas Aplikasi

#### Package Name (Application ID)

File: `android/app/build.gradle.kts`

```kotlin
defaultConfig {
    applicationId = "com.namaklien.aplikasi"  // ← Ganti sesuai klien
    // ...
}
```

File: `android/app/src/main/AndroidManifest.xml`

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.namaklien.aplikasi">  <!-- ← Samakan -->
```

#### Nama Aplikasi

File: `android/app/src/main/AndroidManifest.xml`

```xml
<application
    android:label="Nama Aplikasi"  <!-- ← Ganti nama tampilan -->
```

#### Ikon Aplikasi

Ganti file di:
- `android/app/src/main/res/mipmap-*/ic_launcher.png`

Gunakan tool: [appicon.co](https://www.appicon.co/) atau package `flutter_launcher_icons`.

### 3.4 Setup Release Signing (Android)

> **⚠️ WAJIB untuk Production Build & Play Store!**

#### a. Buat Keystore

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload-key
```

Simpan file `.jks` dan password di tempat aman — **JANGAN hilangkan!**

#### b. Buat `key.properties`

Buat file `android/key.properties` (**jangan commit!**):

```properties
storePassword=<password-keystore>
keyPassword=<password-key>
keyAlias=upload-key
storeFile=<lokasi-absolut>/upload-keystore.jks
```

Tambahkan ke `android/.gitignore`:
```
key.properties
*.jks
```

#### c. Update `build.gradle.kts`

Edit `android/app/build.gradle.kts`:

```kotlin
import java.util.Properties
import java.io.FileInputStream

// Load key.properties
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    // ... existing config ...

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}
```

### 3.5 Build Release APK

```bash
# Install dependencies
flutter pub get

# Build APK 
flutter build apk --release

# Output: build/app/outputs/flutter-apk/app-release.apk
```

Atau build App Bundle untuk Play Store:

```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### 3.6 Publish ke Google Play Store

1. Buka [Google Play Console](https://play.google.com/console)
2. Buat aplikasi baru
3. Upload `.aab` ke **Production** → **Create new release**
4. Isi Store Listing (screenshot, deskripsi, dll)
5. Submit untuk review

---

## 🍎 TAHAP 4 — Setup Flutter App (iOS)

### 4.1 Prasyarat iOS

- macOS dengan **Xcode 15+**
- Apple Developer Account ($99/tahun)
- CocoaPods: `sudo gem install cocoapods`

### 4.2 Update Identitas

Edit di Xcode:

1. Buka `ios/Runner.xcworkspace` di Xcode
2. Pilih **Runner** target → **General**:
   - **Display Name**: `Nama Aplikasi`
   - **Bundle Identifier**: `com.namaklien.aplikasi`
   - **Version**: `1.1.0`
   - **Build**: `2`
3. Pilih **Signing & Capabilities**:
   - Team: Pilih Apple Developer Team
   - Signing Certificate: Automatic

### 4.3 Update Google Maps (iOS)

Edit `ios/Runner/AppDelegate.swift`:

```swift
import Flutter
import UIKit
import GoogleMaps  // Tambahkan jika belum ada

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("<GOOGLE_MAPS_API_KEY>")  // Tambahkan
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

> **📝 Privacy Descriptions** sudah dikonfigurasi di `ios/Runner/Info.plist`:
> - `NSLocationWhenInUseUsageDescription` — Lokasi untuk validasi kehadiran
> - `NSCameraUsageDescription` — Kamera untuk foto selfie
> - `NSPhotoLibraryUsageDescription` — Galeri untuk upload bukti

### 4.4 Build & Publish iOS

```bash
cd ios && pod install && cd ..
flutter build ipa --release
```

Upload ke App Store via **Transporter** app atau `xcrun altool`.

---

## ⚡ TAHAP 5 — Deploy Edge Functions

### 5.1 Install Supabase CLI

```bash
npm install -g supabase
supabase login
```

### 5.2 Link Project

```bash
cd e-pkl
supabase link --project-ref <project-id>
```

### 5.3 Deploy Functions

```bash
# Deploy send-whatsapp function
supabase functions deploy send-whatsapp --no-verify-jwt

# Deploy import-students function
supabase functions deploy import-students --no-verify-jwt
```

> **📝 Catatan**: `--no-verify-jwt` digunakan karena kedua function memiliki autentikasi internal sendiri (JWT check di dalam kode).

### 5.4 Verifikasi

```bash
# Cek status functions
supabase functions list
```

Atau buka **Supabase Dashboard** → **Edge Functions** untuk melihat functions yang sudah deploy.

---

## ✅ Post-Deploy Checklist

### Database
- [ ] Semua 7 file SQL sudah dijalankan berurutan
- [ ] `<YOUR_PROJECT_ID>` sudah diganti di `04_functions_triggers.sql`
- [ ] Admin pertama sudah dibuat dan role-nya `admin`
- [ ] Realtime untuk `attendance_logs` sudah aktif

### Admin Web (Vercel)
- [ ] Build berhasil tanpa error
- [ ] 3 environment variables sudah diset di Vercel
- [ ] Login dengan akun admin berhasil
- [ ] Dashboard menampilkan data dengan benar
- [ ] Google Maps berfungsi (check di halaman DUDI)

### Flutter App  
- [ ] `supabase_config.dart` sudah diupdate dengan URL & key baru
- [ ] Google Maps API Key sudah diganti (Android + iOS)
- [ ] Application ID / Bundle ID sudah diganti
- [ ] Nama dan ikon aplikasi sudah diganti
- [ ] Release signing sudah dikonfigurasi
- [ ] Login berhasil di device/emulator
- [ ] Check-in/out dengan GPS berfungsi
- [ ] Foto selfie bisa diupload

### Edge Functions
- [ ] `send-whatsapp` sudah deploy
- [ ] `import-students` sudah deploy
- [ ] WhatsApp gateway sudah dikonfigurasi (jika dipakai)

---

## ⚙️ Konfigurasi Opsional

### WhatsApp Gateway (Fonnte)

1. Daftar di [fonnte.com](https://fonnte.com)
2. Hubungkan nomor WhatsApp
3. Dapatkan API Token
4. Update di Supabase SQL Editor:

```sql
UPDATE app_config SET value = 'https://api.fonnte.com/send' WHERE key = 'WA_GATEWAY_URL';
UPDATE app_config SET value = '<TOKEN_FONNTE_ANDA>' WHERE key = 'WA_API_KEY';
```

### Google Maps API Restrictions

Untuk keamanan, batasi API Key:

1. Buka [Google Cloud Console](https://console.cloud.google.com) → **Credentials**
2. Klik API Key → **Restrictions**:
   - **Android**: Tambahkan package name + SHA-1 fingerprint
   - **iOS**: Tambahkan Bundle ID
   - **Web** (admin-web): Tambahkan domain Vercel

### Supabase Auth Settings

Buka **Authentication** → **Settings**:

- **Site URL**: `https://domain-admin-web.vercel.app`
- **Redirect URLs**: tambahkan URL admin web
- **Email Templates**: sesuaikan template email (opsional)
- **Rate Limits**: sesuaikan jika traffic tinggi

---

## 🔧 Troubleshooting

### Admin Web

| Masalah | Solusi |
|---------|--------|
| Error `Missing Supabase environment variables` | Cek env variables di Vercel sudah benar, redeploy |
| Google Maps tidak muncul | Cek API key, pastikan Maps JavaScript API di-enable |
| Login gagal | Cek Supabase URL/key, cek user sudah ada di Auth |
| Build error di Vercel | Pastikan `Root Directory` = `admin-web`, Framework = `Vite` |

### Flutter App

| Masalah | Solusi |
|---------|--------|
| GPS tidak akurat | Pastikan permission FINE_LOCATION diizinkan |
| Foto gagal upload | Cek storage bucket `attendances` sudah dibuat |
| Login loop | Cek URL/key di `supabase_config.dart` benar |
| Build error `Execution failed for task ':app:mergeReleaseResources'` | Run `flutter clean && flutter pub get` |
| iOS `pod install` error | Run `cd ios && pod deintegrate && pod install` |

### Supabase

| Masalah | Solusi |
|---------|--------|
| RPC function tidak ditemukan | Pastikan file `04_functions_triggers.sql` sudah dijalankan |
| RLS error "new row violates policy" | Cek user memiliki role yang benar di `profiles` |
| Edge Function 500 | Cek logs di Supabase Dashboard → Edge Functions → Logs |
| WhatsApp tidak terkirim | Cek `app_config` table memiliki key/value yang benar |

---

## 📁 Struktur File Penting

```
E-PKL/
├── admin-web/                   ← Admin Dashboard (React + Vite)
│   ├── src/
│   │   ├── lib/supabase.ts      ← ⚙️ Supabase client (env vars)
│   │   └── features/            ← Fitur-fitur admin
│   ├── .env                     ← 🔑 BUAT FILE INI (jangan commit!)
│   └── package.json
│
├── lib/                         ← Flutter App Source
│   └── src/
│       └── services/
│           └── supabase_config.dart  ← ⚙️ EDIT URL & KEY DI SINI
│
├── android/
│   ├── app/
│   │   ├── build.gradle.kts     ← ⚙️ Application ID & Signing
│   │   ├── proguard-rules.pro   ← Proguard config
│   │   └── src/main/
│   │       └── AndroidManifest.xml  ← ⚙️ Google Maps Key & Permissions
│   └── key.properties           ← 🔑 BUAT FILE INI (jangan commit!)
│
├── ios/Runner/
│   ├── Info.plist               ← Privacy descriptions (sudah set)
│   └── AppDelegate.swift        ← ⚙️ Google Maps Key (iOS)
│
├── supabase/
│   └── functions/               ← Edge Functions
│       ├── send-whatsapp/       ← Notifikasi WhatsApp
│       └── import-students/     ← Import siswa batch
│
├── docs/
│   ├── database/                ← 7 file SQL setup (urut 01-07)
│   └── SETUP.md                 ← 📄 ANDA DI SINI
│
└── pubspec.yaml                 ← Flutter dependencies
```

---

## 📞 Kontak Dukungan

Jika mengalami kendala, hubungi developer:

- **Email**: _[isi email developer]_
- **WhatsApp**: _[isi nomor developer]_

---

> **📌 Versi Dokumen**: 1.0 — Terakhir diupdate: Februari 2026

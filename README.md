# Bun Atelier — "Worth the Mess." 🍔

A modern, editorial burger ordering mobile application built for final academic project (Tugas Akhir Sistem Informasi).

---

## 🛠️ Tech Stack

- **Frontend (Mobile):** Flutter 3.47+ (Dart 3.13+), Riverpod, GoRouter, Dio, SQLite (`sqflite`), `flutter_secure_storage`, `local_auth` (Biometrics), `geolocator`, `flutter_map` (OpenStreetMap), `sensors_plus` (Accelerometer/Gyroscope), `flutter_local_notifications`, `timezone`, GoogleFonts (*DM Serif Display* & *DM Sans*).
- **Authentication:** Customer registration and login use Supabase Auth; legacy customer accounts are migrated when their local account record is available. Admin accounts remain local.
- To mirror Auth users into `public.users`, run [`supabase_auth_users_sync.sql`](./supabase_auth_users_sync.sql) once in the Supabase SQL Editor. It also backfills existing Auth users.
- **Backend (REST API):** Node.js 20+, Express, TypeScript, Prisma ORM, Argon2id, JWT, Zod, Gemini API.
- **Database:**
  - **Online Database:** PostgreSQL hosted on **Supabase** (handled via Prisma ORM).
  - **Local Database:** SQLite (`sqflite`) for offline menu cache, persistent cart, and user preferences.

---

## 📁 Project Structure

```text
d:\PAMobile/
├── mobile/                   # Flutter Mobile App
│   ├── assets/               # Images, icons, fonts
│   ├── lib/
│   │   ├── app/              # Theme, brand colors, app root
│   │   ├── core/             # Network (Dio), constants, secure storage
│   │   ├── data/             # SQLite local database & DAOs
│   │   ├── features/         # Modular feature-driven screens & state
│   │   ├── routing/          # GoRouter configuration
│   │   └── main.dart         # Entry point
│   └── pubspec.yaml
│
├── backend/                  # Node.js + Express + TypeScript REST API
│   ├── prisma/               # Prisma schema & seed scripts
│   ├── src/
│   │   ├── config/           # Prisma client, env loader
│   │   ├── middleware/       # Error handler, JWT auth guards
│   │   ├── routes/           # REST endpoints
│   │   └── app.ts            # Server entry point
│   ├── .env.example          # Environment template
│   └── package.json
│
└── docs/                     # Academic Documentation
```

---

## 🚀 Getting Started

### 1. Setup Backend & Supabase Database
1. Buka folder `backend/`:
   ```bash
   cd backend
   ```
2. Salin `.env.example` ke `.env`:
   ```bash
   cp .env.example .env
   ```
3. Buka Dashboard **[Supabase](https://supabase.com)**:
   - Buat project baru (misal: `bun-atelier-db`).
   - Masuk ke **Project Settings** -> **Database** -> **Connection String**.
   - Salin URI **Connection pooling** (port 6543) ke `DATABASE_URL` di `.env`.
   - Salin URI **Direct connection** (port 5432) ke `DIRECT_URL` di `.env`.
4. Jalankan migrasi tabel ke Supabase:
   ```bash
   npx prisma db push
   ```
5. Jalankan backend development server:
   ```bash
   npm run dev
   ```
   Server akan berjalan di `http://localhost:3000`. Cek kesehatan server di `http://localhost:3000/api/health`.
6. Pastikan `GEMINI_API_KEY` di `backend/.env` berisi API key dari Google AI Studio (bukan nilai contoh), lalu jalankan ulang backend setelah mengubah `.env`. Endpoint `/api/health` harus menampilkan `"geminiConfigured": true`. API key hanya disimpan di backend—jangan masukkan ke aplikasi Flutter.

### 2. Setup & Jalankan Mobile App (Flutter)
1. Buka folder `mobile/`:
   ```bash
   cd mobile
   ```
2. Ambil seluruh dependensi:
   ```bash
   flutter pub get
   ```
3. Jalankan aplikasi:
   - Untuk Android Emulator / HP Fisik:
     ```bash
     flutter run
     ```
   - Untuk Web Preview:
     ```bash
     flutter run -d chrome
     ```
   Android Emulator menggunakan `http://10.0.2.2:3000/api` secara default. Untuk HP fisik yang berada di Wi-Fi yang sama, gunakan IP lokal komputer yang menjalankan backend:
   ```bash
   flutter run --dart-define=API_BASE_URL=http://192.168.x.x:3000/api
   ```
   Ganti `192.168.x.x` dengan IP komputer yang sebenarnya dan pastikan firewall mengizinkan koneksi ke port `3000`. Untuk rilis produksi, gunakan URL backend HTTPS.

---

## 🎨 Design System Palette

- **Background utama:** Cream (`#FFF4DE`)
- **Primary accent:** Coral (`#F2674B`)
- **Secondary accent:** Forest Green (`#203D2B`)
- **Teks gelap:** Espresso (`#39251F`)
- **Highlight:** Butter Yellow (`#F4D98B`)

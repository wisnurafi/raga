# Raga — Kalkulator BMI

**Raga** adalah aplikasi kalkulator BMI (Body Mass Index) berbasis Flutter.
Selain menghitung BMI, Raga menyimpan riwayat, menampilkan grafik tren,
menghitung berat badan ideal, BMR, dan kebutuhan kalori harian (TDEE),
mendukung banyak profil, dan bisa membagikan hasil sebagai gambar.

Dibuat sebagai tugas mata kuliah **Pemrograman Mobile**.

## Fitur

**Wajib:**
- Input tinggi badan (cm/inci)
- Input berat badan (kg/lb)
- Hitung BMI otomatis
- Indikator visual gauge + warna per kategori
- Kategori: Underweight, Normal, Overweight, Obese
- Tips kesehatan sesuai kategori (bahasa Indonesia yang mudah dipahami)

**Nilai plus:**
- **Riwayat + grafik tren** — tiap hasil bisa disimpan, grafik berat/BMI per bulan
- **Kalkulator pelengkap** — berat badan ideal, BMR (Mifflin-St Jeor), TDEE + level aktivitas
- **Multi-profil** — hitung BMI untuk keluarga/teman dalam satu aplikasi
- **Bagikan hasil** — ekspor kartu hasil sebagai gambar
- **Mode gelap/terang** + toggle satuan metrik/imperial
- **Sinkronisasi cloud** (Supabase) — cadangan otomatis, tetap jalan 100% offline

## Tangkapan layar

Tangkapan layar akan ditambahkan setelah build pertama di perangkat.
Sementara itu, install APK dari [halaman Release](../../releases/tag/latest)
untuk mencoba langsung.

## Cara menjalankan

Butuh [Flutter](https://docs.flutter.dev/get-started/install) 3.47+.

```bash
flutter pub get
flutter run
```

Build APK release secara manual:

```bash
flutter build apk --release
```

> Catatan: tiap push ke `main` otomatis memicu GitHub Actions yang
> membangun APK dan menempelkannya di [Release "latest"](../../releases/tag/latest).
> Jadi cara termudah dapat APK: download dari sana.

## Konfigurasi Supabase (opsional)

Tanpa konfigurasi ini aplikasi tetap jalan penuh secara lokal.
Supabase dipakai untuk cadangan cloud tiap riwayat yang disimpan.

1. Buat project gratis di [supabase.com](https://supabase.com).
2. Di **Authentication → Sign In / Up**, aktifkan **Allow anonymous sign-ins**.
3. Di **SQL Editor**, jalankan schema berikut:

```sql
create table bmi_records (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  profile_id text not null,
  height_cm double precision not null,
  weight_kg double precision not null,
  bmi double precision not null,
  category text not null,
  created_at timestamptz default now()
);

alter table bmi_records enable row level security;

create policy "own rows"
  on bmi_records for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
```

4. Ambil **Project URL** dan **anon key** dari **Project Settings → API**.
5. Untuk build lokal:

```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://xxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=xxx
```

Untuk GitHub Actions, isi sebagai repository secrets
`SUPABASE_URL` dan `SUPABASE_ANON_KEY` (Settings → Secrets → Actions).
Workflow `supabase-keepalive.yml` memakai secrets yang sama untuk
ping tiap jam agar project free-tier tidak pause.

## Struktur proyek

```
lib/
  main.dart            # entry point, theme mode, bottom nav shell
  core/
    bmi.dart           # rumus BMI, kategori, berat ideal, BMR, TDEE
    tips.dart          # tips kesehatan per kategori
    theme.dart         # tema ungu Raga (gelap & terang)
  models/              # Profile, BmiRecord
  state/app_state.dart # state global (ChangeNotifier sederhana)
  data/
    local_store.dart   # penyimpanan lokal (sumber kebenaran utama)
    cloud_sync.dart    # sinkronisasi Supabase (opsional, gagal diam-diam)
  widgets/             # gauge, floating nav, kartu input, chips
  screens/             # Hitung, Hasil, Riwayat, Kesehatan, Profil
```

## Privasi

Raga tidak punya iklan, tidak punya analytics, dan tidak menjual data.
Detail lengkap: [PRIVACY.md](PRIVACY.md).

## Lisensi

MIT — lihat [LICENSE](LICENSE).

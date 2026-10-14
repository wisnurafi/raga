# Contributing — Raga

Terima kasih sudah tertarik berkontribusi!

## Cara mulai

1. Butuh Flutter 3.47+ — lihat [panduan install resmi](https://docs.flutter.dev/get-started/install).
2. Clone repo ini, lalu:

```bash
flutter pub get
flutter run
```

3. Pastikan `flutter analyze` lolos tanpa issue sebelum push.

## Aturan main

- **Satu perubahan, satu commit.** Pesan commit yang jelas, mis.
  `feat(riwayat): tambah filter per profil`.
- Jangan commit file rahasia: API key, `.env`, atau keystore.
  Kredensial Supabase hanya lewat `--dart-define` / GitHub Secrets.
- Copywriting aplikasi berbahasa Indonesia yang mudah dipahami orang awam.
  Hindari istilah teknis di teks yang dilihat pengguna.
- Ikuti gaya desain yang ada (tema ungu, kartu membulat). Kalau mau
  mengubah tampilan secara signifikan, diskusikan dulu lewat *issue*.

## Melaporkan bug

Buka *issue* baru dengan format:

- **Langkah reproduksi:** ...
- **Yang terjadi:** ...
- **Yang seharusnya:** ...
- **Perangkat:** (mis. Redmi Note 12, Android 13)

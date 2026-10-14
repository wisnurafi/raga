# Inventaris Visual — Raga Light Mode (Batch A, 7 layar)

Skala referensi: 780×1688 px. Semua estimasi font-size dihitung dari tinggi aktual glyph
(cap height ≈ 0,7 × font-size untuk Manrope). Warna di-sample dengan PIL dari piksel aktual.
`[tidak terbaca]` = teks tidak terbukti dari gambar.

Konvensi warna global yang konsisten di semua 7 layar:
- Teks utama: `#181838` (≈ `#1D1B3A` kontrak)
- Teks sekunder: `#585080` (≈ `#5A5490` kontrak)
- Teks sekunder terang (footnote): `#7870A0`
- Aksen ungu: `#A99BE8` / `#A896E4`; gradient tombol `#AEA2EA → #9684DE`
- Kartu: putih `#F6F6FC` / `#FCFCFC`
- Hijau kategori Normal: `#5EE0A0` (pill), teks di atasnya GELAP `#001820`
- Background: gradient lavender terang `#E3E1F9 → #EDEBF9 → #D8D2F0` + artwork
  ranting daun (mint), lingkaran konsentris (kiri atas), garis ECG (mint, tengah).
  Semua 7 layar memakai background artwork yang sama.
- Padding layar: ±45 px (konten x45–735). Radius kartu besar: ±40–48 px.
- Tombol utama: full-width, tinggi ±130 px, fully rounded, gradient ungu,
  **teks GELAP** `#181838` (bukan putih!) — konsisten di semua layar.

---

## G0 — `c3298e74...jpg` → Onboarding 1/4

**Transkrip teks (persis):**
- "1/4"
- "Kenalan dulu, yuk"
- "Biar Raga bisa menyapamu dan menghitung dengan tepat."
- "Nama panggilan"
- "Wisnu"
- "Umur"
- "21"
- "Jenis kelamin"
- "Pria" (terpilih)
- "Wanita"
- "Lanjut"

**Struktur top→bottom:**
1. Bar atas: tombol back (lingkaran putih, chevron gelap) | progress 4 segmen
   (segmen 1 aktif ungu `#A99BE8`, sisanya `#DED8F0`) | "1/4" gelap.
2. Judul "Kenalan dulu, yuk" (~56–60 px, 800, `#181838`), subjudul 1 baris
   (~30–32 px, 400, `#585080`).
3. Kartu "Nama panggilan": label sekunder (~30 px, 500); nilai "Wisnu"
   (~56 px, 800, gelap). Kartu putih radius ±44.
4. Kartu "Umur": label sekunder kiri; stepper tengah-kanan: tombol "−"
   (lingkaran putih + border), "21" (~56 px, 800), tombol "+" (lingkaran putih + border).
5. Label "Jenis kelamin" (sekunder, ~32 px, 500) — BUKAN di dalam kartu.
6. Dua kartu opsi: "Pria" (TERPILIH: fill lavender `#D2CCF0`, border ungu,
   ikon lingkaran putih berisi simbol Mars gelap, label ~40 px 700 gelap)
   dan "Wanita" (putih, ikon lingkaran berisi simbol Venus gelap).
7. Tombol "Lanjut" (gradient ungu, teks gelap ~40–44 px, 700).

**Warna kunci:** teks `#181838`; sekunder `#585080`; kartu `#F6F6FC`;
gender aktif `#D2CCF0`; tombol `#AEA2EA→#9684DE` + teks `#181840`;
back button `#F6F6FC`; progress aktif `#A99BE8`, nonaktif `#DED8F0`.

**Layout:** padding 45; gap judul→kartu ±35; gap antar kartu ±30;
kartu nama x±60–735, y±355–520 (h±165, radius ±44);
tombol y±1525–1655 (h±130).

**Bottom nav:** tidak ada (onboarding). **Background:** artwork penuh (daun + lingkaran + ECG).

---

## G1 — `70846859...jpg` → Onboarding 2/4

**Transkrip teks (persis):**
- "2/4"
- "Ukuran tubuhmu"
- "Dipakai untuk menghitung BMI awalmu."
- "cm · kg" (terpilih) | "in · lb"
- "Tinggi badan" | "170" | "cm"
- "Berat badan" | "65" | "kg"
- "BMI awalmu" | "22.5" | "Normal"
- "Lanjut"

**Struktur top→bottom:**
1. Bar atas: back | progress (2 segmen aktif) | "2/4".
2. Judul "Ukuran tubuhmu" (~60 px, 800); subjudul (~30–32 px, 400, sekunder).
3. Unit toggle kanan-atas: container abu-lavender `#C6D8E4` (pill),
   opsi aktif "cm · kg" = pill putih `#FCFCFC` teks gelap 700,
   "in · lb" teks gelap non-aktif. Tinggi ±80, opsi aktif radius penuh.
4. Kartu "Tinggi badan": label sekunder (~32 px, 500); "170" (~88–96 px, 800)
   + "cm" (~32 px, 500) sebaris; slider: track aktif ungu `#A896E4`,
   track nonaktif `#DED8F0`, thumb lingkaran putih + border ungu.
5. Kartu "Berat badan": pola sama, "65" + "kg".
6. Kartu ringkas "BMI awalmu": label gelap (~36 px, 700); "22.5" (~40 px, 800);
   pill hijau `#5ADE9C` berisi "Normal" teks GELAP `#001820` (~32 px, 700).
7. Tombol "Lanjut" (sama seperti G0).

**Warna kunci:** teks `#181838`; sekunder `#585080`; toggle container `#C6D8E4`,
pill aktif `#FCFCFC`; slider aktif `#A896E4`, nonaktif `#DED8F0`;
pill Normal `#5ADE9C` + teks `#001820`.

**Layout:** padding 45; kartu tinggi y±505–790 (h±285); kartu BMI y±1080–1230;
tombol y±1425–1660.

**Bottom nav:** tidak ada. **Background:** artwork penuh.

---

## G2 — `415b1f3e...jpg` → Onboarding 3/4

**Transkrip teks (persis):**
- "3/4"
- "OPSIONAL"
- "Punya target berat?"
- "Atur sekarang atau nanti di Profil. Boleh dilewati."
- "Turun" (terpilih) | "Jaga" | "Naik"
- "62" | "kg"
- "Sekarang 65 kg · selisih −3.0 kg"
- "BMI target 21.5 · Normal"
- "Laju per minggu"
- "0.25 kg" | "0.5 kg" (terpilih) | "0.75 kg"
- "Perkiraan tercapai" | "±6 minggu · 25 Nov"
- "Simpan target"
- "Lewati dulu"

**Struktur top→bottom:**
1. Bar atas: back | progress (3 segmen aktif) | "3/4".
2. Badge "OPSIONAL": pill kecil, teks hijau `#206858` (~28 px, 700),
   fill lavender muda `#EAE4FC`, border hijau.
3. Judul "Punya target berat?" (~60 px, 800); subjudul (~30 px, 400, sekunder).
4. Kartu target: segmented control 3 opsi — "Turun" TERPILIH (fill `#A896E4`,
   teks gelap `#201848`, ~36 px 700), "Jaga"/"Naik" (fill `#E4E4F0`, teks gelap).
   Stepper: "−" | "62" (~112 px, 800) + "kg" (~40 px, 500) | "+".
   "Sekarang 65 kg · selisih −3.0 kg" (gelap, ~32 px, 500, rata tengah).
   Pill "BMI target 21.5 · Normal" (fill `#5ADE9C`, teks gelap `#001820`, ~32 px, 700).
5. Kartu "Laju per minggu": label sekunder (~32 px, 500); 3 pill opsi —
   "0.5 kg" TERPILIH (fill `#D8D2F6`, border ungu), lainnya putih;
   teks gelap ~36 px, 700.
   Baris "Perkiraan tercapai" (gelap, ~32 px, 500) kiri dan
   "±6 minggu · 25 Nov" (gelap, ~32 px, 700) kanan.
6. Tombol "Simpan target" (gradient ungu, teks gelap).
7. Text-button "Lewati dulu" (sekunder `#585088`, ~36 px, 500, rata tengah).

**Warna kunci:** OPSIONAL teks `#206858`; segmen aktif `#A896E4`;
pill BMI target `#5ADE9C`; pace terpilih `#D8D2F6`; tombol + "Lewati dulu" `#585088`.

**Layout:** padding 45; dua kartu putih besar; tombol + text-button di bawah
("Lewati dulu" y±1580–1600).

**Bottom nav:** tidak ada. **Background:** artwork penuh.

---

## G3 — `a5254dd4...jpg` → Onboarding 4/4

**Transkrip teks (persis):**
- "4/4"
- "OPSIONAL"
- "Jadwal menimbang"
- "Pilih hari dan jam, Raga akan mengingatkanmu. Boleh dilewati."
- "Sen" (terpilih) | "Sel" | "Rab" | "Kam" (terpilih) | "Jum" | "Sab" | "Min"
- "Jam pengingat" | "07:00"
- "Ringkasan" | "2× seminggu · Sen & Kam · 07.00"
- "Bisa diubah kapan saja di Profil."
- "Selesai"
- "Lewati dulu"

**Struktur top→bottom:**
1. Bar atas: back | progress (4 segmen aktif) | "4/4".
2. Badge "OPSIONAL" (sama seperti G2).
3. Judul "Jadwal menimbang" (~60 px, 800); subjudul 2 baris (~30 px, 400, sekunder).
4. Deretan 7 day-chip (Sen–Min): TERPILIH (Sen, Kam) = fill ungu `#A896E4`,
   label teks GELAP `#201840` (~28–30 px, 700) + **dot gelap** kecil di bawah label;
   tak terpilih = putih, teks gelap. Chip ±90×150 px, radius ±28.
5. Kartu "Jam pengingat": label sekunder `#585080` (~32 px, 500);
   "07:00" (~88–96 px, 800, gelap) kiri; switch kanan = ON
   (track ungu `#A99BE8` ±100×40 px, knob lingkaran putih di kanan).
6. Pill "Ringkasan": "Ringkasan" gelap (~32 px, 700) kiri,
   "2× seminggu · Sen & Kam · 07.00" gelap (~32 px, 500) kanan.
7. "Bisa diubah kapan saja di Profil." (`#7870A0`, ~30 px, 400, rata tengah).
8. Tombol "Selesai" + text-button "Lewati dulu".

**Warna kunci:** chip terpilih `#A896E4` + teks gelap `#201840` (bukan putih!);
switch ON `#A99BE8`; footnote `#7870A0`.

**Layout:** padding 45; chips 7 kolom penuh; kartu jam y±690–930;
pill ringkasan y±960–1040; tombol + lewati di bawah.

**Bottom nav:** tidak ada. **Background:** artwork penuh.

---

## G4 — `5eb94c94...jpg` → Home "Hitung BMI"

**Transkrip teks (persis):**
- "W" (avatar)
- "Hitung BMI" (judul)
- "Wisnu" (terpilih, ada ✓) | "Ibu" | "Dika" | "+ Tambah"
- "Data tubuh" | "cm · kg" (terpilih) | "in · lb"
- "Tinggi badan" | "170" | "cm"
- "Berat badan" | "65" | "kg"
- "Pria" (terpilih) | "Wanita" | "21 tahun"
- "Hitung BMI" (tombol)

**Struktur top→bottom:**
1. Header: avatar lingkaran "W" (fill `#E4C6A8`, teks `#382010`, ~40 px 800)
   kiri; judul "Hitung BMI" (~48–56 px, 800) tengah; tombol theme
   (lingkaran fill `#E4F6F0`, ikon bulan sabit gelap) kanan.
2. Deretan chip profil (horizontal): "Wisnu ✓" TERPILIH
   (fill `#D2C6F0`, border ungu, teks gelap ~36 px 700 + ikon centang);
   "Ibu", "Dika", "+ Tambah" putih, teks gelap. Chip ±80 px tinggi, pill.
3. Kartu "Data tubuh" (putih, radius ±48): baris judul "Data tubuh"
   (~36–40 px, 700/800, gelap) + unit toggle kanan (pola G1);
   blok "Tinggi badan" (label sekunder, "170" ~88–96/800 + "cm", slider);
   blok "Berat badan" (pola sama, "65" + "kg").
4. Kartu gender/umur: segmented "Pria" (TERPILIH, fill `#A896E4`, teks gelap)
   / "Wanita" (fill `#E4E4F0`); "21 tahun" (~40 px, 700, gelap) kanan.
5. Tombol "Hitung BMI" (gradient ungu, teks gelap).
6. Bottom nav pill: putih/translucent, 4 tab TANPA label —
   tab 1 AKTIF (lingkaran ungu `#A89CEA→#9684DE`, ikon kalkulator putih),
   tab 2–4 nonaktif (ikon `#585088`: chart garis, hati, profil).

**Warna kunci:** avatar `#E4C6A8`/`#382010`; tombol moon `#E4F6F0`;
chip aktif `#D2C6F0`; nav aktif `#A89CEA→#9684DE`; ikon nav nonaktif `#585088`.

**Layout:** padding 45; kartu data tubuh y±360–930 (h±570);
kartu gender y±985–1120; tombol y±1170–1300;
nav pill y±1470–1660 (h±190, radius ±95), x±45–735.

**Bottom nav:** 4 tab, tab 1 (kalkulator) aktif, tanpa label, ikon line-style.
**Background:** artwork penuh.

---

## G5 — `3cc0b2d7...jpg` → Result "Hasil BMI"

**Transkrip teks (persis):**
- "Hasil BMI"
- "Wisnu · 14 Okt"
- "22.5"
- "kg/m²"
- "Normal"
- "● Underweight ● Normal ● Overweight ● Obese" ← PERHATIAN: bahasa Inggris
- "Tips untukmu"
- "Tetap aktif" | "Jalan kaki 30 menit, 5 hari seminggu"
- "Cukup minum" | "Air putih sekitar 2 liter per hari"
- "Tidur teratur" | "7–8 jam tiap malam"
- "Simpan ke riwayat" | "Bagikan"

**Struktur top→bottom:**
1. Header: back (kiri); "Hasil BMI" (~56 px, 800) + "Wisnu · 14 Okt"
   (~30 px, 500, gelap) tengah; tombol share (lingkaran, ikon share gelap) kanan.
2. Kartu gauge (putih, radius ±48): arc setengah lingkaran 4 segmen —
   biru `#6CAEFC` (underweight), hijau `#5EE0A0` (normal),
   kuning `#F5B94E` (overweight), merah `#FF7969` (obese);
   marker = dot ring `#2A2370` isi putih, duduk di segmen hijau;
   "22.5" (~120–128 px, 800, gelap) tengah; "kg/m²" (~20–24 px, gelap)
   di bawahnya; pill "Normal" (`#5ADE9C`, teks gelap `#001820`, ~32 px 700);
   legend 4 item (~28 px, 500, gelap) — label Inggris.
3. "Tips untukmu" (~40–44 px, 800, gelap) — label section di luar kartu.
4. Tiga kartu tips (putih, radius ±40): ikon lingkaran (border tipis,
   ikon line gelap: petir / tetes air / bulan) + judul (~36 px, 700, gelap)
   + subjudul (~30 px, 400, `#606070`).
5. Dua tombol sebaris: "Simpan ke riwayat" (gradient ungu, teks gelap
   ~36–40 px 700, lebih lebar ±415 px) + "Bagikan" (putih, teks gelap,
   ±255 px). Tinggi ±105–110.
6. Bottom nav pill: 4 tab tanpa label, tab 1 (kalkulator) aktif.

**Warna kunci:** arc `#6CAEFC`/`#5EE0A0`/`#F5B94E`/`#FF7969`;
marker ring `#2A2370`; pill Normal `#5ADE9C`; sublabel tips `#606070`.

**Layout:** padding 45; kartu gauge y±245–800 (h±555);
section "Tips untukmu" y±830–870; kartu tips h±135, gap ±25;
tombol y±1325–1430.

**Bottom nav:** 4 tab, tab 1 aktif, tanpa label. **Background:** artwork penuh.

---

## G6 — `af54798a...jpg` → History "Riwayat"

**Transkrip teks (persis):**
- "W" (avatar)
- "Riwayat"
- "Mei" | "68" ; "Jun" | "67.5" ; "Jul" | "67" ; "Agu" | "66" ; "Sep" | "65.5" ; "Okt" | "65" (terpilih)
- "Berat badan (kg)" | "Berat" (terpilih) | "BMI"
- "65.0" | "↓ 3.0 kg · 6 bulan"
- "Catatan terakhir"
- "22.5" | "14 Okt" | "65.0 kg · Normal" | "−0.5 kg"
- "22.7" | "14 Sep" | "65.5 kg · Normal" | "−0.5 kg"
- "22.8" | "14 Agu" | "66.0 kg · Normal" | "−1.0 kg"

**Struktur top→bottom:**
1. Header: avatar "W" (sama seperti G4) | "Riwayat" (~48–56 px, 800) |
   tombol moon (sama seperti G4).
2. Strip 6 kartu bulan (horizontal, y±245–385, h±140): label bulan
   (`#303040`, ~32 px, 500) + nilai (`#181828`, ~36 px, 700).
   "Okt" TERPILIH: fill putih + border ungu `#A3A0D5`.
3. Kartu chart (putih, radius ±48, y±425–915): baris "Berat badan (kg)"
   (~36 px, 700, gelap) + toggle "Berat" (TERPILIH, pill putih) / "BMI"
   (container `#E4E4F0`, pola G1); "65.0" (~84–88 px, 800, gelap) +
   pill "↓ 3.0 kg · 6 bulan" (fill `#C6F0DE`, teks hijau `#107850`, ~32 px, 700);
   line chart: garis ungu `#9180DE`, area fill `#E9E6F9`,
   titik-titik putih ber-border ungu, titik terakhir solid hijau `#5BE1A2`.
4. "Catatan terakhir" (~40–44 px, 800, gelap) — label section.
5. Tiga baris catatan (kartu putih, radius ±40): lingkaran ring hijau
   `#65DBA9` berisi BMI (~32 px, 700, gelap: 22.5/22.7/22.8);
   "14 Okt" (~36 px, 700, gelap) + "65.0 kg · Normal" (~30 px, 400, `#202028`);
   delta kanan hijau `#107050` (~36 px, 700): "−0.5 kg", "−0.5 kg", "−1.0 kg".
6. Bottom nav pill: 4 tab tanpa label, tab 2 (chart) AKTIF (lingkaran ungu,
   ikon chart putih).

**Warna kunci:** border bulan terpilih `#A3A0D5`; garis chart `#9180DE`;
area `#E9E6F9`; dot terakhir `#5BE1A2`; pill delta `#C6F0DE`/`#107850`;
ring BMI `#65DBA9`; delta teks `#107050`.

**Layout:** padding 45; kartu bulan ±105×140; kartu chart h±490;
baris catatan h±150, gap ±25.

**Bottom nav:** 4 tab, tab 2 (chart) aktif, tanpa label.
**Background:** artwork penuh.

---

## SCREEN PAIRS (tebakan pasangan versi dark)

| Light (batch ini) | Dugaan pasangan dark |
|---|---|
| G0 Onboarding 1/4 "Kenalan dulu, yuk" | Onboarding 1/4 dark (judul sama) |
| G1 Onboarding 2/4 "Ukuran tubuhmu" | Onboarding 2/4 dark |
| G2 Onboarding 3/4 "Punya target berat?" | Onboarding 3/4 dark |
| G3 Onboarding 4/4 "Jadwal menimbang" | Onboarding 4/4 dark |
| G4 Home "Hitung BMI" | Home dark |
| G5 Result "Hasil BMI" | Result dark |
| G6 History "Riwayat" | History dark |

Batch ini TIDAK memuat: splash, Health "Kesehatan", Streak, dan Profil —
dugaan ada di batch mockup dark/B lainnya.

## Catatan penting untuk implementasi

1. **Teks tombol ungu = GELAP** (`#181838`), bukan putih — berlaku untuk
   "Lanjut", "Simpan target", "Selesai", "Hitung BMI", "Simpan ke riwayat".
   Ini menyimpang dari kebiasaan tombol primer teks-putih.
2. **Teks di atas chip/segmen ungu terpilih = GELAP** (gender Pria, day-chip
   Sen/Kam, "Turun", "Pria" di home) — bukan putih.
3. **Teks di atas pill hijau = GELAP** (`#001820`), bukan putih.
4. Legend gauge result memakai bahasa **Inggris**
   (Underweight/Normal/Overweight/Obese) — konfirmasi ke user apakah dipertahankan
   atau di-Indonesiakan, karena kontrak copy menyebut Bahasa Indonesia.
5. Day-chip terpilih punya **dot indikator** di bawah label.
6. Switch reminder = gaya iOS (track ungu saat ON, knob putih).
7. Bottom nav: 4 tab, **tanpa label**, tab aktif = lingkaran ungu solid dengan
   ikon putih; ikon nonaktif `#585088`.
8. Header home & riwayat: avatar "W" (`#E4C6A8`) + tombol moon `#E4F6F0`.

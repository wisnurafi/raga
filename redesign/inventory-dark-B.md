# Inventaris Visual — Raga Redesign (Dark Mode, Batch B)

Sumber: 8 file mockup (7 layar 780×1688 px + 1 lembar spesifikasi ikon 780×1120 px).
Semua warna di bawah di-sample langsung dari file JPEG dengan PIL (deteksi berbasis kelas piksel, median).
Skala: mockup 780 px ≈ 2× dari lebar logis 390 px. Estimasi "em" = cap-height ÷ 0,72 (Manrope XBold);
kolom "logis" = px mockup ÷ 2. Nilai bertanda ~ adalah estimasi visual karena blur JPEG.

---

## B-1 · HOME — "Hitung BMI"
`image/c5/c5c870bbc5a254ca4772b6082f55f8dec04597803ba2b44fb9574f20428d5284.jpg` · 780×1688

### Identifikasi
Layar utama **Hitung BMI** (kalkulator). State: profil "Wisnu" aktif, unit metrik, Pria, umur 21.

### Transkripsi (persis)
- Judul: `Hitung BMI`
- Avatar: `W`
- Chips profil: `Wisnu ✓` · `Ibu` · `Dika` · `+ Tambah`
- Kartu: `Data tubuh` · toggle `cm · kg` / `in · lb`
- `Tinggi badan` · `170` · `cm`
- `Berat badan` · `65` · `kg`
- Segmented: `Pria` / `Wanita` · `21 tahun`
- Tombol: `Hitung BMI`

### Struktur top → bottom
1. Header: avatar lingkaran (kiri), judul tengah, ikon bulan/theme-toggle (kanan, lingkaran outline).
2. Baris chips profil horizontal (scrollable): "Wisnu ✓" terpilih (fill lebih terang + teks putih tebal), sisanya outline; "+ Tambah" outline.
3. Kartu kaca "Data tubuh": header baris (label kiri, unit toggle kanan — "cm · kg" terpilih dengan pil terang); blok "Tinggi badan" (label kecil, angka raksasa + satuan, slider); blok "Berat badan" (pola sama).
4. Kartu baris: segmented Pria/Wanita ("Pria" terpilih, pil lavender) + "21 tahun" rata kanan.
5. Tombol primer penuh: "Hitung BMI" (fill lavender, teks navy gelap).
6. Bottom nav pill (4 tab).

### Tipografi (terukur)
| Elemen | cap-height | est. em (mockup) | logis |
|---|---|---|---|
| Judul "Hitung BMI" | 38 px | ~53 px | ~26 px · 800 |
| Angka "170" | 70 px | ~97 px | ~49 px · 800 |
| Angka "65" | ~70 px (visual) | ~97 px | ~49 px · 800 |
| Label "Tinggi badan" | ~30 px (visual) | ~42 px | ~21 px · 700 |
| Satuan "cm"/"kg" | ~34 px (visual) | ~47 px | ~24 px · 700 |
| Chip teks | ~28 px (visual) | ~39 px | ~20 px · 700 |
| Tombol "Hitung BMI" | ~36 px (visual) | ~50 px | ~25 px · 800 |
| "21 tahun" | ~30 px (visual) | ~42 px | ~21 px · 700 |

### Warna (sampled)
| Peran | HEX |
|---|---|
| Teks utama (putih) | `#FEFDFF` |
| Aksen lavender (tombol fill) | `#A99BE8` |
| Teks di atas lavender (navy) | `#3F3D73` |
| Avatar "W" (tan) | `#DEC2A7` |
| Background atas → bawah | `#7665C1` → `#0D1031` |
| Daun artwork | `#7DA3BE` (tangkai `#A0C4DC`) |

### Layout
- Padding samping layar: **44 px** (~22 logis); konten & nav pill sejajar kiri-kanan di x 44–736.
- Chips: tinggi ~90 px (45 logis), radius ~45 px (pill penuh), gap ~16 px.
- Kartu "Data tubuh": radius ~52–56 px (26–28 logis), padding dalam ~44 px.
- Slider: track ~12 px, thumb lingkaran putih ~44 px dengan ring lavender.
- Gap antar blok: ~36 px (18 logis).
- Tombol primer: tinggi ~130 px (65 logis), pill penuh.

### Bottom nav
4 tab tanpa label: kalkulator (aktif — lingkaran lavender di belakang ikon), chart, hati, profil.

### Background
Artwork penuh: cabang daun kanan-atas & kiri-bawah, garis ECG tengah, lingkaran konsentris kiri-atas, gradien ungu gelap.

---

## B-2 · RESULT — "Hasil BMI"
`image/6e/6eb0017beef10985e26ba3242713079af833e9f7e0444a6b93b526b9390c02c8.jpg` · 780×1688

### Identifikasi
Layar **hasil perhitungan BMI** setelah tekan "Hitung BMI". State: Wisnu, 14 Okt, BMI 22.5 = Normal.

### Transkripsi (persis)
- `Hasil BMI` · subjudul `Wisnu · 14 Okt`
- `22.5` · `kg/m²`
- Pil kategori: `Normal`
- Legenda: `• Underweight` · `• Normal` · `• Overweight` · `• Obese`
- `Tips untukmu`
- `Tetap aktif` / `Jalan kaki 30 menit, 5 hari seminggu`
- `Cukup minum` / `Air putih sekitar 2 liter per hari`
- `Tidur teratur` / `7–8 jam tiap malam`
- Tombol: `Simpan ke riwayat` · `Bagikan`

### Struktur top → bottom
1. Header: tombol kembali chevron (lingkaran outline, kiri), judul + subjudul tengah, ikon share (lingkaran outline, kanan).
2. Kartu gauge: busur setengah lingkaran 4 segmen (biru → hijau → kuning → merah), marker dot putih ber-ring navy di zona hijau (~posisi jam 11); angka "22.5" raksasa + "kg/m²"; pil hijau "Normal" (teks navy); legenda 4 kategori satu baris (nama kategori **bahasa Inggris**).
3. Judul seksi "Tips untukmu" (di luar kartu).
4. 3 kartu tips: ikon lingkaran outline (petir / tetes air / bulan) + judul tebal + deskripsi 1 baris.
5. Dua tombol: "Simpan ke riwayat" (primer lavender, teks navy) + "Bagikan" (outline, teks putih).
6. Bottom nav pill (4 tab, kalkulator aktif).

### Tipografi (terukur)
| Elemen | cap-height | est. em (mockup) | logis |
|---|---|---|---|
| Judul "Hasil BMI" | ~38 px (visual) | ~53 px | ~26 px · 800 |
| Subjudul "Wisnu · 14 Okt" | ~24 px (visual) | ~33 px | ~17 px · 500 |
| Angka "22.5" | 89 px | ~124 px | ~62 px · 800 |
| "kg/m²" | 25 px | ~35 px | ~17 px · 700 |
| Pil "Normal" | ~30 px (visual) | ~42 px | ~21 px · 800 |
| Legenda | ~24 px (visual) | ~33 px | ~17 px · 700 |
| "Tips untukmu" | ~40 px (visual) | ~56 px | ~28 px · 800 |
| Judul tips | ~32 px (visual) | ~44 px | ~22 px · 700 |
| Deskripsi tips | ~26 px (visual) | ~36 px | ~18 px · 500 |
| Tombol | ~34 px (visual) | ~47 px | ~24 px · 800 |

### Warna (sampled)
| Peran | HEX |
|---|---|
| Teks utama (putih) | `#FCFDFF` |
| Segmen gauge biru | `#6FB1FF` |
| Segmen gauge hijau | `#5EE0A0` |
| Segmen gauge kuning | `#F5B94B` |
| Segmen gauge merah | `#FF7A6B` |
| Marker dot | `#FFFEFF` (ring navy) |
| Pil "Normal" | fill `#5EE0A0`, teks navy |
| Tombol primer | `#A99BE8` / teks `#3F3D73` |

### Layout
- Padding samping 44 px; kartu gauge radius ~56 px.
- Gauge: diameter busur ~470 px, tebal arc ~44 px, marker dot ~64 px.
- Kartu tips: tinggi ~130 px, radius ~40 px, ikon lingkaran ~88 px.
- Gap: kartu→judul seksi ~36 px; antar kartu tips ~24 px; tombol berdampingan gap ~24 px, tinggi ~120 px.

### Bottom nav
4 tab tanpa label; tab kalkulator aktif.

### Background
Artwork sama (daun, ECG, lingkaran, gradien ungu gelap).

---

## B-3 · HISTORY — "Riwayat"
`image/8a/8abda7a6da5a095274061127ad5fdd647df26b4101204ffd4386e886d4c809ce.jpg` · 780×1688

### Identifikasi
Layar **riwayat** penimbangan 6 bulan. State: bulan "Okt" terpilih, mode grafik "Berat".

### Transkripsi (persis)
- `Riwayat`
- Strip bulan: `Mei` `68` · `Jun` `67.5` · `Jul` `67` · `Agu` `66` · `Sep` `65.5` · `Okt` `65`
- `Berat badan (kg)` · toggle `Berat` / `BMI`
- `65.0` · pil `↓ 3.0 kg · 6 bulan`
- `Catatan terakhir`
- Baris 1: `22.5` · `14 Okt` · `65.0 kg · Normal` · `−0.5 kg`
- Baris 2: `22.7` · `14 Sep` · `65.5 kg · Normal` · `−0.5 kg`
- Baris 3: `22.8` · `14 Agu` · `66.0 kg · Normal` · `−1.0 kg`

### Struktur top → bottom
1. Header: avatar "W" (kiri), judul tengah, ikon bulan (kanan).
2. Strip 6 chip bulan horizontal: tiap chip = nama bulan (kecil) + nilai berat (tebal); "Okt" terpilih (fill lebih terang).
3. Kartu grafik: header baris (judul kiri, toggle Berat/BMI kanan — "Berat" terpilih); angka besar "65.0" + pil delta hijau "↓ 3.0 kg · 6 bulan"; line chart 6 titik menurun dengan area fill di bawah garis; gridlines horizontal samar; titik terakhir (Okt) diisi hijau.
4. Judul seksi "Catatan terakhir".
5. 3 baris catatan: lingkaran ring hijau berisi nilai BMI + tanggal tebal + "berat · kategori" + delta kanan hijau ("−0.5 kg").
6. Bottom nav pill (4 tab, **chart aktif**).

### Tipografi (terukur)
| Elemen | cap-height | est. em (mockup) | logis |
|---|---|---|---|
| Judul "Riwayat" | 37 px | ~51 px | ~26 px · 800 |
| Nama bulan chip | ~18 px (visual) | ~25 px | ~13 px · 700 |
| Nilai bulan chip | ~26 px (visual) | ~36 px | ~18 px · 800 |
| Angka "65.0" | 64 px | ~89 px | ~44 px · 800 |
| Pil delta | ~26 px (visual) | ~36 px | ~18 px · 700 |
| "Catatan terakhir" | ~38 px (visual) | ~53 px | ~26 px · 800 |
| Tanggal baris | 25 px | ~35 px | ~17 px · 700 |
| Sub baris | ~22 px (visual) | ~31 px | ~15 px · 500 |
| Delta baris | ~28 px (visual) | ~39 px | ~19 px · 700 |

### Warna (sampled)
| Peran | HEX |
|---|---|
| Teks utama (putih) | `#FCFCFF` |
| Hijau delta/ring (Normal) | `#5EE0A0` (varian sampel `#66DAA6`) |
| Chip bulan terpilih | `#95A2C6` (lebih terang) |
| Chip bulan biasa | `#8D82C3` |
| Garis chart | lavender terang (visual) |
| Area fill chart | ungu transparan (visual) |

### Layout
- Padding samping 44 px.
- Chip bulan: ~110 px lebar, ~150 px tinggi, radius ~36 px.
- Kartu grafik: radius ~52 px, tinggi ~430 px; chart area ~470×200 px.
- Baris catatan: tinggi ~140 px, radius ~40 px; lingkaran BMI ~110 px diameter, ring ~8 px.
- Gap antar baris ~24 px.

### Bottom nav
4 tab tanpa label; tab chart aktif (lingkaran lavender di ikon chart).

### Background
Artwork sama (daun, ECG, lingkaran, gradien ungu gelap).

---

## B-4 · HEALTH — "Kesehatan"
`image/7d/7d8831df83bc39abb9c45ac561344526d68c15232c22f3c8f2a781dbe22934ea.jpg` · 780×1688

### Identifikasi
Layar **kesehatan**: kebutuhan kalori (TDEE/BMR) + berat badan ideal. State: aktivitas "Ringan" terpilih.

### Transkripsi (persis)
- `Kesehatan`
- Chips aktivitas: `Minim` · `Ringan ✓` · `Sedang` · `Berat`
- `Kebutuhan kalori harian` · `2.217` · `kcal` · `73%` · `BMR` · `Pria · 21 th · 170 cm · 65 kg`
- Kartu tujuan: `Turun` `1.717` · `Jaga` `2.217` · `Naik` `2.717`
- `Berat badan ideal` · `53.5 – 72.0` · `kg`
- `40` · `Kamu: 65 kg` · `90`
- Footnote: `BMR 1.613 kcal/hari · rumus Mifflin-St Jeor`

### Struktur top → bottom
1. Header: avatar "W" (kiri), judul tengah, ikon bulan (kanan).
2. Baris 4 chip aktivitas: "Ringan ✓" terpilih (fill terang + teks putih tebal).
3. Kartu kalori: label atas; angka raksasa "2.217" + "kcal"; ring donut kanan ("73%" / "BMR"); sub "Pria · 21 th · 170 cm · 65 kg".
4. Tiga kartu tujuan sejajar: "Turun" 1.717 (mini bar biru), "Jaga" 2.217 (mini bar hijau), "Naik" 2.717 (mini bar kuning). Bar menunjukkan proporsi terhadap nilai.
5. Kartu berat ideal: label; "53.5 – 72.0 kg" besar; range bar (track + segmen hijau 53.5–72.0 + marker lingkaran putih di 65); label "40" kiri, "Kamu: 65 kg" tengah, "90" kanan.
6. Footnote kecil di bawah kartu: "BMR 1.613 kcal/hari · rumus Mifflin-St Jeor".
7. Bottom nav pill (4 tab, **hati aktif**).

### Tipografi (terukur)
| Elemen | cap-height | est. em (mockup) | logis |
|---|---|---|---|
| Judul "Kesehatan" | ~37 px (visual) | ~51 px | ~26 px · 800 |
| Chip aktivitas | ~28 px (visual) | ~39 px | ~20 px · 700 |
| Label kartu | ~30 px (visual) | ~42 px | ~21 px · 700 |
| Angka "2.217" | 75 px | ~104 px | ~52 px · 800 |
| "73%" donut | ~34 px (visual) | ~47 px | ~24 px · 800 |
| Sub profil | ~26 px (visual) | ~36 px | ~18 px · 500 |
| Label tujuan | ~26 px (visual) | ~36 px | ~18 px · 700 |
| Angka tujuan (1.717) | 28 px | ~39 px | ~19 px · 800 |
| "53.5 – 72.0" | 46 px | ~64 px | ~32 px · 800 |
| "Kamu: 65 kg" | ~24 px (visual) | ~33 px | ~17 px · 700 |
| Footnote | ~22 px (visual) | ~31 px | ~15 px · 500 |

### Warna (sampled)
| Peran | HEX |
|---|---|
| Teks utama (putih) | `#FEFDFF` |
| Bar Turun (biru) | `#6EB1FF` |
| Bar Jaga (hijau) | `#5EDEA1` |
| Bar Naik (kuning) | `#F5B949` |
| Segmen ideal hijau | `#5EE0A0` (visual) |
| Donut arc | lavender `#A99BE8` (visual) |

### Layout
- Padding samping 44 px.
- Kartu kalori: radius ~52 px, tinggi ~280 px; donut ~150 px diameter.
- Kartu tujuan: 3 kolom sama lebar (~200 px), tinggi ~190 px, radius ~40 px; mini bar tinggi ~14 px, radius penuh.
- Kartu ideal: radius ~52 px; range bar tinggi ~18 px; marker ~44 px.
- Gap antar blok ~36 px.

### Bottom nav
4 tab tanpa label; tab hati aktif.

### Background
Artwork sama (daun, ECG, lingkaran, gradien ungu gelap).

---

## B-5 · BACKGROUND ARTWORK (aset, bukan layar)
`image/e7/e708ae6007be88424a3f604fd5d5deb8e7bdaa55400253b8017f070a7ebd9e4c.jpg` · 780×1688

### Identifikasi
**Bukan layar aplikasi** — ini file artwork background polos (tanpa UI sama sekali).

### Isi
- Kiri atas: 3 lingkaran konsentris tipis (garis samar, ~`#705FBB`).
- Kanan atas: ranting daun diagonal (7–8 helai daun, `#7DA3BE`; tangkai `#A0C4DC`).
- Tengah kiri: garis ECG/pulse horizontal tipis (teal/mint — terlalu tipis untuk di-sample akurat dari JPEG; bahasa visual = aksen sehat `#8CF0C0`).
- Kiri bawah: ranting daun kedua (5 helai).
- Gradien vertikal: `#7665C1` (atas) → `#4F4198` (tengah) → `#1E1E50` → `#0D1031` (bawah).
- Sudut: TL `#7665C1` · TR `#7281BC` · BL `#353460` · BR `#0D1031`.

### Catatan
Ini tampaknya file `raga-bg.png` versi JPEG (atau pratinjaunya). Komposisi 100% cocok dengan deskripsi background di kontrak: daun + ECG + lingkaran konsentris + gradien ungu gelap.

---

## B-6 · SPLASH
`image/bf/bf7b72b42e6dd971f7afd0cafddadb397b5a38b8663afa7c563ff9eb2401f8bf.jpg` · 780×1688

### Identifikasi
Layar **splash / loading** aplikasi.

### Transkripsi (persis)
- `Raga`
- `Kenali tubuhmu, jaga kesehatanmu.`
- `Memuat...`

### Struktur top → bottom
1. Background artwork penuh (tanpa header/nav).
2. Tengah: tile kaca rounded-square berisi logo gauge (busur biru→hijau→kuning→merah + jarum putih).
3. Di bawah tile, sedikit overlap dengan garis ECG: judul "Raga" raksasa putih dengan glow lavender.
4. Tagline satu baris.
5. Bawah: loading bar horizontal (track gelap, fill lavender ~60%) + teks "Memuat...".

### Tipografi (terukur)
| Elemen | cap-height | est. em (mockup) | logis |
|---|---|---|---|
| "Raga" | 100 px | ~139 px | ~70 px · 800 |
| Tagline | 25 px | ~35 px | ~17 px · 500 |
| "Memuat..." | ~24 px (visual) | ~33 px | ~17 px · 500 |

### Warna (sampled)
| Peran | HEX |
|---|---|
| Teks utama (putih) | `#FEFEFF` |
| Gauge: biru/hijau/kuning/merah | `#6FB1FF` / `#5EE0A0` / `#F5B94B` / `#FF7A6B` (rentang visual; merah tersample `#FE7A6D`) |
| Jarum | putih `#FFFFFF` |
| ECG mint di logo | hijau-mint (visual; kelas `#5FDFA2`) |
| Fill loading bar | lavender `#A99BE8` (visual) |

### Layout
- Tile logo: ~230×230 px, radius ~56 px, border kaca terang.
- "Raga" overlap garis ECG (ECG lewat di belakang teks).
- Loading bar: lebar ~230 px, tinggi ~10 px, radius penuh; posisi ~120 px dari bawah.
- Tidak ada bottom nav.

### Background
Artwork penuh (daun, ECG, lingkaran, gradien ungu gelap).

---

## B-7 · ONBOARDING 1/4 — "Kenalan dulu, yuk"
`image/1c/1cc4a36917a6c00870eeae7d4f66feb4cbe0be7b7a14a75d8d48449630c7915b.jpg` · 780×1688

### Identifikasi
**Setup langkah 1 dari 4** (profil dasar). State: nama terisi "Wisnu", umur 21, gender "Pria" terpilih.

### Transkripsi (persis)
- `1/4`
- `Kenalan dulu, yuk`
- `Biar Raga bisa menyapamu dan menghitung dengan tepat.`
- `Nama panggilan` · `Wisnu`
- `Umur` · `−` · `21` · `+`
- `Jenis kelamin`
- `Pria` · `Wanita`
- `Lanjut`

### Struktur top → bottom
1. Header: tombol kembali chevron (lingkaran outline, kiri); progress 4 segmen (segmen 1 terisi lavender, 3 redup); "1/4" kanan.
2. Judul besar 2 baris: "Kenalan dulu, yuk".
3. Subjudul 2 baris (abu-lavender).
4. Kartu field: label kecil "Nama panggilan" + nilai besar "Wisnu" (text field terisi).
5. Kartu field: "Umur" (kiri) + stepper: tombol "−" lingkaran outline, angka "21" besar, tombol "+" lingkaran outline.
6. Label "Jenis kelamin" (kecil, di luar kartu).
7. Dua kartu pilih: "Pria" (♂ dalam lingkaran, **terpilih** — fill lebih terang + border terang) dan "Wanita" (♀, tidak terpilih).
8. Tombol primer penuh bawah: "Lanjut" (lavender, teks navy).
9. Tidak ada bottom nav.

### Tipografi (terukur)
| Elemen | cap-height | est. em (mockup) | logis |
|---|---|---|---|
| Judul "Kenalan dulu, yuk" | 53 px | ~74 px | ~37 px · 800 |
| Subjudul | 25 px | ~35 px | ~17 px · 500 |
| Label field ("Nama panggilan") | ~24 px (visual) | ~33 px | ~17 px · 700 |
| Nilai "Wisnu" | 36 px | ~50 px | ~25 px · 800 |
| Angka "21" | 35 px | ~49 px | ~24 px · 800 |
| Label "Jenis kelamin" | ~24 px (visual) | ~33 px | ~17 px · 700 |
| "Pria"/"Wanita" | 21 px | ~29 px | ~15 px · 700 |
| Tombol "Lanjut" | ~34 px (visual) | ~47 px | ~24 px · 800 |
| "1/4" | ~24 px (visual) | ~33 px | ~17 px · 700 |

### Warna (sampled)
| Peran | HEX |
|---|---|
| Teks utama (putih) | `#FEFDFF` |
| Aksen lavender | `#A698E7` (≈ `#A99BE8`) |
| Teks tombol (navy) | `#29275F` (rentang gelap; visual = navy `#1D1B3A`-ish) |
| Kartu terpilih (Pria) | fill lebih terang + border lavender terang (visual) |

### Layout
- Padding samping 44 px.
- Progress: 4 segmen × ~110 px, tinggi ~10 px, gap ~14 px; "1/4" rata kanan.
- Kartu field: tinggi ~190 px, radius ~44 px, padding dalam ~40 px.
- Stepper: tombol lingkaran ~96 px diameter, outline ~3 px.
- Kartu gender: 2 kolom, tinggi ~230 px, radius ~44 px; ikon lingkaran ~110 px.
- Tombol "Lanjut": tinggi ~130 px, pill penuh, margin bawah ~60 px (di atas safe area).

### Bottom nav
Tidak ada (aliran onboarding).

### Background
Artwork penuh (daun, ECG, lingkaran, gradien ungu gelap).

---

## B-8 · LEMBAR SPESIFIKASI IKON (aset, bukan layar)
`image/c6/c633ed287facce99d6caff88edbb6cb7d98415d3f02ed7ddd9937459e36bccb7.jpg` · 780×1120

### Identifikasi
**Bukan layar aplikasi dan bukan crop layar** — ini lembar presentasi/spesifikasi **ikon aplikasi**, format potrait pendek (780×1120).

### Transkripsi (persis)
- `Ikon Aplikasi`
- `Raga · 1024 × 1024`
- `Pratinjau bentuk dan ukuran`
- `iOS` · `Android` · `Home` · `Notif`

### Isi
- Ikon besar (~430 px squircle): gradien ungu (lavender atas-kiri → ungu tua bawah-kanan), gauge busur 4 warna (biru `#6FB1FF`, hijau `#5EE0A0`, kuning `#F5B94D`, merah `#FF7A6B`) + jarum putih + garis ECG mint di bawah gauge.
- 4 pratinjau ukuran: iOS (squircle ~200 px), Android (lingkaran ~200 px), Home (~130 px squircle), Notif (~90 px squircle).
- Background lembar: navy sangat gelap `#13153E`.
- Judul putih `#FEFEFF`; subjudul & label platform ungu-muda.

### Catatan
Tidak ada bottom nav, tidak ada artwork daun/ECG/lingkaran — background polos gelap.

---

## RINGKASAN TOKEN GLOBAL (terukur dari mockup)
| Token | HEX (sampled) | Keterangan |
|---|---|---|
| Teks utama dark | `#FEFDFF` ≈ `#FFFFFF` | putih |
| Aksen lavender | `#A99BE8` | **persis** tersample di fill tombol |
| Teks di atas lavender | `#3F3D73` | navy (JPEG-softened; target `#1D1B3A`) |
| Biru (underweight) | `#6FB1FF` | **persis** |
| Hijau (normal) | `#5EE0A0` | **persis** |
| Kuning (overweight) | `#F5B94B` | ≈ spec `#F5B84B` |
| Merah (obese) | `#FF7A6B` | **persis** |
| Avatar tan | `#DEC2A7` | lingkaran inisial |
| BG atas → bawah | `#7665C1` → `#0D1031` | ≈ spec `#7766C2`…`#0E1030` |
| Daun artwork | `#7DA3BE` | tangkai `#A0C4DC` |
| Padding layar | 44 px @780 = 22 logis | |
| Radius kartu | ~52–56 px @780 = 26–28 logis | |
| Radius chip | pill penuh (~45 px @780) | |
| Tinggi nav pill | ~136 px @780 = **68 logis** | |
| Tinggi tombol primer | ~130 px @780 = 65 logis | |

---

## SCREEN PAIRS (tebakan pasangan dark ↔ light)
Berdasarkan judul/copy yang identik di kedua mode (asumsi versi light memakai copy dan struktur yang sama, hanya token warna yang dibalik):
| # | Layar (dark, batch ini) | Pasangan light (tebakan) |
|---|---|---|
| B-1 | Home — "Hitung BMI" | Light home "Hitung BMI" (chips profil, kartu Data tubuh, slider, tombol lavender) |
| B-2 | Result — "Hasil BMI" / "Wisnu · 14 Okt" | Light result "Hasil BMI" (gauge 4 warna sama, pil kategori, 3 kartu tips, Simpan/Bagikan) |
| B-3 | History — "Riwayat" (strip Mei–Okt, chart Berat/BMI) | Light history "Riwayat" (chip bulan, grafik, Catatan terakhir) |
| B-4 | Health — "Kesehatan" (kalori 2.217, Turun/Jaga/Naik, berat ideal) | Light health "Kesehatan" (donut BMR, 3 kartu tujuan, range bar ideal) |
| B-6 | Splash — "Raga" / "Kenali tubuhmu, jaga kesehatanmu." / "Memuat..." | Light splash (tile gauge, judul, tagline, loading bar — di atas bg light) |
| B-7 | Onboarding 1/4 — "Kenalan dulu, yuk" | Light onboarding 1/4 (nama, umur stepper, Pria/Wanita, "Lanjut") |
| B-5 | Background artwork (aset) | Background light (varian terang, komposisi sama — daun/ECG/lingkaran) |
| B-8 | Lembar spesifikasi ikon (aset) | Tidak punya pasangan — bukan layar |

Catatan: batch ini **tidak memuat** layar onboarding 2/4, 3/4, 4/4, streak, maupun profil — tidak bisa dipasangkan dari batch ini.

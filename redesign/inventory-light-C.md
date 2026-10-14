# Inventaris Visual — Raga (Batch C, 6 layar)

Skala referensi: 780×1688 px. Estimasi font-size dihitung dari tinggi aktual glyph
(cap height ≈ 0,7 × font-size untuk Manrope). Warna di-sample dengan PIL dari piksel aktual.
`[tidak terbaca]` = teks tidak terbukti dari gambar.

> CATATAN MODE: 3 file pertama batch ini adalah **light-mode** (Kesehatan, background plate,
> Splash). 3 file terakhir (`4c8410…`, `7dc0c9…`, `37d015…`) secara pengukuran **dark-mode**
> (mean brightness ~102–108 vs ~235–240 untuk light) — diinventarisasi apa adanya sebagai
> Onboarding 2/4, 3/4, 4/4 dark.

Konvensi warna yang konsisten di batch ini:
- Light: teks utama `#1C1D39` (≈ `#1D1B3A` kontrak); kartu putih `#F7F6FD`–`#F9F8FE`;
  background gradient lavender terang `#E7E1FB → #F2F0FD → #FCFCFE` + artwork yang sama
  (ranting daun mint, lingkaran konsentris kiri-atas, garis ECG tengah).
- Dark: teks utama putih `#FFFFFF`; background gradient ungu
  `#7268BD (atas) → #484781 (tengah) → #20214E (bawah)` + artwork yang sama
  (ranting daun, lingkaran konsentris, garis ECG — terlihat di belakang kartu).
- Aksen ungu `#A99BE8` (tombol `#AB9DEA`–`#AC9EEB` terukur, teks tombol GELAP `#1D1B3A`);
  hijau Normal `#4CE7A3`–`#5DE9A2` (≈ `#5EE0A0` kontrak, teks di atasnya gelap);
  bar mini: biru `#61A9FE`, hijau `#5CE89F`, oranye `#FAB847`.
- Padding layar: ±44 px (konten x44–736). Radius kartu besar ±40–60 px.

---

## C1 — `ea7eaa53…jpg` → Kesehatan (LIGHT)

**Transkrip teks (persis):**
- "W" (avatar)
- "Kesehatan"
- "Minim"
- "Ringan" (terpilih, ada ✓)
- "Sedang"
- "Berat"
- "Kebutuhan kalori harian"
- "2.217" + "kcal"
- "Pria · 21 th · 170 cm · 65 kg"
- "73%"
- "BMR"
- "Turun" / "1.717"
- "Jaga" / "2.217"
- "Naik" / "2.717"
- "Berat badan ideal"
- "53.5 – 72.0" + "kg"
- "40"
- "Kamu: 65 kg"
- "90"
- "BMR 1.613 kcal/hari · rumus Mifflin-St Jeor"

**Struktur top→bottom:**
1. Header: avatar lingkaran (tan `#E7C9AF`, huruf "W" cokelat gelap `#321B0B`,
   d≈90) kiri | judul "Kesehatan" tengah | tombol lingkaran putih kaca kanan
   berisi ikon bulan (toggle tema).
2. Baris 4 chip aktivitas: "Minim" | "Ringan ✓" (TERPILIH — fill ungu muda
   `#DDD7F6`, border ungu) | "Sedang" | "Berat" (nonaktif — fill putih
   keunguan `#E8E4FA`). Chip full-rounded, tinggi ±90 px.
3. Kartu hero "Kebutuhan kalori harian": label sekunder → angka raksasa
   "2.217" + suffix "kcal" → sub "Pria · 21 th · 170 cm · 65 kg". Kanan:
   ring donut (track abu-mint `#EDF5F8`, arc ungu `#A998F4`, tebal ±14 px,
   diameter ±110) berisi "73%" / "BMR".
4. Tiga kartu mini sejajar: "Turun" + "1.717" + bar biru (fill ±55%) |
   "Jaga" + "2.217" + bar hijau (fill ±65%) | "Naik" + "2.717" + bar oranye
   (fill ±100%). Bar: h ±12, track `#F6F5FC`, fill solid kategori.
5. Kartu "Berat badan ideal": label → "53.5 – 72.0 kg" (angka raksasa) →
   range bar horizontal (track `#E0DDF2`, segmen hijau `#5DE09F` di rentang
   ideal, marker lingkaran: ring ungu `#CDC3EF` + inti putih, tepat di 65) →
   label "40" kiri, "Kamu: 65 kg" tengah (bold), "90" kanan.
6. Footnote tengah: "BMR 1.613 kcal/hari · rumus Mifflin-St Jeor".
7. Bottom nav pill (lihat §Nav).

**Tipografi (terukur → estimasi):**
- Judul "Kesehatan": cap 28 px → ±40 px, 800, `#1C1D39`
- Chip: ±30–32 px, 700, `#1C1D39` (check ✓ sewarna teks)
- Label "Kebutuhan kalori harian": ±26 px, 700
- Angka hero "2.217": cap 72 px → ±100 px, 800, `#1C1D39`; "kcal" ±28 px, 700
- Sub profil: ±24 px, 500, `#1C1D39`
- "73%": ±30 px, 800; "BMR": ±20 px, 700
- Mini label: ±28 px, 700; mini angka: cap 28 → ±40 px, 800
- "Berat badan ideal": ±26 px, 700; "53.5 – 72.0": cap 53 → ±72 px, 800
- Sub row (40/Kamu/90): ±28 px, 700 ("Kamu: 65 kg" 800)
- Footnote: ±22 px, 500, `#272537`

**Warna kunci (PIL):**
- Teks utama `#1C1D39`; kartu hero `#F7F6FD`; kartu mini `#F9F8FE`;
  kartu ideal `#F8F8FD`; chip terpilih `#DDD7F6`; chip nonaktif `#E8E4FA`;
  avatar `#E7C9AF`; donut arc `#A998F4`; nav pill `#FBF9FE`;
  FAB aktif `#B5AAE9`.

**Layout:** padding 44; hero card y ±345–625 radius ±60; chips y ±200–290;
mini cards y ±660–830, tiap ±205 lebar, gap ±20, radius ±40;
ideal card y ±930–1130 radius ±60; gap antar blok ±30.

**Bottom nav:** ADA — 4 tab tanpa label di pill putih kaca (x44–736, y1504–1644,
h±140, radius 70). Kiri→kanan: kalkulator | grafik | **hati AKTIF**
(hati putih di lingkaran ungu `#B5AAE9`, d±130, di x≈520) | profil.
Ikon nonaktif outline gelap ±30–35 px.

**Background:** artwork light penuh (daun mint kanan-atas & kiri-bawah,
lingkaran konsentris kiri-atas, garis ECG tengah samar).

---

## C2 — `52dfe4d5…jpg` → Background plate (LIGHT, tanpa UI)

Bukan layar — plate background 780×1688 polos untuk light mode. Tidak ada teks,
kontrol, atau nav. Komposisi: gradient `#E7E1FB` (kiri atas) → `#F2F0FD`
(tengah) → `#FCFCFE` (kanan bawah); lingkaran konsentris samar di kiri atas;
ranting daun mint (`#94D4C8` terukur di daun kanan-atas) diagonal kanan-atas
dan kiri-bawah; garis ECG mint horizontal di tengah (y ±840). Tidak ada
elemen gelap (scan: nol baris piksel gelap).

---

## C3 — `93d84886…jpg` → Splash (LIGHT)

**Transkrip teks (persis):**
- "Raga"
- "Kenali tubuhmu, jaga kesehatanmu."
- "Memuat..."

**Struktur top→bottom (tengah, vertikal):**
1. Tile kaca putih (rounded-square ±205×212, radius ±50, fill `#F9F6FC`)
   berisi logo gauge: arc 3 segmen (biru kiri, hijau atas, merah/oranye kanan),
   jarum gelap menunjuk kanan-atas, hub dot gelap. Tile di y ±636–848.
2. "Raga" raksasa di bawah tile (x269–511, y899–999).
3. Tagline 1 baris di bawahnya (x142–636, y1023–1049).
4. Loading bar horizontal (x270–508, y1458–1465, h±10, radius 5;
   track `#FCFBFF`, fill ungu `#9C8DDC` ±55%) + "Memuat..." di bawahnya
   (y1499–1511, tengah).

**Tipografi:**
- "Raga": cap 100 px → ±140 px, 800, `#1D1B3A` (inti glyph `#0E1029`)
- Tagline: ±36 px, 500, `#57516C`
- "Memuat...": ±20 px, 500, `#5D5880`

**Warna:** bg `#DFE2F5` (tengah `#F0EEFC`); tile `#F9F6FC`;
jarum/hub `#181730`.

**Layout:** semua elemen center-horizontal; jarak tile→judul ±50;
judul→tagline ±24; bar→"Memuat..." ±34.

**Bottom nav:** tidak ada.

**Background:** artwork light penuh (sama seperti C2).

---

## C4 — `4c84102b…jpg` → Onboarding 2/4 (DARK)

**Transkrip teks (persis):**
- "2/4"
- "Ukuran tubuhmu"
- "Dipakai untuk menghitung BMI awalmu."
- "cm · kg" (terpilih)
- "in · lb"
- "Tinggi badan"
- "170" + "cm"
- "Berat badan"
- "65" + "kg"
- "BMI awalmu"
- "22.5"
- "Normal"
- "Lanjut"

**Struktur top→bottom:**
1. Bar atas: tombol back lingkaran kaca (chevron kiri putih, d±85, di x≈95)
   | 4 segmen progress (segmen 1–2 terisi terang, 3–4 redup; tiap ±120×10,
   gap ±15) | "2/4" putih kanan (±28 px, 700).
2. Judul "Ukuran tubuhmu" (putih, 800) + sub 1 baris (putih 70%, 500).
3. Unit toggle kanan: pil ganda "cm · kg" (TERPILIH — fill ungu muda ±70%,
   teks putih 800) / "in · lb" (teks putih redup). Kontainer h±65, radius 32.
4. Kartu kaca "Tinggi badan": label → "170" + "cm" → slider (track ungu
   gelap `#544D92`, fill ungu `#9487D7` ±45%, thumb lingkaran putih d±44
   dengan ring ungu).
5. Kartu kaca "Berat badan": pola sama, "65" + "kg", thumb di ±30%.
6. Kartu baris "BMI awalmu" (kiri, putih 700) | "22.5" (putih, 800) |
   pill hijau "Normal" (fill `#4CE7A3`, teks GELAP `#1D1B3A`, 700).
7. Tombol "Lanjut": full-width pill (y ±1525–1635, h±110, radius 55,
   fill ungu `#AB9DEA`, teks GELAP `#1D1B3A`, 800).

**Tipografi:**
- Judul: cap 41 px → ±56 px, 800, putih
- Sub: ±34 px, 500, putih 70%
- Toggle: ±30 px, 700
- Label kartu: ±32 px, 700, putih
- Angka "170"/"65": cap 70–76 → ±100 px, 800, putih
- Unit "cm"/"kg": ±36 px, 700
- "BMI awalmu": ±32 px, 700; "22.5": ±48 px, 800; "Normal": ±30 px, 700
- "Lanjut": ±40 px, 800 (gelap); "2/4": ±28 px, 700

**Warna (PIL):** bg `#7268BD → #484781 → #20214E`; kartu kaca `#6558A7`
(transparan di atas gradient); tombol `#AB9DEA`; pill hijau `#4CE7A3`;
slider fill `#9487D7`; teks putih `#FFFFFF`.

**Layout:** padding 44; kartu Tinggi y ±530–800, Berat y ±830–1100,
baris BMI y ±1130–1250, radius kartu ±60; gap antar kartu ±30.

**Bottom nav:** tidak ada (onboarding).

**Background:** artwork dark (daun kanan-atas, lingkaran konsentris kiri-atas).

---

## C5 — `7dc0c9e7…jpg` → Onboarding 3/4 (DARK)

**Transkrip teks (persis):**
- "3/4"
- "OPSIONAL"
- "Punya target berat?"
- "Atur sekarang atau nanti di Profil. Boleh dilewati."
- "Turun" (terpilih)
- "Jaga"
- "Naik"
- "62" + "kg"
- "−" / "+"
- "Sekarang 65 kg · selisih −3.0 kg"
- "BMI target 21.5 · Normal"
- "Laju per minggu"
- "0.25 kg"
- "0.5 kg" (terpilih)
- "0.75 kg"
- "Perkiraan tercapai"
- "±6 minggu · 25 Nov"
- "Simpan target"
- "Lewati dulu"

**Struktur top→bottom:**
1. Bar atas: back | 4 segmen (3 terisi) | "3/4".
2. Pill outline "OPSIONAL": border hijau `#5EE0A0` ±2, teks hijau `#5DE9A2`
   (±28 px, 700, letterspacing lebar), fill transparan, h±60, radius 30.
3. Judul "Punya target berat?" (putih, 800) + sub 1 baris (putih 70%).
4. Kartu kaca besar (y ±490–950, radius ±40):
   - Segmented control 3 opsi: "Turun" TERPILIH (fill ungu muda `#A496E2`,
     teks GELAP `#0C0531`, 800) | "Jaga" | "Naik" (teks putih). Tinggi ±90.
   - Stepper: tombol "−" lingkaran kaca (d±110, garis putih) | "62" raksasa
     putih + "kg" | tombol "+" lingkaran kaca.
   - "Sekarang 65 kg · selisih −3.0 kg" (putih, 700, tengah).
   - Pill hijau "BMI target 21.5 · Normal" (fill `#54E5A2`, teks gelap, 700,
     h±60).
5. Kartu kaca "Laju per minggu" (y ±980–1240): label → 3 pill
   "0.25 kg" | "0.5 kg" TERPILIH (fill ungu lebih terang + border highlight) |
   "0.75 kg" (kaca redup). Baris bawah: "Perkiraan tercapai" kiri |
   "±6 minggu · 25 Nov" kanan.
6. Tombol "Simpan target" (pill ungu `#AC9EEB`, teks gelap, y ±1415–1525) +
   "Lewati dulu" teks putih di bawahnya (tengah, y ±1595–1620).

**Tipografi:**
- "OPSIONAL": ±28 px, 700, hijau
- Judul: cap 54 px → ±72 px, 800, putih
- Sub: ±28 px, 500, putih 70%
- Segmen: ±32 px, 700
- "62": cap 100 px → ±135 px, 800, putih; "kg" ±44 px, 700
- "Sekarang…": ±32 px, 700; pill BMI: ±30 px, 700 (gelap)
- "Laju per minggu": ±26 px, 700
- Pill laju: ±36 px, 700; baris perkiraan: ±32 px, 700
- "Simpan target": ±40 px, 800 (gelap); "Lewati dulu": ±28 px, 700, putih

**Warna (PIL):** bg `#7268BD → #484781 → #242253`; kartu kaca `#665BA7`-ish;
seg terpilih `#A496E2`; pill hijau `#54E5A2`; tombol `#AC9EEB`;
teks putih `#FFFFFF` (inti `#FFFEFF`).

**Layout:** padding 44; kartu seg y ±490–950; kartu laju y ±980–1240
radius ±40; pill laju h±95 radius 47; gap blok ±30.

**Bottom nav:** tidak ada. **Background:** artwork dark; garis ECG
terlihat samar di balik kartu (y ±930).

---

## C6 — `37d01565…jpg` → Onboarding 4/4 (DARK)

**Transkrip teks (persis):**
- "4/4"
- "OPSIONAL"
- "Jadwal menimbang"
- "Pilih hari dan jam, Raga akan mengingatkanmu. Boleh dilewati."
- "Sen" (terpilih) / "Sel" / "Rab" / "Kam" (terpilih) / "Jum" / "Sab" / "Min"
- "Jam pengingat"
- "07:00"
- "Ringkasan"
- "2× seminggu · Sen & Kam · 07.00"
- "Bisa diubah kapan saja di Profil."
- "Selesai"
- "Lewati dulu"

**Struktur top→bottom:**
1. Bar atas: back | 4 segmen (semua terisi) | "4/4".
2. Pill "OPSIONAL" (sama seperti C5).
3. Judul "Jadwal menimbang" + sub 2 baris.
4. Baris 7 pill hari (y ±540–690, tiap ±100×150, radius ±30, gap ±12):
   "Sen" TERPILIH (fill ungu muda `#A799E6`, teks GELAP `#140B40`, dot gelap
   di bawah teks) | "Sel","Rab" redup (teks putih) | "Kam" TERPILIH
   (fill + dot, sama seperti Sen) | "Jum","Sab","Min" redup.
5. Kartu kaca "Jam pengingat" (y ±750–1010, radius ±60): label kecil →
   "07:00" raksasa putih kiri + toggle switch kanan (track ungu `#A99BE8`,
   knob putih, posisi ON/kanan; ±130×75).
6. Kartu ringkasan (y ±1040–1140, radius ±50, gaya pill): "Ringkasan" kiri
   (700) | "2× seminggu · Sen & Kam · 07.00" kanan (700).
7. "Bisa diubah kapan saja di Profil." (tengah, putih 60%, ±22 px).
8. Tombol "Selesai" (pill ungu `#AC9EEB`, teks gelap, y ±1415–1525) +
   "Lewati dulu" di bawahnya.

**Tipografi:**
- Judul: cap 53 px → ±70 px, 800, putih
- Sub: ±30 px, 500, putih 70% (2 baris)
- Hari: ±26 px, 700 (terpilih = teks gelap)
- "Jam pengingat": ±26 px, 700
- "07:00": cap 80 px → ±110 px, 800, putih
- Ringkasan: ±32 px, 700
- "Bisa diubah…": ±22 px, 500
- "Selesai": ±40 px, 800 (gelap); "Lewati dulu": ±28 px, 700

**Warna (PIL):** hari terpilih `#A799E6` + teks `#140B40`; hari redup
`#5D539C`-ish (kaca); kartu jam `#595296`-ish; tombol `#AC9EEB`;
toggle: track ungu, knob `#FFFFFF`.

**Layout:** padding 44; pill hari ±100×150 radius 30; kartu jam y ±750–1010;
kartu ringkasan y ±1040–1140.

**Bottom nav:** tidak ada. **Background:** artwork dark.

---

## SCREEN PAIRS

Pasangan dark↔light untuk 6 layar batch ini (pasangan lawan-modusnya TIDAK ada
di batch ini — berada di 21 file set awal / batch lain):

| Layar | File batch C | Modus | Pasangan lawan modus |
|---|---|---|---|
| Kesehatan | `ea7eaa53…jpg` | light | dark — tidak di batch ini |
| Background plate | `52dfe4d5…jpg` | light | dark — tidak di batch ini |
| Splash | `93d84886…jpg` | light | dark — tidak di batch ini |
| Onboarding 2/4 | `4c84102b…jpg` | **dark** | light — tidak di batch ini |
| Onboarding 3/4 | `7dc0c9e7…jpg` | **dark** | light — tidak di batch ini |
| Onboarding 4/4 | `37d01565…jpg` | **dark** | light — tidak di batch ini |

Tidak ada pasangan langsung (screen yang sama beda modus) di dalam batch C —
tiga light (Kesehatan, bg plate, Splash) dan tiga dark (Onboarding 2/4, 3/4, 4/4)
adalah layar yang berbeda.

import 'bmi.dart';

/// Tips kesehatan per kategori — ditulis seperti saran teman,
/// bukan seperti jurnal medis.
const Map<BmiCategory, List<String>> healthTips = {
  BmiCategory.underweight: [
    'Makan lebih sering dengan porsi kecil tapi padat gizi.',
    'Pilih camilan seperti kacang, alpukat, dan susu.',
    'Coba latihan beban ringan 2\u20133 kali seminggu.',
    'Jangan lewatkan sarapan, itu bahan bakar pagimu.',
  ],
  BmiCategory.normal: [
    'Berat badanmu ideal. Pertahankan dengan jalan kaki 30 menit, 5 hari seminggu.',
    'Minum air putih sekitar 2 liter per hari.',
    'Tidur 7\u20138 jam agar metabolisme tetap stabil.',
    'Timbang badan seminggu sekali biar kepantau.',
  ],
  BmiCategory.overweight: [
    'Ganti minuman manis dengan air putih.',
    'Jalan santai 30 menit setiap hari.',
    'Makan perlahan, berhenti saat sudah kenyang.',
    'Kurangi camilan larut malam.',
  ],
  BmiCategory.obese: [
    'Mulai dari langkah kecil yang bisa konsisten.',
    'Kurangi gorengan dan minuman bersoda dulu.',
    'Jalan 15 menit sehari, tambah pelan-pelan.',
    'Pertimbangkan konsultasi ke ahli gizi.',
  ],
};

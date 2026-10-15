import 'dart:math';

import 'package:flutter/material.dart';
import 'bmi.dart';

// Health tips in Indonesian — written like advice from a friend.
// Tags drive the contextual rules in tipsForResult:
// 'dasar'    = the 3 basics per category, shown when history has < 2 records
// 'comeback' = slotted in when the weight trend moves away from the goal
// 'streak'   = slotted in when the weigh-in streak reaches 4+ weeks
typedef TipItem = (
  {String title, String desc, IconData icon, Set<String> tags}
);

const Map<BmiCategory, List<TipItem>> healthTips = {
  BmiCategory.underweight: [
    (
      title: 'Makan lebih sering',
      desc: 'Dikit-dikit tapi sering, 5-6 kali sehari.',
      icon: Icons.restaurant_outlined,
      tags: {'dasar'},
    ),
    (
      title: 'Ngemil cerdas',
      desc: 'Kacang, alpukat, susu. Jangan cuma gorengan.',
      icon: Icons.cookie_outlined,
      tags: {'dasar'},
    ),
    (
      title: 'Jangan lewatkan sarapan',
      desc: 'Nasi + telur udah cukup. Yang penting keisi.',
      icon: Icons.free_breakfast_outlined,
      tags: {'dasar'},
    ),
    (
      title: 'Tambah protein',
      desc: 'Tiap makan harus ada lauknya: telur, ayam, tempe, ikan.',
      icon: Icons.egg_outlined,
      tags: <String>{},
    ),
    (
      title: 'Kalori dari minuman',
      desc: 'Jus alpukat + susu. Gampang, enak, nendang.',
      icon: Icons.local_cafe_outlined,
      tags: <String>{},
    ),
    (
      title: 'Latihan beban',
      desc: 'Push up, squat, angkat galon. Otot naik, berat ikut naik.',
      icon: Icons.fitness_center_outlined,
      tags: {'streak'},
    ),
    (
      title: 'Jangan takut lemak',
      desc: 'Alpukat sama kacang itu bagus buat nambah berat.',
      icon: Icons.eco_outlined,
      tags: <String>{},
    ),
    (
      title: 'Tidur yang cukup',
      desc: 'Otot dibangun pas tidur. Begadang = rugi.',
      icon: Icons.bedtime_outlined,
      tags: <String>{},
    ),
    (
      title: 'Catat asupanmu',
      desc: 'Tulis 3 hari apa aja yang dimakan. Nanti kelihatan kurangnya di mana.',
      icon: Icons.edit_note_outlined,
      tags: {'comeback'},
    ),
    (
      title: 'Jangan cuma mie instan',
      desc: 'Kenyang doang, berat nggak naik beneran.',
      icon: Icons.warning_amber_outlined,
      tags: <String>{},
    ),
    (
      title: 'Ngemil sebelum tidur',
      desc: 'Roti + susu 1-2 jam sebelum tidur.',
      icon: Icons.nightlight_outlined,
      tags: <String>{},
    ),
    (
      title: 'Jangan minum sebelum makan',
      desc: 'Minum dulu = kenyang duluan. Minumnya habis makan aja.',
      icon: Icons.water_drop_outlined,
      tags: <String>{},
    ),
    (
      title: 'Konsisten dulu',
      desc: 'Naik 0,5 kg seminggu udah bagus. Jangan buru-buru.',
      icon: Icons.trending_up_outlined,
      tags: <String>{},
    ),
    (
      title: 'Ganti-ganti menu',
      desc: 'Bosen itu musuh. Variasin biar nafsu makan balik.',
      icon: Icons.restaurant_menu_outlined,
      tags: <String>{},
    ),
    (
      title: 'Makan rame-rame',
      desc: 'Makan bareng temen porsinya nambah sendiri, beneran.',
      icon: Icons.group_outlined,
      tags: <String>{},
    ),
    (
      title: 'Udah makan banyak tapi nggak naik?',
      desc: 'Mending cek ke dokter, biar jelas.',
      icon: Icons.medical_services_outlined,
      tags: {'comeback'},
    ),
  ],
  BmiCategory.normal: [
    (
      title: 'Tetap aktif',
      desc: 'Jalan 30 menit, 5 hari seminggu. Udah cukup.',
      icon: Icons.bolt_outlined,
      tags: {'dasar'},
    ),
    (
      title: 'Cukup minum',
      desc: 'Air putih 2 liter sehari. Bukan teh manis.',
      icon: Icons.water_drop_outlined,
      tags: {'dasar'},
    ),
    (
      title: 'Tidur teratur',
      desc: 'Usahain 7-8 jam. Begadang mulu berat bisa geser.',
      icon: Icons.bedtime_outlined,
      tags: {'dasar'},
    ),
    (
      title: 'Ganti olahraga',
      desc: 'Bosen lari? Coba renang atau sepedaan.',
      icon: Icons.pool_outlined,
      tags: <String>{},
    ),
    (
      title: 'Jangan stres mulu',
      desc: 'Stres bikin makan ngaco. Cari pelampiasan yang bener.',
      icon: Icons.spa_outlined,
      tags: <String>{},
    ),
    (
      title: 'Nimbangnya seminggu sekali',
      desc: 'Tiap hari cuma bikin pusing.',
      icon: Icons.monitor_weight_outlined,
      tags: <String>{},
    ),
    (
      title: 'Lauk tiap makan',
      desc: 'Ada protein tiap makan biar kenyang lama.',
      icon: Icons.egg_outlined,
      tags: <String>{},
    ),
    (
      title: 'Jangan duduk terus',
      desc: 'Tiap sejam berdiri, jalan bentar.',
      icon: Icons.timer_outlined,
      tags: <String>{},
    ),
    (
      title: 'Masak sendiri',
      desc: 'Kamu yang atur minyak, garam, sama gulanya.',
      icon: Icons.soup_kitchen_outlined,
      tags: <String>{},
    ),
    (
      title: 'Sayur setengah piring',
      desc: 'Gampang kan? Tiap makan, setengah piring sayur.',
      icon: Icons.eco_outlined,
      tags: <String>{},
    ),
    (
      title: 'Kurang tidur = gampang laper',
      desc: 'Hormon laparnya naik kalau begadang.',
      icon: Icons.nightlight_outlined,
      tags: {'comeback'},
    ),
    (
      title: 'Jalan habis makan',
      desc: '10 menit aja, perut jadi enak.',
      icon: Icons.hiking_outlined,
      tags: <String>{},
    ),
    (
      title: 'Kurangi alkohol',
      desc: 'Bir kalorinya gede, nggak kerasa aja.',
      icon: Icons.no_drinks_outlined,
      tags: <String>{},
    ),
    (
      title: 'Streak udah jalan, sayang kalau putus',
      desc: 'Pertahanin.',
      icon: Icons.emoji_events_outlined,
      tags: {'streak'},
    ),
    (
      title: 'Cek sebulan sekali',
      desc: 'Lihat tab Riwayat, jangan tiap hari.',
      icon: Icons.insights_outlined,
      tags: <String>{},
    ),
    (
      title: 'Tetap nongkrong',
      desc: 'Jangan sampai gara-gara jaga badan nggak bisa kumpul temen.',
      icon: Icons.group_outlined,
      tags: <String>{},
    ),
  ],
  BmiCategory.overweight: [
    (
      title: 'Kurangi minuman manis',
      desc: 'Es teh manis tiap hari itu biang keroknya. Ganti air putih.',
      icon: Icons.local_drink_outlined,
      tags: {'dasar'},
    ),
    (
      title: 'Jalan santai tiap hari',
      desc: '30 menit. Nggak usah lari.',
      icon: Icons.directions_walk_outlined,
      tags: {'dasar'},
    ),
    (
      title: 'Makan perlahan',
      desc: 'Kunyah pelan-pelan, berhenti pas udah kenyang.',
      icon: Icons.restaurant_outlined,
      tags: {'dasar'},
    ),
    (
      title: 'Piring lebih kecil',
      desc: 'Piring kecil kelihatan penuh. Perut aman.',
      icon: Icons.restaurant_menu_outlined,
      tags: <String>{},
    ),
    (
      title: 'Lewat jam 8 dapur tutup',
      desc: 'Kasih jeda buat pencernaan istirahat.',
      icon: Icons.nightlight_outlined,
      tags: {'comeback'},
    ),
    (
      title: 'Lauk dulu, nasi belakangan',
      desc: 'Urutan makan ngaruh ke kenyang.',
      icon: Icons.egg_outlined,
      tags: <String>{},
    ),
    (
      title: 'Laper? Makan buah',
      desc: 'Pisang atau apel. Jangan gorengan.',
      icon: Icons.apple_outlined,
      tags: <String>{},
    ),
    (
      title: 'Foto makananmu 3 hari',
      desc: 'Nanti kaget sendiri lihat polanya.',
      icon: Icons.edit_note_outlined,
      tags: {'comeback'},
    ),
    (
      title: 'Ketemu tangga, naik',
      desc: 'Jangan nunggu lift.',
      icon: Icons.stairs_outlined,
      tags: <String>{},
    ),
    (
      title: 'Tidur yang bener',
      desc: 'Kurang tidur = besoknya pengen yang manis-manis.',
      icon: Icons.bedtime_outlined,
      tags: <String>{},
    ),
    (
      title: 'Sekali kebablasan ya udah',
      desc: 'Lanjut aja. Bukan kiamat.',
      icon: Icons.favorite_outlined,
      tags: <String>{},
    ),
    (
      title: 'Minum sebelum makan',
      desc: 'Segelas air 30 menit sebelum makan.',
      icon: Icons.water_drop_outlined,
      tags: <String>{},
    ),
    (
      title: 'Kurangi gorengan',
      desc: 'Ayam goreng tiap hari? Coba diganti bakar atau kukus.',
      icon: Icons.soup_kitchen_outlined,
      tags: <String>{},
    ),
    (
      title: 'Ditelpon? Sambil jalan',
      desc: 'Muter komplek 15 menit nggak kerasa.',
      icon: Icons.directions_walk_outlined,
      tags: <String>{},
    ),
    (
      title: 'Target kecil dulu',
      desc: '0,5 kg seminggu. Pelan tapi nyampe.',
      icon: Icons.trending_down_outlined,
      tags: <String>{},
    ),
    (
      title: 'Jangan skip makan',
      desc: 'Skip makan siang = kalap pas malem. Udah pasti.',
      icon: Icons.schedule_outlined,
      tags: <String>{},
    ),
    (
      title: 'Cek label kemasan',
      desc: 'Lihat gulanya, jangan cuma kalorinya.',
      icon: Icons.label_outlined,
      tags: <String>{},
    ),
    (
      title: 'Bener 5 hari > sempurna 2 hari',
      desc: 'Konsisten ngalahin sempurna.',
      icon: Icons.check_circle_outlined,
      tags: {'streak'},
    ),
    (
      title: 'Makan sama yang pelan',
      desc: 'Kecepatan makanmu ngikutin teman semeja.',
      icon: Icons.group_outlined,
      tags: <String>{},
    ),
  ],
  BmiCategory.obese: [
    (
      title: 'Mulai dari yang kecil',
      desc: 'Nggak usah langsung marathon. Jalan 15 menit dulu.',
      icon: Icons.eco_outlined,
      tags: {'dasar'},
    ),
    (
      title: 'Bergerak lebih banyak',
      desc: '15 menit sehari. Naikin pelan-pelan.',
      icon: Icons.directions_walk_outlined,
      tags: {'dasar'},
    ),
    (
      title: 'Konsultasi ke ahli',
      desc: 'Ke ahli gizi sekali aja, biar ada panduannya.',
      icon: Icons.medical_services_outlined,
      tags: {'dasar'},
    ),
    (
      title: 'Ubah satu hal dulu',
      desc: 'Misal stop minuman manis. Itu dulu, yang lain nanti.',
      icon: Icons.flag_outlined,
      tags: {'comeback'},
    ),
    (
      title: 'Jalan 5 menit habis makan',
      desc: '5 menit doang, tapi numpuk.',
      icon: Icons.timer_outlined,
      tags: <String>{},
    ),
    (
      title: 'Tidur 7-8 jam',
      desc: 'Begadang bikin berat susah turun. Beneran.',
      icon: Icons.bedtime_outlined,
      tags: <String>{},
    ),
    (
      title: 'Jangan diet ekstrem',
      desc: 'Yang turun 5 kg seminggu biasanya naik lagi 7 kg.',
      icon: Icons.warning_amber_outlined,
      tags: <String>{},
    ),
    (
      title: 'Ajak temen jalan',
      desc: 'Sendirian tuh berat. Barengan lebih gampang konsisten.',
      icon: Icons.group_outlined,
      tags: <String>{},
    ),
    (
      title: 'Turun sekilo itu prestasi',
      desc: 'Jangan disepelein.',
      icon: Icons.celebration_outlined,
      tags: {'streak'},
    ),
    (
      title: 'Foto tiap bulan',
      desc: 'Perubahannya kelihatan di situ.',
      icon: Icons.photo_camera_outlined,
      tags: <String>{},
    ),
    (
      title: 'Stok camilan sehat',
      desc: 'Taruh buah di kulkas. Kalau laper tinggal ambil.',
      icon: Icons.shopping_basket_outlined,
      tags: <String>{},
    ),
    (
      title: 'Banyakin minum air',
      desc: 'Seringnya haus, dikira laper.',
      icon: Icons.water_drop_outlined,
      tags: <String>{},
    ),
    (
      title: 'Berdiri tiap 30 menit',
      desc: 'Pasang alarm kalau perlu.',
      icon: Icons.self_improvement_outlined,
      tags: <String>{},
    ),
    (
      title: 'Nimbangnya mingguan',
      desc: 'Angka naik-turun itu normal.',
      icon: Icons.monitor_weight_outlined,
      tags: <String>{},
    ),
    (
      title: 'Bilang ke keluarga',
      desc: 'Ceritain kamu lagi jaga makan, biar nggak ditawarin mulu.',
      icon: Icons.family_restroom_outlined,
      tags: <String>{},
    ),
    (
      title: 'Pilih yang kamu suka',
      desc: 'Benci lari? Ya jangan lari. Renang kek, sepedaan kek.',
      icon: Icons.favorite_outlined,
      tags: <String>{},
    ),
    (
      title: 'Capek? Istirahat',
      desc: 'Maksa malah berhenti total. Istirahat itu bagian rencana.',
      icon: Icons.weekend_outlined,
      tags: <String>{},
    ),
    (
      title: 'Bete terus makan?',
      desc: 'Tulis mood + apa yang dimakan. Biar sadar polanya.',
      icon: Icons.mood_outlined,
      tags: {'comeback'},
    ),
    (
      title: 'Pelan-pelan aja',
      desc: 'Yang penting nggak berhenti.',
      icon: Icons.volunteer_activism_outlined,
      tags: {'streak'},
    ),
  ],
};

// --- selection ------------------------------------------------------------

int _daySeed(DateTime day, int salt) =>
    day.year * 10000 + day.month * 100 + day.day + salt;

/// Deterministically picks [count] distinct tips from [pool].
List<TipItem> _seededTake(List<TipItem> pool, int seed, int count) {
  final idx = List<int>.generate(pool.length, (i) => i)
    ..shuffle(Random(seed));
  return [for (var i = 0; i < count && i < idx.length; i++) pool[idx[i]]];
}

List<TipItem> _tagged(BmiCategory cat, String tag) =>
    healthTips[cat]!.where((t) => t.tags.contains(tag)).toList();

/// One deterministic pick from [pool], avoiding [exclude] when possible.
TipItem _seededOneExcept(List<TipItem> pool, List<TipItem> exclude, int seed) {
  final rest = pool.where((t) => !exclude.contains(t)).toList();
  final src = rest.isNotEmpty ? rest : pool;
  return _seededTake(src, seed, 1).first;
}

/// 3 tips for the day: same set all day, a new set tomorrow.
/// Seeded by date, so it never reshuffles on rebuild.
List<TipItem> tipsForDay(BmiCategory cat, DateTime day, {int salt = 0}) =>
    _seededTake(healthTips[cat]!, _daySeed(day, salt), 3);

/// The single "tips hari ini" for the Home screen.
/// Different salt from the Result screen so they rarely overlap.
TipItem dailyTip(BmiCategory cat, DateTime day) =>
    _seededTake(healthTips[cat]!, _daySeed(day, 7919), 1).first;

/// Context-aware tips for the Result screen:
/// daily rotation, plus a 'comeback' tip when the trend moves away from
/// the goal and a 'streak' tip at 4+ weeks of consistency.
List<TipItem> tipsForResult({
  required BmiCategory cat,
  required List<double> weightsKg, // oldest-first
  required double? goalKg,
  required int streakWeeks,
  required DateTime day,
}) {
  // Not enough history yet: the 3 basics, like before.
  if (weightsKg.length < 2) return _tagged(cat, 'dasar');

  final tips = tipsForDay(cat, day);
  if (goalKg != null) {
    final last = weightsKg.last;
    final d = last - weightsKg.first;
    final away = (goalKg - last).abs() >= 0.5 &&
        ((goalKg < last && d > 0.05) || (goalKg > last && d < -0.05));
    if (away) {
      final pool = _tagged(cat, 'comeback');
      if (pool.isNotEmpty) {
        tips[0] = _seededOneExcept(pool, tips, _daySeed(day, 104729));
      }
    }
  }
  if (streakWeeks >= 4) {
    final pool = _tagged(cat, 'streak');
    if (pool.isNotEmpty) {
      tips[tips.length - 1] =
          _seededOneExcept(pool, tips, _daySeed(day, 1299709));
    }
  }
  return tips;
}

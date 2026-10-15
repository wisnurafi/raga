import 'dart:math';

import 'package:flutter/material.dart';
import 'bmi.dart';

// Health tips — written like advice from a friend. [healthTips] is the
// Indonesian original; [healthTipsEn] is the English twin (same order,
// same tags). Selection helpers take a locale and default to Indonesian.
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

// English twin of [healthTips] — same order, same tags, friend-tone v2
// like the Indonesian originals. The selection helpers pick the pool
// by locale; tests pin the Indonesian map and keep passing untouched.
const Map<BmiCategory, List<TipItem>> healthTipsEn = {
  BmiCategory.underweight: [
    (
      title: 'Eat more often',
      desc: 'Little but often, 5–6 times a day.',
      icon: Icons.restaurant_outlined,
      tags: {'dasar'},
    ),
    (
      title: 'Snack smart',
      desc: 'Nuts, avocado, milk. Not just fried stuff.',
      icon: Icons.cookie_outlined,
      tags: {'dasar'},
    ),
    (
      title: "Don't skip breakfast",
      desc: 'Rice + eggs is enough. Just get something in.',
      icon: Icons.free_breakfast_outlined,
      tags: {'dasar'},
    ),
    (
      title: 'Add protein',
      desc: 'Every meal needs its protein: eggs, chicken, tempeh, fish.',
      icon: Icons.egg_outlined,
      tags: <String>{},
    ),
    (
      title: 'Calories from drinks',
      desc: 'Avocado juice + milk. Easy, tasty, hits hard.',
      icon: Icons.local_cafe_outlined,
      tags: <String>{},
    ),
    (
      title: 'Lift weights',
      desc: 'Push-ups, squats, lift the water jug. Muscle up, weight follows.',
      icon: Icons.fitness_center_outlined,
      tags: {'streak'},
    ),
    (
      title: "Don't fear fat",
      desc: 'Avocado and nuts are great for gaining weight.',
      icon: Icons.eco_outlined,
      tags: <String>{},
    ),
    (
      title: 'Sleep enough',
      desc: 'Muscle is built while you sleep. Late nights = wasted.',
      icon: Icons.bedtime_outlined,
      tags: <String>{},
    ),
    (
      title: 'Log what you eat',
      desc:
          "Write down 3 days of meals. You'll see where you're short.",
      icon: Icons.edit_note_outlined,
      tags: {'comeback'},
    ),
    (
      title: 'Not just instant noodles',
      desc: "Fills you up, but the weight doesn't really go up.",
      icon: Icons.warning_amber_outlined,
      tags: <String>{},
    ),
    (
      title: 'Snack before bed',
      desc: 'Bread + milk 1–2 hours before sleep.',
      icon: Icons.nightlight_outlined,
      tags: <String>{},
    ),
    (
      title: "Don't drink before meals",
      desc: 'Drinking first = full first. Drink after you eat.',
      icon: Icons.water_drop_outlined,
      tags: <String>{},
    ),
    (
      title: 'Consistency first',
      desc: "Gaining 0.5 kg a week is already good. Don't rush.",
      icon: Icons.trending_up_outlined,
      tags: <String>{},
    ),
    (
      title: 'Rotate the menu',
      desc: 'Boredom is the enemy. Mix it up so your appetite comes back.',
      icon: Icons.restaurant_menu_outlined,
      tags: <String>{},
    ),
    (
      title: 'Eat with friends',
      desc: 'Eating together somehow adds a serving. Really.',
      icon: Icons.group_outlined,
      tags: <String>{},
    ),
    (
      title: 'Eating a lot but not gaining?',
      desc: 'Better see a doctor, just to be sure.',
      icon: Icons.medical_services_outlined,
      tags: {'comeback'},
    ),
  ],
  BmiCategory.normal: [
    (
      title: 'Stay active',
      desc: 'Walk 30 minutes, 5 days a week. That’s enough.',
      icon: Icons.bolt_outlined,
      tags: {'dasar'},
    ),
    (
      title: 'Drink enough',
      desc: '2 liters of water a day. Not sweet tea.',
      icon: Icons.water_drop_outlined,
      tags: {'dasar'},
    ),
    (
      title: 'Sleep regularly',
      desc: 'Aim for 7–8 hours. Late nights can shift your weight.',
      icon: Icons.bedtime_outlined,
      tags: {'dasar'},
    ),
    (
      title: 'Switch it up',
      desc: 'Bored of running? Try swimming or cycling.',
      icon: Icons.pool_outlined,
      tags: <String>{},
    ),
    (
      title: "Don't stress too much",
      desc: 'Stress wrecks your eating. Find a healthy outlet.',
      icon: Icons.spa_outlined,
      tags: <String>{},
    ),
    (
      title: 'Weigh in weekly',
      desc: 'Daily just makes you dizzy.',
      icon: Icons.monitor_weight_outlined,
      tags: <String>{},
    ),
    (
      title: 'Protein every meal',
      desc: 'Some protein each meal keeps you full longer.',
      icon: Icons.egg_outlined,
      tags: <String>{},
    ),
    (
      title: "Don't sit all day",
      desc: 'Every hour, stand up and walk a bit.',
      icon: Icons.timer_outlined,
      tags: <String>{},
    ),
    (
      title: 'Cook your own',
      desc: 'You control the oil, salt, and sugar.',
      icon: Icons.soup_kitchen_outlined,
      tags: <String>{},
    ),
    (
      title: 'Half a plate of veggies',
      desc: 'Easy, right? Every meal, half the plate veggies.',
      icon: Icons.eco_outlined,
      tags: <String>{},
    ),
    (
      title: 'Less sleep = hungrier',
      desc: 'Hunger hormones rise when you stay up late.',
      icon: Icons.nightlight_outlined,
      tags: {'comeback'},
    ),
    (
      title: 'Walk after meals',
      desc: 'Just 10 minutes, your stomach will thank you.',
      icon: Icons.hiking_outlined,
      tags: <String>{},
    ),
    (
      title: 'Cut back on alcohol',
      desc: "Beer packs big calories, you just don't feel it.",
      icon: Icons.no_drinks_outlined,
      tags: <String>{},
    ),
    (
      title: "Streak's going — don't break it",
      desc: 'Keep it.',
      icon: Icons.emoji_events_outlined,
      tags: {'streak'},
    ),
    (
      title: 'Check monthly',
      desc: 'Look at the History tab, not every day.',
      icon: Icons.insights_outlined,
      tags: <String>{},
    ),
    (
      title: 'Keep hanging out',
      desc: "Don't let watching your figure stop you from seeing friends.",
      icon: Icons.group_outlined,
      tags: <String>{},
    ),
  ],
  BmiCategory.overweight: [
    (
      title: 'Cut the sweet drinks',
      desc: 'Daily sweet iced tea is the culprit. Switch to water.',
      icon: Icons.local_drink_outlined,
      tags: {'dasar'},
    ),
    (
      title: 'Easy walk every day',
      desc: '30 minutes. No need to run.',
      icon: Icons.directions_walk_outlined,
      tags: {'dasar'},
    ),
    (
      title: 'Eat slowly',
      desc: "Chew slowly, stop when you're full.",
      icon: Icons.restaurant_outlined,
      tags: {'dasar'},
    ),
    (
      title: 'Smaller plate',
      desc: 'A small plate looks full. Stomach stays safe.',
      icon: Icons.restaurant_menu_outlined,
      tags: <String>{},
    ),
    (
      title: 'Kitchen closes at 8',
      desc: 'Give your digestion a break.',
      icon: Icons.nightlight_outlined,
      tags: {'comeback'},
    ),
    (
      title: 'Sides first, rice later',
      desc: 'Eating order affects how full you feel.',
      icon: Icons.egg_outlined,
      tags: <String>{},
    ),
    (
      title: 'Hungry? Eat fruit',
      desc: 'Banana or apple. Not fried snacks.',
      icon: Icons.apple_outlined,
      tags: <String>{},
    ),
    (
      title: 'Photograph your food for 3 days',
      desc: "You'll be shocked at the pattern.",
      icon: Icons.edit_note_outlined,
      tags: {'comeback'},
    ),
    (
      title: 'See stairs, take them',
      desc: "Don't wait for the elevator.",
      icon: Icons.stairs_outlined,
      tags: <String>{},
    ),
    (
      title: 'Sleep properly',
      desc: 'Less sleep = craving sweets tomorrow.',
      icon: Icons.bedtime_outlined,
      tags: <String>{},
    ),
    (
      title: 'One slip-up? Move on',
      desc: "Just continue. It's not the end of the world.",
      icon: Icons.favorite_outlined,
      tags: <String>{},
    ),
    (
      title: 'Drink before meals',
      desc: 'A glass of water 30 minutes before eating.',
      icon: Icons.water_drop_outlined,
      tags: <String>{},
    ),
    (
      title: 'Cut the fried food',
      desc: 'Fried chicken daily? Try grilled or steamed.',
      icon: Icons.soup_kitchen_outlined,
      tags: <String>{},
    ),
    (
      title: 'On a call? Walk',
      desc: "15 minutes around the block, you won't notice.",
      icon: Icons.directions_walk_outlined,
      tags: <String>{},
    ),
    (
      title: 'Small targets first',
      desc: '0.5 kg a week. Slow but it gets there.',
      icon: Icons.trending_down_outlined,
      tags: <String>{},
    ),
    (
      title: "Don't skip meals",
      desc: 'Skipping lunch = binging at night. Guaranteed.',
      icon: Icons.schedule_outlined,
      tags: <String>{},
    ),
    (
      title: 'Read the labels',
      desc: 'Check the sugar, not just the calories.',
      icon: Icons.label_outlined,
      tags: <String>{},
    ),
    (
      title: 'Right 5 days > perfect 2 days',
      desc: 'Consistency beats perfection.',
      icon: Icons.check_circle_outlined,
      tags: {'streak'},
    ),
    (
      title: 'Eat with slow eaters',
      desc: 'Your pace follows your tablemates.',
      icon: Icons.group_outlined,
      tags: <String>{},
    ),
  ],
  BmiCategory.obese: [
    (
      title: 'Start small',
      desc: 'No need for a marathon. Walk 15 minutes first.',
      icon: Icons.eco_outlined,
      tags: {'dasar'},
    ),
    (
      title: 'Move more',
      desc: '15 minutes a day. Ramp up slowly.',
      icon: Icons.directions_walk_outlined,
      tags: {'dasar'},
    ),
    (
      title: 'Talk to an expert',
      desc: 'See a nutritionist once, get a plan.',
      icon: Icons.medical_services_outlined,
      tags: {'dasar'},
    ),
    (
      title: 'Change one thing first',
      desc: 'Like cutting sweet drinks. That first, the rest later.',
      icon: Icons.flag_outlined,
      tags: {'comeback'},
    ),
    (
      title: '5-minute walk after meals',
      desc: 'Just 5 minutes, but it adds up.',
      icon: Icons.timer_outlined,
      tags: <String>{},
    ),
    (
      title: 'Sleep 7–8 hours',
      desc: 'Late nights make weight harder to lose. Really.',
      icon: Icons.bedtime_outlined,
      tags: <String>{},
    ),
    (
      title: "Don't crash diet",
      desc: 'Losing 5 kg a week usually gains back 7.',
      icon: Icons.warning_amber_outlined,
      tags: <String>{},
    ),
    (
      title: 'Bring a walking buddy',
      desc: "Alone is heavy. Together it's easier to stay consistent.",
      icon: Icons.group_outlined,
      tags: <String>{},
    ),
    (
      title: 'Down a kilo is an achievement',
      desc: "Don't brush it off.",
      icon: Icons.celebration_outlined,
      tags: {'streak'},
    ),
    (
      title: 'Photo every month',
      desc: "That's where the change shows.",
      icon: Icons.photo_camera_outlined,
      tags: <String>{},
    ),
    (
      title: 'Stock healthy snacks',
      desc: 'Put fruit in the fridge. Hungry? Just grab.',
      icon: Icons.shopping_basket_outlined,
      tags: <String>{},
    ),
    (
      title: 'Drink more water',
      desc: "Often it's thirst, mistaken for hunger.",
      icon: Icons.water_drop_outlined,
      tags: <String>{},
    ),
    (
      title: 'Stand every 30 minutes',
      desc: 'Set an alarm if you need to.',
      icon: Icons.self_improvement_outlined,
      tags: <String>{},
    ),
    (
      title: 'Weigh in weekly',
      desc: 'The number going up and down is normal.',
      icon: Icons.monitor_weight_outlined,
      tags: <String>{},
    ),
    (
      title: 'Tell your family',
      desc: "Tell them you're watching your food, so they stop offering.",
      icon: Icons.family_restroom_outlined,
      tags: <String>{},
    ),
    (
      title: 'Pick what you like',
      desc: "Hate running? Then don't run. Swim, cycle, whatever.",
      icon: Icons.favorite_outlined,
      tags: <String>{},
    ),
    (
      title: 'Tired? Rest',
      desc: 'Forcing it leads to quitting. Rest is part of the plan.',
      icon: Icons.weekend_outlined,
      tags: <String>{},
    ),
    (
      title: 'Eating when upset?',
      desc: 'Write down mood + what you ate. See the pattern.',
      icon: Icons.mood_outlined,
      tags: {'comeback'},
    ),
    (
      title: 'Take it slow',
      desc: "What matters is you don't stop.",
      icon: Icons.volunteer_activism_outlined,
      tags: {'streak'},
    ),
  ],
};

// --- selection ------------------------------------------------------------

Map<BmiCategory, List<TipItem>> _poolFor(String locale) =>
    locale == 'en' ? healthTipsEn : healthTips;

int _daySeed(DateTime day, int salt) =>
    day.year * 10000 + day.month * 100 + day.day + salt;

/// Deterministically picks [count] distinct tips from [pool].
List<TipItem> _seededTake(List<TipItem> pool, int seed, int count) {
  final idx = List<int>.generate(pool.length, (i) => i)
    ..shuffle(Random(seed));
  return [for (var i = 0; i < count && i < idx.length; i++) pool[idx[i]]];
}

List<TipItem> _tagged(BmiCategory cat, String tag, String locale) =>
    _poolFor(locale)[cat]!.where((t) => t.tags.contains(tag)).toList();

/// One deterministic pick from [pool], avoiding [exclude] when possible.
TipItem _seededOneExcept(List<TipItem> pool, List<TipItem> exclude, int seed) {
  final rest = pool.where((t) => !exclude.contains(t)).toList();
  final src = rest.isNotEmpty ? rest : pool;
  return _seededTake(src, seed, 1).first;
}

/// 3 tips for the day: same set all day, a new set tomorrow.
/// Seeded by date, so it never reshuffles on rebuild.
List<TipItem> tipsForDay(BmiCategory cat, DateTime day,
        {int salt = 0, String locale = 'id'}) =>
    _seededTake(_poolFor(locale)[cat]!, _daySeed(day, salt), 3);

/// The single "tips hari ini" for the Home screen.
/// Different salt from the Result screen so they rarely overlap.
TipItem dailyTip(BmiCategory cat, DateTime day, {String locale = 'id'}) =>
    _seededTake(_poolFor(locale)[cat]!, _daySeed(day, 7919), 1).first;

/// Context-aware tips for the Result screen:
/// daily rotation, plus a 'comeback' tip when the trend moves away from
/// the goal and a 'streak' tip at 4+ weeks of consistency.
List<TipItem> tipsForResult({
  required BmiCategory cat,
  required List<double> weightsKg, // oldest-first
  required double? goalKg,
  required int streakWeeks,
  required DateTime day,
  String locale = 'id',
}) {
  // Not enough history yet: the 3 basics, like before.
  if (weightsKg.length < 2) return _tagged(cat, 'dasar', locale);

  final tips = tipsForDay(cat, day, locale: locale);
  if (goalKg != null) {
    final last = weightsKg.last;
    final d = last - weightsKg.first;
    final away = (goalKg - last).abs() >= 0.5 &&
        ((goalKg < last && d > 0.05) || (goalKg > last && d < -0.05));
    if (away) {
      final pool = _tagged(cat, 'comeback', locale);
      if (pool.isNotEmpty) {
        tips[0] = _seededOneExcept(pool, tips, _daySeed(day, 104729));
      }
    }
  }
  if (streakWeeks >= 4) {
    final pool = _tagged(cat, 'streak', locale);
    if (pool.isNotEmpty) {
      tips[tips.length - 1] =
          _seededOneExcept(pool, tips, _daySeed(day, 1299709));
    }
  }
  return tips;
}

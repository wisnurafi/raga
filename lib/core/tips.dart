import 'package:flutter/material.dart';
import 'bmi.dart';

// Health tips per category, in Indonesian — written like advice from a
// friend, not a medical journal. The Normal trio matches the mockup
// word for word ("Tetap aktif" / "Cukup minum" / "Tidur teratur").
typedef TipItem = ({String title, String desc, IconData icon});

const Map<BmiCategory, List<TipItem>> healthTips = {
  BmiCategory.underweight: [
    (
      title: 'Makan lebih sering',
      desc: 'Porsi kecil tapi padat nutrisi.',
      icon: Icons.restaurant_outlined,
    ),
    (
      title: 'Ngemil cerdas',
      desc: 'Kacang, alpukat, dan susu pilihan tepat.',
      icon: Icons.cookie_outlined,
    ),
    (
      title: 'Jangan lewatkan sarapan',
      desc: 'Bahan bakar pagimu.',
      icon: Icons.free_breakfast_outlined,
    ),
  ],
  BmiCategory.normal: [
    (
      title: 'Tetap aktif',
      desc: 'Jalan kaki 30 menit, 5 hari seminggu.',
      icon: Icons.bolt_outlined,
    ),
    (
      title: 'Cukup minum',
      desc: 'Air putih sekitar 2 liter per hari.',
      icon: Icons.water_drop_outlined,
    ),
    (
      title: 'Tidur teratur',
      desc: '7–8 jam tiap malam.',
      icon: Icons.bedtime_outlined,
    ),
  ],
  BmiCategory.overweight: [
    (
      title: 'Kurangi minuman manis',
      desc: 'Ganti dengan air putih.',
      icon: Icons.local_drink_outlined,
    ),
    (
      title: 'Jalan santai tiap hari',
      desc: '30 menit jalan santai setiap hari.',
      icon: Icons.directions_walk_outlined,
    ),
    (
      title: 'Makan perlahan',
      desc: 'Berhenti saat sudah kenyang.',
      icon: Icons.restaurant_outlined,
    ),
  ],
  BmiCategory.obese: [
    (
      title: 'Mulai dari yang kecil',
      desc: 'Langkah kecil yang bisa kamu pertahankan.',
      icon: Icons.eco_outlined,
    ),
    (
      title: 'Bergerak lebih banyak',
      desc: '15 menit sehari, tambah pelan-pelan.',
      icon: Icons.directions_walk_outlined,
    ),
    (
      title: 'Konsultasi ke ahli',
      desc: 'Pertimbangkan bicara dengan ahli gizi.',
      icon: Icons.medical_services_outlined,
    ),
  ],
};

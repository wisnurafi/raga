import 'bmi.dart';

// Health tips per category — written like advice from a friend,
// not a medical journal.
const Map<BmiCategory, List<String>> healthTips = {
  BmiCategory.underweight: [
    'Eat more often, smaller portions but packed with nutrients.',
    'Snack on things like nuts, avocado, and milk.',
    'Try some light weight training 2–3 times a week.',
    "Don't skip breakfast — it's your morning fuel.",
  ],
  BmiCategory.normal: [
    'Your weight is right where it should be. Keep it up with a 30-minute walk, 5 days a week.',
    'Drink about 2 liters of water a day.',
    'Get 7–8 hours of sleep to keep your metabolism steady.',
    'Weigh yourself once a week to stay on track.',
  ],
  BmiCategory.overweight: [
    'Swap sugary drinks for water.',
    'Take a relaxed 30-minute walk every day.',
    "Eat slowly, and stop when you're full.",
    'Cut back on late-night snacking.',
  ],
  BmiCategory.obese: [
    'Start with small steps you can actually stick to.',
    'Cut back on fried food and soda first.',
    'Walk 15 minutes a day, then add more little by little.',
    'Consider talking to a nutritionist.',
  ],
};

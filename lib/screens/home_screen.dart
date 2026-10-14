import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/bmi.dart';
import '../state/app_state.dart';
import '../widgets/glass.dart';
import 'cards.dart';
import 'result_screen.dart';

/// Layar "Hitung": input tinggi & berat badan, pilihan profil,
/// jenis kelamin, dan umur.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _pid = '';
  double _h = 170;
  double _w = 65;
  bool _isMale = true;
  int _age = 21;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final p = AppState.of(context).activeProfile;
    if (p.id != _pid) {
      _pid = p.id;
      _h = p.heightCm;
      _w = p.weightKg;
      _isMale = p.isMale;
      _age = p.age;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.of(context);
    final rc = context.rc;
    final p = state.activeProfile;
    final metric = state.metricUnits;

    final hDisp = metric ? _h : _h / 2.54;
    final wDisp = metric ? _w : _w * 2.20462;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
      children: [
        _header(context, rc, p),
        const SizedBox(height: 18),
        Text(
          '${greetingFor(DateTime.now())}, ${p.name}',
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w800,
            color: rc.onBg,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${_dayName(DateTime.now())}, ${formatDateId(DateTime.now())} ${DateTime.now().year}',
          style: TextStyle(fontSize: 14, color: rc.onBgMuted),
        ),
        const SizedBox(height: 16),
        const ProfileChips(),
        const SizedBox(height: 22),
        SectionTitle('Data tubuh', trailing: const UnitToggle()),
        MeasureCard(
          label: 'Tinggi badan',
          displayValue: hDisp,
          unit: metric ? 'cm' : 'inci',
          min: metric ? 120 : 47,
          max: metric ? 220 : 87,
          onChanged: (v) => setState(() => _h = metric ? v : v * 2.54),
        ),
        const SizedBox(height: 14),
        MeasureCard(
          label: 'Berat badan',
          displayValue: wDisp,
          unit: metric ? 'kg' : 'lb',
          min: metric ? 30 : 66,
          max: metric ? 150 : 331,
          onChanged: (v) => setState(() => _w = metric ? v : v / 2.20462),
        ),
        const SizedBox(height: 14),
        _genderAgeCard(context, state, rc),
        const SizedBox(height: 18),
        RagaButton(
          label: 'Hitung BMI',
          onPressed: () => _calculate(context, state, p),
        ),
      ],
    );
  }

  Widget _header(BuildContext context, RagaColors rc, dynamic p) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [rc.primaryBtn, const Color(0xFF9A8CF5)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: rc.primaryBtn.withValues(alpha: 0.4),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.monitor_heart_outlined,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Raga',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                color: rc.onBg,
                letterSpacing: -0.8,
              ),
            ),
          ],
        ),
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFFE8C98F),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.9),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              p.initial,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1B1B2F),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _genderAgeCard(
      BuildContext context, AppState state, RagaColors rc) {
    return GlassContainer(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: rc.panel.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  _genderSeg(context, 'Pria', _isMale, () {
                    setState(() => _isMale = true);
                    state.updateActiveProfile((p) => p.copyWith(isMale: true));
                  }),
                  _genderSeg(context, 'Wanita', !_isMale, () {
                    setState(() => _isMale = false);
                    state.updateActiveProfile((p) => p.copyWith(isMale: false));
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Row(
            children: [
              _ageBtn(context, Icons.remove, () {
                if (_age > 5) {
                  setState(() => _age--);
                  final a = _age;
                  state.updateActiveProfile((p) => p.copyWith(age: a));
                }
              }),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '$_age thn',
                  style: TextStyle(
                    color: rc.onBg,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _ageBtn(context, Icons.add, () {
                if (_age < 100) {
                  setState(() => _age++);
                  final a = _age;
                  state.updateActiveProfile((p) => p.copyWith(age: a));
                }
              }),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _genderSeg(
      BuildContext context, String label, bool active, VoidCallback onTap) {
    final rc = context.rc;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: active
                ? LinearGradient(
                    colors: [rc.primaryBtn, const Color(0xFF9A8CF5)],
                  )
                : null,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: active ? rc.onPrimaryBtn : rc.onBgMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _ageBtn(BuildContext context, IconData icon, VoidCallback onTap) {
    final rc = context.rc;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: rc.primaryBtn.withValues(alpha: 0.14),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 17, color: rc.primaryBtn),
      ),
    );
  }

  void _calculate(BuildContext context, AppState state, dynamic p) {
    // Simpan data tubuh terakhir ke profil.
    state.updateActiveProfile(
      (old) => old.copyWith(heightCm: _h, weightKg: _w),
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          heightCm: _h,
          weightKg: _w,
          profileName: p.name as String,
        ),
      ),
    );
  }

  String _dayName(DateTime d) {
    const days = [
      'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'
    ];
    return days[d.weekday - 1];
  }
}

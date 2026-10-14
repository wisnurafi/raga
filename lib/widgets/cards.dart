import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/bmi.dart';
import '../state/app_state.dart';

/// Kartu putih untuk input angka + slider, seperti di desain referensi.
class MeasureCard extends StatelessWidget {
  final String label;
  final double displayValue;
  final String unit;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const MeasureCard({
    super.key,
    required this.label,
    required this.displayValue,
    required this.unit,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: BoxDecoration(
        color: rc.card,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: rc.onCardMuted,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                formatId(displayValue, 0),
                style: TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -2,
                  color: rc.onCard,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: rc.onCardMuted,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF8B7CF0),
              inactiveTrackColor: const Color(0xFFE4DEFB),
              thumbColor: const Color(0xFF8B7CF0),
            ),
            child: Slider(
              value: displayValue.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

/// Toggle satuan: cm·kg / in·lb
class UnitToggle extends StatelessWidget {
  const UnitToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppState.of(context);
    final rc = context.rc;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: rc.chipInactive.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _seg(context, 'cm · kg', state.metricUnits,
              () => state.setMetricUnits(true)),
          _seg(context, 'in · lb', !state.metricUnits,
              () => state.setMetricUnits(false)),
        ],
      ),
    );
  }

  Widget _seg(
      BuildContext context, String label, bool active, VoidCallback onTap) {
    final rc = context.rc;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: active ? const Color(0xFF1B1B2F) : rc.onBgMuted,
          ),
        ),
      ),
    );
  }
}

/// Deretan chip profil + tombol tambah.
class ProfileChips extends StatelessWidget {
  const ProfileChips({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppState.of(context);
    final rc = context.rc;
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: state.profiles.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          if (i == state.profiles.length) {
            return GestureDetector(
              onTap: () => _showAddDialog(context),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.55),
                    width: 1.5,
                    style: BorderStyle.solid,
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.add, size: 16, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'Tambah',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          final p = state.profiles[i];
          final active = p.id == state.activeProfileId;
          return GestureDetector(
            onTap: () => state.setActiveProfile(p.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: active ? Colors.white : rc.chipInactive.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Center(
                child: Text(
                  p.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: active ? const Color(0xFF1B1B2F) : Colors.white,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Profil baru'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Nama, mis. Ayah',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _submit(ctx, ctrl),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => _submit(ctx, ctrl),
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }

  void _submit(BuildContext ctx, TextEditingController ctrl) {
    final name = ctrl.text.trim();
    Navigator.pop(ctx);
    if (name.isNotEmpty) AppState.of(ctx).addProfile(name);
  }
}

/// Tombol utama Raga (lavender, teks gelap).
class RagaButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool outlined;

  const RagaButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor:
              outlined ? Colors.transparent : rc.primaryBtn,
          foregroundColor: rc.onPrimaryBtn,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
            side: outlined
                ? BorderSide(color: Colors.white.withValues(alpha: 0.6), width: 1.5)
                : BorderSide.none,
          ),
          textStyle:
              const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ).copyWith(
          foregroundColor: outlined
              ? WidgetStatePropertyAll(Colors.white)
              : null,
        ),
        child: Text(label),
      ),
    );
  }
}

/// Judul seksi kecil di atas konten.
class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionTitle(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: rc.onBg,
              letterSpacing: -0.3,
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

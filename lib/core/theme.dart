import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palet warna Raga — dikunci ke mode terang (light).
///
/// Arah visual: glassmorphism di atas latar "healthy care" yang lembut
/// (putih bersih + aksen mint dan lavender pucat). Semua teks memakai
/// warna gelap di atas permukaan terang, jadi tidak ada lagi teks putih
/// yang hilang di atas kartu terang.
@immutable
class RagaColors extends ThemeExtension<RagaColors> {
  final List<Color> bgGradient;
  final Color card;
  final Color panel;
  final Color onCard;
  final Color onCardMuted;
  final Color onBg;
  final Color onBgMuted;
  final Color primaryBtn;
  final Color onPrimaryBtn;
  final Color chipActive;
  final Color chipInactive;
  final Color onChipActive;
  final Color onChipInactive;
  final Color mint;
  final Color mintSoft;

  const RagaColors({
    required this.bgGradient,
    required this.card,
    required this.panel,
    required this.onCard,
    required this.onCardMuted,
    required this.onBg,
    required this.onBgMuted,
    required this.primaryBtn,
    required this.onPrimaryBtn,
    required this.chipActive,
    required this.chipInactive,
    required this.onChipActive,
    required this.onChipInactive,
    required this.mint,
    required this.mintSoft,
  });

  static const light = RagaColors(
    bgGradient: [Color(0xFFEDF1F8), Color(0xFFD9E2F1)],
    card: Color(0xFFFFFFFF),
    panel: Color(0xFFEDE9FB),
    onCard: Color(0xFF1B1B2F),
    onCardMuted: Color(0xFF6E6E93),
    onBg: Color(0xFF1B1B2F),
    onBgMuted: Color(0xFF5A5680),
    primaryBtn: Color(0xFF7E6EE8),
    onPrimaryBtn: Color(0xFFFFFFFF),
    chipActive: Color(0xFF7E6EE8),
    chipInactive: Color(0xFFFFFFFF),
    onChipActive: Color(0xFFFFFFFF),
    onChipInactive: Color(0xFF1B1B2F),
    mint: Color(0xFF22B573),
    mintSoft: Color(0xFFE6F9EF),
  );

  @override
  RagaColors copyWith({
    List<Color>? bgGradient,
    Color? card,
    Color? panel,
    Color? onCard,
    Color? onCardMuted,
    Color? onBg,
    Color? onBgMuted,
    Color? primaryBtn,
    Color? onPrimaryBtn,
    Color? chipActive,
    Color? chipInactive,
    Color? onChipActive,
    Color? onChipInactive,
    Color? mint,
    Color? mintSoft,
  }) {
    return RagaColors(
      bgGradient: bgGradient ?? this.bgGradient,
      card: card ?? this.card,
      panel: panel ?? this.panel,
      onCard: onCard ?? this.onCard,
      onCardMuted: onCardMuted ?? this.onCardMuted,
      onBg: onBg ?? this.onBg,
      onBgMuted: onBgMuted ?? this.onBgMuted,
      primaryBtn: primaryBtn ?? this.primaryBtn,
      onPrimaryBtn: onPrimaryBtn ?? this.onPrimaryBtn,
      chipActive: chipActive ?? this.chipActive,
      chipInactive: chipInactive ?? this.chipInactive,
      onChipActive: onChipActive ?? this.onChipActive,
      onChipInactive: onChipInactive ?? this.onChipInactive,
      mint: mint ?? this.mint,
      mintSoft: mintSoft ?? this.mintSoft,
    );
  }

  @override
  RagaColors lerp(ThemeExtension<RagaColors>? other, double t) {
    if (other is! RagaColors) return this;
    Color lerpC(Color a, Color b) => Color.lerp(a, b, t)!;
    return RagaColors(
      bgGradient: [
        lerpC(bgGradient[0], other.bgGradient[0]),
        lerpC(bgGradient[1], other.bgGradient[1]),
      ],
      card: lerpC(card, other.card),
      panel: lerpC(panel, other.panel),
      onCard: lerpC(onCard, other.onCard),
      onCardMuted: lerpC(onCardMuted, other.onCardMuted),
      onBg: lerpC(onBg, other.onBg),
      onBgMuted: lerpC(onBgMuted, other.onBgMuted),
      primaryBtn: lerpC(primaryBtn, other.primaryBtn),
      onPrimaryBtn: lerpC(onPrimaryBtn, other.onPrimaryBtn),
      chipActive: lerpC(chipActive, other.chipActive),
      chipInactive: lerpC(chipInactive, other.chipInactive),
      onChipActive: lerpC(onChipActive, other.onChipActive),
      onChipInactive: lerpC(onChipInactive, other.onChipInactive),
      mint: lerpC(mint, other.mint),
      mintSoft: lerpC(mintSoft, other.mintSoft),
    );
  }
}

extension RagaThemeX on BuildContext {
  RagaColors get rc => Theme.of(this).extension<RagaColors>()!;
}

class AppTheme {
  static ThemeData get light {
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(
      ThemeData.light().textTheme,
    );
    return ThemeData(
      brightness: Brightness.light,
      textTheme: textTheme,
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF7E6EE8),
        brightness: Brightness.light,
      ),
      extensions: const [RagaColors.light],
      sliderTheme: SliderThemeData(
        trackHeight: 6,
        overlayShape: SliderComponentShape.noOverlay,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 13),
      ),
      useMaterial3: true,
    );
  }
}

/// Latar aplikasi: gradasi terang yang bersih dengan blob warna lembut
/// (mint, lavender, peach) dan motif garis detak jantung (ECG) yang samar —
/// konteks "healthy care" tanpa mengganggu keterbacaan.
class HealthBg extends StatelessWidget {
  final Widget child;
  const HealthBg({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: rc.bgGradient,
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(
            child: CustomPaint(painter: _HealthBgPainter()),
          ),
          child,
        ],
      ),
    );
  }
}

class _HealthBgPainter extends CustomPainter {
  const _HealthBgPainter();

  void _blob(Canvas canvas, Offset c, double r, Color color) {
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = color
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 70),
    );
  }

  /// Garis detak jantung (ECG) — motif utama latar "vital sign".
  /// Mengembalikan titik puncak tiap spike untuk digambar sebagai
  /// penanda data, supaya semua elemen terasa satu sistem.
  List<Offset> _ecg(Canvas canvas, Size size, double baseY, double alpha) {
    const period = 170.0;
    const amp = 36.0;
    final peaks = <Offset>[];
    final path = Path()..moveTo(-20, baseY);
    for (double x = -20; x < size.width + 20; x += period) {
      path.lineTo(x + period * 0.30, baseY);
      path.lineTo(x + period * 0.38, baseY + amp * 0.25);
      final peak = Offset(x + period * 0.45, baseY - amp);
      peaks.add(peak);
      path.lineTo(peak.dx, peak.dy);
      path.lineTo(x + period * 0.51, baseY + amp * 0.55);
      path.lineTo(x + period * 0.59, baseY);
      path.lineTo(x + period, baseY);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF7E6EE8).withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
    return peaks;
  }

  /// Titik data di tiap puncak detak — aksen yang menyatu dengan garis ECG.
  void _peakDots(Canvas canvas, List<Offset> peaks) {
    for (final p in peaks) {
      canvas.drawCircle(
        p,
        11,
        Paint()
          ..color = const Color(0xFF22B573).withValues(alpha: 0.13),
      );
      canvas.drawCircle(
        p,
        4.5,
        Paint()
          ..color = const Color(0xFF22B573).withValues(alpha: 0.32),
      );
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    _blob(canvas, Offset(size.width * 0.88, size.height * 0.06),
        size.width * 0.44, const Color(0xFFBDEFD4).withValues(alpha: 0.65));
    _blob(canvas, Offset(size.width * 0.05, size.height * 0.44),
        size.width * 0.40, const Color(0xFFD9CFFF).withValues(alpha: 0.60));
    _blob(canvas, Offset(size.width * 0.82, size.height * 0.90),
        size.width * 0.46, const Color(0xFFFFE3C2).withValues(alpha: 0.55));
    final peaks = _ecg(canvas, size, size.height * 0.13, 0.14);
    _peakDots(canvas, peaks);
    _ecg(canvas, size, size.height * 0.74, 0.07);
  }

  @override
  bool shouldRepaint(_HealthBgPainter old) => false;
}

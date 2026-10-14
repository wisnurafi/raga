import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palet warna Raga. Diambil dari desain referensi: gradasi ungu,
/// kartu putih untuk input, kartu gelap untuk panel.
@immutable
class RagaColors extends ThemeExtension<RagaColors> {
  final List<Color> bgGradient;
  final Color card;
  final Color cardDark;
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

  const RagaColors({
    required this.bgGradient,
    required this.card,
    required this.cardDark,
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
  });

  static const dark = RagaColors(
    bgGradient: [Color(0xFF7E6EE8), Color(0xFF14152E)],
    card: Color(0xFFFFFFFF),
    cardDark: Color(0xFF23234D),
    onCard: Color(0xFF1B1B2F),
    onCardMuted: Color(0xFF6E6E93),
    onBg: Color(0xFFFFFFFF),
    onBgMuted: Color(0xFFC9C5F2),
    primaryBtn: Color(0xFFB9A7F2),
    onPrimaryBtn: Color(0xFF1B1B2F),
    chipActive: Color(0xFFB9A7F2),
    chipInactive: Color(0xFF2A2B55),
    onChipActive: Color(0xFF1B1B2F),
    onChipInactive: Color(0xFFFFFFFF),
  );

  static const light = RagaColors(
    bgGradient: [Color(0xFF9D8FF5), Color(0xFFF0EDFF)],
    card: Color(0xFFFFFFFF),
    cardDark: Color(0xFFE4DEFB),
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
  );

  @override
  RagaColors copyWith({
    List<Color>? bgGradient,
    Color? card,
    Color? cardDark,
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
  }) {
    return RagaColors(
      bgGradient: bgGradient ?? this.bgGradient,
      card: card ?? this.card,
      cardDark: cardDark ?? this.cardDark,
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
      cardDark: lerpC(cardDark, other.cardDark),
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
    );
  }
}

extension RagaThemeX on BuildContext {
  RagaColors get rc => Theme.of(this).extension<RagaColors>()!;
}

class AppTheme {
  static ThemeData _base(Brightness brightness, RagaColors rc) {
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(
      ThemeData(brightness: brightness).textTheme,
    );
    return ThemeData(
      brightness: brightness,
      textTheme: textTheme,
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF7E6EE8),
        brightness: brightness,
      ),
      extensions: [rc],
      sliderTheme: SliderThemeData(
        trackHeight: 6,
        overlayShape: SliderComponentShape.noOverlay,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 13),
      ),
      useMaterial3: true,
    );
  }

  static ThemeData get dark => _base(Brightness.dark, RagaColors.dark);
  static ThemeData get light => _base(Brightness.light, RagaColors.light);
}

/// Latar gradasi ungu khas Raga, dipakai sebagai root tiap layar.
class GradientBg extends StatelessWidget {
  final Widget child;
  const GradientBg({super.key, required this.child});

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
      child: child,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

// Raga colors — locked to light mode.
//
// The look: frosted-glass cards floating over artwork. Everything the user
// reads sits on a light surface, so text is always dark — except for the
// few labels drawn directly on the background image, which use onImage.
@immutable
class RagaColors extends ThemeExtension<RagaColors> {
  final Color card;
  final Color panel;
  final Color onCard;
  final Color onCardMuted;
  final Color onCardAccent;
  final Color onBg;
  final Color onBgMuted;
  final Color onImage;
  final Color onImageMuted;
  final Color primaryBtn;
  final Color onPrimaryBtn;
  final Color chipActive;
  final Color chipInactive;
  final Color onChipActive;
  final Color onChipInactive;
  final Color mint;
  final Color mintSoft;

  const RagaColors({
    required this.card,
    required this.panel,
    required this.onCard,
    required this.onCardMuted,
    required this.onCardAccent,
    required this.onBg,
    required this.onBgMuted,
    required this.onImage,
    required this.onImageMuted,
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
    card: Color(0xFFFFFFFF),
    panel: Color(0xFFEDE9FB),
    onCard: Color(0xFF1B1B2F),
    onCardMuted: Color(0xFF55517E),
    onCardAccent: Color(0xFF6A5AC8),
    onBg: Color(0xFF1B1B2F),
    onBgMuted: Color(0xFF5A5680),
    onImage: Color(0xFFFFFFFF),
    onImageMuted: Color(0xB8FFFFFF),
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
    Color? card,
    Color? panel,
    Color? onCard,
    Color? onCardMuted,
    Color? onCardAccent,
    Color? onBg,
    Color? onBgMuted,
    Color? onImage,
    Color? onImageMuted,
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
      card: card ?? this.card,
      panel: panel ?? this.panel,
      onCard: onCard ?? this.onCard,
      onCardMuted: onCardMuted ?? this.onCardMuted,
      onCardAccent: onCardAccent ?? this.onCardAccent,
      onBg: onBg ?? this.onBg,
      onBgMuted: onBgMuted ?? this.onBgMuted,
      onImage: onImage ?? this.onImage,
      onImageMuted: onImageMuted ?? this.onImageMuted,
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
      card: lerpC(card, other.card),
      panel: lerpC(panel, other.panel),
      onCard: lerpC(onCard, other.onCard),
      onCardMuted: lerpC(onCardMuted, other.onCardMuted),
      onCardAccent: lerpC(onCardAccent, other.onCardAccent),
      onBg: lerpC(onBg, other.onBg),
      onBgMuted: lerpC(onBgMuted, other.onBgMuted),
      onImage: lerpC(onImage, other.onImage),
      onImageMuted: lerpC(onImageMuted, other.onImageMuted),
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

// App background: Wisnu's artwork, drawn full-bleed behind everything.
// The glass cards blur it, so it doubles as the frost source.
class HealthBg extends StatelessWidget {
  final Widget child;
  const HealthBg({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF241F5C),
      child: Stack(
        children: [
          Positioned.fill(
            child: SvgPicture.asset(
              'assets/images/raga-background.svg',
              fit: BoxFit.cover,
            ),
          ),
          child,
        ],
      ),
    );
  }
}

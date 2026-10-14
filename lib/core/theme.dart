import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Raga design language — rebuilt from Wisnu's mockup (2026-10-14).
//
// The look: frosted-glass cards floating over an illustrated deep-purple
// background (his gradient + leaf branches + ECG line + concentric rings).
// Dark mode IS the mockup. Light mode re-speaks the same visual language
// on a light lavender canvas: same glass, same lavender accents, same
// category colors — only the surfaces and text flip.
@immutable
class RagaColors extends ThemeExtension<RagaColors> {
  final bool isDark;

  /// Fallback surface behind the background art.
  final Color bgFallback;

  /// Frosted-glass card fill + hairline border.
  final Color card;
  final Color cardBorder;

  /// Text on glass cards.
  final Color onCard;
  final Color onCardMuted;
  final Color onCardAccent;

  /// Text drawn directly on the background (headers, section titles).
  final Color onBg;
  final Color onBgMuted;

  /// Primary button gradient + its label color.
  final Color btnTop;
  final Color btnBottom;
  final Color onBtn;

  /// Selectable chips / segmented controls.
  final Color chipActive;
  final Color onChipActive;
  final Color chipInactive;
  final Color onChipInactive;

  /// Category badge (e.g. "Normal").
  final Color badgeOk;
  final Color onBadgeOk;

  /// BMI category colors: underweight / normal / overweight / obese.
  final Color catUnder;
  final Color catNormal;
  final Color catOver;
  final Color catObese;

  /// Sliders.
  final Color sliderTrack;
  final Color sliderFill;
  final Color sliderThumb;

  /// Floating bottom nav.
  final Color navBg;
  final Color navIcon;
  final Color navActive;
  final Color navActiveIcon;

  /// Header avatar circle.
  final Color avatarBg;
  final Color avatarFg;

  /// Background illustration: concentric rings, ECG line, leaf branches.
  final Color decoRings;
  final Color decoEcg;
  final Color decoLeaf;
  final Color decoLeafVein;

  final Color danger;

  const RagaColors({
    required this.isDark,
    required this.bgFallback,
    required this.card,
    required this.cardBorder,
    required this.onCard,
    required this.onCardMuted,
    required this.onCardAccent,
    required this.onBg,
    required this.onBgMuted,
    required this.btnTop,
    required this.btnBottom,
    required this.onBtn,
    required this.chipActive,
    required this.onChipActive,
    required this.chipInactive,
    required this.onChipInactive,
    required this.badgeOk,
    required this.onBadgeOk,
    required this.catUnder,
    required this.catNormal,
    required this.catOver,
    required this.catObese,
    required this.sliderTrack,
    required this.sliderFill,
    required this.sliderThumb,
    required this.navBg,
    required this.navIcon,
    required this.navActive,
    required this.navActiveIcon,
    required this.avatarBg,
    required this.avatarFg,
    required this.decoRings,
    required this.decoEcg,
    required this.decoLeaf,
    required this.decoLeafVein,
    required this.danger,
  });

  // The mockup, exactly: deep purple, glass cards, white text,
  // lavender buttons with dark-navy labels.
  static const dark = RagaColors(
    isDark: true,
    bgFallback: Color(0xFF2A2158),
    card: Color(0x1AFFFFFF),
    cardBorder: Color(0x38FFFFFF),
    onCard: Color(0xFFFFFFFF),
    onCardMuted: Color(0xA6FFFFFF),
    onCardAccent: Color(0xFFC4B5FD),
    onBg: Color(0xFFFFFFFF),
    onBgMuted: Color(0xA6FFFFFF),
    btnTop: Color(0xFFC2B1F7),
    btnBottom: Color(0xFF9C84F1),
    onBtn: Color(0xFF2B2358),
    chipActive: Color(0xFFAE97F2),
    onChipActive: Color(0xFF2B2358),
    chipInactive: Color(0x1AFFFFFF),
    onChipInactive: Color(0xFFFFFFFF),
    badgeOk: Color(0xFF4ADE80),
    onBadgeOk: Color(0xFF0B3B24),
    catUnder: Color(0xFF60A5FA),
    catNormal: Color(0xFF34D399),
    catOver: Color(0xFFFBBF24),
    catObese: Color(0xFFFB7185),
    sliderTrack: Color(0x2EFFFFFF),
    sliderFill: Color(0xFFAE97F2),
    sliderThumb: Color(0xFFFFFFFF),
    navBg: Color(0x8C1E1848),
    navIcon: Color(0x8CFFFFFF),
    navActive: Color(0xFFAE97F2),
    navActiveIcon: Color(0xFFFFFFFF),
    avatarBg: Color(0xFFE4C68C),
    avatarFg: Color(0xFF2B2358),
    decoRings: Color(0x14FFFFFF),
    decoEcg: Color(0x595EEAD4),
    decoLeaf: Color(0x1FFFFFFF),
    decoLeafVein: Color(0x30FFFFFF),
    danger: Color(0xFFFB7185),
  );

  // Same language on a light canvas: white glass, deep-purple text,
  // identical accents and category colors.
  static const light = RagaColors(
    isDark: false,
    bgFallback: Color(0xFFF2EEFB),
    card: Color(0x99FFFFFF),
    cardBorder: Color(0xB3FFFFFF),
    onCard: Color(0xFF2B2358),
    onCardMuted: Color(0xFF6F6894),
    onCardAccent: Color(0xFF6A5AC8),
    onBg: Color(0xFF2B2358),
    onBgMuted: Color(0xFF6F6894),
    btnTop: Color(0xFFC2B1F7),
    btnBottom: Color(0xFF9C84F1),
    onBtn: Color(0xFF2B2358),
    chipActive: Color(0xFF8B7CF0),
    onChipActive: Color(0xFFFFFFFF),
    chipInactive: Color(0x80FFFFFF),
    onChipInactive: Color(0xFF2B2358),
    badgeOk: Color(0xFF4ADE80),
    onBadgeOk: Color(0xFF0B3B24),
    catUnder: Color(0xFF60A5FA),
    catNormal: Color(0xFF34D399),
    catOver: Color(0xFFFBBF24),
    catObese: Color(0xFFFB7185),
    sliderTrack: Color(0x332B2358),
    sliderFill: Color(0xFF8B7CF0),
    sliderThumb: Color(0xFFFFFFFF),
    navBg: Color(0xA6FFFFFF),
    navIcon: Color(0xFF8A84A8),
    navActive: Color(0xFF8B7CF0),
    navActiveIcon: Color(0xFFFFFFFF),
    avatarBg: Color(0xFFE4C68C),
    avatarFg: Color(0xFF2B2358),
    decoRings: Color(0x146A5AC8),
    decoEcg: Color(0x4D6A5AC8),
    decoLeaf: Color(0x1A6A5AC8),
    decoLeafVein: Color(0x336A5AC8),
    danger: Color(0xFFE11D48),
  );

  @override
  RagaColors copyWith({
    bool? isDark,
    Color? bgFallback,
    Color? card,
    Color? cardBorder,
    Color? onCard,
    Color? onCardMuted,
    Color? onCardAccent,
    Color? onBg,
    Color? onBgMuted,
    Color? btnTop,
    Color? btnBottom,
    Color? onBtn,
    Color? chipActive,
    Color? onChipActive,
    Color? chipInactive,
    Color? onChipInactive,
    Color? badgeOk,
    Color? onBadgeOk,
    Color? catUnder,
    Color? catNormal,
    Color? catOver,
    Color? catObese,
    Color? sliderTrack,
    Color? sliderFill,
    Color? sliderThumb,
    Color? navBg,
    Color? navIcon,
    Color? navActive,
    Color? navActiveIcon,
    Color? avatarBg,
    Color? avatarFg,
    Color? decoRings,
    Color? decoEcg,
    Color? decoLeaf,
    Color? decoLeafVein,
    Color? danger,
  }) {
    return RagaColors(
      isDark: isDark ?? this.isDark,
      bgFallback: bgFallback ?? this.bgFallback,
      card: card ?? this.card,
      cardBorder: cardBorder ?? this.cardBorder,
      onCard: onCard ?? this.onCard,
      onCardMuted: onCardMuted ?? this.onCardMuted,
      onCardAccent: onCardAccent ?? this.onCardAccent,
      onBg: onBg ?? this.onBg,
      onBgMuted: onBgMuted ?? this.onBgMuted,
      btnTop: btnTop ?? this.btnTop,
      btnBottom: btnBottom ?? this.btnBottom,
      onBtn: onBtn ?? this.onBtn,
      chipActive: chipActive ?? this.chipActive,
      onChipActive: onChipActive ?? this.onChipActive,
      chipInactive: chipInactive ?? this.chipInactive,
      onChipInactive: onChipInactive ?? this.onChipInactive,
      badgeOk: badgeOk ?? this.badgeOk,
      onBadgeOk: onBadgeOk ?? this.onBadgeOk,
      catUnder: catUnder ?? this.catUnder,
      catNormal: catNormal ?? this.catNormal,
      catOver: catOver ?? this.catOver,
      catObese: catObese ?? this.catObese,
      sliderTrack: sliderTrack ?? this.sliderTrack,
      sliderFill: sliderFill ?? this.sliderFill,
      sliderThumb: sliderThumb ?? this.sliderThumb,
      navBg: navBg ?? this.navBg,
      navIcon: navIcon ?? this.navIcon,
      navActive: navActive ?? this.navActive,
      navActiveIcon: navActiveIcon ?? this.navActiveIcon,
      avatarBg: avatarBg ?? this.avatarBg,
      avatarFg: avatarFg ?? this.avatarFg,
      decoRings: decoRings ?? this.decoRings,
      decoEcg: decoEcg ?? this.decoEcg,
      decoLeaf: decoLeaf ?? this.decoLeaf,
      decoLeafVein: decoLeafVein ?? this.decoLeafVein,
      danger: danger ?? this.danger,
    );
  }

  @override
  RagaColors lerp(ThemeExtension<RagaColors>? other, double t) {
    if (other is! RagaColors) return this;
    Color lp(Color a, Color b) => Color.lerp(a, b, t)!;
    return RagaColors(
      isDark: t < 0.5 ? isDark : other.isDark,
      bgFallback: lp(bgFallback, other.bgFallback),
      card: lp(card, other.card),
      cardBorder: lp(cardBorder, other.cardBorder),
      onCard: lp(onCard, other.onCard),
      onCardMuted: lp(onCardMuted, other.onCardMuted),
      onCardAccent: lp(onCardAccent, other.onCardAccent),
      onBg: lp(onBg, other.onBg),
      onBgMuted: lp(onBgMuted, other.onBgMuted),
      btnTop: lp(btnTop, other.btnTop),
      btnBottom: lp(btnBottom, other.btnBottom),
      onBtn: lp(onBtn, other.onBtn),
      chipActive: lp(chipActive, other.chipActive),
      onChipActive: lp(onChipActive, other.onChipActive),
      chipInactive: lp(chipInactive, other.chipInactive),
      onChipInactive: lp(onChipInactive, other.onChipInactive),
      badgeOk: lp(badgeOk, other.badgeOk),
      onBadgeOk: lp(onBadgeOk, other.onBadgeOk),
      catUnder: lp(catUnder, other.catUnder),
      catNormal: lp(catNormal, other.catNormal),
      catOver: lp(catOver, other.catOver),
      catObese: lp(catObese, other.catObese),
      sliderTrack: lp(sliderTrack, other.sliderTrack),
      sliderFill: lp(sliderFill, other.sliderFill),
      sliderThumb: lp(sliderThumb, other.sliderThumb),
      navBg: lp(navBg, other.navBg),
      navIcon: lp(navIcon, other.navIcon),
      navActive: lp(navActive, other.navActive),
      navActiveIcon: lp(navActiveIcon, other.navActiveIcon),
      avatarBg: lp(avatarBg, other.avatarBg),
      avatarFg: lp(avatarFg, other.avatarFg),
      decoRings: lp(decoRings, other.decoRings),
      decoEcg: lp(decoEcg, other.decoEcg),
      decoLeaf: lp(decoLeaf, other.decoLeaf),
      decoLeafVein: lp(decoLeafVein, other.decoLeafVein),
      danger: lp(danger, other.danger),
    );
  }

  /// Badge fill for a BMI category (bright green for Normal in the mockup;
  /// other categories tint their own color).
  Color badgeFor(BmiCat c) => switch (c) {
        BmiCat.under => catUnder,
        BmiCat.normal => badgeOk,
        BmiCat.over => catOver,
        BmiCat.obese => catObese,
      };

  Color onBadgeFor(BmiCat c) => switch (c) {
        BmiCat.under => const Color(0xFF0B2B4B),
        BmiCat.normal => onBadgeOk,
        BmiCat.over => const Color(0xFF4A2E0B),
        BmiCat.obese => const Color(0xFF4B0B1A),
      };
}

/// Thin category enum mirroring core/bmi.dart's BmiCategory so the theme
/// doesn't import the calculator.
enum BmiCat { under, normal, over, obese }

BmiCat bmiCatOf(double bmi) {
  if (bmi < 18.5) return BmiCat.under;
  if (bmi < 25) return BmiCat.normal;
  if (bmi < 30) return BmiCat.over;
  return BmiCat.obese;
}

String bmiCatLabel(BmiCat c) => switch (c) {
      BmiCat.under => 'Underweight',
      BmiCat.normal => 'Normal',
      BmiCat.over => 'Overweight',
      BmiCat.obese => 'Obese',
    };

class AppTheme {
  static ThemeData get dark => _build(RagaColors.dark, Brightness.dark);
  static ThemeData get light => _build(RagaColors.light, Brightness.light);

  static ThemeData _build(RagaColors rc, Brightness b) {
    final base = ThemeData(
      brightness: b,
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: ColorScheme.fromSeed(
        seedColor: rc.chipActive,
        brightness: b,
      ),
      extensions: [rc],
    );
    final text = GoogleFonts.plusJakartaSansTextTheme(base.textTheme);
    return base.copyWith(
      textTheme: text,
      sliderTheme: base.sliderTheme.copyWith(
        trackHeight: 6,
        overlayShape: SliderComponentShape.noOverlay,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? rc.chipActive
              : rc.sliderTrack,
        ),
      ),
      dialogTheme: base.dialogTheme.copyWith(
        backgroundColor:
            rc.isDark ? const Color(0xFF352B73) : const Color(0xFFF6F3FE),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      bottomSheetTheme: base.bottomSheetTheme.copyWith(
        backgroundColor:
            rc.isDark ? const Color(0xFF352B73) : const Color(0xFFF6F3FE),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
    );
  }
}

extension RagaThemeX on BuildContext {
  RagaColors get rc => Theme.of(this).extension<RagaColors>()!;
}

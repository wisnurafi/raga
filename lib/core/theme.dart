import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'bmi.dart';

// Raga design language — rebuilt from Wisnu's 21-frame mockup (2026-10-14).
//
// The look: soft glass/white cards floating over his illustrated background
// (lavender gradient + leaf branches + ECG line + concentric rings).
// Dark mode = deep purple canvas, white text, glass cards.
// Light mode = the same language on his light lavender canvas: white cards,
// deep-navy text, identical accents and category colors.
//
// Measured from the mockup (780x1688 frames, logical = px/2):
//   screen padding 22 | card radius 26 | chips pill h40-45
//   primary button h64 pill, lavender gradient, DARK navy label
//   hero numbers 48-64, weight 800, Manrope
@immutable
class RagaColors extends ThemeExtension<RagaColors> {
  final bool isDark;

  /// Fallback surface behind the background art.
  final Color bgFallback;

  /// Card fill + hairline border + soft shadow.
  final Color card;
  final Color cardBorder;
  final Color cardShadow;

  /// Text on cards.
  final Color onCard;
  final Color onCardMuted;
  final Color onCardFaint;

  /// Text drawn directly on the background (screen titles, section labels).
  final Color onBg;
  final Color onBgMuted;

  /// Primary button gradient + its label color (dark navy on lavender).
  final Color btnTop;
  final Color btnBottom;
  final Color onBtn;

  /// Selectable chips / segmented controls. Selected chips carry a DARK
  /// label on the lavender fill — exactly like the mockup.
  final Color chipActive;
  final Color onChipActive;
  final Color chipInactive;
  final Color onChipInactive;
  final Color chipBorder;

  /// Category badge (e.g. the green "Normal" pill).
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
  final Color sliderRing;

  /// Switch (reminder toggle).
  final Color switchTrackOn;
  final Color switchTrackOff;

  /// Floating bottom nav.
  final Color navBg;
  final Color navBorder;
  final Color navIcon;
  final Color navActive;
  final Color navActiveIcon;

  /// Header avatar circle.
  final Color avatarBg;
  final Color avatarFg;

  /// Round icon button in headers (moon / back / share).
  final Color iconBtnBg;
  final Color iconBtnFg;

  final Color danger;
  final Color success;

  const RagaColors({
    required this.isDark,
    required this.bgFallback,
    required this.card,
    required this.cardBorder,
    required this.cardShadow,
    required this.onCard,
    required this.onCardMuted,
    required this.onCardFaint,
    required this.onBg,
    required this.onBgMuted,
    required this.btnTop,
    required this.btnBottom,
    required this.onBtn,
    required this.chipActive,
    required this.onChipActive,
    required this.chipInactive,
    required this.onChipInactive,
    required this.chipBorder,
    required this.badgeOk,
    required this.onBadgeOk,
    required this.catUnder,
    required this.catNormal,
    required this.catOver,
    required this.catObese,
    required this.sliderTrack,
    required this.sliderFill,
    required this.sliderThumb,
    required this.sliderRing,
    required this.switchTrackOn,
    required this.switchTrackOff,
    required this.navBg,
    required this.navBorder,
    required this.navIcon,
    required this.navActive,
    required this.navActiveIcon,
    required this.avatarBg,
    required this.avatarFg,
    required this.iconBtnBg,
    required this.iconBtnFg,
    required this.danger,
    required this.success,
  });

  // The mockup's dark frames: deep purple, glass cards, white text,
  // lavender buttons with dark-navy labels.
  static const dark = RagaColors(
    isDark: true,
    bgFallback: Color(0xFF241D55),
    card: Color(0x24FFFFFF),
    cardBorder: Color(0x40FFFFFF),
    cardShadow: Color(0x40000000),
    onCard: Color(0xFFFFFFFF),
    onCardMuted: Color(0xB3FFFFFF),
    onCardFaint: Color(0x80FFFFFF),
    onBg: Color(0xFFFFFFFF),
    onBgMuted: Color(0xB3FFFFFF),
    btnTop: Color(0xFFB3A5EC),
    btnBottom: Color(0xFF9684DE),
    onBtn: Color(0xFF1D1B3A),
    chipActive: Color(0xFFA99BE8),
    onChipActive: Color(0xFF1D1B3A),
    chipInactive: Color(0x1FFFFFFF),
    onChipInactive: Color(0xFFFFFFFF),
    chipBorder: Color(0x40FFFFFF),
    badgeOk: Color(0xFF5EE0A0),
    onBadgeOk: Color(0xFF1D1B3A),
    catUnder: Color(0xFF6FB1FF),
    catNormal: Color(0xFF5EE0A0),
    catOver: Color(0xFFF5B84B),
    catObese: Color(0xFFFF7A6B),
    sliderTrack: Color(0x33FFFFFF),
    sliderFill: Color(0xFFA99BE8),
    sliderThumb: Color(0xFFFFFFFF),
    sliderRing: Color(0xFFA99BE8),
    switchTrackOn: Color(0xFFA99BE8),
    switchTrackOff: Color(0x4DFFFFFF),
    navBg: Color(0xB31E1848),
    navBorder: Color(0x40FFFFFF),
    navIcon: Color(0x99FFFFFF),
    navActive: Color(0xFFA99BE8),
    navActiveIcon: Color(0xFFFFFFFF),
    avatarBg: Color(0xFFE4C6A8),
    avatarFg: Color(0xFF382010),
    iconBtnBg: Color(0x24FFFFFF),
    iconBtnFg: Color(0xFFFFFFFF),
    danger: Color(0xFFFF7A6B),
    success: Color(0xFF5EE0A0),
  );

  // Wisnu's light frames: lavender canvas, white cards, deep-navy text.
  // Same accents, same category colors — only surfaces and text flip.
  static const light = RagaColors(
    isDark: false,
    bgFallback: Color(0xFFF2EEFB),
    card: Color(0xE8FFFFFF),
    cardBorder: Color(0xCCFFFFFF),
    cardShadow: Color(0x1A6A5AC8),
    onCard: Color(0xFF1D1B3A),
    onCardMuted: Color(0xFF5A5490),
    onCardFaint: Color(0xFF8B84B8),
    onBg: Color(0xFF1D1B3A),
    onBgMuted: Color(0xFF5A5490),
    btnTop: Color(0xFFAEA2EA),
    btnBottom: Color(0xFF9684DE),
    onBtn: Color(0xFF1D1B3A),
    chipActive: Color(0xFFA99BE8),
    onChipActive: Color(0xFF1D1B3A),
    chipInactive: Color(0xB3FFFFFF),
    onChipInactive: Color(0xFF1D1B3A),
    chipBorder: Color(0xFFE0DBF5),
    badgeOk: Color(0xFF5EE0A0),
    onBadgeOk: Color(0xFF1D1B3A),
    catUnder: Color(0xFF6FB1FF),
    catNormal: Color(0xFF5EE0A0),
    catOver: Color(0xFFF5B84B),
    catObese: Color(0xFFFF7A6B),
    sliderTrack: Color(0xFFDED8F0),
    sliderFill: Color(0xFFA99BE8),
    sliderThumb: Color(0xFFFFFFFF),
    sliderRing: Color(0xFFA99BE8),
    switchTrackOn: Color(0xFFA99BE8),
    switchTrackOff: Color(0xFFD5CFEC),
    navBg: Color(0xE6FFFFFF),
    navBorder: Color(0xCCFFFFFF),
    navIcon: Color(0xFF5A5490),
    navActive: Color(0xFFA99BE8),
    navActiveIcon: Color(0xFFFFFFFF),
    avatarBg: Color(0xFFE4C6A8),
    avatarFg: Color(0xFF382010),
    iconBtnBg: Color(0xB3FFFFFF),
    iconBtnFg: Color(0xFF1D1B3A),
    danger: Color(0xFFE14D4D),
    success: Color(0xFF0B7A52),
  );

  @override
  RagaColors copyWith({
    bool? isDark,
    Color? bgFallback,
    Color? card,
    Color? cardBorder,
    Color? cardShadow,
    Color? onCard,
    Color? onCardMuted,
    Color? onCardFaint,
    Color? onBg,
    Color? onBgMuted,
    Color? btnTop,
    Color? btnBottom,
    Color? onBtn,
    Color? chipActive,
    Color? onChipActive,
    Color? chipInactive,
    Color? onChipInactive,
    Color? chipBorder,
    Color? badgeOk,
    Color? onBadgeOk,
    Color? catUnder,
    Color? catNormal,
    Color? catOver,
    Color? catObese,
    Color? sliderTrack,
    Color? sliderFill,
    Color? sliderThumb,
    Color? sliderRing,
    Color? switchTrackOn,
    Color? switchTrackOff,
    Color? navBg,
    Color? navBorder,
    Color? navIcon,
    Color? navActive,
    Color? navActiveIcon,
    Color? avatarBg,
    Color? avatarFg,
    Color? iconBtnBg,
    Color? iconBtnFg,
    Color? danger,
    Color? success,
  }) {
    return RagaColors(
      isDark: isDark ?? this.isDark,
      bgFallback: bgFallback ?? this.bgFallback,
      card: card ?? this.card,
      cardBorder: cardBorder ?? this.cardBorder,
      cardShadow: cardShadow ?? this.cardShadow,
      onCard: onCard ?? this.onCard,
      onCardMuted: onCardMuted ?? this.onCardMuted,
      onCardFaint: onCardFaint ?? this.onCardFaint,
      onBg: onBg ?? this.onBg,
      onBgMuted: onBgMuted ?? this.onBgMuted,
      btnTop: btnTop ?? this.btnTop,
      btnBottom: btnBottom ?? this.btnBottom,
      onBtn: onBtn ?? this.onBtn,
      chipActive: chipActive ?? this.chipActive,
      onChipActive: onChipActive ?? this.onChipActive,
      chipInactive: chipInactive ?? this.chipInactive,
      onChipInactive: onChipInactive ?? this.onChipInactive,
      chipBorder: chipBorder ?? this.chipBorder,
      badgeOk: badgeOk ?? this.badgeOk,
      onBadgeOk: onBadgeOk ?? this.onBadgeOk,
      catUnder: catUnder ?? this.catUnder,
      catNormal: catNormal ?? this.catNormal,
      catOver: catOver ?? this.catOver,
      catObese: catObese ?? this.catObese,
      sliderTrack: sliderTrack ?? this.sliderTrack,
      sliderFill: sliderFill ?? this.sliderFill,
      sliderThumb: sliderThumb ?? this.sliderThumb,
      sliderRing: sliderRing ?? this.sliderRing,
      switchTrackOn: switchTrackOn ?? this.switchTrackOn,
      switchTrackOff: switchTrackOff ?? this.switchTrackOff,
      navBg: navBg ?? this.navBg,
      navBorder: navBorder ?? this.navBorder,
      navIcon: navIcon ?? this.navIcon,
      navActive: navActive ?? this.navActive,
      navActiveIcon: navActiveIcon ?? this.navActiveIcon,
      avatarBg: avatarBg ?? this.avatarBg,
      avatarFg: avatarFg ?? this.avatarFg,
      iconBtnBg: iconBtnBg ?? this.iconBtnBg,
      iconBtnFg: iconBtnFg ?? this.iconBtnFg,
      danger: danger ?? this.danger,
      success: success ?? this.success,
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
      cardShadow: lp(cardShadow, other.cardShadow),
      onCard: lp(onCard, other.onCard),
      onCardMuted: lp(onCardMuted, other.onCardMuted),
      onCardFaint: lp(onCardFaint, other.onCardFaint),
      onBg: lp(onBg, other.onBg),
      onBgMuted: lp(onBgMuted, other.onBgMuted),
      btnTop: lp(btnTop, other.btnTop),
      btnBottom: lp(btnBottom, other.btnBottom),
      onBtn: lp(onBtn, other.onBtn),
      chipActive: lp(chipActive, other.chipActive),
      onChipActive: lp(onChipActive, other.onChipActive),
      chipInactive: lp(chipInactive, other.chipInactive),
      onChipInactive: lp(onChipInactive, other.onChipInactive),
      chipBorder: lp(chipBorder, other.chipBorder),
      badgeOk: lp(badgeOk, other.badgeOk),
      onBadgeOk: lp(onBadgeOk, other.onBadgeOk),
      catUnder: lp(catUnder, other.catUnder),
      catNormal: lp(catNormal, other.catNormal),
      catOver: lp(catOver, other.catOver),
      catObese: lp(catObese, other.catObese),
      sliderTrack: lp(sliderTrack, other.sliderTrack),
      sliderFill: lp(sliderFill, other.sliderFill),
      sliderThumb: lp(sliderThumb, other.sliderThumb),
      sliderRing: lp(sliderRing, other.sliderRing),
      switchTrackOn: lp(switchTrackOn, other.switchTrackOn),
      switchTrackOff: lp(switchTrackOff, other.switchTrackOff),
      navBg: lp(navBg, other.navBg),
      navBorder: lp(navBorder, other.navBorder),
      navIcon: lp(navIcon, other.navIcon),
      navActive: lp(navActive, other.navActive),
      navActiveIcon: lp(navActiveIcon, other.navActiveIcon),
      avatarBg: lp(avatarBg, other.avatarBg),
      avatarFg: lp(avatarFg, other.avatarFg),
      iconBtnBg: lp(iconBtnBg, other.iconBtnBg),
      iconBtnFg: lp(iconBtnFg, other.iconBtnFg),
      danger: lp(danger, other.danger),
      success: lp(success, other.success),
    );
  }

  /// Category color: underweight / normal / overweight / obese.
  Color catColor(BmiCategory c) => switch (c) {
        BmiCategory.underweight => catUnder,
        BmiCategory.normal => catNormal,
        BmiCategory.overweight => catOver,
        BmiCategory.obese => catObese,
      };

  /// Badge fill per category. The mockup paints "Normal" bright green;
  /// other categories tint their own color.
  Color badgeFor(BmiCategory c) => switch (c) {
        BmiCategory.underweight => catUnder,
        BmiCategory.normal => badgeOk,
        BmiCategory.overweight => catOver,
        BmiCategory.obese => catObese,
      };

  /// Badge label is always dark navy — exactly like the mockup.
  Color get onBadge => const Color(0xFF1D1B3A);

  /// Primary button gradient (160° diagonal per spec).
  LinearGradient get btnGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [btnTop, btnBottom],
      );
}

/// Manrope type scale, measured from the mockup. Every style takes its
/// color explicitly so light/dark call sites stay obvious.
class RagaType {
  static TextStyle _s(
    double size,
    FontWeight w,
    Color c, {
    double height = 1.15,
    double spacing = 0,
  }) =>
      GoogleFonts.manrope(
        fontSize: size,
        fontWeight: w,
        color: c,
        height: height,
        letterSpacing: spacing,
      );

  /// Hero numbers (BMI value, calorie count, kg): 800.
  static TextStyle hero(double size, Color c) =>
      _s(size, FontWeight.w800, c, height: 1.0);

  /// Screen titles ("Hitung BMI"): 26/800.
  static TextStyle title(Color c) => _s(26, FontWeight.w800, c, height: 1.2);

  /// Onboarding titles ("Kenalan dulu, yuk"): 30/800.
  static TextStyle bigTitle(Color c) => _s(30, FontWeight.w800, c, height: 1.25);

  /// Section labels outside cards ("Tips untukmu"): 20/800.
  static TextStyle section(Color c) => _s(20, FontWeight.w800, c);

  /// Card headings ("Data tubuh"): 17/700.
  static TextStyle cardTitle(Color c) => _s(17, FontWeight.w700, c);

  /// Labels above values ("Tinggi badan"): 15/700.
  static TextStyle label(Color c) => _s(15, FontWeight.w700, c);

  /// Body copy: 15/500.
  static TextStyle body(Color c) => _s(15, FontWeight.w500, c, height: 1.45);

  /// Small text (captions, footnote): 13/500.
  static TextStyle caption(Color c) => _s(13, FontWeight.w500, c, height: 1.4);

  /// Chips and buttons: 15/700.
  static TextStyle chip(Color c) => _s(15, FontWeight.w700, c);

  /// Primary buttons: 18/800.
  static TextStyle button(Color c) => _s(18, FontWeight.w800, c);

  /// Tiny badge text ("OPSIONAL"): 12/700, wide tracking.
  static TextStyle badge(Color c) =>
      _s(12, FontWeight.w700, c, spacing: 1.5);
}

class AppTheme {
  static ThemeData get dark => _build(RagaColors.dark, Brightness.dark);
  static ThemeData get light => _build(RagaColors.light, Brightness.light);

  static ThemeData _build(RagaColors rc, Brightness b) {
    final base = ThemeData(
      brightness: b,
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFA99BE8),
        brightness: b,
      ),
      extensions: [rc],
    );
    final text = GoogleFonts.manropeTextTheme(base.textTheme);
    return base.copyWith(
      textTheme: text,
      sliderTheme: base.sliderTheme.copyWith(
        trackHeight: 6,
        overlayShape: SliderComponentShape.noOverlay,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 11),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? rc.switchTrackOn
              : rc.switchTrackOff,
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      dialogTheme: base.dialogTheme.copyWith(
        backgroundColor:
            rc.isDark ? const Color(0xFF322A6E) : const Color(0xFFFFFFFF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
        ),
        titleTextStyle: RagaType.cardTitle(rc.onCard),
        contentTextStyle: RagaType.body(rc.onCardMuted),
      ),
      bottomSheetTheme: base.bottomSheetTheme.copyWith(
        backgroundColor:
            rc.isDark ? const Color(0xFF322A6E) : const Color(0xFFFFFFFF),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      timePickerTheme: base.timePickerTheme.copyWith(
        backgroundColor:
            rc.isDark ? const Color(0xFF322A6E) : const Color(0xFFFFFFFF),
      ),
    );
  }
}

extension RagaThemeX on BuildContext {
  RagaColors get rc => Theme.of(this).extension<RagaColors>()!;
}

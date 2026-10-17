import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raga/core/theme.dart';
import 'package:raga/screens/avatar_screen.dart';
import 'package:raga/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pumps the Avatar screen against a real AppState (fresh prefs).
/// AppState.load() must run in the real async zone (runAsync) — it
/// hangs under testWidgets' FakeAsync.
Future<AppState> pumpAvatarScreen(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final app = await tester.runAsync(() => AppState.load());
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: AppStateScope(
        state: app!,
        child: const AvatarScreen(),
      ),
    ),
  );
  await tester.pump();
  return app;
}

void main() {
  testWidgets('renders header, preview, stats, categories and save',
      (tester) async {
    final app = await pumpAvatarScreen(tester);
    expect(tester.takeException(), isNull);

    // Header + preview.
    expect(find.text('Avatar'), findsWidgets);
    expect(find.text(app.activeProfile.name), findsOneWidget);

    // Level chip reflects the migrated fresh profile (setup XP granted).
    final prog = app.avatarService!.progression;
    final totalXp = app.avatarState!.totalXp;
    final level = prog.levelForXp(totalXp);
    expect(find.textContaining('Lv. $level'), findsOneWidget);

    // Stat tiles.
    expect(find.text('Hari streak'), findsOneWidget);
    expect(find.text('Catatan'), findsOneWidget);
    expect(find.text('Koleksi'), findsOneWidget);
    expect(
        find.text(
            '${app.avatarState!.unlockedItemIds.length}/${app.avatarService!.manifest.totalItems}'),
        findsOneWidget);

    // Category chips.
    for (final label in ['Rambut', 'Baju', 'Aksesori', 'Bingkai']) {
      expect(find.text(label), findsOneWidget);
    }

    // Tagline + save button (scrolls into view).
    expect(
        find.text(
            'Avatar tumbuh dari kebiasaanmu, bukan dari angka timbangan.'),
        findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Simpan penampilan'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Simpan penampilan'), findsOneWidget);

    // Hair category shows 4 item thumbnails (labels like "Rambut …, …").
    expect(find.bySemanticsLabel(RegExp(r'^Rambut .+,')), findsNWidgets(4));
  });

  testWidgets('selecting an unlocked item updates the draft, save persists',
      (tester) async {
    final app = await pumpAvatarScreen(tester);

    // Default shirt is lavender; switch to the mint shirt (unlocked).
    expect(app.avatarState!.config.shirt, 'lavender');

    // Open the Baju category.
    await tester.tap(find.text('Baju'));
    await tester.pump();

    // Tap the mint tile by key (scroll it into view first).
    final mintTile = find.byKey(const ValueKey('avatar_option_mint'));
    await tester.ensureVisible(mintTile);
    await tester.pump();
    await tester.tap(mintTile);
    await tester.pump();

    // Draft changed but nothing persisted yet.
    expect(app.avatarState!.config.shirt, 'lavender');

    // Save persists the new look.
    await tester.scrollUntilVisible(
      find.text('Simpan penampilan'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Simpan penampilan'));
    await tester.pump();
    expect(app.avatarState!.config.shirt, 'mint');
    expect(find.text('Penampilan disimpan'), findsOneWidget);
  });

  testWidgets('locked item shows requirement and is not selectable',
      (tester) async {
    final app = await pumpAvatarScreen(tester);

    // Amber shirt needs level 8 — locked on a fresh profile.

    await tester.tap(find.text('Baju'));
    await tester.pump();

    // Scroll the locked tile into view so the GridView builds it, then
    // the lock overlay with the requirement text must be visible.
    final amberTile = find.byKey(const ValueKey('avatar_option_amber'));
    await tester.ensureVisible(amberTile);
    await tester.pump();
    expect(find.text('Level 8'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsWidgets);
    // Tapping the locked tile changes nothing.
    await tester.tap(amberTile);
    await tester.pump();
    expect(app.avatarState!.config.shirt, 'lavender');
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raga/core/theme.dart';
import 'package:raga/screens/collection_screen.dart';
import 'package:raga/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppState> pumpCollectionScreen(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final app = await tester.runAsync(() => AppState.load());
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: AppStateScope(
        state: app!,
        child: const CollectionScreen(),
      ),
    ),
  );
  await tester.pump();
  return app;
}

void main() {
  testWidgets('renders progress, filters and full grid', (tester) async {
    await pumpCollectionScreen(tester);
    expect(tester.takeException(), isNull);

    expect(find.text('Koleksi'), findsWidgets);
    // Fresh profile: 8 of 14 unlocked.
    expect(find.text('Terkumpul 8 / 14'), findsOneWidget);

    // Filter chips: Semua + Baju/Aksesori/Bingkai, deliberately no Rambut.
    expect(find.text('Semua'), findsOneWidget);
    expect(find.text('Baju'), findsOneWidget);
    expect(find.text('Aksesori'), findsOneWidget);
    expect(find.text('Bingkai'), findsOneWidget);
    expect(find.text('Rambut'), findsNothing);

    // Semua shows all 14 items.
    expect(
        find.byKey(const ValueKey('collection_short')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('collection_fire')), findsOneWidget);

    // Filter to Baju: hair items disappear.
    await tester.tap(find.text('Baju'));
    await tester.pump();
    expect(find.byKey(const ValueKey('collection_short')), findsNothing);
    expect(find.byKey(const ValueKey('collection_lavender')),
        findsOneWidget);
  });

  testWidgets('locked item opens bottom sheet with requirement + progress',
      (tester) async {
    final app = await pumpCollectionScreen(tester);
    expect(app.avatarState!.unlockedItemIds.contains('amber'), isFalse);

    // Amber (level 8) is below the fold; scroll it into view.
    final amberTile = find.byKey(const ValueKey('collection_amber'));
    await tester.ensureVisible(amberTile);
    await tester.pump();
    await tester.tap(amberTile);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Bottom sheet: requirement + progress for a fresh profile.
    expect(find.text('Jaket Amber'), findsWidgets);
    expect(find.textContaining('Syarat:'), findsOneWidget);
    expect(find.textContaining('Level 8'), findsWidgets);
    expect(find.textContaining('Progres:'), findsOneWidget);
    // Fresh profile is level 2 (40 setup XP): "2 / 8".
    expect(find.textContaining('2 / 8'), findsOneWidget);
  });

  testWidgets('tapping unlocked item does not crash', (tester) async {
    await pumpCollectionScreen(tester);
    final mintTile = find.byKey(const ValueKey('collection_mint'));
    await tester.ensureVisible(mintTile);
    await tester.pump();
    await tester.tap(mintTile);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}

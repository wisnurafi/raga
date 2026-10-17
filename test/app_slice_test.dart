import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:raga/data/local_store.dart';
import 'package:raga/state/app_state.dart';
import 'package:raga/widgets/app_slice.dart';

// M8: AppState.of subscribes to EVERY notifyListeners. AppSlice must
// rebuild its builder only when the selected slice actually changes.

Future<AppState> _makeState() async {
  SharedPreferences.setMockInitialValues({});
  return AppState(await LocalStore.load());
}

void main() {
  testWidgets('rebuilds only when the selected slice changes',
      (tester) async {
    final state = await _makeState();
    var builds = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: AppStateScope(
          state: state,
          child: AppSlice<String>(
            select: (s) => s.locale,
            builder: (context, locale) {
              builds++;
              return Text(locale, textDirection: TextDirection.ltr);
            },
          ),
        ),
      ),
    );
    expect(builds, 1);
    expect(find.text('id'), findsOneWidget);

    // Unrelated notification: metricUnits changes, locale doesn't.
    state.metricUnits = false;
    state.notifyListeners();
    await tester.pump();
    expect(builds, 1, reason: 'unrelated change must not rebuild the slice');
    expect(find.text('id'), findsOneWidget);

    // The slice itself changes.
    state.locale = 'en';
    state.notifyListeners();
    await tester.pump();
    expect(builds, 2);
    expect(find.text('en'), findsOneWidget);
  });

  testWidgets('builder never calls AppState.of (no hidden subscription)',
      (tester) async {
    final state = await _makeState();
    var builds = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: AppStateScope(
          state: state,
          child: AppSlice<int>(
            select: (s) => s.records.length,
            builder: (context, n) {
              builds++;
              // If this subscribed, every notify would rebuild us.
              return Text('$n', textDirection: TextDirection.ltr);
            },
          ),
        ),
      ),
    );
    expect(builds, 1);

    state.darkMode = false;
    state.notifyListeners();
    await tester.pump();
    expect(builds, 1);
  });

  testWidgets('picks up a new select closure on widget update',
      (tester) async {
    final state = await _makeState();
    var flag = true;
    var builds = 0;

    Widget frame() => MaterialApp(
          home: AppStateScope(
            state: state,
            child: AppSlice<String>(
              select: (s) => flag ? s.locale : s.activity,
              builder: (context, v) {
                builds++;
                return Text(v, textDirection: TextDirection.ltr);
              },
            ),
          ),
        );

    await tester.pumpWidget(frame());
    expect(find.text('id'), findsOneWidget);

    flag = false;
    await tester.pumpWidget(frame());
    await tester.pump();
    expect(builds, 2);
    expect(find.text('Light'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'state/app_state.dart';
import 'data/auth_service.dart';
import 'data/cloud_sync.dart';
import 'data/reminder_service.dart';
import 'widgets/floating_nav.dart';
import 'widgets/raga_bg.dart';
import 'screens/home_screen.dart';
import 'screens/history_screen.dart';
import 'screens/health_screen.dart';
import 'screens/streak_screen.dart';
import 'screens/arena_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Trap every framework/isolate error into the developer log: if a screen
  // ever goes blank again, the log names the exact line that threw.
  ReminderService.onLog = CloudSync.logEvent;
  FlutterError.onError = (details) {
    CloudSync.logEvent('FLUTTER ERROR: ${details.exceptionAsString()}');
    FlutterError.presentError(details);
  };
  WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
    CloudSync.logEvent('UNCAUGHT: $error');
    return true;
  };
  final state = await AppState.load();
  CloudSync.logEvent('app: start (locale=${state.locale}, '
      'profiles=${state.profiles.length}, records=${state.records.length})');
  // Every service init is guarded: a failing subsystem (notifications,
  // cloud) must never stop the app itself from starting.
  try {
    await ReminderService.init();
  } catch (_) {}
  // Re-arm the weekly nudge in case the system cleared it.
  if (state.weeklyReminder) {
    try {
      // Unlike the Profil/onboarding toggle flows, this path runs on every
      // cold start with no UI to be honest in — so when the exact-alarm
      // permission is gone we log the downgrade instead of letting the
      // toggle pretend the nudge still fires on time. (Each alarm's actual
      // mode is also logged by ReminderService._schedule.)
      if (!await ReminderService.canScheduleExact()) {
        CloudSync.logEvent('reminder: launch re-arm without exact-alarm '
            'permission — inexact fallback, may fire late');
      }
      await ReminderService.scheduleBestEffortDays(
        weekdays: state.reminderWeekdays,
        hour: state.reminderHour,
        minute: state.reminderMinute,
        locale: state.locale,
        detakName:
            state.detak.notifFlavor ? state.detak.name : null,
      );
    } catch (_) {}
  }
  try {
    await CloudSync.init();
  } catch (_) {}
  // Pick up a persisted Google session (if any) and watch for
  // login/logout while the app runs.
  try {
    await AuthService.init();
  } catch (_) {}
  // Retry records that didn't make it up yet (e.g. saved while offline).
  try {
    await CloudSync.syncPending(state.records);
  } catch (_) {}
  runApp(AppStateScope(state: state, child: const RagaApp()));
}

class RagaApp extends StatelessWidget {
  const RagaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppState.of(context);
    return AnimatedBuilder(
      animation: state,
      builder: (_, __) => MaterialApp(
        title: 'Raga',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        // Dark is the mockup's look and the default; the moon button
        // in every header flips it live.
        themeMode: state.darkMode ? ThemeMode.dark : ThemeMode.light,
        home: const SplashGate(),
      ),
    );
  }
}

// First frame: animated splash -> first-launch onboarding (once) ->
// the main app. The OS-level launch_background already showed the
// splash's first frame, so the transition feels continuous.
class SplashGate extends StatefulWidget {
  const SplashGate({super.key});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  bool _splashDone = false;
  bool _onboardingDone = false;

  @override
  Widget build(BuildContext context) {
    final state = AppState.of(context);
    if (!_splashDone) {
      return SplashScreen(
        onDone: () => setState(() {
          _splashDone = true;
          _onboardingDone = state.onboardingDone;
        }),
      );
    }
    if (!_onboardingDone) {
      // RagaBg behind the glass fields: without it the frosted cards
      // have nothing to blur and the muted labels become unreadable.
      return RagaBg(
        child: OnboardingScreen(
          onDone: () => setState(() => _onboardingDone = true),
        ),
      );
    }
    return const MainShell();
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Deep-link tab switches (e.g. Detak's daily quests). Consumed once.
    final req = AppState.of(context).consumeRequestedTab();
    if (req != null && req != _index) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _index = req);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RagaBg(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        body: SafeArea(
          bottom: false,
          child: IndexedStack(
            index: _index,
            children: const [
              HomeScreen(),
              HistoryScreen(),
              HealthScreen(),
              StreakScreen(),
              ArenaScreen(),
              ProfileScreen(),
            ],
          ),
        ),
        bottomNavigationBar:
            FloatingNav(index: _index, onTap: (i) => setState(() => _index = i)),
      ),
    );
  }
}

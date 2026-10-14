import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'state/app_state.dart';
import 'data/cloud_sync.dart';
import 'data/reminder_service.dart';
import 'widgets/floating_nav.dart';
import 'screens/home_screen.dart';
import 'screens/history_screen.dart';
import 'screens/health_screen.dart';
import 'screens/profile_screen.dart';

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
  // Every service init is guarded: a failing subsystem (notifications,
  // cloud) must never stop the app itself from starting.
  try {
    await ReminderService.init();
  } catch (_) {}
  // Re-arm the weekly nudge in case the system cleared it.
  if (state.weeklyReminder) {
    try {
      await ReminderService.scheduleBestEffort(
        weekday: state.reminderWeekday,
        hour: state.reminderHour,
        minute: state.reminderMinute,
      );
    } catch (_) {}
  }
  try {
    await CloudSync.init();
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
        home: const MainShell(),
      ),
    );
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
  Widget build(BuildContext context) {
    return HealthBg(
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

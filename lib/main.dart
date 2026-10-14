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
  final state = await AppState.load();
  await ReminderService.init();
  // Re-arm the weekly nudge in case the system cleared it.
  if (state.weeklyReminder) await ReminderService.scheduleWeekly();
  await CloudSync.init();
  // Retry records that didn't make it up yet (e.g. saved while offline).
  await CloudSync.syncPending(state.records);
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

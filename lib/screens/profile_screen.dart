import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/bmi.dart';
import '../core/theme.dart';
import '../models/profile.dart';
import '../state/app_state.dart';
import '../data/cloud_sync.dart';
import '../data/reminder_service.dart';
import '../widgets/glass.dart';
import '../widgets/add_profile_sheet.dart';
import '../widgets/buttons.dart';
import '../widgets/chips.dart';
import '../widgets/controls.dart';
import '../widgets/headers.dart';

// Profile tab: identity, profiles, goal, reminder, units, appearance,
// cloud backup, developer tools, and the danger zone.
// New visual language — every feature from the old screen is ported.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static String _dayName(int d) => idShortDays[d - 1];
  static String _hdot(int h, int m) =>
      '${h.toString().padLeft(2, '0')}.${m.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    final state = AppState.of(context);
    final p = state.activeProfile;
    final goal = state.goalFor(p.id);

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 110),
      children: [
        const RagaHeader(title: 'Profil'),
        const SizedBox(height: 18),
        // Active profile identity card.
        GlassCard(
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
          child: Column(
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: rc.avatarBg,
                ),
                child: Center(
                  child: Text(
                    p.initial,
                    style: RagaType.hero(32, rc.avatarFg),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => _renameDialog(context, state, p.name),
                behavior: HitTestBehavior.opaque,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      p.name,
                      style: RagaType.title(rc.onCard),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: rc.onCardMuted,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _profileLine(state, p),
                style: RagaType.body(rc.onCardMuted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _label(context, 'Profil'),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final prof in state.profiles) ...[
                GestureDetector(
                  onLongPress: () =>
                      _confirmDeleteProfile(context, state, prof),
                  child: ProfileChip(
                    label: prof.name,
                    selected: prof.id == state.activeProfileId,
                    showCheck: true,
                    onTap: () async {
                      if (prof.id != state.activeProfileId) {
                        await state.setActiveProfile(prof.id);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
              ],
              ProfileChip(
                label: 'Tambah',
                isAdd: true,
                selected: false,
                onTap: () => _addProfileSheet(context, state),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _label(context, 'Pengaturan'),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Unit', style: RagaType.label(rc.onCardMuted)),
              const SizedBox(height: 10),
              RagaSegmented(
                options: const ['cm · kg', 'in · lb'],
                selected: state.metricUnits ? 0 : 1,
                onChanged: (i) => state.setMetricUnits(i == 0),
              ),
              _divider(context),
              Text('Tema', style: RagaType.label(rc.onCardMuted)),
              const SizedBox(height: 10),
              RagaSegmented(
                options: const ['Gelap', 'Terang'],
                selected: state.darkMode ? 0 : 1,
                onChanged: (i) => state.setDarkMode(i == 0),
              ),
              _divider(context),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pengingat',
                          style: RagaType.cardTitle(rc.onCard),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          state.weeklyReminder
                              ? 'Pengingat timbang mingguan aktif'
                              : 'Pengingat timbang mingguan mati',
                          style: RagaType.caption(rc.onCardMuted),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: state.weeklyReminder,
                    onChanged: (v) => _toggleReminder(context, v),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => _reminderDialog(context, state),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: rc.chipInactive,
                    borderRadius: BorderRadius.circular(18),
                    border:
                        Border.all(color: rc.cardBorder, width: 1.2),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.schedule,
                          size: 20, color: rc.onCardMuted),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          state.weeklyReminder
                              ? reminderSummary(
                                  state.reminderWeekdays,
                                  state.reminderHour,
                                  state.reminderMinute,
                                )
                              : 'Mati',
                          style: RagaType.chip(rc.onCard),
                        ),
                      ),
                      Icon(Icons.chevron_right,
                          color: rc.onCardMuted),
                    ],
                  ),
                ),
              ),
              _divider(context),
              GestureDetector(
                onTap: () => _goalDialog(context, state),
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Target berat',
                            style: RagaType.cardTitle(rc.onCard),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            goal == null
                                ? 'Belum ada target — ketuk untuk atur'
                                : _goalText(
                                    state.metricUnits, p.weightKg, goal),
                            style: RagaType.caption(rc.onCardMuted),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: rc.onCardMuted),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _label(context, 'Backup'),
        _backupCard(context, state),
        const SizedBox(height: 18),
        _label(context, 'Lainnya'),
        GlassCard(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mode pengembang',
                          style: RagaType.cardTitle(rc.onCard),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          state.devMode
                              ? 'Log, notifikasi tes, info server'
                              : 'Perkakas tambahan untuk debugging',
                          style: RagaType.caption(rc.onCardMuted),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: state.devMode,
                    onChanged: state.setDevMode,
                  ),
                ],
              ),
              if (state.devMode) ...[
                const SizedBox(height: 6),
                _devRow(
                  context,
                  icon: Icons.notifications_active_outlined,
                  title: 'Kirim notifikasi tes',
                  subtitle: 'Kirim satu sekarang',
                  onTap: () => _sendTestNotification(context),
                ),
                _devRow(
                  context,
                  icon: Icons.alarm_outlined,
                  title: 'Alarm terdaftar',
                  subtitle: 'Yang benar-benar didaftarkan OS',
                  onTap: () => _pendingAlarmsDialog(context),
                ),
                _devRow(
                  context,
                  icon: Icons.terminal_outlined,
                  title: 'Log sinkron sesi',
                  subtitle: 'Sesi ini saja',
                  onTap: () => _logsDialog(context),
                ),
              ],
              _divider(context),
              GestureDetector(
                onTap: () => _confirmClear(context, state),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  height: 58,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(29),
                    border: Border.all(color: rc.danger, width: 1.5),
                    color: rc.danger.withValues(alpha: 0.10),
                  ),
                  child: Center(
                    child: Text(
                      'Hapus semua data',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: rc.danger,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Text(
                    'Versi aplikasi',
                    style: RagaType.caption(rc.onCardMuted),
                  ),
                  const Spacer(),
                  Text(
                    'Raga 1.0.0',
                    style: RagaType.label(rc.onCard),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // "Pria · 21 th · 170 cm", converted for imperial.
  String _profileLine(AppState state, Profile p) {
    final h = state.metricUnits
        ? '${p.heightCm.toStringAsFixed(0)} cm'
        : '${(p.heightCm / cmToIn).round()} in';
    return '${p.isMale ? 'Pria' : 'Wanita'} · ${p.age} th · $h';
  }

  String _fmtW(double kg, bool metric) => metric
      ? '${kg.toStringAsFixed(1)} kg'
      : '${(kg * kgToLb).round()} lb';

  String _goalText(bool metric, double curKg, double goalKg) {
    final d = goalKg - curKg;
    final g = _fmtW(goalKg, metric);
    if (d.abs() < 0.5) return 'Jaga di $g';
    return d < 0 ? 'Turun ke $g' : 'Naik ke $g';
  }

  Widget _label(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        text,
        style: RagaType.label(context.rc.onBgMuted),
      ),
    );
  }

  Widget _divider(BuildContext context) {
    return Divider(
      height: 32,
      thickness: 1,
      color: context.rc.cardBorder,
    );
  }

  // "Hari ini · 07.00", "Besok · 07.00", or "Sen · 07.00" — the
  // earliest upcoming armed day.
  String _nextLabel(Set<int> days, int h, int m) {
    if (days.isEmpty) return 'Pilih minimal satu hari';
    var best = ReminderService.nextOccurrence(days.first, h, m);
    for (final d in days.skip(1)) {
      final c = ReminderService.nextOccurrence(d, h, m);
      if (c.isBefore(best)) best = c;
    }
    final now = DateTime.now();
    final diff = DateTime(best.year, best.month, best.day)
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
    final when =
        diff == 0 ? 'Hari ini' : diff == 1 ? 'Besok' : _dayName(best.weekday);
    return '$when · ${_hdot(h, m)}';
  }

  // One arming flow for the toggle and the schedule dialog: permission
  // first (a denied permission must not flip the reminder on), then
  // exact alarms when allowed, and an honest message about which one
  // the OS actually gave us.
  Future<bool> _armDays(
    ScaffoldMessengerState messenger,
    List<int> days,
    int hour,
    int minute,
  ) async {
    final ok = await ReminderService.requestPermission();
    if (!ok) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Nyalakan notifikasi di pengaturan sistem dulu'),
        ),
      );
      return false;
    }
    // Exact alarms are required for a reliable weekly nudge.
    // requestExactAlarmsPermission() only OPENS Settings — it returns
    // immediately without waiting for the toggle. Scheduling right away
    // would silently fall back to an inexact alarm that may never fire
    // on aggressive OEM skins, so we stop here and let the user re-arm
    // after granting.
    if (!await ReminderService.canScheduleExact()) {
      await ReminderService.requestExactAlarmsPermission();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Aktifkan "Alarm & pengingat" di pengaturan '
              'sistem, lalu nyalakan pengingatnya lagi.'),
        ),
      );
      return false;
    }
    final exact = await ReminderService.scheduleBestEffortDays(
      weekdays: days,
      hour: hour,
      minute: minute,
    );
    messenger.showSnackBar(
      SnackBar(
        content: Text(exact
            ? 'Pengingat mingguan aktif'
            : 'Pengingat aktif, tapi alarm tepat waktu mati — bisa '
                'terlambat. Izinkan "Alarm & pengingat" di pengaturan '
                'sistem biar tepat waktu.'),
      ),
    );
    return true;
  }

  Future<void> _toggleReminder(BuildContext context, bool v) async {
    final state = AppState.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (v) {
      final days = state.reminderWeekdays;
      await state.setReminderSchedule(
        weekdays: days,
        hour: state.reminderHour,
        minute: state.reminderMinute,
      );
      final armed = await _armDays(
        messenger,
        days,
        state.reminderHour,
        state.reminderMinute,
      );
      if (!armed) return;
      await state.setWeeklyReminder(true);
    } else {
      await state.setWeeklyReminder(false);
      await ReminderService.cancelAll();
    }
  }

  void _reminderDialog(BuildContext context, AppState state) {
    final rc = context.rc;
    final days = state.reminderWeekdays.toSet();
    var time =
        TimeOfDay(hour: state.reminderHour, minute: state.reminderMinute);
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setLocal) => AlertDialog(
          title: const Text('Jadwal pengingat'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (var d = 1; d <= 7; d++) ...[
                      if (d > 1) const SizedBox(width: 8),
                      DayChip(
                        label: _dayName(d),
                        selected: days.contains(d),
                        onTap: () => setLocal(() {
                          if (days.contains(d)) {
                            days.remove(d);
                          } else {
                            days.add(d);
                          }
                        }),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  final picked = await showTimePicker(
                    context: ctx2,
                    initialTime: time,
                  );
                  if (picked != null) setLocal(() => time = picked);
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: rc.chipInactive,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: rc.cardBorder, width: 1.2),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.schedule,
                          size: 22, color: rc.onCardMuted),
                      const SizedBox(width: 12),
                      Text(
                        _hdot(time.hour, time.minute),
                        style: RagaType.hero(40, rc.onCard),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Berikutnya: ${_nextLabel(days, time.hour, time.minute)}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: rc.onCardMuted,
                ),
              ),
              const SizedBox(height: 18),
              RagaButton(
                label: 'Simpan',
                height: 56,
                onPressed: days.isEmpty
                    ? null
                    : () async {
                        final messenger =
                            ScaffoldMessenger.of(ctx2);
                        final list = days.toList()..sort();
                        await state.setReminderSchedule(
                          weekdays: list,
                          hour: time.hour,
                          minute: time.minute,
                        );
                        if (state.weeklyReminder) {
                          await _armDays(
                            messenger,
                            list,
                            time.hour,
                            time.minute,
                          );
                        }
                        if (ctx2.mounted) Navigator.pop(ctx2);
                      },
              ),
              RagaTextButton(
                label: 'Batal',
                onPressed: () => Navigator.pop(ctx2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Goal dialog in the onboarding language: direction segmented +
  // weight stepper + a live "−3.0 kg lagi" line.
  void _goalDialog(BuildContext context, AppState state) {
    final rc = context.rc;
    final p = state.activeProfile;
    final metric = state.metricUnits;
    final cur = p.weightKg;
    final unit = metric ? 'kg' : 'lb';
    final min = metric ? 30.0 : 66.0;
    final max = metric ? 150.0 : 330.0;
    final step = metric ? 0.5 : 1.0;
    double toDisplay(double kg) => metric ? kg : kg * kgToLb;
    double toKg(double v) => metric ? v : v / kgToLb;
    String dirOf(double v) {
      final d = toKg(v) - cur;
      if (d.abs() < 0.5) return 'Jaga';
      return d < 0 ? 'Turun' : 'Naik';
    }

    var value = toDisplay(state.goalFor(p.id) ?? cur).clamp(min, max);
    var dir = dirOf(value);
    const dirs = ['Turun', 'Jaga', 'Naik'];
    final hasGoal = state.goalFor(p.id) != null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setLocal) {
          final d = toKg(value) - cur;
          final diffText = d.abs() < 0.5
              ? 'Tetap di ${_fmtW(cur, metric)}'
              : d < 0
                  ? '−${_fmtW(d.abs(), metric)} lagi'
                  : '+${_fmtW(d, metric)} lagi';
          return AlertDialog(
            title: const Text('Target berat'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RagaSegmented(
                  options: dirs,
                  selected: dirs.indexOf(dir),
                  onChanged: (i) => setLocal(() {
                    dir = dirs[i];
                    final kgNow = toKg(value);
                    if (dir == 'Jaga') {
                      value = toDisplay(cur);
                    } else if (dir == 'Turun' && kgNow >= cur) {
                      value = toDisplay(cur - 3).clamp(min, max);
                    } else if (dir == 'Naik' && kgNow <= cur) {
                      value = toDisplay(cur + 3).clamp(min, max);
                    }
                  }),
                ),
                const SizedBox(height: 18),
                StepperRow(
                  value: value.toStringAsFixed(metric ? 1 : 0),
                  unit: unit,
                  valueSize: 48,
                  onMinus: () => setLocal(() {
                    value = (value - step).clamp(min, max);
                    dir = dirOf(value);
                  }),
                  onPlus: () => setLocal(() {
                    value = (value + step).clamp(min, max);
                    dir = dirOf(value);
                  }),
                ),
                const SizedBox(height: 8),
                Text(
                  diffText,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: rc.onCardMuted,
                  ),
                ),
                const SizedBox(height: 18),
                RagaButton(
                  label: 'Simpan target',
                  height: 56,
                  onPressed: () async {
                    await state.setGoalWeight(p.id, toKg(value));
                    if (ctx2.mounted) Navigator.pop(ctx2);
                  },
                ),
                if (hasGoal)
                  RagaTextButton(
                    label: 'Hapus target',
                    onPressed: () async {
                      await state.setGoalWeight(p.id, null);
                      if (ctx2.mounted) Navigator.pop(ctx2);
                    },
                  )
                else
                  RagaTextButton(
                    label: 'Batal',
                    onPressed: () => Navigator.pop(ctx2),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _backupCard(BuildContext context, AppState state) {
    final rc = context.rc;
    final code = CloudSync.backupCode ?? '(belum siap)';
    final pending = CloudSync.pendingCount(state.records);
    final isError = CloudSync.state == SyncState.error;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status',
                      style: RagaType.label(rc.onCardMuted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CloudSync.describe(state.records,
                          indonesian: true),
                      style: RagaType.cardTitle(rc.onCard),
                    ),
                  ],
                ),
              ),
              _syncDot(context),
            ],
          ),
          if (pending > 0) ...[
            const SizedBox(height: 6),
            Text(
              '$pending catatan menunggu diunggah.',
              style: TextStyle(
                fontSize: 13,
                color: rc.onCardMuted,
              ),
            ),
          ],
          if (isError && CloudSync.lastError.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Error: ${CloudSync.lastError}',
              style: TextStyle(fontSize: 13, color: rc.onCardMuted),
            ),
            if (CloudSync.hintFor(CloudSync.lastError) != null) ...[
              const SizedBox(height: 4),
              Text(
                CloudSync.hintFor(CloudSync.lastError)!,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: rc.onCard,
                ),
              ),
            ],
          ],
          const SizedBox(height: 14),
          Text(
            'Kode backup',
            style: RagaType.label(rc.onCardMuted),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: rc.chipInactive,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: rc.cardBorder, width: 1.2),
            ),
            child: SelectableText(
              code,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                color: rc.onCard,
              ),
            ),
          ),
          const SizedBox(height: 14),
          RagaOutlineButton(
            label: 'Salin kode',
            height: 56,
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: code));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Kode backup disalin')),
                );
              }
            },
          ),
          const SizedBox(height: 10),
          RagaButton(
            label: 'Sinkron sekarang',
            height: 56,
            onPressed: () async {
              await state.refreshSync();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text(CloudSync.describe(state.records))),
                );
              }
            },
          ),
          const SizedBox(height: 10),
          RagaOutlineButton(
            label: 'Restore dari kode',
            height: 56,
            onPressed: () => _restoreCodeDialog(context, state),
          ),
          if (state.devMode) ...[
            const SizedBox(height: 10),
            Text(
              'Server: ${CloudSync.configuredHost}',
              style: TextStyle(
                fontSize: 12.5,
                color: rc.onCardMuted,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            'Tersimpan aman di cloud pribadimu. Tanpa akun — tinggal pakai.',
            style: TextStyle(
              fontSize: 12.5,
              color: rc.onCardMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _syncDot(BuildContext context) {
    final rc = context.rc;
    final color = switch (CloudSync.state) {
      SyncState.ready => rc.badgeOk,
      SyncState.notConfigured => const Color(0xFFF2B544),
      SyncState.error => rc.danger,
    };
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _devRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final rc = context.rc;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: rc.chipActive.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 20, color: rc.chipActive),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: rc.onCard,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: rc.onCardMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: rc.onCardMuted),
          ],
        ),
      ),
    );
  }

  Future<void> _addProfileSheet(
      BuildContext context, AppState state) async {
    final name = await showAddProfileSheet(context);
    // Empty name falls back to AppState.addProfile's default.
    if (name != null) {
      await state.addProfile(name);
    }
  }

  void _renameDialog(
      BuildContext context, AppState state, String current) {
    final ctrl = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ubah nama'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) {
                Navigator.pop(ctx);
                _applyRename(state, ctrl.text);
              },
            ),
            const SizedBox(height: 18),
            RagaButton(
              label: 'Simpan',
              height: 56,
              onPressed: () {
                Navigator.pop(ctx);
                _applyRename(state, ctrl.text);
              },
            ),
            RagaTextButton(
              label: 'Batal',
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    ).whenComplete(ctrl.dispose);
  }

  void _applyRename(AppState state, String name) {
    final n = name.trim();
    if (n.isNotEmpty) {
      state.updateActiveProfile((p) => p.copyWith(name: n));
    }
  }

  void _confirmDeleteProfile(
      BuildContext context, AppState state, Profile prof) {
    final rc = context.rc;
    if (state.profiles.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Tidak bisa menghapus profil terakhir')),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus profil?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${prof.name} beserta riwayatnya akan hilang selamanya.',
              style: TextStyle(color: rc.onCardMuted),
            ),
            const SizedBox(height: 20),
            DangerPillButton(
              label: 'Hapus',
              onTap: () async {
                Navigator.pop(ctx);
                await state.removeProfile(prof.id);
              },
            ),
            RagaTextButton(
              label: 'Batal',
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  void _restoreCodeDialog(BuildContext context, AppState state) {
    final ctl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore dari kode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctl,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                hintText: 'XXXX-XXXX-XXXX-XXXX',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 18),
            RagaButton(
              label: 'Lanjut',
              height: 56,
              onPressed: () {
                if (ctl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                _confirmRestore(context, state, ctl.text);
              },
            ),
            RagaTextButton(
              label: 'Batal',
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    ).whenComplete(ctl.dispose);
  }

  void _confirmRestore(
      BuildContext context, AppState state, String code) {
    final rc = context.rc;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ganti semuanya?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Semua profil dan riwayat di HP ini akan diganti dengan data backup. Tidak bisa dibatalkan.',
              style: TextStyle(color: rc.onCardMuted),
            ),
            const SizedBox(height: 20),
            DangerPillButton(
              label: 'Restore',
              onTap: () async {
                Navigator.pop(ctx);
                final ok =
                    await state.restoreFromBackupCode(code);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ok
                          ? 'Backup dipulihkan — selamat datang kembali.'
                          : 'Kode tidak ditemukan atau cloud tidak terjangkau. Cek kodenya lalu coba lagi.'),
                    ),
                  );
                }
              },
            ),
            RagaTextButton(
              label: 'Batal',
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  void _sendTestNotification(BuildContext context) async {
    final ok = await ReminderService.showTest();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(ok
                ? 'Notifikasi tes terkirim'
                : 'Tidak bisa menampilkan notifikasi — cek izinnya')),
      );
    }
  }

  void _logsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log sinkron'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(
              CloudSync.logText,
              style:
                  const TextStyle(fontFamily: 'monospace', fontSize: 11),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              CloudSync.clearLog();
              Navigator.pop(ctx);
            },
            child: const Text('Hapus'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  // Developer inspector: lists the alarms the OS actually has
  // registered. If a reminder "never fires", this shows whether it
  // was even scheduled.
  Future<void> _pendingAlarmsDialog(BuildContext context) async {
    final alarms = await ReminderService.pendingAlarms();
    if (!context.mounted) return;
    final body = alarms.isEmpty
        ? 'Tidak ada alarm yang terdaftar di OS.'
        : alarms
            .map((a) =>
                '#${a.id} — ${a.title ?? "(tanpa judul)"}\n  ${a.body ?? ""}')
            .join('\n');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Alarm terdaftar'),
        content: SingleChildScrollView(
          child: SelectableText(
            body,
            style:
                const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _confirmClear(BuildContext context, AppState state) {
    final rc = context.rc;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus semua data?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Riwayat dan profil di perangkat ini akan hilang selamanya.',
              style: TextStyle(color: rc.onCardMuted),
            ),
            const SizedBox(height: 20),
            DangerPillButton(
              label: 'Hapus',
              onTap: () {
                Navigator.pop(ctx);
                state.clearAllData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Semua data dihapus')),
                );
              },
            ),
            RagaTextButton(
              label: 'Batal',
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }
}

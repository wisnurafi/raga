import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../avatar/avatar_view.dart';
import '../core/bmi.dart';
import '../core/strings.dart';
import '../core/theme.dart';
import '../models/profile.dart';
import '../state/app_state.dart';
import 'avatar_screen.dart';
import 'profile_backup_section.dart';
import 'profile_dev_section.dart';
import '../data/reminder_service.dart';
import '../widgets/glass.dart';
import '../widgets/profile_sheet.dart';
import '../widgets/buttons.dart';
import '../widgets/chips.dart';
import '../widgets/headers.dart';

// Profile tab: account, identity, profiles, reminder, units, appearance,
// cloud backup, developer tools, and the danger zone.
// (The weight target lives on the Streak tab as "Goals".)
// New visual language — every feature from the old screen is ported.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // True while a Google sign-in / photo upload is in flight.
  bool _authBusy = false;

  static String _dayName(BuildContext context, int d) =>
      shortDays(AppState.of(context).locale)[d - 1];
  static String _hdot(int h, int m) =>
      '${h.toString().padLeft(2, '0')}.${m.toString().padLeft(2, '0')}';

  /// The identity card avatar: the user's set avatar, or the letter
  /// initial if the avatar feature is off.
  static Widget _identityAvatar(BuildContext context, AppState state) {
    final rc = context.rc;
    final svc = state.avatarService;
    final config = state.avatarState?.config;
    if (svc != null && config != null) {
      return AvatarView(
        manifest: svc.manifest,
        config: config,
        size: 84,
      );
    }
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: rc.avatarBg,
      ),
      child: Center(
        child: Text(
          state.activeProfile.initial,
          style: RagaType.hero(32, rc.avatarFg),
        ),
      ),
    );
  }

  /// Small avatar thumbnail for a profile chip, or null if the
  /// avatar feature is off.
  static Widget? _avatarThumb(AppState state, String profileId) {
    final svc = state.avatarService;
    final config = state.avatarStates[profileId]?.config;
    if (svc == null || config == null) return null;
    return AvatarView(
      manifest: svc.manifest,
      config: config,
      size: 24,
    );
  }

  @override
  Widget build(BuildContext context) {
    final rc = context.rc;
    final state = AppState.of(context);
    final p = state.activeProfile;

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 110),
      children: [
        RagaHeader(title: tx(context, 'profile_title')),
        const SizedBox(height: 18),
        _accountCard(context, state),
        const SizedBox(height: 18),
        // Profile section: identity card + profile switcher together.
        _label(context, tx(context, 'profile_title')),
        GlassCard(
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
          child: Column(
            children: [
              GestureDetector(
                onTap: () {
                  if (state.avatarService == null) return;
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AvatarScreen(),
                    ),
                  );
                },
                child: _identityAvatar(context, state),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final updated = await showProfileSheet(
                    context,
                    existing: p,
                    metric: state.metricUnits,
                  );
                  if (updated != null) {
                    await state.updateActiveProfile((_) => updated);
                  }
                },
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
                _profileLine(context, state, p),
                style: RagaType.body(rc.onCardMuted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
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
                    leading: _avatarThumb(state, prof.id),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              ProfileChip(
                label: tx(context, 'add'),
                isAdd: true,
                selected: false,
                onTap: () => _addProfileSheet(context, state),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          tx(context, 'profile_longpress_hint'),
          style: RagaType.caption(rc.onCardMuted),
        ),
        const SizedBox(height: 18),
        _label(context, tx(context, 'profile_settings')),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tx(context, 'profile_units'),
                  style: RagaType.label(rc.onCardMuted)),
              const SizedBox(height: 10),
              RagaSegmented(
                options: const ['cm · kg', 'in · lb'],
                selected: state.metricUnits ? 0 : 1,
                onChanged: (i) => state.setMetricUnits(i == 0),
              ),
              _divider(context),
              Text(tx(context, 'profile_theme'),
                  style: RagaType.label(rc.onCardMuted)),
              const SizedBox(height: 10),
              RagaSegmented(
                options: [
                  tx(context, 'theme_dark'),
                  tx(context, 'theme_light')
                ],
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
                          tx(context, 'profile_reminder'),
                          style: RagaType.cardTitle(rc.onCard),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          state.weeklyReminder
                              ? tx(context, 'profile_reminder_on')
                              : tx(context, 'profile_reminder_off'),
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
                                  locale: state.locale,
                                )
                              : tx(context, 'rem_off'),
                          style: RagaType.chip(rc.onCard),
                        ),
                      ),
                      Icon(Icons.chevron_right,
                          color: rc.onCardMuted),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _label(context, tx(context, 'profile_backup')),
        ProfileBackupSection(state: state),
        const SizedBox(height: 18),
        _label(context, tx(context, 'profile_others')),
        ProfileDevSection(state: state),
      ],
    );
  }

  // --- optional Google account -------------------------------------
  Widget _accountCard(BuildContext context, AppState state) {
    final rc = context.rc;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tx(context, 'auth_title'),
            style: RagaType.label(rc.onCardMuted),
          ),
          const SizedBox(height: 10),
          if (state.isLoggedIn)
            _loggedInBody(context, state)
          else ...[
            Text(
              tx(context, 'auth_anon_note'),
              style: RagaType.body(rc.onCardMuted),
            ),
            const SizedBox(height: 14),
            _googleButton(context),
          ],
        ],
      ),
    );
  }

  // White Google-style button with a "G" monogram (no asset needed).
  Widget _googleButton(BuildContext context) {
    return GestureDetector(
      onTap: _authBusy ? null : () => _signIn(),
      behavior: HitTestBehavior.opaque,
      child: Opacity(
        opacity: _authBusy ? 0.6 : 1.0,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 14,
                spreadRadius: -6,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_authBusy)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              else
                const Text(
                  'G',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4285F4),
                  ),
                ),
              const SizedBox(width: 12),
              Text(
                _authBusy
                    ? tx(context, 'splash_loading')
                    : tx(context, 'auth_sign_in_google'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F1F1F),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _loggedInBody(BuildContext context, AppState state) {
    final rc = context.rc;
    final name = state.accountName ?? tx(context, 'auth_default_name');
    return Column(
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: _authBusy ? null : () => _changePhoto(),
              child: _avatar(context, state, name),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: RagaType.cardTitle(rc.onCard),
                  ),
                  if (state.accountEmail != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      state.accountEmail!,
                      style: RagaType.caption(rc.onCardMuted),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.logout, color: rc.onCardMuted),
              tooltip: tx(context, 'auth_sign_out'),
              onPressed: _authBusy ? null : () => _confirmSignOut(state),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: RagaOutlineButton(
                label: tx(context, 'auth_edit_name'),
                height: 52,
                onPressed: () => _editNameSheet(state),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: RagaOutlineButton(
                label: tx(context, 'auth_change_photo'),
                height: 52,
                onPressed: _authBusy ? null : () => _changePhoto(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _avatar(BuildContext context, AppState state, String name) {
    final rc = context.rc;
    final url = state.accountAvatarUrl;
    final initial =
        name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: rc.avatarBg,
      ),
      clipBehavior: Clip.antiAlias,
      child: (url != null && url.isNotEmpty)
          ? Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Center(
                child: Text(
                  initial,
                  style: RagaType.hero(28, rc.avatarFg),
                ),
              ),
            )
          : Center(
              child: Text(
                initial,
                style: RagaType.hero(28, rc.avatarFg),
              ),
            ),
    );
  }

  // Note: no BuildContext parameter — these async methods use the
  // State's own context, so the State's `mounted` guard is the one the
  // analyzer expects (a context parameter reads as "unrelated").
  Future<void> _signIn() async {
    final state = AppState.of(context);
    // Capture everything context-derived up front: using BuildContext
    // after an await trips use_build_context_synchronously.
    final cancelledMsg = tx(context, 'auth_sign_in_cancelled');
    final notConfiguredMsg = tx(context, 'auth_not_configured');
    setState(() => _authBusy = true);
    final res = await state.signInWithGoogle();
    if (!mounted) return;
    setState(() => _authBusy = false);
    final messenger = ScaffoldMessenger.of(context);
    void snack(String s) =>
        messenger.showSnackBar(SnackBar(content: Text(s)));
    if (res.cancelled) {
      snack(cancelledMsg);
      return;
    }
    if (res.notConfigured) {
      snack(notConfiguredMsg);
      return;
    }
    if (res.failed) {
      snack(tx(context, 'auth_sign_in_failed', {'e': res.detail}));
      return;
    }
    if (res.isFirstLogin) {
      snack(res.migratedCount > 0
          ? tx(context, 'auth_migrated', {'n': res.migratedCount})
          : tx(context, 'auth_welcome',
              {'name': state.accountName ?? ''}));
      return;
    }
    if (res.cloudCount > 0) {
      _offerMerge(state, res.cloudCount);
    } else {
      snack(tx(context, 'auth_welcome_back'));
    }
  }

  // Returning login with cloud rows: offer to merge them in.
  void _offerMerge(AppState state, int cloudCount) {
    final rc = context.rc;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tx(ctx, 'auth_sync_offer_title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tx(ctx, 'auth_sync_offer_body', {'n': cloudCount}),
              style: TextStyle(color: rc.onCardMuted),
            ),
            const SizedBox(height: 20),
            RagaButton(
              label: tx(ctx, 'auth_sync_merge'),
              height: 56,
              onPressed: () async {
                Navigator.pop(ctx);
                final n = await state.mergeFromCloud();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(n > 0
                        ? tx(context, 'auth_merged', {'n': n})
                        : n == 0
                            ? tx(context, 'auth_merge_empty')
                            : tx(context, 'auth_merge_failed')),
                  ),
                );
              },
            ),
            RagaTextButton(
              label: tx(ctx, 'auth_sync_later'),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmSignOut(AppState state) {
    final rc = context.rc;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tx(ctx, 'auth_sign_out_title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tx(ctx, 'auth_sign_out_body'),
              style: TextStyle(color: rc.onCardMuted),
            ),
            const SizedBox(height: 20),
            DangerPillButton(
              label: tx(ctx, 'auth_sign_out'),
              onTap: () async {
                Navigator.pop(ctx);
                await state.signOut();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(tx(context, 'auth_signed_out'))),
                );
              },
            ),
            RagaTextButton(
              label: tx(ctx, 'cancel'),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  void _editNameSheet(AppState state) {
    final rc = context.rc;
    final nameCtrl =
        TextEditingController(text: state.accountName ?? '');
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 22,
            right: 22,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tx(ctx, 'auth_name_title'),
                  style: RagaType.cardTitle(rc.onCard)),
              const SizedBox(height: 14),
              TextField(
                controller: nameCtrl,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                style: RagaType.body(rc.onCard),
                decoration: InputDecoration(
                  hintText: tx(ctx, 'auth_name_hint'),
                  hintStyle: RagaType.body(rc.onCardMuted),
                  filled: true,
                  fillColor: rc.chipInactive,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(color: rc.chipBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(color: rc.chipBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide:
                        BorderSide(color: rc.chipActive, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              RagaButton(
                label: tx(ctx, 'save'),
                onPressed: () async {
                  final ok =
                      await state.setAccountName(nameCtrl.text);
                  if (!mounted) return;
                  // Capture State-context work before touching the
                  // sheet's ctx: each context gets its own guard.
                  final messenger = ScaffoldMessenger.of(context);
                  final msg = tx(
                      context,
                      ok ? 'auth_name_updated' : 'auth_name_failed');
                  if (ctx.mounted) Navigator.pop(ctx);
                  messenger.showSnackBar(
                    SnackBar(content: Text(msg)),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(nameCtrl.dispose);
  }

  Future<void> _changePhoto() async {
    final state = AppState.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final uploading = tx(context, 'auth_uploading_photo');
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 768,
      imageQuality: 85,
    );
    if (picked == null) return;
    if (!mounted) return;
    setState(() => _authBusy = true);
    messenger.showSnackBar(SnackBar(content: Text(uploading)));
    final bytes = await picked.readAsBytes();
    final url = await state.uploadAccountAvatar(bytes);
    if (!mounted) return;
    setState(() => _authBusy = false);
    messenger.showSnackBar(
      SnackBar(
        content: Text(tx(
            context,
            url != null
                ? 'auth_photo_updated'
                : 'auth_photo_failed')),
      ),
    );
  }

  // "Pria · 21 th · 170 cm", converted for imperial.
  String _profileLine(BuildContext context, AppState state, Profile p) {
    final h = state.metricUnits
        ? '${p.heightCm.toStringAsFixed(0)} cm'
        : '${(p.heightCm * cmToIn).round()} in';
    return tx(context, 'profile_line', {
      'gender': tx(context, p.isMale ? 'male' : 'female'),
      'n': p.age,
      'h': h,
    });
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
  String _nextLabel(BuildContext context, Set<int> days, int h, int m) {
    if (days.isEmpty) return tx(context, 'profile_pick_day');
    var best = ReminderService.nextOccurrence(days.first, h, m);
    for (final d in days.skip(1)) {
      final c = ReminderService.nextOccurrence(d, h, m);
      if (c.isBefore(best)) best = c;
    }
    final now = DateTime.now();
    final diff = DateTime(best.year, best.month, best.day)
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
    final when = diff == 0
        ? tx(context, 'profile_today')
        : diff == 1
            ? tx(context, 'profile_tomorrow')
            : _dayName(context, best.weekday);
    return '$when · ${_hdot(h, m)}';
  }

  // One arming flow for the toggle and the schedule dialog: permission
  // first (a denied permission must not flip the reminder on), then
  // exact alarms when allowed, and an honest message about which one
  // the OS actually gave us.
  Future<bool> _armDays(
    BuildContext context,
    ScaffoldMessengerState messenger,
    List<int> days,
    int hour,
    int minute,
  ) async {
    // Capture everything context-derived up front: using BuildContext
    // after an await trips use_build_context_synchronously.
    final locale = AppState.of(context).locale;
    final detak = AppState.of(context).detak;
    final detakName = detak.notifFlavor ? detak.name : null;
    final notifOff = tx(context, 'profile_arm_notif');
    final exactOff = tx(context, 'profile_arm_exact');
    final okMsg = tx(context, 'profile_arm_ok');
    final lateMsg = tx(context, 'profile_arm_late');
    final ok = await ReminderService.requestPermission();
    if (!ok) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(notifOff),
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
        SnackBar(
          content: Text(exactOff),
        ),
      );
      return false;
    }
    final exact = await ReminderService.scheduleBestEffortDays(
      weekdays: days,
      hour: hour,
      minute: minute,
      locale: locale,
      detakName: detakName,
    );
    messenger.showSnackBar(
      SnackBar(
        content: Text(exact ? okMsg : lateMsg),
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
      if (!context.mounted) return;
      final armed = await _armDays(
        context,
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
          title: Text(tx(ctx2, 'profile_sched_title')),
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
                        label: _dayName(ctx2, d),
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
                tx(ctx2, 'profile_next', {
                  't': _nextLabel(ctx2, days, time.hour, time.minute)
                }),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: rc.onCardMuted,
                ),
              ),
              const SizedBox(height: 18),
              RagaButton(
                label: tx(ctx2, 'save'),
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
                          if (!ctx2.mounted) return;
                          await _armDays(
                            ctx2,
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
                label: tx(ctx2, 'cancel'),
                onPressed: () => Navigator.pop(ctx2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addProfileSheet(
      BuildContext context, AppState state) async {
    final p = await showProfileSheet(context, metric: state.metricUnits);
    if (p != null) {
      await state.addProfile(p);
    }
  }

  void _confirmDeleteProfile(
      BuildContext context, AppState state, Profile prof) {
    final rc = context.rc;
    if (state.profiles.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(tx(context, 'profile_delete_last'))),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tx(ctx, 'profile_delete_title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tx(ctx, 'profile_delete_body', {'name': prof.name}),
              style: TextStyle(color: rc.onCardMuted),
            ),
            const SizedBox(height: 20),
            DangerPillButton(
              label: tx(ctx, 'delete'),
              onTap: () async {
                Navigator.pop(ctx);
                await state.removeProfile(prof.id);
              },
            ),
            RagaTextButton(
              label: tx(ctx, 'cancel'),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

}

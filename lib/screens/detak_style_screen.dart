// "Penampilan Detak": rename, recolor, accessories, and the two
// behavior toggles. Edits apply on Simpan (mockup 2).

import 'package:flutter/material.dart';

import '../core/strings.dart';
import '../core/theme.dart';
import '../data/reminder_service.dart';
import '../state/app_state.dart';
import '../widgets/buttons.dart';
import '../widgets/glass.dart';
import '../widgets/headers.dart';
import '../widgets/raga_bg.dart';
import '../detak/detak_assets.dart';
import '../detak/detak_widget.dart';

class DetakStyleScreen extends StatefulWidget {
  const DetakStyleScreen({super.key});

  @override
  State<DetakStyleScreen> createState() => _DetakStyleScreenState();
}

class _DetakStyleScreenState extends State<DetakStyleScreen> {
  bool _init = false;
  late TextEditingController _nameCtrl;
  DetakColor _color = DetakColor.lavender;
  DetakAccessory _acc = DetakAccessory.none;
  bool _notif = true;
  bool _calm = false;

  static const _swatches = {
    DetakColor.lavender: Color(0xFF998DD3),
    DetakColor.mint: Color(0xFF8ECFB4),
    DetakColor.langit: Color(0xFF8EACD3),
    DetakColor.persik: Color(0xFFD09991),
  };
  static const _colorOrder = [
    DetakColor.lavender,
    DetakColor.mint,
    DetakColor.langit,
    DetakColor.persik,
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_init) {
      final d = AppState.of(context).detak;
      _nameCtrl = TextEditingController(text: d.name);
      _color = d.color;
      _acc = d.accessory;
      _notif = d.notifFlavor;
      _calm = d.calmMode;
      _init = true;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final state = AppState.of(context);
    final d = state.detak;
    final name = _nameCtrl.text.trim();
    d.name = name.isEmpty ? 'Detak' : name;
    d.color = _color;
    d.accessory = _acc;
    d.notifFlavor = _notif;
    d.calmMode = _calm;
    await state.saveDetak();
    // Re-arm so the Detak-voice toggle applies to pending nudges now.
    if (state.weeklyReminder) {
      try {
        await ReminderService.scheduleBestEffortDays(
          weekdays: state.reminderWeekdays,
          hour: state.reminderHour,
          minute: state.reminderMinute,
          locale: state.locale,
          detakName: d.notifFlavor ? d.name : null,
        );
      } catch (_) {}
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.of(context);
    final rc = context.rc;
    final stage = state.detak.stage;

    return RagaBg(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 40),
            children: [
              Row(
                children: [
                  CircleBtn(
                    icon: Icons.chevron_left,
                    onTap: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(tx(context, 'detak_style_title'),
                            style: RagaType.title(rc.onBg),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 2),
                        Text(tx(context, 'detak_style_subtitle'),
                            style: RagaType.label(rc.onBgMuted),
                            textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
              const SizedBox(height: 18),
              // Preview + name.
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: SizedBox(
                        width: 170,
                        child: DetakWidget(
                          mood: DetakMood.halo,
                          color: _color,
                          stage: stage,
                          accessory: _acc,
                          energy: state.detakEnergy,
                          calmMode: _calm,
                          interactive: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(height: 1, color: rc.cardBorder),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Text(tx(context, 'detak_name_label'),
                            style: RagaType.label(rc.onCardMuted)),
                        const Spacer(),
                        Text(
                          '${_nameCtrl.text.length} / 12',
                          style: RagaType.caption(rc.onCardMuted),
                        ),
                      ],
                    ),
                    TextField(
                      controller: _nameCtrl,
                      maxLength: 12,
                      style: RagaType.title(rc.onCard)
                          .copyWith(fontSize: 26),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        counterText: '',
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // Color.
              GlassCard(
                padding: const EdgeInsets.all(18),
                radius: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tx(context, 'detak_color'),
                        style: RagaType.cardTitle(rc.onCard)),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        for (final c in _colorOrder)
                          GestureDetector(
                            onTap: () => setState(() => _color = c),
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _swatches[c],
                                border: Border.all(
                                  color: _color == c
                                      ? rc.onCard
                                      : Colors.transparent,
                                  width: 3,
                                ),
                                boxShadow: _color == c
                                    ? [
                                        BoxShadow(
                                          color: _swatches[c]!
                                              .withValues(alpha: 0.5),
                                          blurRadius: 12,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // Accessories.
              GlassCard(
                padding: const EdgeInsets.all(18),
                radius: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tx(context, 'detak_accessory'),
                        style: RagaType.cardTitle(rc.onCard)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        for (final a in DetakAccessory.values)
                          Expanded(
                              child: _accMini(context, rc, stage, a)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _toggleRow(
                context,
                rc,
                label: tx(context, 'detak_notif'),
                value: _notif,
                onChanged: (v) => setState(() => _notif = v),
              ),
              const SizedBox(height: 10),
              _toggleRow(
                context,
                rc,
                label: tx(context, 'detak_calm'),
                value: _calm,
                onChanged: (v) => setState(() => _calm = v),
              ),
              const SizedBox(height: 20),
              RagaButton(
                label: tx(context, 'save'),
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _accMini(BuildContext context, RagaColors rc, DetakStage stage,
      DetakAccessory a) {
    final selected = a == _acc;
    final labels = {
      DetakAccessory.none: tx(context, 'detak_acc_none'),
      DetakAccessory.kacamata: tx(context, 'detak_acc_kacamata'),
      DetakAccessory.pita: tx(context, 'detak_acc_pita'),
    };
    return GestureDetector(
      onTap: () => setState(() => _acc = a),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: rc.chipInactive.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? rc.chipActive : rc.cardBorder,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: DetakWidget(
                mood: DetakMood.halo,
                color: _color,
                stage: stage,
                accessory: a,
                energy: 0.5,
                calmMode: true,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              labels[a]!,
              style:
                  RagaType.caption(rc.onCard).copyWith(
                          fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggleRow(
    BuildContext context,
    RagaColors rc, {
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: rc.chipInactive,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: rc.cardBorder, width: 1.2),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: RagaType.body(rc.onCard)),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

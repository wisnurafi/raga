import 'package:flutter/material.dart';

import '../core/bmi.dart';
import '../core/theme.dart';
import '../models/profile.dart';
import 'buttons.dart';
import 'chips.dart';
import 'controls.dart';

/// Bottom sheet for creating or editing a profile: name, gender, age and
/// height. Returns the new/edited [Profile], or null when dismissed.
/// Shared by Home (add) and Profil (add + edit). Weight stays on the
/// Home sliders — this sheet only asks what Home can't change.
Future<Profile?> showProfileSheet(
  BuildContext context, {
  Profile? existing,
  required bool metric,
}) {
  final isEdit = existing != null;
  final nameCtrl = TextEditingController(text: existing?.name ?? '');
  var isMale = existing?.isMale ?? true;
  var age = existing?.age ?? 21;
  var heightCm = existing?.heightCm ?? 170.0;

  // The slider works in display units; the profile stores canonical cm.
  double dispH() => metric ? heightCm : heightCm / cmToIn;
  void setDispH(double v) => heightCm = metric ? v : v * cmToIn;

  return showModalBottomSheet<Profile>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      final rc = ctx.rc;
      return StatefulBuilder(
        builder: (ctx2, setLocal) => SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 22,
              right: 22,
              top: 24,
              bottom: MediaQuery.of(ctx2).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isEdit ? 'Edit profil' : 'Profil baru',
                    style: RagaType.cardTitle(rc.onCard)),
                const SizedBox(height: 14),
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  style: RagaType.body(rc.onCard),
                  decoration: InputDecoration(
                    hintText: 'Nama',
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
                  onSubmitted: (_) => _submit(
                      ctx2, nameCtrl, existing, isMale, age, heightCm),
                ),
                const SizedBox(height: 16),
                Text('Jenis kelamin',
                    style: RagaType.label(rc.onCardMuted)),
                const SizedBox(height: 8),
                RagaSegmented(
                  options: const ['Pria', 'Wanita'],
                  selected: isMale ? 0 : 1,
                  onChanged: (i) => setLocal(() => isMale = i == 0),
                ),
                const SizedBox(height: 16),
                Text('Umur', style: RagaType.label(rc.onCardMuted)),
                const SizedBox(height: 4),
                StepperRow(
                  value: '$age',
                  unit: 'tahun',
                  onMinus: () => setLocal(
                      () => age = (age - 1).clamp(5, 120).toInt()),
                  onPlus: () => setLocal(
                      () => age = (age + 1).clamp(5, 120).toInt()),
                ),
                const SizedBox(height: 8),
                MeasureSlider(
                  label: 'Tinggi badan',
                  value: dispH().toStringAsFixed(0),
                  unit: metric ? 'cm' : 'in',
                  sliderValue: dispH(),
                  min: metric ? heightRangeCm.min : heightRangeIn.min,
                  max: metric ? heightRangeCm.max : heightRangeIn.max,
                  onChanged: (v) => setLocal(() => setDispH(v)),
                ),
                const SizedBox(height: 20),
                RagaButton(
                  label: isEdit ? 'Simpan' : 'Tambah',
                  onPressed: () => _submit(
                      ctx2, nameCtrl, existing, isMale, age, heightCm),
                ),
              ],
            ),
          ),
        ),
      );
    },
  ).whenComplete(nameCtrl.dispose);
}

void _submit(
  BuildContext ctx,
  TextEditingController nameCtrl,
  Profile? existing,
  bool isMale,
  int age,
  double heightCm,
) {
  final name = nameCtrl.text.trim();
  final base = existing ?? Profile(name: '');
  // Add mode falls back to 'Profile' (the old sheet's default);
  // edit mode keeps the current name when the field is cleared.
  final resolvedName =
      name.isEmpty ? (existing?.name ?? 'Profile') : name;
  Navigator.pop(
    ctx,
    base.copyWith(
      name: resolvedName,
      isMale: isMale,
      age: age,
      heightCm: heightCm,
    ),
  );
}

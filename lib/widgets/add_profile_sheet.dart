import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'buttons.dart';

/// Bottom sheet asking for a profile name. Returns the trimmed name, or
/// null when dismissed. Shared by Home and Profil (the home version's
/// styling won).
Future<String?> showAddProfileSheet(BuildContext context) {
  final ctrl = TextEditingController();
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      final rc = ctx.rc;
      return SafeArea(
        child: Padding(
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
              Text('Profil baru',
                  style: RagaType.cardTitle(rc.onCard)),
              const SizedBox(height: 14),
              TextField(
                controller: ctrl,
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
                onSubmitted: (_) =>
                    Navigator.pop(ctx, ctrl.text.trim()),
              ),
              const SizedBox(height: 16),
              RagaButton(
                label: 'Tambah',
                onPressed: () =>
                    Navigator.pop(ctx, ctrl.text.trim()),
              ),
            ],
          ),
        ),
      );
    },
  ).whenComplete(ctrl.dispose);
}

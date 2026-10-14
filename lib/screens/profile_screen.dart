import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../state/app_state.dart';
import '../data/cloud_sync.dart';
import '../widgets/glass.dart';

/// Layar "Profil": info profil aktif + pengaturan aplikasi.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppState.of(context);
    final rc = context.rc;
    final p = state.activeProfile;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
      children: [
        Text(
          'Profil',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            color: rc.onBg,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 18),
        GlassContainer(
          padding: const EdgeInsets.all(22),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8C98F),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.9),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    p.initial,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1B1B2F),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: rc.onBg,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${p.isMale ? 'Pria' : 'Wanita'} · ${p.age} tahun',
                      style:
                          TextStyle(fontSize: 13.5, color: rc.onBgMuted),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _renameDialog(context, state, p.name),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: rc.primaryBtn.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Ubah',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: rc.primaryBtn,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        _sectionLabel(context, 'Pengaturan'),
        _tile(
          context,
          icon: Icons.straighten_outlined,
          title: 'Satuan',
          subtitle:
              state.metricUnits ? 'Sentimeter · kilogram' : 'Inci · pon',
          trailing: Switch(
            value: state.metricUnits,
            onChanged: state.setMetricUnits,
          ),
        ),
        const SizedBox(height: 22),
        _sectionLabel(context, 'Data'),
        _tile(
          context,
          icon: Icons.cloud_outlined,
          title: 'Sinkronisasi cloud',
          subtitle: CloudSync.describe(state.records),
          trailing: _syncDot(context),
          onTap: () => _syncDialog(context, state),
        ),
        _tile(
          context,
          icon: Icons.delete_outline,
          title: 'Hapus semua data',
          subtitle: 'Riwayat dan profil di perangkat ini',
          trailing: null,
          danger: true,
          onTap: () => _confirmClear(context, state),
        ),
        const SizedBox(height: 22),
        _sectionLabel(context, 'Tentang'),
        _tile(
          context,
          icon: Icons.info_outline,
          title: 'Raga v1.0.0',
          subtitle: 'Kalkulator BMI — tugas Pemrograman Mobile',
          trailing: null,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline,
                  size: 14, color: rc.onBgMuted),
              const SizedBox(width: 6),
              Text(
                'Datamu cuma tersimpan di HP ini & cloud pribadimu',
                style: TextStyle(fontSize: 12.5, color: rc.onBgMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _syncDot(BuildContext context) {
    final rc = context.rc;
    final color = switch (CloudSync.state) {
      SyncState.ready => rc.mint,
      SyncState.notConfigured => const Color(0xFFF2B544),
      SyncState.error => const Color(0xFFF2555A),
    };
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  void _syncDialog(BuildContext context, AppState state) {
    final rc = context.rc;
    final pending = CloudSync.pendingCount(state.records);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sinkronisasi cloud'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _syncDot(ctx),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    CloudSync.describe(state.records),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            if (pending > 0) ...[
              const SizedBox(height: 8),
              Text('$pending data menunggu dikirim ke Supabase.',
                  style: TextStyle(color: rc.onCardMuted)),
            ],
            if (CloudSync.lastError.isNotEmpty &&
                CloudSync.state == SyncState.error) ...[
              const SizedBox(height: 8),
              Text('Error: ${CloudSync.lastError}',
                  style: TextStyle(color: rc.onCardMuted)),
            ],
            const SizedBox(height: 8),
            Text(
              'Data dikirim anonim ke database Supabase pribadimu.',
              style: TextStyle(fontSize: 12.5, color: rc.onCardMuted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await state.refreshSync();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          CloudSync.describe(state.records))),
                );
              }
            },
            child: const Text('Sinkronkan sekarang'),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: context.rc.onBgMuted,
        ),
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget? trailing,
    bool danger = false,
    VoidCallback? onTap,
  }) {
    final rc = context.rc;
    final dangerColor = const Color(0xFFF2555A);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: GlassContainer(
        margin: const EdgeInsets.only(bottom: 10),
        padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        borderRadius: 22,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: danger
                    ? dangerColor.withValues(alpha: 0.14)
                    : rc.primaryBtn.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                size: 20,
                color: danger ? dangerColor : rc.primaryBtn,
              ),
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
                      color: danger ? dangerColor : rc.onBg,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style:
                        TextStyle(fontSize: 12.5, color: rc.onBgMuted),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  void _renameDialog(
      BuildContext context, AppState state, String current) {
    final ctrl = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ubah nama'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          onSubmitted: (_) {
            Navigator.pop(ctx);
            _applyRename(state, ctrl.text);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _applyRename(state, ctrl.text);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _applyRename(AppState state, String name) {
    final n = name.trim();
    if (n.isNotEmpty) {
      state.updateActiveProfile((p) => p.copyWith(name: n));
    }
  }

  void _confirmClear(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus semua data?'),
        content: const Text(
            'Riwayat dan profil di perangkat ini akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF2555A)),
            onPressed: () {
              Navigator.pop(ctx);
              state.clearAllData();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Semua data dihapus')),
              );
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

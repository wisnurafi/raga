import 'dart:io';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../core/theme.dart';
import '../core/bmi.dart';
import '../core/tips.dart';
import '../widgets/gauge.dart';
import '../widgets/glass.dart';
import '../widgets/cards.dart';
import '../state/app_state.dart';
import '../data/cloud_sync.dart';

/// Layar "Hasil BMI": gauge, angka, kategori, tips, tombol simpan & bagikan.
class ResultScreen extends StatefulWidget {
  final double heightCm;
  final double weightKg;
  final String profileName;

  const ResultScreen({
    super.key,
    required this.heightCm,
    required this.weightKg,
    required this.profileName,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final _shot = ScreenshotController();
  bool _sharing = false;

  @override
  Widget build(BuildContext context) {
    final bmi = calcBmi(weightKg: widget.weightKg, heightCm: widget.heightCm);
    final cat = categoryOf(bmi);
    final meta = categoryMeta[cat]!;
    final rc = context.rc;
    final hTxt = formatId(widget.heightCm, 0);
    final wTxt = formatId(widget.weightKg, 0);

    return HealthBg(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.65),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        color: rc.onBg,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hasil BMI',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: rc.onBg,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.profileName} · $hTxt cm · $wTxt kg · ${formatDateId(DateTime.now())}',
                          style: TextStyle(
                              fontSize: 13.5, color: rc.onBgMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // Kartu gauge (ini yang di-screenshot saat dibagikan).
              Screenshot(
                controller: _shot,
                child: GlassContainer(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
                  opacity: 0.72,
                  child: Column(
                    children: [
                      BmiGauge(bmi: bmi),
                      Text(
                        formatId(bmi),
                        style: TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -3,
                          color: rc.onBg,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      Text(
                        'kg/m²',
                        style: TextStyle(
                            fontSize: 15,
                            color: rc.onBgMuted,
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 26, vertical: 10),
                        decoration: BoxDecoration(
                          color: meta.color,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [
                            BoxShadow(
                              color: meta.color.withValues(alpha: 0.45),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Text(
                          meta.label,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1B1B2F),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      GaugeLegend(active: cat),
                      const SizedBox(height: 10),
                      Text(
                        meta.explanation,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: rc.onCardMuted,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GlassContainer(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: rc.mintSoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.tips_and_updates_outlined,
                            size: 19,
                            color: rc.mint,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Tips untukmu',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: rc.onCard,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...healthTips[cat]!.take(3).map(
                          (t) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 9,
                                  height: 9,
                                  margin:
                                      const EdgeInsets.only(top: 6, right: 12),
                                  decoration: BoxDecoration(
                                    color: rc.mint,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    t,
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      height: 1.5,
                                      color: rc.onCardMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: RagaButton(
                      label: 'Simpan ke riwayat',
                      onPressed: () => _save(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RagaButton(
                      label: _sharing ? 'Menyiapkan…' : 'Bagikan',
                      outlined: true,
                      onPressed: _sharing ? () {} : () => _share(bmi, meta),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save(BuildContext context) async {
    await AppState.of(context).saveRecord(
      heightCm: widget.heightCm,
      weightKg: widget.weightKg,
    );
    if (!context.mounted) return;
    final synced = CloudSync.isReady && CloudSync.lastError.isEmpty;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(synced
            ? 'Tersimpan ke riwayat & cloud'
            : 'Tersimpan ke riwayat (cloud menyusul)'),
      ),
    );
    Navigator.pop(context);
  }

  Future<void> _share(double bmi, CategoryMeta meta) async {
    setState(() => _sharing = true);
    try {
      final bytes = await _shot.capture();
      if (bytes == null) throw 'gagal';
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/raga-bmi-${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            'BMI saya ${formatId(bmi)} (${meta.label}) — dihitung dengan Raga',
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal membuat gambar')),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }
}

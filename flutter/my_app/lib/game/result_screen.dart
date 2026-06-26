import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'game_api_service.dart';
import 'theme.dart';
import 'common_widgets.dart';
import 'game_screen.dart';

class ResultScreen extends StatefulWidget {
  final int    patientId;
  final String patientName;

  const ResultScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  Map<String, dynamic>? _result;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadResult();
  }

  Future<void> _loadResult() async {
    try {
      final data = await GameApiService.getResult(widget.patientId);
      setState(() { _result = data; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text('النتيجة',
          style: GoogleFonts.lora(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.navy),
        ),
        automaticallyImplyLeading: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.sage))
          : _result == null
              ? const Center(child: Text('خطأ في تحميل النتيجة'))
              : _buildResults(),
    );
  }

  Widget _buildResults() {
    final r        = _result!;
    final score    = r['score']    as int;
    final total    = r['total']    as int;
    final accuracy = (r['accuracy'] as num).toDouble();
    final level    = r['level']    as String;
    final hardest  = List<Map<String, dynamic>>.from(r['hardest']  ?? []);
    final easiest  = List<Map<String, dynamic>>.from(r['easiest']  ?? []);
    final summary  = r['summary']  as Map<String, dynamic>;
    final pct      = accuracy / 100;

    final ringColor = pct >= 0.8 ? AppColors.sage
        : pct >= 0.5 ? AppColors.amber
        : AppColors.coral;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [

        // ── Score card ──────────────────────────────────────────────────────
        Card(
          elevation: 3,
          shadowColor: AppColors.shadow,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              CircularPercentIndicator(
                radius: 75,
                lineWidth: 10,
                percent: pct.clamp(0.0, 1.0),
                progressColor: ringColor,
                backgroundColor: AppColors.warm,
                circularStrokeCap: CircularStrokeCap.round,
                animation: true,
                animationDuration: 1500,
                center: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('$score',
                    style: GoogleFonts.nunito(
                      fontSize: 42, fontWeight: FontWeight.w900,
                      color: AppColors.navy, height: 1,
                    ),
                  ),
                  Text('/ $total',
                    style: GoogleFonts.nunito(fontSize: 14, color: Colors.grey[500]),
                  ),
                ]),
              ),
              const SizedBox(height: 16),
              Text(widget.patientName,
                style: GoogleFonts.lora(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.navy),
              ),
              const SizedBox(height: 4),
              Text(level,
                style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.sage),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10, runSpacing: 10, alignment: WrapAlignment.center,
                children: [
                  StatPill(value: '${accuracy.toStringAsFixed(1)}%', label: 'الدقة'),
                  StatPill(value: '${summary['total_sessions']}',    label: 'الجلسات'),
                  StatPill(value: '${summary['best_score']}',        label: 'أفضل نتيجة'),
                ],
              ),
              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                ElevatedButton(
                  onPressed: () async {
                    await GameApiService.restartGame(widget.patientId);
                    if (mounted) {
                      Navigator.pushReplacement(context, MaterialPageRoute(
                        builder: (_) => GameScreen(
                          patientId:   widget.patientId,
                          patientName: widget.patientName,
                        ),
                      ));
                    }
                  },
                  child: const Text('🔄 العب مجدداً'),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.charcoal,
                    side: const BorderSide(color: AppColors.warm, width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                  child: Text('رجوع', style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
                ),
              ]),
            ]),
          ),
        ).animate().fadeIn().slideY(begin: 0.2),

        const SizedBox(height: 12),

        // ── Hardest & Easiest ───────────────────────────────────────────────
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('😓 الأصعب',
                    style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.coral),
                  ),
                  const SizedBox(height: 8),
                  if (hardest.isEmpty)
                    Text('لا بيانات', style: GoogleFonts.nunito(color: Colors.grey[400]))
                  else
                    ...hardest.map((p) => PersonRow(
                      name: p['name'] as String,
                      stat: '${p['accuracy']}%',
                      statColor: AppColors.coral,
                    )),
                ]),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('⭐ الأسهل',
                    style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.sage),
                  ),
                  const SizedBox(height: 8),
                  if (easiest.isEmpty)
                    Text('لا بيانات', style: GoogleFonts.nunito(color: Colors.grey[400]))
                  else
                    ...easiest.map((p) => PersonRow(
                      name: p['name'] as String,
                      stat: '${p['accuracy']}%',
                      statColor: AppColors.sage,
                    )),
                ]),
              ),
            ),
          ),
        ]).animate().fadeIn(delay: 200.ms),

        const SizedBox(height: 30),
      ]),
    );
  }
}
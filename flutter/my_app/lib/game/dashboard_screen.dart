import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game_api_service.dart';
import 'theme.dart';
import 'common_widgets.dart';
//import 'game_screen.dart';
import 'dart:convert';

class DashboardScreen extends StatefulWidget {
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  Set<String> _importantPeople = {};

  // ✅ مضاف
  int? _patientId;
  String _patientName = '';

  @override
  void initState() {
    super.initState();
    _initFromSession(); // ✅ بدل _loadDashboard مباشرة
  }

  // ✅ مضاف — جيبي الـ session الأول، وبعدين حمّلي الداشبورد
  Future<void> _initFromSession() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _patientId = prefs.getInt('patient_id');
      _patientName =
          prefs.getString('patient_name') ?? prefs.getString('user_name') ?? '';
    });
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    if (_patientId == null) {
      // ✅ guard
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    try {
      final res = await GameApiService.getDashboard(_patientId!); // ✅

      final d = Map<String, dynamic>.from(
        res.body.isNotEmpty ? _decode(res.body) : {},
      );

      setState(() {
        _data = d;
        _importantPeople =
            Set<String>.from((d['important_people'] as List?) ?? []);
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  dynamic _decode(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return {};
    }
  }

  void _toggleImportant(String name) {
    setState(() {
      if (_importantPeople.contains(name)) {
        _importantPeople.remove(name);
      } else {
        _importantPeople.add(name);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 1,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📊 متابعتي',
              style: GoogleFonts.lora(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy),
            ),
            Text(
              _patientName, // ✅ بدل widget.patientName
              style: GoogleFonts.nunito(fontSize: 12, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.sage))
          : _data == null
              ? const Center(child: Text('Error loading dashboard'))
              : _buildDashboard(),
    );
  }

  // ✅ باقي الكود من هنا لآخره زي ما هو بالظبط
  Widget _buildDashboard() {
    final d = _data!;
    final summary = d['summary'] as Map<String, dynamic>? ?? {};
    final weights = d['weights'] as Map<String, dynamic>? ?? {};
    final hardest =
        List<Map<String, dynamic>>.from(d['hardest'] as List? ?? []);
    final easiest =
        List<Map<String, dynamic>>.from(d['easiest'] as List? ?? []);
    final confusionPairs =
        List<Map<String, dynamic>>.from(d['confusion_pairs'] as List? ?? []);

    final dailyScores =
        List<Map<String, dynamic>>.from(d['daily_scores'] as List? ?? []);
    final accuracyTrend =
        List<Map<String, dynamic>>.from(d['accuracy_trend'] as List? ?? []);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  StatPill(
                      value: '${summary['total_sessions'] ?? 0}',
                      label: 'الجلسات'),
                  StatPill(
                      value: '${summary['avg_accuracy'] ?? 0}%',
                      label: 'متوسط الدقة'),
                  StatPill(
                      value: '${summary['best_score'] ?? 0}',
                      label: 'أفضل نتيجة'),
                  StatPill(
                      value: '${_importantPeople.length}', label: 'المهمين'),
                ],
              ),
            ),
          ).animate().fadeIn(),
          const SizedBox(height: 12),
          if (dailyScores.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📅 نتائج الجلسات اليومية',
                      style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy),
                    ),
                    const SizedBox(height: 14),
                    _DailyBarChart(scores: dailyScores),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 12),
          if (accuracyTrend.length > 1)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📈 تطور الدقة',
                      style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy),
                    ),
                    const SizedBox(height: 14),
                    _AccuracyLineChart(trend: accuracyTrend),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 150.ms),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '😓 الأصعب في التذكر',
                          style: GoogleFonts.nunito(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.coral),
                        ),
                        const SizedBox(height: 8),
                        if (hardest.isEmpty)
                          Text('لا بيانات',
                              style:
                                  GoogleFonts.nunito(color: Colors.grey[400]))
                        else
                          ...hardest.map((p) => PersonRow(
                                name: p['name'] as String,
                                stat: '${p['accuracy']}%',
                                statColor: AppColors.coral,
                                subStat: '(${p['total']})',
                              )),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '⭐ الأسهل في التذكر',
                          style: GoogleFonts.nunito(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.sage),
                        ),
                        const SizedBox(height: 8),
                        if (easiest.isEmpty)
                          Text('لا بيانات',
                              style:
                                  GoogleFonts.nunito(color: Colors.grey[400]))
                        else
                          ...easiest.map((p) => PersonRow(
                                name: p['name'] as String,
                                stat: '${p['accuracy']}%',
                                statColor: AppColors.sage,
                                subStat: '(${p['total']})',
                              )),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 12),
          if (weights.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🧩 أوزان صعوبة التذكر',
                      style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'كلما زادت القيمة → كان تذكر الشخص أصعب',
                      style: GoogleFonts.nunito(
                          fontSize: 11, color: Colors.grey[400]),
                    ),
                    const SizedBox(height: 12),
                    ...() {
                      final sorted = weights.entries.toList()
                        ..sort((a, b) =>
                            (b.value as num).compareTo(a.value as num));
                      return sorted
                          .take(8)
                          .map((e) => _WeightRow(
                                name: e.key,
                                weight: (e.value as num).toDouble(),
                                isImportant: _importantPeople.contains(e.key),
                                onToggle: () => _toggleImportant(e.key),
                              ))
                          .toList();
                    }(),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 250.ms),
          const SizedBox(height: 12),
          if (confusionPairs.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🔀 خريطة الالتباس',
                      style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.amber),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: confusionPairs.map((pair) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.cream,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                pair['guessed'] as String,
                                style: GoogleFonts.nunito(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.coral),
                              ),
                              Text(
                                ' → ',
                                style: GoogleFonts.nunito(
                                    fontSize: 12, color: Colors.grey[400]),
                              ),
                              Text(
                                pair['actual'] as String,
                                style: GoogleFonts.nunito(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.navy),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.amber,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '×${pair['count']}',
                                  style: GoogleFonts.nunito(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

// ── Weight row ────────────────────────────────────────────────────────────────

class _WeightRow extends StatelessWidget {
  final String name;
  final double weight;
  final bool isImportant;
  final VoidCallback onToggle;

  const _WeightRow({
    required this.name,
    required this.weight,
    required this.isImportant,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final Color barColor = weight > 3
        ? AppColors.coral
        : weight > 1.5
            ? AppColors.amber
            : AppColors.sage;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
          color: AppColors.cream, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          if (isImportant) ...[
            const Text('⭐', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Text(
              name,
              style:
                  GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
          SizedBox(
            width: 70,
            height: 6,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (weight / 5).clamp(0.0, 1.0),
                backgroundColor: AppColors.warm,
                valueColor: AlwaysStoppedAnimation(barColor),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            weight.toStringAsFixed(2),
            style: GoogleFonts.nunito(
                fontSize: 13, fontWeight: FontWeight.w800, color: barColor),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onToggle,
            child: Text(isImportant ? '⭐' : '☆',
                style: const TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }
}

// ── Daily bar chart ───────────────────────────────────────────────────────────

class _DailyBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> scores;
  const _DailyBarChart({required this.scores});

  @override
  Widget build(BuildContext context) {
    final maxScore = scores
        .map((s) => (s['score'] as num).toDouble())
        .fold(1.0, (a, b) => a > b ? a : b);

    return SizedBox(
      height: 110,
      child: BarChart(
        BarChartData(
          maxY: maxScore * 1.2,
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= scores.length) return const SizedBox();
                  final date = (scores[i]['date'] as String).substring(5);
                  return Text(date,
                      style: GoogleFonts.nunito(
                          fontSize: 9, color: Colors.grey[400]));
                },
              ),
            ),
          ),
          barGroups: List.generate(
            scores.length,
            (i) => BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: (scores[i]['score'] as num).toDouble(),
                  gradient: const LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [AppColors.sage, AppColors.sageLt],
                  ),
                  width: 16,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(6)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Accuracy line chart ───────────────────────────────────────────────────────

class _AccuracyLineChart extends StatelessWidget {
  final List<Map<String, dynamic>> trend;
  const _AccuracyLineChart({required this.trend});

  @override
  Widget build(BuildContext context) {
    final spots = List.generate(
      trend.length,
      (i) => FlSpot(i.toDouble(), (trend[i]['accuracy'] as num).toDouble()),
    );

    return SizedBox(
      height: 100,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 25,
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: AppColors.warm, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (v, _) => Text('${v.toInt()}%',
                    style: GoogleFonts.nunito(
                        fontSize: 9, color: Colors.grey[400])),
              ),
            ),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          minY: 0,
          maxY: 100,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.sage,
              barWidth: 2.5,
              dotData: FlDotData(
                show: true,
                getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                  radius: 4,
                  color: AppColors.sage,
                  strokeWidth: 0,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.sage.withValues(alpha: 0.25),
                    AppColors.sage.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

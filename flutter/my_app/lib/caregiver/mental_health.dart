import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class MentalHealthPage extends StatelessWidget {
  final int todayMood = 4;
  final List<int> weeklyMood = const [2, 3, 4, 3, 4, 5, 3];
  final List<int> monthlyMood = const [3, 3, 4, 4];
  final Map<String, int> gameScore = const {'correct': 15, 'wrong': 5};

  const MentalHealthPage({super.key});

  bool isImproving() {
    double prev = monthlyMood[0].toDouble();
    for (var mood in monthlyMood) {
      if (mood < prev) return false;
      prev = mood.toDouble();
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffF6F1F1),
      appBar: AppBar(
        title: Text('Caregiver Support'),
        backgroundColor: Color(0xffF6F1F1),
        elevation: 0,
        foregroundColor: Colors.black,
      ),

      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ===== Title =====
            Text(
              "Your Well-being",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 6),
            Text(
              "Taking care of yourself is part of taking care of them.",
              style: TextStyle(color: Colors.grey[600]),
            ),

            SizedBox(height: 20),

            /// ===== Circle Mood =====
            containerCard(
              child: Column(
                children: [
                  SizedBox(height: 10),

                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 160,
                        height: 160,
                        child: CircularProgressIndicator(
                          value: todayMood / 5,
                          strokeWidth: 10,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation(Color(0xff3A6D6D)),
                        ),
                      ),
                      Column(
                        children: [
                          Icon(
                            Icons.sentiment_satisfied,
                            color: Color(0xff4C6B4C),
                            size: 30,
                          ),
                          SizedBox(height: 8),
                          Text(
                            "${(todayMood / 5 * 100).toInt()}%",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "GOOD MOOD",
                            style: TextStyle(fontSize: 12, letterSpacing: 1),
                          ),
                        ],
                      ),
                    ],
                  ),

                  SizedBox(height: 16),

                  Text(
                    "You've had a calm and balanced day so far.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            /// ===== Weekly =====
            containerCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Weekly Flow",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  SizedBox(height: 16),

                  SizedBox(
                    height: 180,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(show: false),
                        borderData: FlBorderData(show: false),

                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, _) {
                                const days = [
                                  'M',
                                  'T',
                                  'W',
                                  'T',
                                  'F',
                                  'S',
                                  'S',
                                ];
                                return Text(days[value.toInt()]);
                              },
                            ),
                          ),
                        ),

                        lineBarsData: [
                          LineChartBarData(
                            spots: weeklyMood
                                .asMap()
                                .entries
                                .map(
                                  (e) => FlSpot(
                                    e.key.toDouble(),
                                    e.value.toDouble(),
                                  ),
                                )
                                .toList(),
                            isCurved: true,
                            barWidth: 4,
                            dotData: FlDotData(show: false),
                            color: Color(0xff3A6D6D),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 10),

                  Row(
                    children: [
                      CircleAvatar(
                        radius: 4,
                        backgroundColor: Color(0xff3A6D6D),
                      ),
                      SizedBox(width: 6),
                      Text(
                        "Stablest week this month",
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            /// ===== Monthly =====
            containerCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Monthly Overview",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "Tracking emotional resilience",
                    style: TextStyle(color: Colors.grey),
                  ),

                  SizedBox(height: 20),

                  SizedBox(
                    height: 160,
                    child: BarChart(
                      BarChartData(
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(show: false),

                        barGroups: monthlyMood.asMap().entries.map((e) {
                          return BarChartGroupData(
                            x: e.key,
                            barRods: [
                              BarChartRodData(
                                toY: e.value.toDouble(),
                                width: 16,
                                color: Color(0xff3A6D6D),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            /// ===== Tip =====
            containerCard(
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Color(0xffEAF3EA),
                    child: Icon(Icons.lightbulb, color: Color(0xff4C6B4C)),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Your mood often dips on Tuesdays. Consider scheduling a 15-minute respite walk then.",
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ===== Styled Card =====
  Widget containerCard({required Widget child}) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xffFDFDFD),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}

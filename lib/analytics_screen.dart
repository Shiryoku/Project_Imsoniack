import 'package:flutter/material.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'sensor_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _selectedPeriod = 'Week'; // Options: Week, Month, Year

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              'Sleep Analytics',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 20),
            
            // Sleep Quality Chart Card
            _buildQualityChartCard(),
            
            const SizedBox(height: 20),
            
            // Sleep Quality Score Today Card
            _buildDailyScoreCard(),
            
            const SizedBox(height: 20),
            
            // Sleep Stages Card
            _buildSleepStagesCard(),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }


  Widget _buildQualityChartCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF5D4037), // Dark Brown
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Text(
            'Sleep Quality Score',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          // Toggle
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFCC80),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildToggleItem("Week", _selectedPeriod == 'Week'),
                _buildToggleItem("Month", _selectedPeriod == 'Month'),
                _buildToggleItem("Year", _selectedPeriod == 'Year'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Chart with Y-Axis and Grid
          SizedBox(
            height: 200,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Y-Axis Labels
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('100', style: TextStyle(color: Colors.white54, fontSize: 10)),
                    Text('80', style: TextStyle(color: Colors.white54, fontSize: 10)),
                    Text('60', style: TextStyle(color: Colors.white54, fontSize: 10)),
                    Text('40', style: TextStyle(color: Colors.white54, fontSize: 10)),
                    Text('20', style: TextStyle(color: Colors.white54, fontSize: 10)),
                    Text('0', style: TextStyle(color: Colors.white54, fontSize: 10)),
                  ],
                ),
                const SizedBox(width: 10),
                
                // Chart Area
                Expanded(
                  child: Stack(
                    children: [
                      // Grid Lines
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(6, (index) {
                          return Container(
                            height: 1,
                            color: Colors.white12, // Subtle grid line
                            margin: const EdgeInsets.only(top: 6, bottom: 6), // align with text
                          );
                        }),
                      ),
                      
                      // Bars
                      StreamBuilder<QuerySnapshot>(
                        stream: _getStreamForPeriod(),
                        builder: (context, snapshot) {
                           if (!snapshot.hasData) {
                             return const Center(child: CircularProgressIndicator(color: Colors.white));
                           }
                           
                           // Aggregate Data based on Period
                           Map<String, List<double>> aggregatedData = _aggregateData(snapshot.data!.docs);
                           
                           // Generate Labels based on Period
                           List<String> labels = _getLabelsForPeriod();

                           return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: labels.map((label) {
                              double avg = 0;
                              if (aggregatedData[label] != null && aggregatedData[label]!.isNotEmpty) {
                                avg = aggregatedData[label]!.reduce((a, b) => a + b) / aggregatedData[label]!.length;
                              }
                              // We need to shift bars up slightly to account for the X-axis labels being outside the grid in a real chart lib,
                              // but here we just render them within the 200px height.
                              // Actually, the previous implementation had labels inside the Column.
                              // Let's keep it simple: Bars align bottom.
                              return _buildBar(label, avg, width: _getBarWidth());
                            }).toList(),
                          );
                        }
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _getStreamForPeriod() {
    if (_selectedPeriod == 'Month') return SensorService().getMonthlySleepData();
    if (_selectedPeriod == 'Year') return SensorService().getYearlySleepData();
    return SensorService().getWeeklySleepData();
  }

  Map<String, List<double>> _aggregateData(List<QueryDocumentSnapshot> docs) {
    Map<String, List<double>> data = {};
    
    // Initialize map keys
    for (var label in _getLabelsForPeriod()) {
      data[label] = [];
    }

    for (var doc in docs) {
      final d = doc.data() as Map<String, dynamic>;
      final ts = (d['server_timestamp'] as Timestamp?)?.toDate();
      final score = (d['sleep_score'] as num?)?.toDouble() ?? 0.0;

      if (ts != null) {
        String key = "";
        if (_selectedPeriod == 'Week') {
          // Mon, Tue...
          const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
          key = days[ts.weekday - 1];
        } else if (_selectedPeriod == 'Month') {
          // Week 1, Week 2... (Simple bucket based on day of month)
          // 1-7 = W1, 8-14 = W2, 15-21 = W3, 22+ = W4
          int day = ts.day;
          if (day <= 7) key = 'W1';
          else if (day <= 14) key = 'W2';
          else if (day <= 21) key = 'W3';
          else key = 'W4';
        } else if (_selectedPeriod == 'Year') {
          // Jan, Feb...
          const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
          key = months[ts.month - 1];
        }
        
        if (data.containsKey(key)) {
          data[key]!.add(score);
        }
      }
    }
    return data;
  }

  List<String> _getLabelsForPeriod() {
    if (_selectedPeriod == 'Week') return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    if (_selectedPeriod == 'Month') return ['W1', 'W2', 'W3', 'W4'];
    if (_selectedPeriod == 'Year') return ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return [];
  }
  
  double _getBarWidth() {
    if (_selectedPeriod == 'Year') return 12; // Thinner bars for year
    if (_selectedPeriod == 'Month') return 40; // Wider bars for month
    return 30; // Default for week
  }

  Widget _buildToggleItem(String text, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPeriod = text;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFB74D) : Colors.transparent, 
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildBar(String label, double heightPercentage, {double width = 30, double fontSize = 10}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: width, 
          height: (heightPercentage / 100) * 150, // Scale to chart area
          decoration: BoxDecoration(
            color: const Color(0xFFFFB74D), // Orange bars
            borderRadius: BorderRadius.circular(width / 2),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(color: Colors.white70, fontSize: fontSize),
        ),
      ],
    );
  }


  Widget _buildDailyScoreCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE0B2), // Beige
        borderRadius: BorderRadius.circular(24),
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: SensorService().getTodaySleepData(), 
        builder: (context, snapshot) {
          int finalScore = 0; 
          double avgHr = 0;
          String durationText = "0h 0m";
          
          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
             final docs = snapshot.data!.docs;
             
             // 1. Calculate Average Quality Score & Avg HR
             double totalQuality = 0;
             double totalHr = 0;
             int count = 0;
             
             List<DateTime> timestamps = [];

             for (var doc in docs) {
                final d = doc.data() as Map<String, dynamic>;
                final q = (d['sleep_score'] as num?)?.toDouble() ?? 0;
                final h = (d['heart_rate'] as num?)?.toDouble() ?? 0;
                final ts = (d['server_timestamp'] as Timestamp?)?.toDate();

                if (ts != null) timestamps.add(ts);
                
                // Only count valid readings
                if (q > 0) {
                   totalQuality += q;
                   if (h > 0) totalHr += h;
                   count++;
                }
             }

             double avgQuality = (count > 0) ? totalQuality / count : 0;
             if (count > 0) avgHr = totalHr / count;

             // 2. Calculate Duration
             timestamps.sort(); // Oldest first
             Duration sleepDuration = Duration.zero;
             if (timestamps.isNotEmpty) {
                 sleepDuration = timestamps.last.difference(timestamps.first);
             }
             
             int hours = sleepDuration.inHours;
             int minutes = sleepDuration.inMinutes.remainder(60);
             durationText = "${hours}h ${minutes}m";

             // 3. Duration Score
             double durationScore = 0;
             if (hours >= 7) durationScore = 100;
             else if (hours >= 6) durationScore = 85;
             else if (hours >= 5) durationScore = 70;
             else if (hours >= 4) durationScore = 50;
             else durationScore = 30; // Very short sleep

             // 4. Final Weighted Score
             // If duration is very short (< 1 hr), relying on quality alone might be misleading.
             // But let's stick to the requested 50/50 split for a "Session Score".
             if (sleepDuration.inMinutes < 30) {
                finalScore = avgQuality.toInt(); // Too short to count duration
             } else {
                finalScore = ((avgQuality * 0.6) + (durationScore * 0.4)).toInt(); 
             }
          }

          return Column(
            children: [
              const Text(
                'Sleep Quality Score\nToday',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF5D4037),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 20),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120, height: 120,
                    child: CircularProgressIndicator(
                      value: finalScore / 100.0,
                      strokeWidth: 12,
                      backgroundColor: Colors.white, 
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF5D4037)),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$finalScore',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5D4037),
                        ),
                      ),
                      Text(
                        finalScore >= 80 ? "Excellent" : (finalScore >= 50 ? "Good" : "Fair"), 
                        style: const TextStyle(fontSize: 10, color: Colors.brown),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Column(
                     children: [
                        const Icon(Icons.favorite, color: Color(0xFF5D4037), size: 16),
                        const SizedBox(height: 4),
                        Text(
                         "${avgHr.toStringAsFixed(0)} bpm", 
                         style: const TextStyle(fontSize: 12, color: Color(0xFF5D4037)),
                       ),
                     ],
                   ),
                   const SizedBox(width: 20),
                   Column(
                     children: [
                        const Icon(Icons.access_time, color: Color(0xFF5D4037), size: 16),
                        const SizedBox(height: 4),
                        Text(
                         durationText, 
                         style: const TextStyle(fontSize: 12, color: Color(0xFF5D4037)),
                       ),
                     ],
                   ),
                ],
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildSleepStagesCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: SensorService().getLatestReading(), // Just to trigger rebuilds, but we need history
      builder: (context, _) {
          return StreamBuilder<QuerySnapshot>(
            stream: SensorService().getRecentHistory(), // Get recent history for stage calculation
            builder: (context, snapshot) {
               
               int total = 0;
               int awakeCount = 0;
               int remCount = 0;
               int lightCount = 0;
               int deepCount = 0;

               if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                   total = snapshot.data!.docs.length;
                   for (var doc in snapshot.data!.docs) {
                       final data = doc.data() as Map<String, dynamic>;
                       final stage = data['sleep_stage'] as String? ?? 'Light';
                       
                       if (stage == 'Awake') awakeCount++;
                       else if (stage == 'REM') remCount++;
                       else if (stage == 'Deep') deepCount++;
                       else lightCount++; // Default to Light
                   }
               }
               
               // Prevent division by zero
               if (total == 0) total = 1;

               double awake = awakeCount / total;
               double rem = remCount / total;
               double light = lightCount / total;
               double deep = deepCount / total;
               
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF3E2723), // Very Dark Brown
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Sleep Stages\nToday (Real-time)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                         color: Colors.white,
                         fontWeight: FontWeight.bold,
                         fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildStageRow("Awake", "${(awake*100).toInt()}%", awake, const Color(0xFFFFCC80)),
                    const SizedBox(height: 12),
                    _buildStageRow("REM", "${(rem*100).toInt()}%", rem, const Color(0xFFE1BEE7)),
                    const SizedBox(height: 12),
                    _buildStageRow("Light", "${(light*100).toInt()}%", light, const Color(0xFF90CAF9)),
                    const SizedBox(height: 12),
                    _buildStageRow("Deep", "${(deep*100).toInt()}%", deep, const Color(0xFF5E35B1)),
                  ],
                ),
              );
            }
          );
      }
    );
  }

  Widget _buildStageRow(String label, String value, double percentage, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            Text(value, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 8,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFFFE0B2), // Beige background track
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percentage,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

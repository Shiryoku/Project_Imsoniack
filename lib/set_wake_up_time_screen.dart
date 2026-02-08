import 'package:flutter/material.dart';
import 'notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as fln;
import 'package:shared_preferences/shared_preferences.dart';

class SetWakeUpTimeScreen extends StatefulWidget {
  const SetWakeUpTimeScreen({super.key});

  @override
  State<SetWakeUpTimeScreen> createState() => _SetWakeUpTimeScreenState();
}

class _SetWakeUpTimeScreenState extends State<SetWakeUpTimeScreen> {
  // Scroll Controllers for 24h format (Hour 0-23, Minute 0-59)
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;
  
  List<String> _history = [];

  @override
  void initState() {
    super.initState();
    _hourController = FixedExtentScrollController(initialItem: 7);
    _minuteController = FixedExtentScrollController(initialItem: 0);
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _history = prefs.getStringList('wakeUpHistory') ?? [];
    });
  }

  Future<void> _saveHistory(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    final formatted = "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
    final entry = "Set: $formatted"; // Simplified entry
    
    // Add to top
    if (!_history.contains(entry)) {
       _history.insert(0, entry);
       // Limit to last 10
       if (_history.length > 10) _history = _history.sublist(0, 10);
       await prefs.setStringList('wakeUpHistory', _history);
       setState(() {});
    }
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Set Wake Up Time',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Set 24h Wake Up Time',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'We will notify you 7 hours before.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 40),
            
            // Custom Time Input Row (2 Wheels: HH and MM)
            SizedBox(
              height: 150,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Hours 0-23
                  _buildScrollWheel(_hourController, 24, label: "H"),
                  const SizedBox(width: 16),
                  Text(':', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(width: 16),
                  // Minutes 0-59
                  _buildScrollWheel(_minuteController, 60, label: "M"),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                    // Start by requesting permissions to ensure notification is allowed
                    await NotificationService().flutterLocalNotificationsPlugin
                        .resolvePlatformSpecificImplementation<
                            fln.AndroidFlutterLocalNotificationsPlugin>()
                        ?.requestNotificationsPermission();

                    int hour = _hourController.selectedItem;
                    int minute = _minuteController.selectedItem;
                    
                    // Construct DateTime for *next* occurrence
                    final now = DateTime.now();
                    var wakeUpTime = DateTime(now.year, now.month, now.day, hour, minute);
                    
                    // If time already passed today, assume tomorrow
                    if (wakeUpTime.isBefore(now)) {
                      wakeUpTime = wakeUpTime.add(const Duration(days: 1));
                    }
                    
                    // Schedule Notification
                    await NotificationService().scheduleSleepReminder(wakeUpTime);
                    await _saveHistory(wakeUpTime);
                    
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Wake up set for ${_formatTime(hour, minute)}. Sleep reminder scheduled!"),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFE0B2), // Light Peach
                  foregroundColor: const Color(0xFFA0522D), // Brown Text
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text('Save Wake Up Time'),
              ),
            ),
            
            const SizedBox(height: 30),
            Text("History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: _history.length,
                itemBuilder: (context, index) {
                   return ListTile(
                     leading: Icon(Icons.history, color: Colors.grey),
                     title: Text(_history[index], style: TextStyle(color: textColor)),
                   );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
  
  String _formatTime(int h, int m) {
    return "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}";
  }

  Widget _buildScrollWheel(FixedExtentScrollController controller, int itemCount, {String? label}) {
    return Column(
      children: [
        if (label != null) Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Container(
          width: 80,
          height: 120, 
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListWheelScrollView.useDelegate(
            controller: controller,
            itemExtent: 50,
            physics: const FixedExtentScrollPhysics(),
            perspective: 0.005,
            diameterRatio: 1.2,
            childDelegate: ListWheelChildBuilderDelegate(
              builder: (context, index) {
                return Center(
                  child: Text(
                    index.toString().padLeft(2, '0'),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                );
              },
              childCount: itemCount,
            ),
          ),
        ),
      ],
    );
  }
}

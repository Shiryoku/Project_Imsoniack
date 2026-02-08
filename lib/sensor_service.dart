import 'package:cloud_firestore/cloud_firestore.dart';

class SensorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream the latest single sensor reading for real-time dashboard
  Stream<QuerySnapshot> getLatestReading() {
    return _firestore
        .collection('iot_data')
        .orderBy('server_timestamp', descending: true)
        .limit(1)
        .snapshots();
  }


  /// Stream the last hour of data for charts (optional usage)
  Stream<QuerySnapshot> getRecentReadings() {
    final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
    return _firestore
        .collection('iot_data')
        .where('server_timestamp', isGreaterThan: oneHourAgo)
        .orderBy('server_timestamp', descending: true)
        .snapshots();
  }

  /// Stream the last 20 readings for the real-time graph
  Stream<QuerySnapshot> getRecentHistory() {
    return _firestore
        .collection('iot_data')
        .orderBy('server_timestamp', descending: true)
        .limit(20)
        .snapshots();
  }
  /// Stream data for the last 7 days for Weekly Analytics
  Stream<QuerySnapshot> getWeeklySleepData() {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    return _firestore
        .collection('iot_data')
        .where('server_timestamp', isGreaterThan: sevenDaysAgo)
        .orderBy('server_timestamp', descending: true)
        .snapshots();
  }

  /// Stream data for the last 30 days for Monthly Analytics
  Stream<QuerySnapshot> getMonthlySleepData() {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    return _firestore
        .collection('iot_data')
        .where('server_timestamp', isGreaterThan: thirtyDaysAgo)
        .orderBy('server_timestamp', descending: true)
        .snapshots();
  }

  /// Stream data for the last 365 days for Yearly Analytics
  Stream<QuerySnapshot> getYearlySleepData() {
    final oneYearAgo = DateTime.now().subtract(const Duration(days: 365));
    return _firestore
        .collection('iot_data')
        .where('server_timestamp', isGreaterThan: oneYearAgo)
        .orderBy('server_timestamp', descending: true)
        .snapshots();
  }

  /// Stream all data from today (since midnight) for Daily Score Calculation
  Stream<QuerySnapshot> getTodaySleepData() {
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day); 
    // Optimization: If user sleeps past midnight, this might split the session.
    // Better Approach: Get last 12-14 hours to capture a full night regardless of date crossing.
    final sessionStart = now.subtract(const Duration(hours: 14));

    return _firestore
        .collection('iot_data')
        .where('server_timestamp', isGreaterThan: sessionStart)
        .orderBy('server_timestamp', descending: true)
        .snapshots();
  }
}

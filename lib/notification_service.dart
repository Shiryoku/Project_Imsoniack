import 'package:flutter_local_notifications/flutter_local_notifications.dart' as fln;
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter/foundation.dart'; // for kDebugMode

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final fln.FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      fln.FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Initialize Timezone
    tz.initializeTimeZones();
    // Get Local Timezone
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    // Android Settings
    const fln.AndroidInitializationSettings initializationSettingsAndroid =
        fln.AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS Settings
    const fln.DarwinInitializationSettings initializationSettingsDarwin =
        fln.DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const fln.InitializationSettings initializationSettings = fln.InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (fln.NotificationResponse details) {
        // Handle notification tap
        if (kDebugMode) {
          print('Notification payload: ${details.payload}');
        }
      },
    );

    // Request Android Permissions (API 33+)
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            fln.AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

  }

  Future<void> scheduleSleepReminder(DateTime wakeUpTime) async {
    // Calculate sleep time (7 hours before wake up)
    final scheduledTime = wakeUpTime.subtract(const Duration(hours: 7));
    
    var now = DateTime.now();
    var targetTime = scheduledTime;

    if (targetTime.isBefore(now)) {
      targetTime = targetTime.add(const Duration(days: 1));
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      0, // ID
      'Time to Sleep!', // Title
      'You need 7 hours of sleep. Based on your ${wakeUpTime.hour.toString().padLeft(2, '0')}:${wakeUpTime.minute.toString().padLeft(2, '0')} wake up time, you should sleep now.', // Body
      tz.TZDateTime.from(targetTime, tz.local),
      const fln.NotificationDetails(
        android: fln.AndroidNotificationDetails(
          'sleep_reminder_notify_v2', // Changed Channel ID to force update
          'Sleep Reminders', 
          channelDescription: 'Reminds you when to go to sleep',
          importance: fln.Importance.max,
          priority: fln.Priority.high,
          ticker: 'ticker',
          enableVibration: true,
          playSound: true,
        ),
        iOS: fln.DarwinNotificationDetails(
          presentSound: true,
        ),
      ),
      androidScheduleMode: fln.AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: fln.DateTimeComponents.time, // Repeats daily at this time
    );
  }
  
  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }


}

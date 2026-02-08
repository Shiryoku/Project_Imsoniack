import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vibration/vibration.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';

class EmergencyAlertScreen extends StatefulWidget {
  final int heartRate;

  const EmergencyAlertScreen({super.key, required this.heartRate});

  @override
  State<EmergencyAlertScreen> createState() => _EmergencyAlertScreenState();
}

class _EmergencyAlertScreenState extends State<EmergencyAlertScreen> {
  int _timeLeft = 20; // Reduced to 20 Seconds
  Timer? _timer;
  bool _contacting = false;
  String _contactName = "Emergency Contact";
  String _contactPhone = "";

  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _vibrationTimer;

  @override
  void initState() {
    super.initState();
    _loadContact();
    _requestPermission(); // Request permission early
    _startAlarm();
  }

  Future<void> _requestPermission() async {
    final status = await Permission.phone.request();
    if (status.isDenied) {
       // Optional: Show rationale, but for now just log
       debugPrint("Phone permission denied");
    }
  }

  Future<void> _startAlarm() async {
    // Start Sound
    try {
      // Assuming you have an alarm_sound.mp3 in assets. 
      // If not, we can use a system sound or default to just vibration for now if mp3 missing.
      // But user asked for sound. I'll use a standard asset reference.
      // NOTE: You must ensure 'assets/audio/alarm.mp3' exists or this will fail silently/log error.
      _audioPlayer.setReleaseMode(ReleaseMode.loop);
      // 'audio/alarm.mp3' matches the structure inside 'assets/'
      await _audioPlayer.play(AssetSource('audio/alarm.mp3'));
    } catch (e) {
      debugPrint("Error playing sound: $e");
    }

    // Start Vibration Loop
    bool? hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
        _vibrationTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
             Vibration.vibrate(duration: 500); 
        });
    }

    _startTimer();
  }
  
  void _stopAlarmAndVibration() {
    _timer?.cancel();
    _vibrationTimer?.cancel();
    _audioPlayer.stop();
    Vibration.cancel();
  }

  Future<void> _loadContact() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _contactName = prefs.getString('emergencyName') ?? "Emergency Contact";
      _contactPhone = prefs.getString('emergencyPhone') ?? "";
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });
      } else {
        _timer?.cancel();
        _triggerEmergency();
      }
    });
  }

  void _stopAlarm() {
    _stopAlarmAndVibration();
    
    // Return to home
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Alarm Cancelled. Glad you are okay!")),
      );
    }
  }

  Future<void> _triggerEmergency() async {
    _stopAlarmAndVibration(); // Stop noise when calling

    setState(() {
      _contacting = true;
    });

    if (_contactPhone.isEmpty) {
        if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("No emergency contact set! Please update your profile.")),
              );
             await Future.delayed(const Duration(seconds: 3));
             if(mounted) Navigator.pop(context); 
        }
        return;
    }

    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: _contactPhone,
    );

    try {
      // Try Direct Call first
      bool? res = await FlutterPhoneDirectCaller.callNumber(_contactPhone);
      if (res != true) {
         // Fallback to Dialer if direct call fails
         if (await canLaunchUrl(phoneUri)) {
            await launchUrl(phoneUri);
         } else {
            debugPrint("Could not launch Phone Dialer");
         }
      }
    } catch (e) {
      debugPrint("Error launching Phone: $e");
      // Fallback
       if (await canLaunchUrl(phoneUri)) {
            await launchUrl(phoneUri);
       }
    }
    
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _stopAlarmAndVibration();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade900,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 80, color: Colors.white),
            const SizedBox(height: 24),
            const Text(
              "ABNORMAL HEART RATE DETECTED",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "${widget.heartRate} BPM",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 48,
              ),
            ),
            const SizedBox(height: 40),
            
            // Countdown Circle
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: CircularProgressIndicator(
                    value: _timeLeft / 20, // Updated base to 20
                    strokeWidth: 12,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    backgroundColor: Colors.red.shade700,
                  ),
                ),
                Text(
                  "$_timeLeft",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 64,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 48),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Text(
                "Calling $_contactName in $_timeLeft seconds...",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ),
            
            const SizedBox(height: 24),

            // Cancel Button
            GestureDetector(
              onTap: _stopAlarm,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    )
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.green, size: 32),
                    SizedBox(width: 12),
                    Text(
                      "I'M OK - FALSE ALARM",
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
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

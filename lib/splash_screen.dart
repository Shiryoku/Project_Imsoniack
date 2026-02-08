import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'main.dart' as com_main;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Wait 3 seconds then navigate
    Timer(const Duration(seconds: 3), () {
       if (mounted) {
         // Check if we are already in a navigation stack or just replace
         // We navigate to AuthWrapper which handles the "Where to go" logic
         Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const com_main.AuthWrapper()),
         );
       }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFE4C4), // Peach fallback
      body: SizedBox.expand(
        child: Image.asset(
          'assets/images/intro_full.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

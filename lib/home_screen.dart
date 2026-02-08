import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart'; // Import url_launcher
import 'dart:async';
import 'sensor_service.dart';
import 'music_screen.dart';
import 'analytics_screen.dart';
import 'profile_screen.dart';
import 'emergency_alert_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  int _streakDays = 2; // Initial streak
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  StreamSubscription? _sensorSubscription;
  DateTime? _lastAlertTime;

  @override
  void initState() {
    super.initState();
    _startMonitoring();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  void _startMonitoring() {
    _sensorSubscription = SensorService().getLatestReading().listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data() as Map<String, dynamic>;
        final hr = (data['heart_rate'] as num?)?.toInt() ?? 0;
        
        // Trigger Condition: HR > 150 or HR < 40 (only if valid > 0)
        if (hr > 150 || (hr > 0 && hr < 40)) {
           _triggerAlert(hr);
        }
      }
    });
  }

  void _triggerAlert(int hr) {
    final now = DateTime.now();
    // Debounce: Only alert once every 2 minutes to prevent spam loops
    if (_lastAlertTime == null || now.difference(_lastAlertTime!) > const Duration(minutes: 2)) {
      _lastAlertTime = now;
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => EmergencyAlertScreen(heartRate: hr)),
        );
      }
    }
  }

  @override
  void dispose() {
    _sensorSubscription?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }



  @override
  Widget build(BuildContext context) {
    
    // Theme data
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final navBarColor = isDarkMode ? Colors.black : const Color(0xFFFFF0E0);
    final navItemColor = isDarkMode ? Colors.white : Colors.black87;
    final navUnselectedColor = isDarkMode ? Colors.white54 : Colors.grey;

    Widget currentScreen;
    switch (_selectedIndex) {
      case 0:
        currentScreen = _buildDashboard(context);
        break;
      case 1:
        currentScreen = const MusicScreen();
        break;
      case 2:
        currentScreen = const AnalyticsScreen();
        break;
      case 3:
        currentScreen = const ProfileScreen();
        break;
      default:
        currentScreen = _buildDashboard(context);
    }
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(child: currentScreen),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: navBarColor, 
        selectedItemColor: navItemColor,
        unselectedItemColor: navUnselectedColor,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
             icon: Icon(Icons.music_note),
            label: 'Music',
          ),
           BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Analytics',
          ),
           BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Account',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDarkMode ? Colors.white : Colors.black87;
    const accentColor = Color(0xFFD98850);
    final peachBg = const Color(0xFFFFE4C4);
    final navBarColor = isDarkMode ? Colors.black : const Color(0xFFFFF0E0); // Need for Article logic
    
    return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: Row(
                  children: [
                    StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseAuth.instance.currentUser != null 
                            ? FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).snapshots()
                            : null,
                        builder: (context, snapshot) {
                            ImageProvider? image;
                            if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
                                final data = snapshot.data!.data() as Map<String, dynamic>?;
                                final url = data?['photoURL'];
                                if (url != null && url.isNotEmpty) {
                                    image = NetworkImage(url);
                                }
                            }
                            
                            return CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.grey,
                              backgroundImage: image,
                              child: image == null ? const Icon(Icons.person, color: Colors.white) : null,
                            );
                        }
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Time to sleep,',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        Text(
                          'Dosatsu',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: primaryText,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.grey),
                      onPressed: () {}, // Close/Dismiss action
                    ),
                  ],
                ),
              ),

              // Circular Progress Ring
              const SizedBox(height: 20),
              Center(
                child: StreamBuilder<QuerySnapshot>(
                  stream: SensorService().getLatestReading(),
                  builder: (context, snapshot) {
                    double progress = 0;
                    String mainText = "--";
                    String subText = "Waiting for data...";
                    
                    if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                       final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
                       final score = (data['sleep_score'] as num?)?.toInt() ?? 0;
                       progress = score / 100.0;
                       mainText = "$score";
                       subText = "Sleep Score";
                    }

                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 250,
                          height: 250,
                          child: CircularProgressIndicator(
                            value: progress == 0 ? null : progress, // null for indeterminate if 0? No, let's keep it 0 or null if waiting.
                            // actually if waiting, progress is 0.
                            strokeWidth: 20,
                            backgroundColor: Colors.grey[200],
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFCC99)), // Light Orange
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bed, size: 32, color: Colors.grey),
                            SizedBox(height: 8),
                            Text(
                              mainText,
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w300,
                                color: primaryText,
                              ),
                            ),
                            Text(
                              subText,
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    );
                  }
                ),
              ),
              
              const SizedBox(height: 40),

              // Stats Grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: StreamBuilder<QuerySnapshot>(
                  stream: SensorService().getRecentHistory(),
                  builder: (context, snapshot) {
                     String scoreVal = "0";
                     String streakVal = "0";
                     String bedtimeVal = "--:--";
                     
                     if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                        final docs = snapshot.data!.docs;
                        final latest = docs.first.data() as Map<String, dynamic>;
                        
                        // 1. Sleep Score
                        scoreVal = (latest['sleep_score'] as num?)?.toInt().toString() ?? "0";
                        
                        // 2. Excellent Score (Streak)
                        int streak = 0;
                        for (var doc in docs) {
                           final data = doc.data() as Map<String, dynamic>;
                           final score = (data['sleep_score'] as num?)?.toInt() ?? 0;
                           if (score >= 80) {
                             streak++;
                           } else {
                             break; // Reset if user got bad/ok sleep
                           }
                        }
                        streakVal = streak.toString();
                        
                        // 3. Bedtime (Timestamp of latest reading)
                        if (latest['server_timestamp'] != null) {
                           final ts = (latest['server_timestamp'] as Timestamp).toDate();
                           bedtimeVal = DateFormat('h:mm a').format(ts);
                        }
                     }
                  
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildInfoCard(scoreVal, 'Sleep Score', Icons.star, const Color(0xFFFFE0B2), false),
                        _buildInfoCard(streakVal, 'Excellent Score', Icons.local_fire_department, const Color(0xFFFFCCBC), true), 
                        _buildInfoCard(bedtimeVal, 'Bedtime', Icons.access_time, const Color(0xFFFFE0B2), false),
                      ],
                    );
                  }
                ),
              ),

              const SizedBox(height: 30),

              // Explore Tips Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Explore Tips',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryText,
                      ),
                    ),
                     Text(
                      'See all',
                      style: TextStyle(
                        fontSize: 14,
                        color: accentColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Article List
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    _buildArticleCard(
                      '7 Bedtime Drinks That May Help You Sleep',
                      'assets/images/morning_tea.jpg',
                      'https://www.thehealthy.com/sleep/best-beverages-sleep-better-say-nutritionists/',
                      navBarColor == Colors.black,
                    ),
                    const SizedBox(height: 16),
                    _buildArticleCard(
                      'Common Medication Techniques for Sleep',
                      'assets/images/meditation.jpg',
                      'https://www.mayoclinic.org/diseases-conditions/insomnia/in-depth/sleeping-pills/art-20043959',
                      navBarColor == Colors.black,
                    ),
                    const SizedBox(height: 16),
                    _buildArticleCard(
                      'Relaxation Exercises To Help Fall Asleep',
                      'assets/images/relaxation.jpg',
                      'https://www.sleepfoundation.org/sleep-hygiene/relaxation-exercises-to-help-fall-asleep',
                      navBarColor == Colors.black,
                    ),
                    const SizedBox(height: 16),
                    _buildArticleCard(
                      '20 ways to fall asleep naturally',
                      'assets/images/reading.jpg',
                      'https://www.medicalnewstoday.com/articles/322928#summary',
                      navBarColor == Colors.black,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              

              const SizedBox(height: 30),
            ],
          ),
        );
  }
  
  Widget _buildArticleCard(String title, String imageUrl, String url, bool isDarkMode) {
    return GestureDetector(
      onTap: () async {
        final Uri uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not launch $url')),
          );
        }
      },
      child: Container(
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[900] : Colors.brown[400], 
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: imageUrl.startsWith('http') 
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(color: Colors.grey); // Fallback
                      },
                    )
                  : Image.asset(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                         return Container(color: Colors.grey); // Fallback
                      },
                    ),
            ),
            // Gradient Overlay for readability
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black54, Colors.transparent], 
                    begin: Alignment.bottomCenter, 
                    end: Alignment.topCenter
                  ),
                ),
              ),
            ),
            
            Positioned(
              left: 16,
              bottom: 16,
              right: 16,
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      blurRadius: 4.0,
                      color: Colors.black,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
            // Play icon
            Positioned(
              bottom: 12,
              right: 12,
              child: Icon(Icons.play_circle_fill, color: Colors.white.withAlpha(200), size: 32),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String value, String label, IconData icon, Color bgColor, bool isStreak) {
    return Container(
      width: 100, // Fixed width for uniformity
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isStreak 
            ? ScaleTransition(
                scale: _scaleAnimation,
                child: Icon(icon, size: 20, color: Colors.deepOrange /*Fire Color*/),
              )
            : Icon(icon, size: 20, color: Colors.brown[700]),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

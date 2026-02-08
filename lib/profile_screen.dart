import 'package:flutter/material.dart';

import 'package:project_imsoniack/theme_manager.dart';
import 'package:project_imsoniack/set_wake_up_time_screen.dart';
import 'package:project_imsoniack/edit_profile_screen.dart';
import 'package:project_imsoniack/change_password_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as fln;
import 'notification_service.dart';
import 'auth_service.dart';
import 'emergency_alert_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsEnabled = false;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final sectionHeaderColor = isDarkMode ? Colors.grey[800] : const Color(0xFFEEEEEE);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Account & Preferences',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
          const SizedBox(height: 30),
          
          // Profile Header
          Center(
            child: Column(
              children: [
                Stack(
                  children: [
                    const CircleAvatar(
                      radius: 50,
                      backgroundImage: AssetImage('assets/images/user_avatar.png'), // Placeholder or use NetworkImage
                      child: Icon(Icons.person, size: 50, color: Colors.grey),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.orange,
                        child: const Icon(Icons.edit, color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Dosatsu',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Text(
                  'dosatsu@gmail.com',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 30),
          
          // General Section
          _buildSectionHeader('General', sectionHeaderColor!),
          
          ValueListenableBuilder<ThemeMode>(
            valueListenable: ThemeManager(),
            builder: (context, themeMode, _) {
              final isDark = themeMode == ThemeMode.dark;
              return ListTile(
                leading: Icon(Icons.brightness_6, color: textColor),
                title: Text('Mode', style: TextStyle(color: textColor)),
                subtitle: Text(isDark ? 'Dark' : 'Light', style: const TextStyle(color: Colors.grey)),
                trailing: Switch(
                  value: isDark,
                  onChanged: (val) {
                    ThemeManager().toggleTheme(val);
                  },
                  activeColor: Colors.orange,
                ),
              );
            },
          ),
          
          ListTile(
            leading: Icon(Icons.notifications, color: textColor),
            title: Text('Notifications', style: TextStyle(color: textColor)),
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: (val) {
                setState(() {
                  _notificationsEnabled = val;
                });
              },
              activeColor: Colors.orange,
            ),
          ),
          
          ListTile(
            leading: Icon(Icons.access_alarm, color: textColor),
            title: Text('Set Wake Up Time', style: TextStyle(color: textColor)),
            trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SetWakeUpTimeScreen()),
              );
            },
          ),
          
          const SizedBox(height: 20),
          
          // Account Section
          _buildSectionHeader('Account', sectionHeaderColor),
          
          ListTile(
            leading: Icon(Icons.person_outline, color: textColor),
            title: Text('Edit Profile & Contact', style: TextStyle(color: textColor)),
            subtitle: const Text('Photo, Name, Emergency Info', style: TextStyle(color: Colors.grey, fontSize: 12)),
            trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: () {
               Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EditProfileScreen()),
              );
            },
          ),
          
          ListTile(
            leading: Icon(Icons.vpn_key, color: textColor),
            title: Text('Change Password', style: TextStyle(color: textColor)),
            trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: () {
               Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
              );
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.orange), // Changed to orange to differentiate
            title: const Text('Sign Out', style: TextStyle(color: Colors.orange)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.orange),
            onTap: () async {
               await AuthService().signOut();
            },
          ),
          
          const SizedBox(height: 20),
          _buildSectionHeader('Developer & Demo', sectionHeaderColor),
          
          ListTile(
            leading: const Icon(Icons.warning_amber_rounded, color: Colors.red),
            title: const Text('Test Emergency Alert', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            subtitle: const Text('Simulate 180 BPM trigger', style: TextStyle(color: Colors.grey, fontSize: 12)),
            trailing: const Icon(Icons.play_circle_outline, size: 24, color: Colors.red),
            onTap: () {
               Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EmergencyAlertScreen(heartRate: 180)),
              );
            },
          ),
           const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color bgColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: bgColor,
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

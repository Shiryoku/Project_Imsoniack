import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _nameController = TextEditingController(text: "Dosatsu");
  final TextEditingController _urlController = TextEditingController(); 
  final TextEditingController _emergencyNameController = TextEditingController();
  final TextEditingController _emergencyPhoneController = TextEditingController();

  String? _selectedFileName;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;

    String? photoURL;
    if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
            photoURL = doc.data()?['photoURL'];
        }
    }

    setState(() {
      _emergencyNameController.text = prefs.getString('emergencyName') ?? "";
      _emergencyPhoneController.text = prefs.getString('emergencyPhone') ?? "";
      if (photoURL != null) _urlController.text = photoURL;
    });
  }

  Future<void> _saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('emergencyName', _emergencyNameController.text);
    await prefs.setString('emergencyPhone', _emergencyPhoneController.text);
    
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'photoURL': _urlController.text,
            'updatedAt': FieldValue.serverTimestamp(), // Optional metadata
        }, SetOptions(merge: true));
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Changes saved successfully!")),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFileName = result.files.single.name;
        _isUploading = true;
      });
      
      try {
          final file = File(result.files.single.path!);
          final user = FirebaseAuth.instance.currentUser;
          
          if (user == null) throw Exception("No user logged in");

          // Upload to Firebase Storage
          final ref = FirebaseStorage.instance.ref().child('users/${user.uid}/profile.jpg');
          await ref.putFile(file);
          
          // Get URL
          final downloadURL = await ref.getDownloadURL();
          
          setState(() {
              _urlController.text = downloadURL;
              _isUploading = false;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Image uploaded successfully!")),
            );
          }
      } catch (e) {
          debugPrint("Error uploading image: $e");
          setState(() {
              _isUploading = false;
          });
          if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Upload failed: $e")),
              );
          }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final inputBgColor = const Color(0xFFFFE0B2); // Peach for inputs
    final inputBorderColor = Colors.black;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Edit Profile & Contact',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            Text(
              'Profile',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildLabel("Display Name"),
            _buildInput(_nameController, Icons.person_outline, inputBgColor, inputBorderColor),
            
            const SizedBox(height: 16),
            
            _buildLabel("Profile Picture URL"),
             // Show Image Preview if URL exists
            if (_urlController.text.isNotEmpty) 
                Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Center(
                        child: CircleAvatar(
                            radius: 50,
                            backgroundImage: NetworkImage(_urlController.text),
                            backgroundColor: Colors.grey,
                        ),
                    ),
                ),
            _buildInput(_urlController, Icons.link, inputBgColor, inputBorderColor, hint: "Paste a direct link to an image"),
            const SizedBox(height: 8),
            const Text(
              "Paste a direct link to an image",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            
            const SizedBox(height: 24),
            
            // Upload Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : _pickImage,
                icon: _isUploading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                    : const Icon(Icons.image_outlined, color: Color(0xFFA0522D)),
                label: Text(
                    _isUploading 
                        ? "Uploading..." 
                        : (_selectedFileName != null ? 'Selected: $_selectedFileName' : 'Select & Upload Image'),
                    style: const TextStyle(color: Color(0xFFA0522D), fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFE0B2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Colors.transparent), 
                  ),
                  elevation: 0,
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Emergency Contact Section
            const Text(
              'Emergency Contact',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Who should we call if we detect abnormal sleep patterns?',
              style: TextStyle(
                fontSize: 14,
                color: textColor.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
             _buildLabel("Contact Name"),
            _buildInput(_emergencyNameController, Icons.person_outline, inputBgColor, inputBorderColor),
             const SizedBox(height: 16),
             _buildLabel("Phone Number"),
            _buildInput(_emergencyPhoneController, Icons.phone_outlined, inputBgColor, inputBorderColor),

             const SizedBox(height: 40),
             
              // Save Changes Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveProfile,
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
                child: const Text('Save Changes'),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
      return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(text, style: const TextStyle(color: Colors.grey, fontSize: 13)),
      );
  }

  Widget _buildInput(TextEditingController controller, IconData icon, Color bgColor, Color borderColor, {String? hint}) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.black87),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black45, fontWeight: FontWeight.normal),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
      ),
    );
  }
}

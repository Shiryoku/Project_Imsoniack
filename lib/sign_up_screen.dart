import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';
import 'theme_manager.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // NOTE: Current AuthService might not take username yet. 
      // We will pass email/pass. Username is collected for future/profile use.
      await _authService.signUpWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      
      // Auto-sign out to prevent auto-login, as user requested redirection to Sign In screen
      // Wait, if we sign out, the Auth stream might flicker or just default to signed out state.
      // Since Sign Up usually auto-signs in, we need to explicitly sign out. 
      await _authService.signOut();

      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(
             content: Text('The account has been created'),
             backgroundColor: Colors.green,
             duration: Duration(seconds: 2),
           ),
         );
         Navigator.of(context).pop(); // Go back to Sign In
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? 'An error occurred';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isDarkMode ? Colors.black : Colors.white;
    final primaryTextColor = isDarkMode ? Colors.white : Colors.black87;
    final secondaryTextColor = isDarkMode ? Colors.white70 : Colors.black54;

    // Orange/Brown for links & accents
    final accentTextColor = const Color(0xFFD98850); 

    // Inputs
    final inputFillColor = isDarkMode ? const Color(0xFF424242) : const Color(0xFFFFEAD1); 
    final borderColor = isDarkMode ? Colors.grey[600]! : Colors.black; 
    final inputIconColor = isDarkMode ? Colors.grey[400]! : Colors.black54;

    // Button
    final buttonColor = const Color(0xFFFFEAD1); 

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // Header: Back Arrow + Title
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: secondaryTextColor),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Sign Up',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      color: primaryTextColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Title: Create Account
              Text(
                'Create Account',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: primaryTextColor,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 30),

              // Helper for Error
               if (_errorMessage != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.red[50], 
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red[800], fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),

              // Username Field
              _buildStyledTextField(
                controller: _usernameController,
                icon: Icons.person_outline,
                hintText: 'Username',
                fillColor: inputFillColor,
                borderColor: borderColor,
                textColor: primaryTextColor,
                iconColor: inputIconColor,
              ),
              const SizedBox(height: 20),

              // Email Input
              _buildStyledTextField(
                controller: _emailController,
                icon: Icons.mail_outlined, 
                hintText: 'Email',
                fillColor: inputFillColor,
                borderColor: borderColor,
                textColor: primaryTextColor,
                iconColor: inputIconColor,
              ),
              const SizedBox(height: 20),

              // Password Input
              _buildStyledTextField(
                controller: _passwordController,
                icon: Icons.lock_outlined,
                hintText: 'Password',
                fillColor: inputFillColor,
                borderColor: borderColor,
                textColor: primaryTextColor,
                iconColor: inputIconColor,
                isPassword: true,
              ),
              const SizedBox(height: 40),

              // Sign Up Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    foregroundColor: const Color(0xFFA0522D),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFA0522D)))
                      : const Text(
                          'Sign Up',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFA0522D),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // Login Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ", // Kept "Don't have" as per user request to mimic design exactly? 
                    // Wait, usually Sign Up screen says "Already have an account?"
                    // The uploaded image 1767584299609.png shows "Don't have an account? Sign In" at the bottom.
                    // That is a weird copy for a Sign Up screen, but I will follow the mock exactly as requested "same as this".
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primaryTextColor.withOpacity(0.7),
                      fontSize: 13,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop(); // Go back to Sign In
                    },
                    child: Text(
                      'Sign In',
                      style: TextStyle(
                        color: accentTextColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required IconData icon,
    required String hintText,
    required Color fillColor,
    required Color borderColor,
    required Color textColor,
    required Color iconColor,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.5), 
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2), 
      child: TextField(
        controller: controller,
        obscureText: isPassword ? _obscurePassword : false,
        style: TextStyle(color: textColor, fontWeight: FontWeight.normal),
        cursorColor: textColor,
        decoration: InputDecoration(
          border: InputBorder.none,
          icon: Icon(icon, color: iconColor), 
          hintText: hintText,
          hintStyle: TextStyle(color: iconColor),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: iconColor,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                )
              : null,
        ),
      ),
    );
  }
}

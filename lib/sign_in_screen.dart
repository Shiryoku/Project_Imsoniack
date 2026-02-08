import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';
import 'theme_manager.dart';
import 'forgot_password_screen.dart';
import 'sign_up_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  
  bool _isLoading = false;
  bool _rememberMe = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
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
    // Dynamic Colors based on Theme
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isDarkMode ? Colors.black : Colors.white;
    final primaryTextColor = isDarkMode ? Colors.white : Colors.black87;
    final secondaryTextColor = isDarkMode ? Colors.white70 : Colors.black54;
    final borderColor = isDarkMode ? Colors.white : Colors.black;
    
    // Light Peach in light mode, Dark Grey in dark mode
    final inputFillColor = isDarkMode ? const Color(0xFF2C2C2C) : const Color(0xFFFFEAD1); 
    
    // Button follows input fill in light, but maybe pop more in dark? 
    // Keeping consistent pattern: contrast.
    final buttonColor = const Color(0xFFFFEAD1); // Keep signature peach for button even in dark mode for contrast? 
    // Or make it dark? The user wants "same as this" which was peach. 
    // Usually buttons keep brand color. Let's keep button peach but ensure text is readable.
    
    final accentTextColor = const Color(0xFFD98850); // Orange/Brown for links

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Top Status Area placeholder if needed (handled by SafeArea)
              const SizedBox(height: 20),

              // Title
              Text(
                'Sign In',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: secondaryTextColor,
                ),
              ),
              const SizedBox(height: 30),

              // Logo
              Center(
                child: Image.asset(
                  'assets/images/transparent_icon_final.png',
                  height: 140, 
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 30),

              // Welcome Text
              Text(
                'Welcome!',
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

              // Email Input
              _buildStyledTextField(
                controller: _emailController,
                icon: Icons.mail_outlined, 
                hintText: 'Email',
                fillColor: inputFillColor,
                borderColor: borderColor,
                textColor: primaryTextColor,
                iconColor: secondaryTextColor,
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
                iconColor: secondaryTextColor,
                isPassword: true,
              ),
              const SizedBox(height: 16),

              // Remember Me & Forgot Password
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      // Custom checkbox to match look better
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: _rememberMe,
                          onChanged: (val) {
                            setState(() {
                              _rememberMe = val ?? false;
                            });
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          activeColor: isDarkMode ? Colors.white : Colors.black, 
                          checkColor: isDarkMode ? Colors.black : Colors.white,
                          side: BorderSide(color: borderColor, width: 1.5),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Remember Me',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: primaryTextColor,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ForgotPasswordScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'Forgot Password?',
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

              // Dark Mode Toggle
              Row(
                children: [
                  Icon(Icons.brightness_medium_outlined, color: borderColor, size: 22), 
                  const SizedBox(width: 8),
                  Text(
                    'Dark Mode',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primaryTextColor,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  // Switch styling
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: ThemeManager().isDarkMode,
                      activeColor: Colors.white,
                      activeTrackColor: isDarkMode ? Colors.white : Colors.black, 
                      inactiveThumbColor: Colors.grey[400],
                      trackOutlineColor: MaterialStateProperty.all(Colors.transparent),
                      onChanged: (val) {
                        setState(() {
                          ThemeManager().toggleTheme(val);
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Sign In Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    foregroundColor: const Color(0xFFA0522D), // Siena/Brown
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFA0522D)))
                      : Text(
                          'Sign In',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFA0522D),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // Switch Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primaryTextColor.withOpacity(0.7),
                      fontSize: 13,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignUpScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'Sign Up',
                      style: TextStyle(
                        color: accentTextColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
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

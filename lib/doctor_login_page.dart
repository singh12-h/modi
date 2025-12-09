import 'package:flutter/material.dart';
import 'dart:math';
import 'glassmorphism.dart';
import 'doctor_dashboard.dart';
import 'staff_login_page.dart';
import 'database_helper.dart';
import 'models.dart';
import 'doctor_registration_page.dart';
import 'forgot_password_page.dart';

class DoctorLoginPage extends StatefulWidget {
  const DoctorLoginPage({super.key});

  @override
  State<DoctorLoginPage> createState() => _DoctorLoginPageState();
}

class _DoctorLoginPageState extends State<DoctorLoginPage> {
  bool _rememberMe = false;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 700;
    
    // Scale factors for responsive design
    final scale = isMobile ? 0.7 : 1.0;
    final logoSize = isMobile ? 200.0 : 400.0;
    final cardWidth = isMobile ? screenSize.width * 0.92 : 450.0;
    final cardHeight = isMobile ? screenSize.height * 0.85 : 580.0;

    return Scaffold(
      body: Stack(
        children: [
          // Background - Same design on mobile and desktop
          Row(
            children: [
              // Left side: Dark blue gradient with design
              Expanded(
                flex: 1,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF001F3F), Color(0xFF003366)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Molecular Network Lines
                      CustomPaint(
                        painter: NetworkLinesPainter(),
                        child: Container(),
                      ),
                      const _GlowingDnaStrand(),
                    ],
                  ),
                ),
              ),
              // Right side: Clean white background - same on mobile and desktop
              Expanded(
                flex: 1,
                child: Container(
                  color: Colors.white,
                ),
              ),
            ],
          ),

          // Medical Logo - positioned on white section (responsive for mobile and desktop)
          Positioned(
            left: isMobile ? screenSize.width * 0.52 : screenSize.width * 0.58,
            top: isMobile 
                ? screenSize.height * 0.08  // Higher on mobile
                : screenSize.height * 0.5 - (logoSize / 2) - 25,
            child: Image.asset(
              'assets/images/medical_logo.png',
              width: logoSize,
              height: logoSize,
              fit: BoxFit.contain,
            ),
          ),

          // Login Card - centered with glassmorphic effect
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 0,
                  vertical: 16,
                ),
                child: GlassmorphicContainer(
                  width: cardWidth,
                  height: cardHeight,
                  borderRadius: 20,
                  blur: 10,
                  alignment: Alignment.center,
                  border: 2,
                  linearGradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withAlpha(51),
                      Colors.white.withAlpha(26),
                    ],
                    stops: const [0.1, 1],
                  ),
                  borderGradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withAlpha(128),
                      Colors.white.withAlpha(128),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(isMobile ? 20.0 : 32.0),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // App Icon for mobile (same style as desktop icon)
                          if (isMobile) ...[
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.asset(
                                  'assets/icon/app_icon.png',
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          Text(
                            'Doctor Portal Login',
                            style: TextStyle(
                              fontSize: isMobile ? 20 : 24,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF001F3F),
                            ),
                          ),
                          SizedBox(height: isMobile ? 8 : 16),
                          Icon(
                            Icons.local_hospital_outlined,
                            size: isMobile ? 36 : 48,
                            color: const Color(0xFF001F3F),
                          ),
                          SizedBox(height: isMobile ? 20 : 32),
                          _buildTextField(
                            controller: _usernameController,
                            hintText: 'Doctor Username',
                            icon: Icons.person_outline,
                          ),
                          SizedBox(height: isMobile ? 14 : 20),
                          _buildTextField(
                            controller: _passwordController,
                            hintText: 'Password',
                            icon: Icons.lock_outline,
                            obscureText: _obscurePassword,
                            isPassword: true,
                          ),
                          SizedBox(height: isMobile ? 14 : 20),
                          _buildRememberMeAndForgotPassword(),
                          SizedBox(height: isMobile ? 20 : 32),
                          _buildLoginButton(),
                          SizedBox(height: isMobile ? 12 : 16),
                          // Create Account Button
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFF003366), width: 2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (context) => const DoctorRegistrationPage()),
                                );
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: isMobile ? 10 : 14),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.person_add, color: const Color(0xFF003366), size: isMobile ? 18 : 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Create New Account',
                                    style: TextStyle(
                                      color: const Color(0xFF003366),
                                      fontSize: isMobile ? 14 : 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: isMobile ? 8 : 12),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(builder: (context) => const StaffLoginPage()),
                              );
                            },
                            child: Text(
                              'Switch to Staff Login',
                              style: TextStyle(
                                color: const Color(0xFF003366),
                                fontSize: isMobile ? 13 : 14,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
      {required TextEditingController controller,
      required String hintText,
      required IconData icon,
      bool obscureText = false,
      bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon, color: Colors.teal),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(obscureText ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              )
            : null,
        filled: true,
        fillColor: Colors.white.withAlpha(204),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.teal, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.teal, width: 2.5),
        ),
      ),
    );
  }

  Widget _buildRememberMeAndForgotPassword() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Checkbox(
              value: _rememberMe,
              onChanged: (value) {
                setState(() {
                  _rememberMe = value ?? false;
                });
              },
              activeColor: Colors.teal,
            ),
            const Text('Remember Me'),
          ],
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const ForgotPasswordPage()),
            );
          },
          child: const Text(
            'Forgot Password?',
            style: TextStyle(color: Colors.teal),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.teal, Color(0xFF008080)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : () async {
          setState(() => _isLoading = true);
          try {
            final staff = await DatabaseHelper.instance.authenticate(
              _usernameController.text,
              _passwordController.text,
            );

            if (staff != null && staff.role == 'doctor') {
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => DoctorDashboard(loggedInDoctor: staff)),
                );
              }
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid credentials or not a doctor account')),
                );
              }
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: $e')),
              );
            }
          } finally {
            if (mounted) setState(() => _isLoading = false);
          }
        },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          _isLoading ? 'Logging in...' : 'Login',
          style: const TextStyle(fontSize: 18, color: Colors.white),
        ),
      ),
    );
  }
}

class _GlowingDnaStrand extends StatelessWidget {
  const _GlowingDnaStrand();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 100,
      left: -50,
      child: Transform.rotate(
        angle: -pi / 6,
        child: SizedBox(
          width: 200,
          height: 600,
          child: Column(
            children: List.generate(15, (index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildGlowDot(),
                    Container(
                      width: 50 + 20 * sin(index * 0.8),
                      height: 2,
                      color: Colors.tealAccent.withAlpha(77),
                    ),
                    _buildGlowDot(),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildGlowDot() {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.tealAccent.withAlpha(179),
        boxShadow: [
          BoxShadow(
            color: Colors.tealAccent.withAlpha(128),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }
}

class NetworkLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(38)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final random = Random(123); // Seed for consistent layout
    final points = List.generate(50, (index) {
      return Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      );
    });

    for (int i = 0; i < points.length; i++) {
      for (int j = i + 1; j < points.length; j++) {
        final distance = (points[i] - points[j]).distance;
        if (distance < 120) {
          canvas.drawLine(points[i], points[j], paint);
        }
      }
    }

    final circlePaint = Paint()..color = Colors.white.withAlpha(51);

    for (final point in points) {
      canvas.drawCircle(point, 2, circlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

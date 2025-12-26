import 'package:flutter/material.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'glassmorphism.dart';
import 'staff_dashboard.dart';
import 'doctor_login_page.dart';
import 'database_helper.dart';
import 'models.dart';
import 'responsive_helper.dart';

class StaffLoginPage extends StatefulWidget {
  const StaffLoginPage({super.key});

  @override
  State<StaffLoginPage> createState() => _StaffLoginPageState();
}

class _StaffLoginPageState extends State<StaffLoginPage> {
  bool _rememberMe = false;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _canCheckBiometrics = false;
  bool _hasSavedCredentials = false;

  @override
  void initState() {
    super.initState();
    _initializeLogin();
  }

  Future<void> _initializeLogin() async {
    await _loadSavedCredentials();
    await _checkBiometricSupport();
    
    // Auto-trigger fingerprint if credentials are saved
    if (_canCheckBiometrics && _hasSavedCredentials) {
      // Small delay to let UI render first
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        _authenticateWithBiometrics();
      }
    }
  }

  Future<void> _checkBiometricSupport() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      setState(() {
        _canCheckBiometrics = canCheck && isDeviceSupported;
      });
    } on PlatformException {
      setState(() => _canCheckBiometrics = false);
    }
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUsername = prefs.getString('staff_saved_username');
    final savedPassword = prefs.getString('staff_saved_password');
    final rememberMe = prefs.getBool('staff_remember_me') ?? false;
    
    if (rememberMe && savedUsername != null) {
      setState(() {
        _usernameController.text = savedUsername;
        // Also fill password when Remember Me is enabled
        if (savedPassword != null) {
          _passwordController.text = savedPassword;
        }
        _rememberMe = true;
        _hasSavedCredentials = savedPassword != null;
      });
    }
  }

  Future<void> _saveCredentials(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('staff_saved_username', username);
      await prefs.setString('staff_saved_password', password);
      await prefs.setBool('staff_remember_me', true);
    } else {
      await prefs.remove('staff_saved_username');
      await prefs.remove('staff_saved_password');
      await prefs.setBool('staff_remember_me', false);
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    try {
      // First check if we have saved credentials
      final prefs = await SharedPreferences.getInstance();
      final savedUsername = prefs.getString('staff_saved_username');
      final savedPassword = prefs.getString('staff_saved_password');
      
      if (savedUsername == null || savedPassword == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please login with password first and enable "Remember Me" to use fingerprint'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Now authenticate with biometrics
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Scan your fingerprint to login',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allow PIN/Pattern as fallback
        ),
      );

      if (authenticated) {
        setState(() => _isLoading = true);
        try {
          final staff = await DatabaseHelper.instance.authenticate(
            savedUsername,
            savedPassword,
          );

          if (staff != null) {
            Staff? parentDoctor;
            if (staff.doctorId != null) {
              parentDoctor = await DatabaseHelper.instance.getStaffById(staff.doctorId!);
            }
            
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => StaffDashboard(
                    loggedInStaff: staff,
                    parentDoctor: parentDoctor,
                  ),
                ),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Saved credentials are invalid. Please login manually.')),
              );
            }
          }
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      }
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Biometric error: ${e.message ?? "Unknown error"}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 700;
    
    // Scale factors for responsive design
    final logoSize = isMobile ? 200.0 : 400.0;
    final cardWidth = isMobile ? screenSize.width * 0.92 : 450.0;
    final cardHeight = isMobile ? screenSize.height * 0.78 : 520.0;

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
                            'Staff Portal Login',
                            style: TextStyle(
                              fontSize: isMobile ? 20 : 24,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF001F3F),
                            ),
                          ),
                          SizedBox(height: isMobile ? 8 : 16),
                          Icon(
                            Icons.badge_outlined,
                            size: isMobile ? 36 : 48,
                            color: const Color(0xFF001F3F),
                          ),
                          SizedBox(height: isMobile ? 20 : 32),
                          _buildTextField(
                            controller: _usernameController,
                            hintText: 'Staff Username',
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
                          // Fingerprint Login Button
                          if (_canCheckBiometrics && _hasSavedCredentials) ...[
                            SizedBox(height: isMobile ? 8 : 12),
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.purple.shade400, Colors.purple.shade600],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ElevatedButton.icon(
                                onPressed: _isLoading ? null : _authenticateWithBiometrics,
                                icon: const Icon(Icons.fingerprint, color: Colors.white, size: 24),
                                label: const Text(
                                  'Login with Fingerprint',
                                  style: TextStyle(fontSize: 16, color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          SizedBox(height: isMobile ? 12 : 16),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(builder: (context) => const DoctorLoginPage()),
                              );
                            },
                            child: Text(
                              'Switch to Doctor Login',
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
            // Staff cannot reset their own password - show info dialog
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade700),
                    const SizedBox(width: 10),
                    const Text('Password Reset'),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Staff members cannot reset their password themselves.',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Please contact your administrator or doctor to reset your password.',
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.security, color: Colors.blue.shade700, size: 20),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'This is a security measure to protect your account.',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
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

            if (staff != null) {
              // Get parent doctor for this staff
              Staff? parentDoctor;
              if (staff.doctorId != null) {
                parentDoctor = await DatabaseHelper.instance.getStaffById(staff.doctorId!);
              }
              
              await _saveCredentials(_usernameController.text, _passwordController.text);
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => StaffDashboard(
                      loggedInStaff: staff,
                      parentDoctor: parentDoctor,
                    ),
                  ),
                );
              }
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid credentials')),
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

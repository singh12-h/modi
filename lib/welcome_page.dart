import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_signup_choice.dart';
import 'admin_branding_page.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _pulseController;
  late AnimationController _rotateController;

  // Branding
  String? _customAppName;
  String? _customLogoPath;
  int _tapCounter = 0;
  
  @override
  void initState() {
    super.initState();
    
    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _rotateController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat();

    _loadBranding();
  }

  Future<void> _loadBranding() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _customAppName = prefs.getString('custom_app_title');
        _customLogoPath = prefs.getString('custom_logo_path');
      });
    }
  }

  void _handleLogoTap() {
    setState(() {
      _tapCounter++;
    });

    if (_tapCounter >= 15) {
      _tapCounter = 0;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AdminBrandingPage()),
      ).then((_) => _loadBranding());
    }
  }

  @override
  void dispose() {
    _floatController.dispose();
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 400;
    
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0f0c29),
              Color(0xFF302b63),
              Color(0xFF24243e),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Animated background orbs
            ...List.generate(4, (index) {
              final positions = [
                const Offset(-0.2, -0.1),
                const Offset(0.8, 0.2),
                const Offset(-0.1, 0.7),
                const Offset(0.9, 0.8),
              ];
              final sizes = [250.0, 200.0, 180.0, 220.0];
              final colors = [
                const Color(0xFF667eea),
                const Color(0xFF764ba2),
                const Color(0xFFa8edea),
                const Color(0xFF667eea),
              ];
              
              return AnimatedBuilder(
                animation: _rotateController,
                builder: (context, child) {
                  final offset = math.sin(_rotateController.value * 2 * math.pi + index) * 20;
                  return Positioned(
                    left: positions[index].dx * screenSize.width + offset,
                    top: positions[index].dy * screenSize.height + offset,
                    child: Container(
                      width: sizes[index],
                      height: sizes[index],
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            colors[index].withOpacity(0.15),
                            colors[index].withOpacity(0.05),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
            
            // Main content
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 20 : 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: isSmallScreen ? 40 : 60),
                        
                        // Floating Logo with Secret Gesture
                        GestureDetector(
                          onTap: _handleLogoTap,
                          child: AnimatedBuilder(
                            animation: _floatController,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(0, math.sin(_floatController.value * math.pi) * 10),
                                child: AnimatedBuilder(
                                  animation: _pulseController,
                                  builder: (context, child) {
                                    final scale = 1.0 + (_pulseController.value * 0.03);
                                    return Transform.scale(
                                      scale: scale,
                                      child: Container(
                                        width: isSmallScreen ? 100 : 120,
                                        height: isSmallScreen ? 100 : 120,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: _customLogoPath == null ? const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Color(0xFF667eea),
                                            Color(0xFF764ba2),
                                          ],
                                        ) : null,
                                        image: _customLogoPath != null ? DecorationImage(
                                          image: FileImage(File(_customLogoPath!)),
                                          fit: BoxFit.cover,
                                        ) : null,
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF667eea).withOpacity(0.4),
                                            blurRadius: 25,
                                            spreadRadius: 5,
                                          ),
                                          BoxShadow(
                                            color: const Color(0xFF764ba2).withOpacity(0.3),
                                            blurRadius: 40,
                                            spreadRadius: 10,
                                          ),
                                        ],
                                      ),
                                      child: _customLogoPath == null ? const Icon(
                                        Icons.local_hospital_rounded,
                                        size: 50,
                                        color: Colors.white,
                                      ) : null,
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      
                      SizedBox(height: isSmallScreen ? 30 : 40),
                      
                      // Welcome Text
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFFa8edea), Color(0xFFfed6e3)],
                        ).createShader(bounds),
                        child: Text(
                          'Welcome to',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 16 : 20,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // MODI Title / Custom App Name
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFF667eea), Color(0xFFa8edea)],
                        ).createShader(bounds),
                        child: Text(
                          _customAppName?.isNotEmpty == true ? _customAppName! : 'MODI',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 52 : 64,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 6,
                            height: 1.1,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Subtitle
                      if (_customAppName?.isEmpty ?? true)
                        Text(
                          'Medical OPD Digital Interface',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : 14,
                            color: Colors.white.withOpacity(0.6),
                            letterSpacing: 1,
                          ),
                        ),
                      
                      SizedBox(height: isSmallScreen ? 40 : 60),
                      
                      // Feature Cards
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: [
                          _buildGlassCard(
                            icon: Icons.speed_rounded,
                            title: 'Fast',
                            subtitle: 'Workflow',
                            color: const Color(0xFF667eea),
                            isSmall: isSmallScreen,
                          ),
                          _buildGlassCard(
                            icon: Icons.security_rounded,
                            title: 'Secure',
                            subtitle: 'Data',
                            color: const Color(0xFF764ba2),
                            isSmall: isSmallScreen,
                          ),
                          _buildGlassCard(
                            icon: Icons.cloud_done_rounded,
                            title: 'Cloud',
                            subtitle: 'Backup',
                            color: const Color(0xFFa8edea),
                            isSmall: isSmallScreen,
                          ),
                        ],
                      ),
                      
                      SizedBox(height: isSmallScreen ? 50 : 70),
                      
                      // Get Started Button
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF667eea).withOpacity(
                                    0.3 + (_pulseController.value * 0.2),
                                  ),
                                  blurRadius: 20 + (_pulseController.value * 10),
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation, secondaryAnimation) =>
                                        const LoginSignupChoice(),
                                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                      return FadeTransition(opacity: animation, child: child);
                                    },
                                    transitionDuration: const Duration(milliseconds: 400),
                                  ),
                                ).then((_) => _loadBranding()); // Refresh branding when returning
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.zero,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: Ink(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isSmallScreen ? 40 : 50,
                                    vertical: isSmallScreen ? 16 : 18,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Get Started',
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 16 : 18,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      const Icon(Icons.arrow_forward_rounded, size: 22),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      
                      SizedBox(height: isSmallScreen ? 40 : 60),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isSmall,
  }) {
    return Container(
      width: isSmall ? 95 : 110,
      padding: EdgeInsets.symmetric(
        vertical: isSmall ? 16 : 20,
        horizontal: isSmall ? 12 : 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isSmall ? 45 : 50,
            height: isSmall ? 45 : 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, color.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: isSmall ? 24 : 26),
          ),
          SizedBox(height: isSmall ? 10 : 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isSmall ? 12 : 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isSmall ? 10 : 12,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'onboarding_screen.dart';
import 'welcome_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _glowController;
  late AnimationController _particleController;
  late AnimationController _waveController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _logoRotateAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<Offset> _textSlideAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    
    // Remove native splash immediately when Flutter is ready
    FlutterNativeSplash.remove();
    
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );
    
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    );
    
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.elasticOut,
      ),
    );
    
    _logoRotateAnimation = Tween<double>(begin: -0.5, end: 0.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.easeOutCubic,
      ),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    
    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.easeIn,
      ),
    );
    
    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 1.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.easeOutCubic,
      ),
    );
    
    _glowAnimation = Tween<double>(begin: 0.7, end: 1.3).animate(
      CurvedAnimation(
        parent: _glowController,
        curve: Curves.easeInOut,
      ),
    );
    
    _startAnimations();
  }

  Future<void> _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    
    _logoController.forward();
    _particleController.repeat();
    _waveController.repeat();
    
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    _textController.forward();
    
    _glowController.repeat(reverse: true);
    
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(milliseconds: 3800));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            hasSeenOnboarding ? const WelcomePage() : const OnboardingScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOut),
              ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _glowController.dispose();
    _particleController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1a1a2e),
              Color(0xFF16213e),
              Color(0xFF0f3460),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Animated wave background
            AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                return CustomPaint(
                  painter: WavePainter(_waveController.value),
                  child: Container(),
                );
              },
            ),
            
            // Floating particles
            AnimatedBuilder(
              animation: _particleController,
              builder: (context, child) {
                return CustomPaint(
                  painter: EnhancedParticlesPainter(_particleController.value),
                  child: Container(),
                );
              },
            ),
            
            // Main content - Centered
            Center(
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  // Logo with premium effects
                  AnimatedBuilder(
                    animation: _logoController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _fadeAnimation.value,
                        child: Transform.scale(
                          scale: _scaleAnimation.value,
                          child: Transform.rotate(
                            angle: _logoRotateAnimation.value * math.pi,
                            child: AnimatedBuilder(
                              animation: _glowController,
                              builder: (context, child) {
                                return Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Outer glow ring
                                    Container(
                                      width: 230 * _glowAnimation.value,
                                      height: 230 * _glowAnimation.value,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: RadialGradient(
                                          colors: [
                                            const Color(0xFF00d4ff).withOpacity(0.0),
                                            const Color(0xFF00d4ff).withOpacity(0.15 * _glowAnimation.value),
                                            const Color(0xFF0096ff).withOpacity(0.05 * _glowAnimation.value),
                                          ],
                                        ),
                                      ),
                                    ),
                                    
                                    // Middle glow
                                    Container(
                                      width: 210,
                                      height: 210,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF00d4ff).withOpacity(0.5 * _glowAnimation.value),
                                            blurRadius: 60 * _glowAnimation.value,
                                            spreadRadius: 20 * _glowAnimation.value,
                                          ),
                                          BoxShadow(
                                            color: const Color(0xFF0096ff).withOpacity(0.3 * _glowAnimation.value),
                                            blurRadius: 80 * _glowAnimation.value,
                                            spreadRadius: 30 * _glowAnimation.value,
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    // Logo container with gradient border
                                    Container(
                                      width: 200,
                                      height: 200,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Color(0xFF00d4ff),
                                            Color(0xFF0096ff),
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.3),
                                            blurRadius: 30,
                                            offset: const Offset(0, 15),
                                          ),
                                        ],
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(5),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                const Color(0xFF1a1a2e).withOpacity(0.95),
                                                const Color(0xFF16213e).withOpacity(0.95),
                                              ],
                                            ),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(20),
                                            child: ClipOval(
                                              child: Image.asset(
                                                'assets/icon/app_icon.png',
                                                fit: BoxFit.contain,
                                                errorBuilder: (context, error, stackTrace) => Container(
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        const Color(0xFF00d4ff).withOpacity(0.3),
                                                        const Color(0xFF0096ff).withOpacity(0.3),
                                                      ],
                                                    ),
                                                  ),
                                                  child: const Icon(
                                                    Icons.medical_services_rounded,
                                                    size: 90,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 60),
                  
                  // App name with premium styling
                  SlideTransition(
                    position: _textSlideAnimation,
                    child: FadeTransition(
                      opacity: _textFadeAnimation,
                      child: Column(
                        children: [
                          // Main title with gradient
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [
                                Color(0xFF00d4ff),
                                Color(0xFFffffff),
                                Color(0xFF00d4ff),
                              ],
                              stops: [0.0, 0.5, 1.0],
                            ).createShader(bounds),
                            child: const Text(
                              'Modi Dental Clinic',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 38,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 1.5,
                                height: 1.2,
                                shadows: [
                                  Shadow(
                                    color: Colors.black45,
                                    blurRadius: 20,
                                    offset: Offset(0, 5),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Tagline with glassmorphic container
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(25),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.15),
                                  Colors.white.withOpacity(0.08),
                                ],
                              ),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.25),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFF00d4ff),
                                        Color(0xFF0096ff),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(0xFF00d4ff),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Your Smile, Our Passion',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    letterSpacing: 1.2,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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

// Enhanced particles painter
class EnhancedParticlesPainter extends CustomPainter {
  final double animationValue;

  EnhancedParticlesPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 30; i++) {
      final progress = (animationValue + i * 0.03) % 1.0;
      final dx = (i * 60.0 + progress * 300) % size.width;
      final dy = (i * 90.0 + progress * 200) % size.height;
      final opacity = (0.15 + (i % 4) * 0.1) * (1 - progress * 0.7);
      final sizeParticle = 2.0 + (i % 4);
      
      paint.color = const Color(0xFF00d4ff).withOpacity(opacity);
      canvas.drawCircle(Offset(dx, dy), sizeParticle, paint);
    }
  }

  @override
  bool shouldRepaint(EnhancedParticlesPainter oldDelegate) => true;
}

// Wave painter for background
class WavePainter extends CustomPainter {
  final double animationValue;

  WavePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    final path = Path();
    
    // First wave
    paint.color = const Color(0xFF00d4ff).withOpacity(0.03);
    path.moveTo(0, size.height * 0.7);
    for (double i = 0; i < size.width; i++) {
      path.lineTo(
        i,
        size.height * 0.7 + 
        math.sin((i / size.width * 2 * math.pi) + (animationValue * 2 * math.pi)) * 30,
      );
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);

    // Second wave
    final path2 = Path();
    paint.color = const Color(0xFF0096ff).withOpacity(0.05);
    path2.moveTo(0, size.height * 0.8);
    for (double i = 0; i < size.width; i++) {
      path2.lineTo(
        i,
        size.height * 0.8 + 
        math.sin((i / size.width * 2 * math.pi) - (animationValue * 2 * math.pi)) * 25,
      );
    }
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) => true;
}

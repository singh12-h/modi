import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'onboarding_screen.dart';
import 'welcome_page.dart';
import 'online_license_service.dart';
import 'license_activation_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _textOpacity;

  @override
  void initState() {
    super.initState();
    
    // Remove native splash immediately
    FlutterNativeSplash.remove();
    
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    
    // Logo entrance animation
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    // Continuous pulse glow
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Shimmer effect
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.elasticOut,
      ),
    );
    
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
    
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _shimmerController,
        curve: Curves.easeInOut,
      ),
    );
    
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );
    
    _startAnimations();
  }

  void _startAnimations() {
    _logoController.forward();
    _pulseController.repeat(reverse: true);
    _shimmerController.repeat();
    
    // Start background loading
    _loadAndNavigate();
  }

  Future<void> _loadAndNavigate() async {
    // Minimum splash time for branding
    final minSplashTime = Future.delayed(const Duration(milliseconds: 2500));
    
    // Load data in parallel
    final results = await Future.wait([
      minSplashTime,
      _loadData(),
    ]);
    
    if (!mounted) return;
    
    final loadResult = results[1] as Map<String, dynamic>;
    _navigate(loadResult);
  }

  Future<Map<String, dynamic>> _loadData() async {
    try {
      final futures = await Future.wait([
        Connectivity().checkConnectivity(),
        OnlineLicenseService.initializeDemoIfNeeded(),
        OnlineLicenseService.initialize().then((_) => OnlineLicenseService.checkLicenseStatus()),
        SharedPreferences.getInstance(),
      ]);
      
      return {
        'connectivity': futures[0] as List<ConnectivityResult>,
        'license': futures[2] as LicenseStatus,
        'prefs': futures[3] as SharedPreferences,
      };
    } catch (e) {
      return {
        'connectivity': <ConnectivityResult>[],
        'license': LicenseStatus.notFound,
        'prefs': await SharedPreferences.getInstance(),
      };
    }
  }

  void _navigate(Map<String, dynamic> result) {
    final connectivity = result['connectivity'] as List<ConnectivityResult>;
    final hasInternet = connectivity.contains(ConnectivityResult.mobile) ||
                        connectivity.contains(ConnectivityResult.wifi) ||
                        connectivity.contains(ConnectivityResult.ethernet);

    if (!hasInternet) {
      _showNoInternetDialog();
      return;
    }
    
    final license = result['license'] as LicenseStatus;
    
    if (license == LicenseStatus.expired || license == LicenseStatus.notFound) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LicenseActivationPage()),
      );
      return;
    }

    final prefs = result['prefs'] as SharedPreferences;
    final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            hasSeenOnboarding ? const WelcomePage() : const OnboardingScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _showNoInternetDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.redAccent, size: 28),
            SizedBox(width: 12),
            Text('No Internet', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'Please check your internet connection and try again.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _loadAndNavigate();
            },
            child: const Text('RETRY', style: TextStyle(color: Color(0xFF00d4ff))),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
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
              Color(0xFF0f0c29),
              Color(0xFF302b63),
              Color(0xFF24243e),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Animated background particles
            ...List.generate(20, (index) => _buildParticle(index)),
            
            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Glowing Logo
                  AnimatedBuilder(
                    animation: Listenable.merge([_logoController, _pulseController]),
                    builder: (context, child) {
                      return Opacity(
                        opacity: _logoOpacity.value,
                        child: Transform.scale(
                          scale: _logoScale.value * _pulseAnimation.value,
                          child: Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00d4ff).withOpacity(0.5 * _pulseAnimation.value),
                                  blurRadius: 40 * _pulseAnimation.value,
                                  spreadRadius: 10 * _pulseAnimation.value,
                                ),
                                BoxShadow(
                                  color: const Color(0xFF667eea).withOpacity(0.3 * _pulseAnimation.value),
                                  blurRadius: 60 * _pulseAnimation.value,
                                  spreadRadius: 20 * _pulseAnimation.value,
                                ),
                              ],
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF00d4ff),
                                    Color(0xFF667eea),
                                  ],
                                ),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              padding: const EdgeInsets.all(4),
                              child: Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF1a1a2e),
                                ),
                                padding: const EdgeInsets.all(20),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/icon/app_icon.png',
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) => const Icon(
                                      Icons.medical_services_rounded,
                                      size: 80,
                                      color: Color(0xFF00d4ff),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 50),
                  
                  // App Name with Shimmer
                  AnimatedBuilder(
                    animation: Listenable.merge([_logoController, _shimmerController]),
                    builder: (context, child) {
                      return Opacity(
                        opacity: _textOpacity.value,
                        child: ShaderMask(
                          shaderCallback: (bounds) {
                            return LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: const [
                                Colors.white,
                                Color(0xFF00d4ff),
                                Colors.white,
                              ],
                              stops: [
                                _shimmerAnimation.value - 0.3,
                                _shimmerAnimation.value,
                                _shimmerAnimation.value + 0.3,
                              ].map((s) => s.clamp(0.0, 1.0)).toList(),
                            ).createShader(bounds);
                          },
                          child: const Text(
                            'MODI',
                            style: TextStyle(
                              fontSize: 52,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 12,
                              shadows: [
                                Shadow(
                                  color: Color(0xFF00d4ff),
                                  blurRadius: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Tagline
                  AnimatedBuilder(
                    animation: _logoController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _textOpacity.value,
                        child: const Text(
                          'Medical OPD Digital Interface',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 80),
                  
                  // Loading indicator
                  AnimatedBuilder(
                    animation: _logoController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _textOpacity.value,
                        child: SizedBox(
                          width: 30,
                          height: 30,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              const Color(0xFF00d4ff).withOpacity(0.7),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticle(int index) {
    final random = math.Random(index);
    final size = 2.0 + random.nextDouble() * 4;
    final left = random.nextDouble() * MediaQuery.of(context).size.width;
    final top = random.nextDouble() * MediaQuery.of(context).size.height;
    final duration = 2000 + random.nextInt(3000);
    
    return Positioned(
      left: left,
      top: top,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: duration),
        builder: (context, value, child) {
          return Opacity(
            opacity: (math.sin(value * math.pi * 2) * 0.5 + 0.5) * 0.6,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00d4ff),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00d4ff).withOpacity(0.5),
                    blurRadius: size * 2,
                  ),
                ],
              ),
            ),
          );
        },
        onEnd: () {
          if (mounted) setState(() {});
        },
      ),
    );
  }
}

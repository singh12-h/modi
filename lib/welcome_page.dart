import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'login_signup_choice.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> with TickerProviderStateMixin {
  late AnimationController _floatingController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    
    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _floatingController.dispose();
    _pulseController.dispose();
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
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0a0a1a), // Dark navy top
              Color(0xFF0d1b2a), // Dark blue
              Color(0xFF1b263b), // Slightly lighter blue
            ],
          ),
        ),
        child: Stack(
          children: [
            // Animated Stars/Particles
            ...List.generate(40, (index) {
              return _AnimatedStar(
                index: index,
                controller: _floatingController,
              );
            }),

            // Main Content
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 60),
                      
                      // Animated Logo - Purple/Pink gradient circle with icon
                      AnimatedBuilder(
                        animation: _floatingController,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, math.sin(_floatingController.value * 2 * math.pi) * 8),
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF9D4EDD), // Purple
                                    Color(0xFFE040FB), // Pink
                                    Color(0xFF7B2CBF), // Deep purple
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF9D4EDD).withOpacity(0.6),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  ),
                                  BoxShadow(
                                    color: const Color(0xFFE040FB).withOpacity(0.4),
                                    blurRadius: 50,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.business, // Building/Hospital icon
                                size: 50,
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // "Welcome to" text with gradient
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [
                            Color(0xFF9D4EDD),
                            Color(0xFFE040FB),
                            Color(0xFF00D9FF),
                          ],
                        ).createShader(bounds),
                        child: const Text(
                          'Welcome to',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // "MODI" - Large glowing text
                      Text(
                        'MODI',
                        style: TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 6,
                          shadows: [
                            Shadow(
                              color: const Color(0xFF9D4EDD).withOpacity(0.8),
                              offset: const Offset(0, 0),
                              blurRadius: 20,
                            ),
                            Shadow(
                              color: const Color(0xFFE040FB).withOpacity(0.5),
                              offset: const Offset(0, 0),
                              blurRadius: 40,
                            ),
                            const Shadow(
                              color: Colors.white24,
                              offset: Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Subtitle
                      Text(
                        'Medical OPD Digital Interface',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.6),
                          letterSpacing: 1,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      
                      const SizedBox(height: 50),
                      
                      // Feature Cards Row - Exactly like image
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildFeatureCard(
                            icon: Icons.bolt,
                            title: 'Fast &',
                            subtitle: 'Efficient',
                            color: const Color(0xFF00D9FF),
                          ),
                          const SizedBox(width: 12),
                          _buildFeatureCard(
                            icon: Icons.lock,
                            title: 'Secure &',
                            subtitle: 'Private',
                            color: const Color(0xFF9D4EDD),
                          ),
                          const SizedBox(width: 12),
                          _buildFeatureCard(
                            icon: Icons.cloud,
                            title: 'Cloud',
                            subtitle: 'Synced',
                            color: const Color(0xFF00D9FF),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 60),
                      
                      // Get Started Button - Purple gradient with arrow
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF9D4EDD).withOpacity(
                                    0.4 + (_pulseController.value * 0.2),
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
                                      return FadeTransition(
                                        opacity: animation,
                                        child: child,
                                      );
                                    },
                                    transitionDuration: const Duration(milliseconds: 400),
                                  ),
                                );
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
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      Color(0xFF7B2CBF),
                                      Color(0xFF9D4EDD),
                                      Color(0xFFE040FB),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Get Started',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(Icons.arrow_forward, size: 20),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 60),
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

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      width: 95,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon with gradient background
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color,
                  color.withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedStar extends StatelessWidget {
  final int index;
  final AnimationController controller;

  const _AnimatedStar({
    required this.index,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final random = math.Random(index);
    final size = 1.0 + random.nextDouble() * 2;
    final left = random.nextDouble() * MediaQuery.of(context).size.width;
    final top = random.nextDouble() * MediaQuery.of(context).size.height;
    
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final opacity = 0.2 + (math.sin((controller.value + random.nextDouble()) * 2 * math.pi) * 0.3);
        return Positioned(
          left: left,
          top: top,
          child: Opacity(
            opacity: opacity.clamp(0.1, 0.6),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.5),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

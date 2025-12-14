import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui';
import 'doctor_login_page.dart';
import 'staff_login_page.dart';

class LoginSignupChoice extends StatefulWidget {
  const LoginSignupChoice({super.key});

  @override
  State<LoginSignupChoice> createState() => _LoginSignupChoiceState();
}

class _LoginSignupChoiceState extends State<LoginSignupChoice> with TickerProviderStateMixin {
  late AnimationController _bgController;
  late AnimationController _cardController;
  late Animation<double> _cardAnimation;
  int? _hoveredCard;
  
  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();
    
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _cardAnimation = CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeOutBack,
    );
    
    Future.delayed(const Duration(milliseconds: 300), () {
      _cardController.forward();
    });
  }

  @override
  void dispose() {
    _bgController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F0C29),
              Color(0xFF302B63),
              Color(0xFF24243E),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Animated gradient orbs
            ...List.generate(6, (index) => _buildGlowingOrb(index)),
            
            // Grid pattern overlay
            Positioned.fill(
              child: CustomPaint(
                painter: GridPatternPainter(),
              ),
            ),
            
            // Floating particles
            ...List.generate(20, (index) => _AnimatedParticle(
              index: index,
              controller: _bgController,
            )),

            // Glass morphism overlay
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5),
                child: Container(color: Colors.transparent),
              ),
            ),

            // Back Button with glow
            Positioned(
              top: 50,
              left: 20,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF667eea).withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: -5,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 22),
                  ),
                ),
              ),
            ),

            // Main Content
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 20 : 40,
                    vertical: 24,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        
                        // Logo/Icon
                        AnimatedBuilder(
                          animation: _bgController,
                          builder: (context, child) {
                            return Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    const Color(0xFF667eea),
                                    const Color(0xFF764ba2),
                                    Color.lerp(
                                      const Color(0xFF667eea),
                                      const Color(0xFF00f2fe),
                                      (math.sin(_bgController.value * math.pi * 2) + 1) / 2,
                                    )!,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF667eea).withOpacity(0.5),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.local_hospital_rounded,
                                color: Colors.white,
                                size: 40,
                              ),
                            );
                          },
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Title with shimmer effect
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Colors.white, Color(0xFFE0E0FF), Colors.white],
                          ).createShader(bounds),
                          child: Text(
                            'Choose Your Role',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 32 : 42,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -1,
                              height: 1.1,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        Text(
                          'Select how you want to access MODI',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                            color: Colors.white.withOpacity(0.7),
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 50),
                        
                        // Doctor Card
                        ScaleTransition(
                          scale: _cardAnimation,
                          child: _buildPremiumRoleCard(
                            index: 0,
                            icon: Icons.medical_services_rounded,
                            title: 'Doctor',
                            subtitle: 'Access patient records & manage consultations',
                            gradientColors: const [Color(0xFF667eea), Color(0xFF764ba2)],
                            glowColor: const Color(0xFF667eea),
                            onTap: () => _navigateWithAnimation(context, const DoctorLoginPage()),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Staff Card
                        ScaleTransition(
                          scale: _cardAnimation,
                          child: _buildPremiumRoleCard(
                            index: 1,
                            icon: Icons.groups_rounded,
                            title: 'Staff',
                            subtitle: 'Manage appointments & patient registration',
                            gradientColors: const [Color(0xFF00B4DB), Color(0xFF0083B0)],
                            glowColor: const Color(0xFF00B4DB),
                            onTap: () => _navigateWithAnimation(context, const StaffLoginPage()),
                          ),
                        ),
                        
                        const SizedBox(height: 50),
                        
                        // Bottom decoration
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildDot(const Color(0xFF667eea)),
                            const SizedBox(width: 8),
                            _buildDot(const Color(0xFF764ba2)),
                            const SizedBox(width: 8),
                            _buildDot(const Color(0xFF00B4DB)),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        Text(
                          'MODI Healthcare System',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.4),
                            letterSpacing: 2,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                        
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(Color color) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildGlowingOrb(int index) {
    final random = math.Random(index * 42);
    final size = 150.0 + random.nextDouble() * 200;
    
    return AnimatedBuilder(
      animation: _bgController,
      builder: (context, child) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        
        final baseX = random.nextDouble() * screenWidth;
        final baseY = random.nextDouble() * screenHeight;
        final offsetX = math.sin((_bgController.value + index * 0.2) * math.pi * 2) * 50;
        final offsetY = math.cos((_bgController.value + index * 0.3) * math.pi * 2) * 30;
        
        return Positioned(
          left: baseX + offsetX - size / 2,
          top: baseY + offsetY - size / 2,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  [
                    const Color(0xFF667eea).withOpacity(0.3),
                    const Color(0xFF764ba2).withOpacity(0.2),
                    const Color(0xFF00B4DB).withOpacity(0.25),
                  ][index % 3],
                  Colors.transparent,
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPremiumRoleCard({
    required int index,
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradientColors,
    required Color glowColor,
    required VoidCallback onTap,
  }) {
    final isHovered = _hoveredCard == index;
    
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hoveredCard = index),
      onExit: (_) => setState(() => _hoveredCard = null),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          transform: Matrix4.identity()
            ..translate(0.0, isHovered ? -5.0 : 0.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: glowColor.withOpacity(isHovered ? 0.5 : 0.3),
                blurRadius: isHovered ? 40 : 25,
                spreadRadius: isHovered ? 5 : 0,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      gradientColors[0].withOpacity(0.8),
                      gradientColors[1].withOpacity(0.9),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(isHovered ? 0.4 : 0.2),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    // Icon container with glass effect
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Icon(
                        icon,
                        size: 35,
                        color: Colors.white,
                      ),
                    ),
                    
                    const SizedBox(width: 20),
                    
                    // Text content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.85),
                              height: 1.4,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Arrow with animation
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.only(left: isHovered ? 8 : 0),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(isHovered ? 0.3 : 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 22,
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
    );
  }

  void _navigateWithAnimation(BuildContext context, Widget page) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.05, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }
}

// Grid pattern painter
class GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 0.5;
    
    const gridSize = 40.0;
    
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Animated floating particle
class _AnimatedParticle extends StatelessWidget {
  final int index;
  final AnimationController controller;

  const _AnimatedParticle({
    required this.index,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final random = math.Random(index + 100);
    final size = 3.0 + random.nextDouble() * 5;
    final left = random.nextDouble() * MediaQuery.of(context).size.width;
    final startTop = random.nextDouble() * MediaQuery.of(context).size.height;
    final speed = 0.5 + random.nextDouble() * 0.5;
    
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final top = (startTop - (controller.value * speed * MediaQuery.of(context).size.height)) % 
                    MediaQuery.of(context).size.height;
        final opacity = 0.2 + (math.sin(controller.value * math.pi * 2 + index) + 1) * 0.2;
        
        return Positioned(
          left: left,
          top: top,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(opacity),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(opacity * 0.5),
                  blurRadius: size * 2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

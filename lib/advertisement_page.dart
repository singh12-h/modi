import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Premium Advertisement Page for MODI Medical App
class AdvertisementPage extends StatefulWidget {
  final VoidCallback? onClose;
  final VoidCallback? onGetStarted;
  
  const AdvertisementPage({
    super.key,
    this.onClose,
    this.onGetStarted,
  });

  @override
  State<AdvertisementPage> createState() => _AdvertisementPageState();
}

class _AdvertisementPageState extends State<AdvertisementPage>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _floatController;
  late AnimationController _shimmerController;
  late PageController _featureController;
  int _currentFeature = 0;

  final List<FeatureItem> _features = [
    FeatureItem(
      icon: Icons.medical_services_rounded,
      title: 'Smart Patient Management',
      description: 'Manage all your patients with ease. Quick registration, detailed history, and instant access.',
      color: const Color(0xFF6366F1),
    ),
    FeatureItem(
      icon: Icons.calendar_month_rounded,
      title: 'Appointment Booking',
      description: 'Seamless appointment scheduling with SMS & WhatsApp reminders for patients.',
      color: const Color(0xFF10B981),
    ),
    FeatureItem(
      icon: Icons.description_rounded,
      title: 'Digital Prescriptions',
      description: 'Create professional prescriptions with medicine database and voice input support.',
      color: const Color(0xFFF59E0B),
    ),
    FeatureItem(
      icon: Icons.analytics_rounded,
      title: 'Reports & Analytics',
      description: 'Track your clinic performance with beautiful charts and detailed reports.',
      color: const Color(0xFFEC4899),
    ),
    FeatureItem(
      icon: Icons.payment_rounded,
      title: 'Payment Tracking',
      description: 'Manage payments, installments, and generate invoices effortlessly.',
      color: const Color(0xFF8B5CF6),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
    
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    
    _featureController = PageController(viewportFraction: 0.85);
    
    // Auto-scroll features
    Future.delayed(const Duration(seconds: 3), _autoScrollFeatures);
  }

  void _autoScrollFeatures() {
    if (!mounted) return;
    final nextPage = (_currentFeature + 1) % _features.length;
    _featureController.animateToPage(
      nextPage,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
    Future.delayed(const Duration(seconds: 4), _autoScrollFeatures);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _floatController.dispose();
    _shimmerController.dispose();
    _featureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 400;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF1E293B),
              Color(0xFF0F172A),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Animated background elements
            ...List.generate(15, (i) => _buildFloatingOrb(i, size)),
            
            // Grid pattern overlay
            CustomPaint(
              painter: GridPatternPainter(),
              size: size,
            ),
            
            // Main content
            SafeArea(
              child: Column(
                children: [
                  // Header with close button
                  _buildHeader(isSmall),
                  
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          SizedBox(height: isSmall ? 20 : 40),
                          
                          // Hero Section
                          _buildHeroSection(isSmall),
                          
                          SizedBox(height: isSmall ? 30 : 50),
                          
                          // Feature Cards Carousel
                          _buildFeatureCarousel(isSmall),
                          
                          SizedBox(height: isSmall ? 25 : 40),
                          
                          // Stats Section
                          _buildStatsSection(isSmall),
                          
                          SizedBox(height: isSmall ? 25 : 40),
                          
                          // Testimonial Section
                          _buildTestimonialSection(isSmall),
                          
                          SizedBox(height: isSmall ? 30 : 50),
                          
                          // CTA Section
                          _buildCTASection(isSmall),
                          
                          SizedBox(height: isSmall ? 30 : 50),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingOrb(int index, Size size) {
    final random = math.Random(index);
    final x = random.nextDouble() * size.width;
    final y = random.nextDouble() * size.height;
    final orbSize = 50 + random.nextDouble() * 150;
    final colors = [
      const Color(0xFF6366F1),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
      const Color(0xFF10B981),
      const Color(0xFF06B6D4),
    ];
    
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        final offset = math.sin(_floatController.value * math.pi * 2 + index) * 20;
        return Positioned(
          left: x + offset,
          top: y + offset * 0.5,
          child: Container(
            width: orbSize,
            height: orbSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  colors[index % colors.length].withOpacity(0.15),
                  colors[index % colors.length].withOpacity(0.0),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isSmall) {
    return Padding(
      padding: EdgeInsets.all(isSmall ? 12 : 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(Icons.local_hospital_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                ).createShader(bounds),
                child: Text(
                  'MODI',
                  style: TextStyle(
                    fontSize: isSmall ? 22 : 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ],
          ),
          
          // Close button
          if (widget.onClose != null)
            GestureDetector(
              onTap: widget.onClose,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: const Icon(Icons.close_rounded, color: Colors.white70, size: 22),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(bool isSmall) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isSmall ? 20 : 40),
      child: Column(
        children: [
          // Animated badge
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1 + _pulseController.value * 0.05,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF10B981).withOpacity(0.2),
                        const Color(0xFF10B981).withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '🎉 Special Launch Offer',
                        style: TextStyle(
                          color: Color(0xFF10B981),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          
          SizedBox(height: isSmall ? 20 : 30),
          
          // Main headline
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Colors.white, Color(0xFFE2E8F0)],
            ).createShader(bounds),
            child: Text(
              'Transform Your\nClinic Management',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isSmall ? 28 : 42,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.2,
                letterSpacing: -0.5,
              ),
            ),
          ),
          
          SizedBox(height: isSmall ? 15 : 20),
          
          // Subtitle
          Text(
            'The complete digital solution for modern doctors.\nManage patients, appointments & prescriptions seamlessly.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isSmall ? 14 : 16,
              color: const Color(0xFF94A3B8),
              height: 1.6,
            ),
          ),
          
          SizedBox(height: isSmall ? 25 : 35),
          
          // CTA Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPrimaryButton('Get Started Free', Icons.rocket_launch_rounded, isSmall),
              const SizedBox(width: 12),
              _buildSecondaryButton('Watch Demo', Icons.play_circle_outline_rounded, isSmall),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton(String text, IconData icon, bool isSmall) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onGetStarted,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmall ? 20 : 28,
                  vertical: isSmall ? 14 : 18,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: Colors.white, size: isSmall ? 18 : 22),
                    SizedBox(width: isSmall ? 8 : 10),
                    Text(
                      text,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: isSmall ? 13 : 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSecondaryButton(String text, IconData icon, bool isSmall) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        color: Colors.white.withOpacity(0.05),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isSmall ? 20 : 28,
              vertical: isSmall ? 14 : 18,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white70, size: isSmall ? 18 : 22),
                SizedBox(width: isSmall ? 8 : 10),
                Text(
                  text,
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                    fontSize: isSmall ? 13 : 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCarousel(bool isSmall) {
    return Column(
      children: [
        // Section title
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isSmall ? 20 : 40),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Powerful Features',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        
        SizedBox(height: isSmall ? 20 : 30),
        
        // Feature cards carousel
        SizedBox(
          height: isSmall ? 200 : 240,
          child: PageView.builder(
            controller: _featureController,
            onPageChanged: (index) => setState(() => _currentFeature = index),
            itemCount: _features.length,
            itemBuilder: (context, index) {
              final feature = _features[index];
              return AnimatedBuilder(
                animation: _featureController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_featureController.position.haveDimensions) {
                    value = _featureController.page! - index;
                    value = (1 - (value.abs() * 0.2)).clamp(0.8, 1.0);
                  }
                  return Transform.scale(
                    scale: value,
                    child: _buildFeatureCard(feature, isSmall),
                  );
                },
              );
            },
          ),
        ),
        
        SizedBox(height: isSmall ? 15 : 20),
        
        // Page indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_features.length, (index) {
            final isActive = index == _currentFeature;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isActive ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: isActive ? _features[index].color : Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildFeatureCard(FeatureItem feature, bool isSmall) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            feature.color.withOpacity(0.15),
            feature.color.withOpacity(0.05),
          ],
        ),
        border: Border.all(color: feature.color.withOpacity(0.2)),
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmall ? 20 : 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [feature.color, feature.color.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: feature.color.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Icon(feature.icon, color: Colors.white, size: isSmall ? 26 : 32),
            ),
            
            SizedBox(height: isSmall ? 16 : 24),
            
            // Title
            Text(
              feature.title,
              style: TextStyle(
                color: Colors.white,
                fontSize: isSmall ? 18 : 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 10),
            
            // Description
            Text(
              feature.description,
              style: TextStyle(
                color: const Color(0xFF94A3B8),
                fontSize: isSmall ? 13 : 15,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(bool isSmall) {
    final stats = [
      {'value': '10K+', 'label': 'Doctors', 'icon': Icons.person_rounded},
      {'value': '1M+', 'label': 'Patients', 'icon': Icons.groups_rounded},
      {'value': '99.9%', 'label': 'Uptime', 'icon': Icons.speed_rounded},
      {'value': '4.9★', 'label': 'Rating', 'icon': Icons.star_rounded},
    ];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: isSmall ? 20 : 40),
      padding: EdgeInsets.all(isSmall ? 20 : 30),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.03),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: stats.map((stat) {
          return Expanded(
            child: Column(
              children: [
                Icon(
                  stat['icon'] as IconData,
                  color: const Color(0xFF6366F1),
                  size: isSmall ? 24 : 30,
                ),
                SizedBox(height: isSmall ? 8 : 12),
                Text(
                  stat['value'] as String,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmall ? 20 : 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stat['label'] as String,
                  style: TextStyle(
                    color: const Color(0xFF64748B),
                    fontSize: isSmall ? 11 : 13,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTestimonialSection(bool isSmall) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isSmall ? 20 : 40),
      padding: EdgeInsets.all(isSmall ? 20 : 30),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF10B981).withOpacity(0.1),
            const Color(0xFF10B981).withOpacity(0.03),
          ],
        ),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
      ),
      child: Column(
        children: [
          // Quote icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.format_quote_rounded, color: Color(0xFF10B981), size: 28),
          ),
          
          SizedBox(height: isSmall ? 16 : 24),
          
          Text(
            '"MODI has completely transformed how I manage my clinic. The patient management and prescription features save me hours every day!"',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: isSmall ? 15 : 18,
              fontStyle: FontStyle.italic,
              height: 1.6,
            ),
          ),
          
          SizedBox(height: isSmall ? 16 : 24),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.3),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('DR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dr. Rajesh Kumar',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  Text(
                    'Senior Physician, Mumbai',
                    style: TextStyle(color: const Color(0xFF64748B), fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCTASection(bool isSmall) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isSmall ? 20 : 40),
      padding: EdgeInsets.all(isSmall ? 25 : 40),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFEC4899)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.4),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        children: [
          // Offer badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '🔥 LIMITED TIME OFFER',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
            ),
          ),
          
          SizedBox(height: isSmall ? 16 : 24),
          
          Text(
            'Start Your Free Trial Today!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: isSmall ? 24 : 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          SizedBox(height: isSmall ? 10 : 14),
          
          Text(
            '30 days free • No credit card required • Cancel anytime',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: isSmall ? 13 : 15,
            ),
          ),
          
          SizedBox(height: isSmall ? 20 : 30),
          
          // CTA Button
          GestureDetector(
            onTap: widget.onGetStarted,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: isSmall ? 16 : 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.rocket_launch_rounded, color: Color(0xFF6366F1), size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Get Started Now',
                    style: TextStyle(
                      color: const Color(0xFF6366F1),
                      fontWeight: FontWeight.bold,
                      fontSize: isSmall ? 16 : 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, color: Color(0xFF6366F1), size: 20),
                ],
              ),
            ),
          ),
          
          SizedBox(height: isSmall ? 16 : 20),
          
          // Trust badges
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTrustBadge(Icons.security_rounded, 'Secure'),
              const SizedBox(width: 20),
              _buildTrustBadge(Icons.support_agent_rounded, '24/7 Support'),
              const SizedBox(width: 20),
              _buildTrustBadge(Icons.verified_rounded, 'HIPAA Ready'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrustBadge(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.8), size: 16),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Feature item model
class FeatureItem {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}

/// Grid pattern painter for background
class GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 1;

    const spacing = 40.0;
    
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;

/// Living Background - Animated background with floating orbs
/// Kept for backward compatibility but PremiumBackground is now preferred
class LivingBackground extends StatefulWidget {
  final Widget child;
  
  const LivingBackground({super.key, required this.child});

  @override
  State<LivingBackground> createState() => _LivingBackgroundState();
}

class _LivingBackgroundState extends State<LivingBackground> with TickerProviderStateMixin {
  late AnimationController _orb1Controller;
  late AnimationController _orb2Controller;
  late AnimationController _orb3Controller;

  @override
  void initState() {
    super.initState();
    _orb1Controller = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat(reverse: true);
    _orb2Controller = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat(reverse: true);
    _orb3Controller = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _orb1Controller.dispose();
    _orb2Controller.dispose();
    _orb3Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    return Container(
      width: screenSize.width,
      height: screenSize.height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0a0e21),
            Color(0xFF1a1a3e),
            Color(0xFF0d1b2a),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Orb 1
          AnimatedBuilder(
            animation: _orb1Controller,
            builder: (context, child) {
              final offset = math.sin(_orb1Controller.value * math.pi * 2) * 30;
              return Positioned(
                top: -50 + offset,
                left: -80 + offset,
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00d4ff).withOpacity(0.4),
                        blurRadius: 150,
                        spreadRadius: 80,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          // Orb 2
          AnimatedBuilder(
            animation: _orb2Controller,
            builder: (context, child) {
              final offset = math.cos(_orb2Controller.value * math.pi * 2) * 40;
              return Positioned(
                bottom: -100 + offset,
                right: -80 + offset,
                child: Container(
                  width: 450,
                  height: 450,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFbd00ff).withOpacity(0.35),
                        blurRadius: 180,
                        spreadRadius: 100,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          // Orb 3
          AnimatedBuilder(
            animation: _orb3Controller,
            builder: (context, child) {
              final offsetX = math.sin(_orb3Controller.value * math.pi * 2) * 50;
              final offsetY = math.cos(_orb3Controller.value * math.pi * 2) * 30;
              return Positioned(
                top: screenSize.height * 0.4 + offsetY,
                left: screenSize.width * 0.3 + offsetX,
                child: Container(
                  width: 350,
                  height: 350,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366f1).withOpacity(0.3),
                        blurRadius: 120,
                        spreadRadius: 60,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          // Blur Layer
          Positioned.fill(
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                child: Container(
                  color: Colors.black.withOpacity(0.1),
                ),
              ),
            ),
          ),
          // Main Content
          widget.child,
        ],
      ),
    );
  }
}

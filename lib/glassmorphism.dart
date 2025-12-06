import 'dart:ui';
import 'package:flutter/material.dart';

class GlassmorphicContainer extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final double blur;
  final double border;
  final LinearGradient linearGradient;
  final LinearGradient borderGradient;
  final Widget child;
  final AlignmentGeometry? alignment;

  const GlassmorphicContainer({
    super.key,
    required this.width,
    required this.height,
    required this.borderRadius,
    required this.blur,
    required this.border,
    required this.linearGradient,
    required this.borderGradient,
    required this.child,
    this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: width,
          height: height,
          alignment: alignment,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: linearGradient,
          ),
          child: Stack(
            children: [
              // Border
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border.all(
                    color: Colors.transparent, // Transparent border
                    width: border,
                  ),
                  gradient: borderGradient,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(borderRadius),
                  // This inner clip prevents the border gradient from overlapping the child
                  child: Container(),
                ),
              ),
              // Shadow
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(51),
                      spreadRadius: 2,
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
              ),
              // Child content
              Center(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class GlassMorphism extends StatelessWidget {
  final double blur;
  final double opacity;
  final BorderRadius borderRadius;
  final Widget child;

  const GlassMorphism({
    super.key,
    required this.blur,
    required this.opacity,
    required this.borderRadius,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withAlpha((255 * opacity).round()),
            borderRadius: borderRadius,
            border: Border.all(
              color: Colors.white.withAlpha(51),
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

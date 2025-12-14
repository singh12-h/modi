import 'package:flutter/material.dart';

/// Professional Responsive Design System
/// Use this throughout the app for consistent responsive behavior

class ResponsiveHelper {
  static late MediaQueryData _mediaQueryData;
  static late double screenWidth;
  static late double screenHeight;
  static late double blockSizeHorizontal;
  static late double blockSizeVertical;
  static late double safeBlockHorizontal;
  static late double safeBlockVertical;
  static late double textScaleFactor;
  static late EdgeInsets safePadding;

  /// Initialize responsive values - call this in build method
  static void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    screenHeight = _mediaQueryData.size.height;
    blockSizeHorizontal = screenWidth / 100;
    blockSizeVertical = screenHeight / 100;
    textScaleFactor = _mediaQueryData.textScaleFactor.clamp(0.8, 1.3);
    safePadding = _mediaQueryData.padding;

    final safeWidth = screenWidth - safePadding.left - safePadding.right;
    final safeHeight = screenHeight - safePadding.top - safePadding.bottom;
    safeBlockHorizontal = safeWidth / 100;
    safeBlockVertical = safeHeight / 100;
  }

  /// Device type checks
  static bool get isVerySmallPhone => screenWidth < 320;
  static bool get isSmallPhone => screenWidth >= 320 && screenWidth < 375;
  static bool get isMediumPhone => screenWidth >= 375 && screenWidth < 414;
  static bool get isLargePhone => screenWidth >= 414 && screenWidth < 600;
  static bool get isTablet => screenWidth >= 600 && screenWidth < 1024;
  static bool get isDesktop => screenWidth >= 1024;
  static bool get isMobile => screenWidth < 600;

  /// Dynamic sizing based on screen width percentage
  static double wp(double percentage) => screenWidth * percentage / 100;
  static double hp(double percentage) => screenHeight * percentage / 100;

  /// Safe area sizing (excludes notches, status bar, etc.)
  static double swp(double percentage) => safeBlockHorizontal * percentage;
  static double shp(double percentage) => safeBlockVertical * percentage;

  /// Responsive font sizes that scale properly
  static double fontSize(double size) {
    // Base on 375px width (iPhone X standard)
    final scaleFactor = screenWidth / 375;
    final scaledSize = size * scaleFactor.clamp(0.8, 1.4);
    return scaledSize * textScaleFactor;
  }

  /// Fixed responsive font sizes
  static double get fontXS => fontSize(10);
  static double get fontSM => fontSize(12);
  static double get fontMD => fontSize(14);
  static double get fontLG => fontSize(16);
  static double get fontXL => fontSize(18);
  static double get fontXXL => fontSize(20);
  static double get fontHeading => fontSize(24);
  static double get fontTitle => fontSize(28);

  /// Responsive spacing/padding
  static double get spacingXS => wp(1);
  static double get spacingSM => wp(2);
  static double get spacingMD => wp(3);
  static double get spacingLG => wp(4);
  static double get spacingXL => wp(5);
  static double get spacingXXL => wp(6);

  /// Responsive icon sizes
  static double get iconSM => isMobile ? 16 : 20;
  static double get iconMD => isMobile ? 20 : 24;
  static double get iconLG => isMobile ? 24 : 28;
  static double get iconXL => isMobile ? 28 : 32;

  /// Responsive border radius
  static double get radiusSM => isMobile ? 6 : 8;
  static double get radiusMD => isMobile ? 10 : 12;
  static double get radiusLG => isMobile ? 14 : 16;
  static double get radiusXL => isMobile ? 18 : 20;

  /// Button heights
  static double get buttonHeightSM => isMobile ? 36 : 40;
  static double get buttonHeightMD => isMobile ? 44 : 48;
  static double get buttonHeightLG => isMobile ? 50 : 56;

  /// Get responsive padding based on device
  static EdgeInsets get screenPadding {
    if (isVerySmallPhone) return const EdgeInsets.all(8);
    if (isSmallPhone) return const EdgeInsets.all(12);
    if (isMobile) return const EdgeInsets.all(16);
    if (isTablet) return const EdgeInsets.all(20);
    return const EdgeInsets.all(24);
  }

  /// Card padding
  static EdgeInsets get cardPadding {
    if (isVerySmallPhone) return const EdgeInsets.all(8);
    if (isSmallPhone) return const EdgeInsets.all(10);
    if (isMobile) return const EdgeInsets.all(12);
    return const EdgeInsets.all(16);
  }

  /// Dialog inset padding
  static EdgeInsets get dialogPadding {
    if (isVerySmallPhone) return const EdgeInsets.symmetric(horizontal: 12, vertical: 16);
    if (isSmallPhone) return const EdgeInsets.symmetric(horizontal: 16, vertical: 20);
    if (isMobile) return const EdgeInsets.symmetric(horizontal: 20, vertical: 24);
    return const EdgeInsets.symmetric(horizontal: 40, vertical: 24);
  }

  /// Get max width for content (prevents too wide layouts on tablets/desktop)
  static double get maxContentWidth {
    if (isMobile) return screenWidth;
    if (isTablet) return 600;
    return 800;
  }

  /// Get grid cross axis count based on screen
  static int get gridCrossAxisCount {
    if (isVerySmallPhone || isSmallPhone) return 1;
    if (isMobile) return 1;
    if (isTablet) return 2;
    return 3;
  }

  /// Get aspect ratio for cards/grid items
  static double get cardAspectRatio {
    if (isVerySmallPhone) return 3.0;
    if (isSmallPhone) return 2.6;
    if (isMobile) return 2.2;
    if (isTablet) return 1.6;
    return 1.5;
  }
}

/// Responsive Text Widget - automatically scales and never overflows
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final double? minFontSize;
  final double? maxFontSize;

  const ResponsiveText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines = 1,
    this.minFontSize,
    this.maxFontSize,
  });

  @override
  Widget build(BuildContext context) {
    ResponsiveHelper.init(context);
    
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate appropriate font size based on available width
        final baseStyle = style ?? const TextStyle();
        final baseFontSize = baseStyle.fontSize ?? 14;
        
        // Scale font if text would overflow
        double fontSize = baseFontSize;
        final textPainter = TextPainter(
          text: TextSpan(text: text, style: baseStyle.copyWith(fontSize: fontSize)),
          maxLines: maxLines,
          textDirection: TextDirection.ltr,
        );
        
        textPainter.layout(maxWidth: constraints.maxWidth);
        
        // If text overflows, reduce font size
        while (textPainter.didExceedMaxLines && fontSize > (minFontSize ?? 8)) {
          fontSize -= 0.5;
          textPainter.text = TextSpan(text: text, style: baseStyle.copyWith(fontSize: fontSize));
          textPainter.layout(maxWidth: constraints.maxWidth);
        }

        return Text(
          text,
          style: baseStyle.copyWith(fontSize: fontSize),
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}

/// Responsive Button - scales properly on all screens
class ResponsiveButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool isOutlined;
  final bool isCompact;

  const ResponsiveButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.isOutlined = false,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    ResponsiveHelper.init(context);
    
    final buttonStyle = isOutlined
        ? OutlinedButton.styleFrom(
            foregroundColor: foregroundColor ?? Theme.of(context).primaryColor,
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? ResponsiveHelper.spacingMD : ResponsiveHelper.spacingLG,
              vertical: isCompact ? ResponsiveHelper.spacingSM : ResponsiveHelper.spacingMD,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ResponsiveHelper.radiusMD),
            ),
          )
        : ElevatedButton.styleFrom(
            backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
            foregroundColor: foregroundColor ?? Colors.white,
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? ResponsiveHelper.spacingMD : ResponsiveHelper.spacingLG,
              vertical: isCompact ? ResponsiveHelper.spacingSM : ResponsiveHelper.spacingMD,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ResponsiveHelper.radiusMD),
            ),
          );

    final child = FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: ResponsiveHelper.iconSM),
            SizedBox(width: ResponsiveHelper.spacingSM),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: ResponsiveHelper.fontMD,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
          ),
        ],
      ),
    );

    if (isOutlined) {
      return OutlinedButton(
        onPressed: onPressed,
        style: buttonStyle as ButtonStyle,
        child: child,
      );
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: buttonStyle as ButtonStyle,
      child: child,
    );
  }
}

/// Responsive Dialog - properly sized for all screens
class ResponsiveDialog extends StatelessWidget {
  final String? title;
  final Widget content;
  final List<Widget>? actions;
  final bool scrollable;

  const ResponsiveDialog({
    super.key,
    this.title,
    required this.content,
    this.actions,
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    ResponsiveHelper.init(context);

    return Dialog(
      insetPadding: ResponsiveHelper.dialogPadding,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ResponsiveHelper.radiusLG),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: ResponsiveHelper.maxContentWidth,
          maxHeight: ResponsiveHelper.hp(85),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null)
              Padding(
                padding: ResponsiveHelper.cardPadding,
                child: Text(
                  title!,
                  style: TextStyle(
                    fontSize: ResponsiveHelper.fontXL,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (scrollable)
              Flexible(
                child: SingleChildScrollView(
                  padding: ResponsiveHelper.cardPadding,
                  child: content,
                ),
              )
            else
              Padding(
                padding: ResponsiveHelper.cardPadding,
                child: content,
              ),
            if (actions != null && actions!.isNotEmpty)
              Padding(
                padding: ResponsiveHelper.cardPadding,
                child: Wrap(
                  spacing: ResponsiveHelper.spacingSM,
                  runSpacing: ResponsiveHelper.spacingSM,
                  alignment: WrapAlignment.end,
                  children: actions!,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Responsive Row that automatically wraps on small screens
class ResponsiveRow extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final double spacing;
  final double runSpacing;

  const ResponsiveRow({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.spacing = 8,
    this.runSpacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    ResponsiveHelper.init(context);

    // On very small screens, use Wrap to allow wrapping
    if (ResponsiveHelper.isVerySmallPhone || ResponsiveHelper.isSmallPhone) {
      return Wrap(
        spacing: spacing,
        runSpacing: runSpacing,
        alignment: WrapAlignment.start,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: children,
      );
    }

    // On larger screens, use Row with Flexible children
    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: children.map((child) {
        // Wrap each child in Flexible to prevent overflow
        if (child is Expanded || child is Flexible || child is Spacer) {
          return child;
        }
        return Flexible(child: child);
      }).toList(),
    );
  }
}

/// Responsive Container with max width constraint
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? color;
  final BoxDecoration? decoration;
  final double? maxWidth;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.decoration,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    ResponsiveHelper.init(context);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? ResponsiveHelper.maxContentWidth,
        ),
        child: Container(
          padding: padding ?? ResponsiveHelper.screenPadding,
          color: decoration == null ? color : null,
          decoration: decoration,
          child: child,
        ),
      ),
    );
  }
}

/// Responsive Card with proper padding and sizing
class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? color;
  final double? elevation;
  final BorderRadius? borderRadius;

  const ResponsiveCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.elevation,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    ResponsiveHelper.init(context);

    return Card(
      margin: margin ?? EdgeInsets.all(ResponsiveHelper.spacingSM),
      elevation: elevation ?? 2,
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(ResponsiveHelper.radiusMD),
      ),
      child: Padding(
        padding: padding ?? ResponsiveHelper.cardPadding,
        child: child,
      ),
    );
  }
}

/// Extension for easy responsive sizing
extension ResponsiveExtension on num {
  /// Width percentage
  double get w => ResponsiveHelper.wp(toDouble());
  
  /// Height percentage
  double get h => ResponsiveHelper.hp(toDouble());
  
  /// Responsive font size
  double get sp => ResponsiveHelper.fontSize(toDouble());
}

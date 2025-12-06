import 'package:flutter/material.dart';

// Design System for OPD Management App
// Based on Material Design 3 principles

class AppColors {
  // Primary Colors
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color darkBlue = Color(0xFF1976D2);
  static const Color lightBlue = Color(0xFFE3F2FD);

  // Secondary Colors
  static const Color teal = Color(0xFF009688);
  static const Color darkTeal = Color(0xFF00796B);
  static const Color lightTeal = Color(0xFFE0F2F1);

  // Accent Colors
  static const Color orange = Color(0xFFFF9800);
  static const Color amber = Color(0xFFFFC107);

  // Status Colors
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color dangerRed = Color(0xFFF44336);
  static const Color infoBlue = Color(0xFF2196F3);

  // Neutral Colors
  static const Color background = Color(0xFFF5F5F5);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color divider = Color(0xFFBDBDBD);
}

class AppTypography {
  // Font Family
  static const String primaryFont = 'Roboto';
  static const String secondaryFont = 'Open Sans';

  // Font Sizes
  static const double h1 = 28.0;
  static const double h2 = 24.0;
  static const double h3 = 20.0;
  static const double bodyLarge = 16.0;
  static const double body = 14.0;
  static const double caption = 12.0;
  static const double small = 10.0;

  // Font Weights
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;

  // Text Styles
  static TextStyle h1Style = const TextStyle(
    fontSize: h1,
    fontWeight: bold,
    color: AppColors.textPrimary,
    fontFamily: primaryFont,
  );

  static TextStyle h2Style = const TextStyle(
    fontSize: h2,
    fontWeight: bold,
    color: AppColors.textPrimary,
    fontFamily: primaryFont,
  );

  static TextStyle h3Style = const TextStyle(
    fontSize: h3,
    fontWeight: semiBold,
    color: AppColors.textPrimary,
    fontFamily: primaryFont,
  );

  static TextStyle bodyLargeStyle = const TextStyle(
    fontSize: bodyLarge,
    fontWeight: regular,
    color: AppColors.textPrimary,
    fontFamily: primaryFont,
  );

  static TextStyle bodyStyle = const TextStyle(
    fontSize: body,
    fontWeight: regular,
    color: AppColors.textSecondary,
    fontFamily: primaryFont,
  );

  static TextStyle captionStyle = const TextStyle(
    fontSize: caption,
    fontWeight: regular,
    color: AppColors.textSecondary,
    fontFamily: primaryFont,
  );
}

class AppSpacing {
  // Padding/Margin
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;

  // Grid System (8dp grid)
  static const double gridUnit = 8.0;
}

class AppComponents {
  // Button Styles
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    minimumSize: const Size(double.infinity, 48.0),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8.0),
    ),
    backgroundColor: AppColors.primaryBlue,
    foregroundColor: Colors.white,
    textStyle: const TextStyle(
      fontSize: 14.0,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.25,
    ),
    elevation: 2.0,
  );

  static ButtonStyle secondaryButtonStyle = OutlinedButton.styleFrom(
    minimumSize: const Size(double.infinity, 48.0),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8.0),
    ),
    side: const BorderSide(color: AppColors.primaryBlue),
    foregroundColor: AppColors.primaryBlue,
    textStyle: const TextStyle(
      fontSize: 14.0,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.25,
    ),
  );

  // Card Styles
  static BoxDecoration cardDecoration = BoxDecoration(
    color: AppColors.cardBackground,
    borderRadius: BorderRadius.circular(12.0),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withAlpha((255 * 0.1).round()),
        blurRadius: 4.0,
        offset: const Offset(0, 2),
      ),
    ],
  );

  // Text Field Styles
  static InputDecoration textFieldDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: AppColors.dangerRed),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
    );
  }

  // Chip Styles
  static ChipThemeData chipTheme = ChipThemeData(
    backgroundColor: AppColors.lightBlue,
    disabledColor: AppColors.divider,
    selectedColor: AppColors.primaryBlue,
    secondarySelectedColor: AppColors.primaryBlue,
    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
    labelStyle: const TextStyle(
      fontSize: 12.0,
      color: AppColors.textPrimary,
    ),
    secondaryLabelStyle: const TextStyle(
      fontSize: 12.0,
      color: Colors.white,
    ),
    brightness: Brightness.light,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16.0),
    ),
  );

  // Dialog Styles
  static DialogThemeData dialogTheme = DialogThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16.0)),
    ),
    elevation: 24.0,
  );
}

class AppIcons {
  // Icon Sizes
  static const double small = 16.0;
  static const double regular = 24.0;
  static const double large = 32.0;
  static const double extraLarge = 48.0;

  // Common Icons
  static const IconData home = Icons.home;
  static const IconData patient = Icons.person;
  static const IconData doctor = Icons.medical_services;
  static const IconData appointment = Icons.event;
  static const IconData prescription = Icons.description;
  static const IconData payment = Icons.payment;
  static const IconData reports = Icons.assessment;
  static const IconData settings = Icons.settings;
  static const IconData search = Icons.search;
  static const IconData notification = Icons.notifications;
  static const IconData add = Icons.add;
  static const IconData edit = Icons.edit;
  static const IconData delete = Icons.delete;
  static const IconData save = Icons.save;
  static const IconData print = Icons.print;
  static const IconData email = Icons.email;
  static const IconData sms = Icons.sms;
  static const IconData whatsapp = Icons.message;
  static const IconData camera = Icons.camera;
  static const IconData gallery = Icons.photo_library;
  static const IconData calendar = Icons.calendar_today;
  static const IconData clock = Icons.schedule;
  static const IconData phone = Icons.phone;
  static const IconData location = Icons.location_on;
}

class AppAnimations {
  // Transitions
  static const Duration slideTransition = Duration(milliseconds: 300);
  static const Duration fadeTransition = Duration(milliseconds: 200);
  static const Duration scaleTransition = Duration(milliseconds: 150);

  // Easing Curves
  static const Curve standardEasing = Curves.easeInOut;
  static const Curve decelerationEasing = Curves.decelerate;
  static const Curve accelerationEasing = Curves.easeIn;

  // Loading Animation
  static Widget loadingIndicator({Color? color}) {
    return CircularProgressIndicator(
      valueColor: AlwaysStoppedAnimation<Color>(color ?? AppColors.primaryBlue),
    );
  }

  // Shimmer Effect Placeholder
  static Widget shimmerBox({double width = double.infinity, double height = 16.0}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.divider.withAlpha((255 * 0.5).round()),
        borderRadius: BorderRadius.circular(4.0),
      ),
    );
  }
}

class AppResponsive {
  // Breakpoints
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 840.0;

  // Screen Type Detection
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width >= mobileBreakpoint &&
           MediaQuery.of(context).size.width < tabletBreakpoint;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }

  // Responsive Values
  static double getResponsiveValue(BuildContext context, {
    required double mobile,
    required double tablet,
    required double desktop,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  // Grid Columns
  static int getGridColumns(BuildContext context) {
    if (isMobile(context)) return 1;
    if (isTablet(context)) return 2;
    return 3;
  }
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: AppColors.primaryBlue,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryBlue,
        secondary: AppColors.teal,
        surface: AppColors.cardBackground,
        error: AppColors.dangerRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary, // onBackground is deprecated
        onError: Colors.white,
      ),
      fontFamily: AppTypography.primaryFont,
      textTheme: TextTheme(
        headlineLarge: AppTypography.h1Style,
        headlineMedium: AppTypography.h2Style,
        headlineSmall: AppTypography.h3Style,
        bodyLarge: AppTypography.bodyLargeStyle,
        bodyMedium: AppTypography.bodyStyle,
        bodySmall: AppTypography.captionStyle,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: AppComponents.primaryButtonStyle,
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: AppComponents.secondaryButtonStyle,
      ),
      cardTheme: const CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12.0)),
        ),
        elevation: 4.0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2.0),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      ),
      chipTheme: AppComponents.chipTheme,
      dialogTheme: AppComponents.dialogTheme,
    );
  }
}

// Technical Requirements Constants
class AppTechnical {
  // Platform Requirements
  static const String platform = 'Android';
  static const int minSdk = 24; // Android 7.0
  static const int targetSdk = 34; // Android 14
  static const String language = 'Kotlin'; // or Java

  // Architecture
  static const String pattern = 'MVVM';
  static const List<String> architectureComponents = [
    'ViewModel',
    'LiveData',
    'Room Database',
    'Navigation Component',
    'WorkManager'
  ];

  // Permissions Required
  static const List<String> permissions = [
    'android.permission.CAMERA',
    'android.permission.READ_EXTERNAL_STORAGE',
    'android.permission.WRITE_EXTERNAL_STORAGE',
    'android.permission.READ_MEDIA_IMAGES',
    'android.permission.INTERNET',
    'android.permission.ACCESS_NETWORK_STATE',
    'android.permission.SEND_SMS',
    'android.permission.CALL_PHONE',
    'android.permission.POST_NOTIFICATIONS',
    'android.permission.BLUETOOTH',
    'android.permission.BLUETOOTH_ADMIN',
    'android.permission.BLUETOOTH_CONNECT',
  ];

  // Data Storage Options
  static const List<String> storageOptions = [
    'Local SQLite (Room Database)',
    'Firebase (Cloud)',
    'Hybrid (Recommended)'
  ];

  // Security Features
  static const List<String> securityFeatures = [
    'Password hashing (BCrypt)',
    'Session management',
    'Auto-logout after inactivity',
    'Biometric authentication',
    'SQLite database encryption (SQLCipher)',
    'Encrypted shared preferences',
    'Secure file storage',
    'HTTPS only',
    'Certificate pinning',
    'API key security'
  ];
}

// Development Priority Phases
class DevelopmentPhases {
  static const Map<String, List<String>> phases = {
    'Phase 1 (MVP - 4 weeks)': [
      'Authentication (both logins)',
      'Patient registration',
      'Token system',
      'Basic dashboard',
      'Simple prescription'
    ],
    'Phase 2 (4 weeks)': [
      'Advanced prescription',
      'Appointments',
      'Patient search',
      'Payment tracking',
      'Basic reports'
    ],
    'Phase 3 (4 weeks)': [
      'Analytics & charts',
      'SMS/Email integration',
      'PDF generation',
      'Templates',
      'Settings'
    ],
    'Phase 4 (2 weeks)': [
      'Polish & optimization',
      'Bug fixes',
      'Testing',
      'Documentation'
    ]
  };
}

// Success Metrics
class SuccessMetrics {
  static const Map<String, String> metrics = {
    'User Satisfaction': '4.5+ rating',
    'Performance': 'App opens in < 2 seconds',
    'Stability': '< 1% crash rate',
    'Usage': '90% daily active users',
    'Efficiency': '50% reduction in patient wait time',
    'Accuracy': '99% data accuracy'
  };
}

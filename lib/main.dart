import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'onboarding_screen.dart';
import 'welcome_page.dart';
import 'login_signup_choice.dart';
import 'staff_login_page.dart';
import 'doctor_login_page.dart';
import 'patient_qr_code.dart';
import 'waiting_room_display.dart';
import 'password_reset_tool.dart';
import 'doctor_registration_page.dart';
import 'forgot_password_page.dart';
import 'patient_report_page.dart';
import 'online_license_service.dart';
import 'license_activation_page.dart';

import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MODI - Medical OPD Digital Interface',
      
      locale: const Locale('en', 'US'),
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('en', 'GB'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const StartupScreen(),
      
      onGenerateRoute: (settings) {
        if (settings.name != null && settings.name!.startsWith('/patient-report')) {
          final uri = Uri.parse(settings.name!);
          final encodedData = uri.queryParameters['data'];
          return MaterialPageRoute(
            builder: (context) => PatientReportPage(encodedData: encodedData),
          );
        }
        
        switch (settings.name) {
          case '/onboarding':
            return MaterialPageRoute(builder: (_) => const OnboardingScreen());
          case '/welcome':
            return MaterialPageRoute(builder: (_) => const WelcomePage());
          case '/login-signup-choice':
            return MaterialPageRoute(builder: (_) => const LoginSignupChoice());
          case '/doctor-login':
            return MaterialPageRoute(builder: (_) => const DoctorLoginPage());
          case '/staff-login':
            return MaterialPageRoute(builder: (_) => const StaffLoginPage());
          case '/patient-qr':
            return MaterialPageRoute(builder: (_) => const PatientQrCode());
          case '/waiting-room-display':
            return MaterialPageRoute(builder: (_) => const WaitingRoomDisplay());
          case '/password-reset':
            return MaterialPageRoute(builder: (_) => const PasswordResetTool());
          case '/doctor-register':
            return MaterialPageRoute(builder: (_) => const DoctorRegistrationPage());
          case '/forgot-password':
            return MaterialPageRoute(builder: (_) => const ForgotPasswordPage());
          default:
            return MaterialPageRoute(builder: (_) => const WelcomePage());
        }
      },
    );
  }
}

// Quick startup screen - checks status and navigates
class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  @override
  void initState() {
    super.initState();
    _checkAndNavigate();
  }

  Future<void> _checkAndNavigate() async {
    try {
      // Check connectivity
      final connectivity = await Connectivity().checkConnectivity();
      final hasInternet = connectivity.contains(ConnectivityResult.mobile) ||
                          connectivity.contains(ConnectivityResult.wifi) ||
                          connectivity.contains(ConnectivityResult.ethernet);

      if (!mounted) return;

      if (!hasInternet) {
        _showNoInternetDialog();
        return;
      }

      // Initialize license service (runs quickly in background)
      await OnlineLicenseService.initializeDemoIfNeeded();
      await OnlineLicenseService.initialize();
      
      if (!mounted) return;

      // Check license
      final licenseStatus = await OnlineLicenseService.checkLicenseStatus();
      
      if (!mounted) return;

      if (licenseStatus == LicenseStatus.expired || licenseStatus == LicenseStatus.notFound) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LicenseActivationPage()),
        );
        return;
      }

      // Check onboarding
      final prefs = await SharedPreferences.getInstance();
      final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => hasSeenOnboarding ? const LoginSignupChoice() : const OnboardingScreen(),
        ),
      );
    } catch (e) {
      print('❌ Startup error: $e');
      // On any error, still navigate to welcome to avoid stuck screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const WelcomePage()),
        );
      }
    }
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
              _checkAndNavigate();
            },
            child: const Text('RETRY', style: TextStyle(color: Color(0xFF00d4ff))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Same background as native splash for seamless transition
    return const Scaffold(
      backgroundColor: Color(0xFF1a1a2e),
      body: SizedBox.shrink(),
    );
  }
}

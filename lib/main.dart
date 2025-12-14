import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'splash_screen.dart';
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

void main() {
  print('========== APP STARTING ==========');
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  
  // Preserve native splash until Flutter is ready
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  print('Using temporary in-memory storage for testing');

  runApp(const MyApp());
  print('App launched with temporary storage!');
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MODI - Medical OPD Digital Interface',
      
      // Localization for English date picker
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
      home: const SplashScreen(),
      
      // Handle deep links with route generator
      onGenerateRoute: (settings) {
        // Handle /patient-report?data=BASE64_DATA
        if (settings.name != null && settings.name!.startsWith('/patient-report')) {
          final uri = Uri.parse(settings.name!);
          final encodedData = uri.queryParameters['data'];
          return MaterialPageRoute(
            builder: (context) => PatientReportPage(encodedData: encodedData),
          );
        }
        
        // Default routes
        switch (settings.name) {
          case '/splash':
            return MaterialPageRoute(builder: (_) => const SplashScreen());
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
            return MaterialPageRoute(builder: (_) => const SplashScreen());
        }
      },
    );
  }
}


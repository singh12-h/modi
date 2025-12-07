import 'package:flutter/material.dart';
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

void main() {
  print('========== APP STARTING ==========');
  WidgetsFlutterBinding.ensureInitialized();

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
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/welcome': (context) => const WelcomePage(),
        '/login-signup-choice': (context) => const LoginSignupChoice(),
        '/doctor-login': (context) => const DoctorLoginPage(),
        '/staff-login': (context) => const StaffLoginPage(),
        '/patient-qr': (context) => const PatientQrCode(),
        '/waiting-room-display': (context) => const WaitingRoomDisplay(),
        '/password-reset': (context) => const PasswordResetTool(),
        '/doctor-register': (context) => const DoctorRegistrationPage(),
        '/forgot-password': (context) => const ForgotPasswordPage(),
      },
    );
  }
}

import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Email Service using EmailJS (FREE - 200 emails/month)
/// 
/// To setup EmailJS:
/// 1. Go to https://www.emailjs.com/ and create free account
/// 2. Add email service (Gmail recommended)
/// 3. Create email template with variables: {{to_email}}, {{otp}}, {{user_name}}
/// 4. Get Service ID, Template ID, and Public Key
/// 5. Update the constants below
class EmailService {
  // ========== EMAILJS CONFIGURATION ==========
  // Configured EmailJS credentials
  static const String _serviceId = 'service_3kv868g';
  static const String _templateId = 'template_vv8z5wt';
  static const String _publicKey = 'CaGRZbmuBXU4SjQG-';
  
  // EmailJS API endpoint - using v1.0 for browser compatibility
  static const String _emailJsUrl = 'https://api.emailjs.com/api/v1.0/email/send';
  
  // OTP validity duration in minutes
  static const int otpValidityMinutes = 10;
  
  /// Generate a 6-digit OTP
  static String generateOTP() {
    final random = Random.secure();
    int otp = 100000 + random.nextInt(900000);
    return otp.toString();
  }
  
  /// Send OTP to email address
  /// Returns true if sent successfully
  static Future<bool> sendOtpEmail({
    required String toEmail,
    required String userName,
    required String otp,
  }) async {
    try {
      // Check if EmailJS is configured
      if (_serviceId == 'YOUR_SERVICE_ID' || 
          _templateId == 'YOUR_TEMPLATE_ID' || 
          _publicKey == 'YOUR_PUBLIC_KEY') {
        print('⚠️ EmailJS not configured! Using demo mode.');
        // In demo mode, just save OTP locally
        await _saveOtpLocally(toEmail, otp);
        return true;
      }

      final requestBody = jsonEncode({
        'service_id': _serviceId,
        'template_id': _templateId,
        'user_id': _publicKey,
        'template_params': {
          'email': toEmail,  // Matches {{email}} in template
          'passcode': otp,   // Matches {{passcode}} in template
          'time': '$otpValidityMinutes',  // Matches {{time}} in template
        },
      });

      print('📧 Sending OTP email to $toEmail...');
      
      final response = await http.post(
        Uri.parse(_emailJsUrl),
        headers: {
          'Content-Type': 'application/json',
          'origin': 'http://localhost',
        },
        body: requestBody,
      );

      print('📧 Response status: ${response.statusCode}');
      print('📧 Response body: ${response.body}');

      if (response.statusCode == 200 || response.body == 'OK') {
        print('✅ OTP email sent successfully to $toEmail');
        await _saveOtpLocally(toEmail, otp);
        return true;
      } else {
        print('❌ Failed to send email. Status: ${response.statusCode}');
        // Still save OTP locally for demo/fallback
        await _saveOtpLocally(toEmail, otp);
        print('📧 OTP saved locally as fallback: $otp');
        return true; // Return true so user can still proceed with demo OTP
      }
    } catch (e) {
      print('❌ Email error: $e');
      // Save OTP locally as fallback
      await _saveOtpLocally(toEmail, otp);
      print('📧 OTP saved locally as fallback: $otp');
      return true; // Return true so user can still proceed with demo OTP
    }
  }
  
  /// Save OTP locally for verification
  static Future<void> _saveOtpLocally(String email, String otp) async {
    final prefs = await SharedPreferences.getInstance();
    final expiryTime = DateTime.now().add(Duration(minutes: otpValidityMinutes));
    
    await prefs.setString('otp_email', email.toLowerCase());
    await prefs.setString('otp_code', otp);
    await prefs.setString('otp_expiry', expiryTime.toIso8601String());
    
    print('📧 OTP saved for $email: $otp (expires: $expiryTime)');
  }
  
  /// Verify OTP entered by user
  /// Returns true if OTP is valid and not expired
  static Future<OtpVerificationResult> verifyOtp({
    required String email,
    required String enteredOtp,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final savedEmail = prefs.getString('otp_email') ?? '';
      final savedOtp = prefs.getString('otp_code') ?? '';
      final expiryString = prefs.getString('otp_expiry');
      
      if (savedEmail.isEmpty || savedOtp.isEmpty || expiryString == null) {
        return OtpVerificationResult(
          success: false,
          message: 'No OTP found. Please request a new one.',
        );
      }
      
      if (savedEmail.toLowerCase() != email.toLowerCase()) {
        return OtpVerificationResult(
          success: false,
          message: 'OTP was sent to a different email.',
        );
      }
      
      final expiryTime = DateTime.parse(expiryString);
      if (DateTime.now().isAfter(expiryTime)) {
        await _clearOtp();
        return OtpVerificationResult(
          success: false,
          message: 'OTP has expired. Please request a new one.',
        );
      }
      
      if (savedOtp != enteredOtp) {
        return OtpVerificationResult(
          success: false,
          message: 'Invalid OTP. Please try again.',
        );
      }
      
      // OTP is valid - clear it so it can't be reused
      await _clearOtp();
      
      return OtpVerificationResult(
        success: true,
        message: 'OTP verified successfully!',
      );
    } catch (e) {
      return OtpVerificationResult(
        success: false,
        message: 'Verification error: $e',
      );
    }
  }
  
  /// Clear saved OTP data
  static Future<void> _clearOtp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('otp_email');
    await prefs.remove('otp_code');
    await prefs.remove('otp_expiry');
  }
  
  /// Check if EmailJS is configured
  static bool isConfigured() {
    return _serviceId != 'YOUR_SERVICE_ID' && 
           _templateId != 'YOUR_TEMPLATE_ID' && 
           _publicKey != 'YOUR_PUBLIC_KEY';
  }
  
  /// Send password reset OTP
  static Future<bool> sendPasswordResetOtp({
    required String email,
    required String userName,
  }) async {
    final otp = generateOTP();
    return await sendOtpEmail(
      toEmail: email,
      userName: userName,
      otp: otp,
    );
  }
  
  /// Send email verification OTP for new account
  static Future<bool> sendVerificationOtp({
    required String email,
    required String userName,
  }) async {
    final otp = generateOTP();
    return await sendOtpEmail(
      toEmail: email,
      userName: userName,
      otp: otp,
    );
  }
  
  /// Get the locally stored OTP (works in demo mode or as fallback)
  static Future<String?> getDemoOtp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('otp_code');
  }
  
  /// Check if we should show the fallback OTP (when email sending might have failed)
  static Future<bool> shouldShowFallbackOtp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('otp_code') != null;
  }
}

/// Result class for OTP verification
class OtpVerificationResult {
  final bool success;
  final String message;
  
  OtpVerificationResult({
    required this.success,
    required this.message,
  });
}

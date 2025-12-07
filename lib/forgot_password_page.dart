import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import 'database_helper.dart';
import 'models.dart';
import 'email_service.dart';
import 'doctor_login_page.dart';

/// Forgot Password Page
/// - Only for DOCTORS (Staff cannot reset their own password)
/// - Uses Email OTP verification
/// - Professional premium UI
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  
  // Step tracking: 0 = Enter Email, 1 = Enter OTP, 2 = New Password
  int _step = 0;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _demoOtp;
  Staff? _foundStaff;

  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _findAccountAndSendOtp() async {
    if (_usernameController.text.isEmpty || _emailController.text.isEmpty) {
      _showSnackBar('Please enter username and email', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Find staff by username
      final staff = await DatabaseHelper.instance.getStaffByUsername(
        _usernameController.text,
      );

      if (staff == null) {
        _showSnackBar('No account found with this username', isError: true);
        setState(() => _isLoading = false);
        return;
      }

      // Check if staff is a doctor (only doctors can reset password via email)
      if (staff.role != 'doctor') {
        _showSnackBar(
          'Staff accounts cannot reset password via email.\nPlease contact your administrator.',
          isError: true,
        );
        setState(() => _isLoading = false);
        return;
      }

      _foundStaff = staff;

      // Send OTP
      final success = await EmailService.sendPasswordResetOtp(
        email: _emailController.text,
        userName: staff.name,
      );

      if (success) {
        setState(() => _step = 1);
        
        // Always get OTP for fallback display
        _demoOtp = await EmailService.getDemoOtp();
        
        _showSnackBar(
          'OTP sent! Check your email or use fallback OTP shown below.',
        );
      } else {
        _showSnackBar('Failed to send OTP. Please try again.', isError: true);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.isEmpty) {
      _showSnackBar('Please enter OTP', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await EmailService.verifyOtp(
        email: _emailController.text,
        enteredOtp: _otpController.text,
      );

      if (result.success) {
        setState(() => _step = 2);
        _showSnackBar('OTP verified! Create your new password.');
      } else {
        _showSnackBar(result.message, isError: true);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    if (_foundStaff == null) {
      _showSnackBar('Session expired. Please start again.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Generate new salt and hash
      final newSalt = const Uuid().v4();
      final bytes = utf8.encode(_passwordController.text + newSalt);
      final newHash = sha256.convert(bytes).toString();

      // Update staff password
      final updatedStaff = Staff(
        id: _foundStaff!.id,
        name: _foundStaff!.name,
        username: _foundStaff!.username,
        passwordHash: newHash,
        salt: newSalt,
        role: _foundStaff!.role,
        createdAt: _foundStaff!.createdAt,
      );

      await DatabaseHelper.instance.updateStaff(updatedStaff);

      // Verify the update
      final verified = await DatabaseHelper.instance.authenticate(
        _foundStaff!.username,
        _passwordController.text,
      );

      if (verified != null) {
        _showSuccessDialog();
      } else {
        _showSnackBar('Password update failed. Please try again.', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.green.shade600,
                size: 60,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Password Reset Successful!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A237E),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your password has been updated.\nYou can now login with your new password.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const DoctorLoginPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Go to Login',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0D1B2A),
              Color(0xFF1B3A5F),
              Color(0xFF2E5077),
              Color(0xFF1A237E),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 30),
                    _buildStepIndicator(),
                    const SizedBox(height: 30),
                    _buildFormCard(),
                    const SizedBox(height: 20),
                    _buildBackToLogin(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Forgot Password?',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Reset via Email OTP',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(
            Icons.lock_reset,
            color: Colors.white,
            size: 30,
          ),
        ),
      ],
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: [
        _buildStepCircle(0, 'Email'),
        _buildStepLine(0),
        _buildStepCircle(1, 'OTP'),
        _buildStepLine(1),
        _buildStepCircle(2, 'Password'),
      ],
    );
  }

  Widget _buildStepCircle(int step, String label) {
    final isActive = _step >= step;
    final isCurrent = _step == step;
    
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? Colors.white : Colors.white.withOpacity(0.2),
              border: Border.all(
                color: isCurrent ? Colors.amber : Colors.transparent,
                width: 3,
              ),
              boxShadow: isCurrent
                  ? [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: isActive && _step > step
                  ? Icon(Icons.check, color: Colors.green.shade700, size: 20)
                  : Text(
                      '${step + 1}',
                      style: TextStyle(
                        color: isActive ? const Color(0xFF1A237E) : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine(int step) {
    final isActive = _step > step;
    return Container(
      width: 50,
      height: 3,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: _buildCurrentStepContent(),
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_step) {
      case 0:
        return _buildEmailStep();
      case 1:
        return _buildOtpStep();
      case 2:
        return _buildPasswordStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildEmailStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepTitle('Enter Your Details', 'We will send OTP to reset password'),
        const SizedBox(height: 24),
        _buildInputField(
          controller: _usernameController,
          label: 'Username',
          hint: 'Enter your username',
          icon: Icons.person,
          validator: (v) => v!.isEmpty ? 'Username is required' : null,
        ),
        const SizedBox(height: 16),
        _buildInputField(
          controller: _emailController,
          label: 'Email Address',
          hint: 'Enter your registered email',
          icon: Icons.email,
          keyboardType: TextInputType.emailAddress,
          validator: (v) {
            if (v!.isEmpty) return 'Email is required';
            if (!v.contains('@')) return 'Enter valid email';
            return null;
          },
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Note: Only doctors can reset password via email. Staff should contact administrator.',
                  style: TextStyle(
                    color: Colors.blue.shade900,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildActionButton('Send OTP', _findAccountAndSendOtp),
      ],
    );
  }

  Widget _buildOtpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepTitle('Enter OTP', 'Check your email for 6-digit code'),
        const SizedBox(height: 24),
        _buildInputField(
          controller: _otpController,
          label: 'OTP Code',
          hint: '123456',
          icon: Icons.lock_clock,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
        ),
        if (_demoOtp != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.amber.shade800, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Fallback OTP: $_demoOtp (use if email not received)',
                    style: TextStyle(
                      color: Colors.amber.shade900,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Didn't receive? "),
            TextButton(
              onPressed: _isLoading ? null : _findAccountAndSendOtp,
              child: const Text('Resend OTP'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildActionButton('Verify OTP', _verifyOtp),
      ],
    );
  }

  Widget _buildPasswordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepTitle('Create New Password', 'Enter a strong password'),
        const SizedBox(height: 24),
        _buildInputField(
          controller: _passwordController,
          label: 'New Password',
          hint: '••••••••',
          icon: Icons.lock,
          obscureText: _obscurePassword,
          suffix: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
          validator: (v) {
            if (v!.isEmpty) return 'Password is required';
            if (v.length < 6) return 'Min 6 characters';
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildInputField(
          controller: _confirmPasswordController,
          label: 'Confirm Password',
          hint: '••••••••',
          icon: Icons.lock_outline,
          obscureText: _obscureConfirmPassword,
          suffix: IconButton(
            icon: Icon(
              _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
            ),
            onPressed: () =>
                setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
          ),
          validator: (v) {
            if (v!.isEmpty) return 'Please confirm password';
            if (v != _passwordController.text) return 'Passwords do not match';
            return null;
          },
        ),
        const SizedBox(height: 12),
        _buildPasswordStrength(),
        const SizedBox(height: 24),
        _buildActionButton('Reset Password', _resetPassword),
      ],
    );
  }

  Widget _buildStepTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A237E),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordStrength() {
    final password = _passwordController.text;
    int strength = 0;
    if (password.length >= 6) strength++;
    if (password.length >= 10) strength++;
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;

    Color color;
    String text;
    if (strength <= 2) {
      color = Colors.red;
      text = 'Weak';
    } else if (strength <= 3) {
      color = Colors.orange;
      text = 'Medium';
    } else {
      color = Colors.green;
      text = 'Strong';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ...List.generate(5, (index) {
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: index < 4 ? 4 : 0),
                  decoration: BoxDecoration(
                    color: index < strength ? color : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Password strength: $text',
          style: TextStyle(fontSize: 12, color: color),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffix,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF1A237E)),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildActionButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A237E),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildBackToLogin() {
    return TextButton.icon(
      onPressed: () => Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DoctorLoginPage()),
      ),
      icon: const Icon(Icons.arrow_back, color: Colors.white),
      label: const Text(
        'Back to Login',
        style: TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }
}

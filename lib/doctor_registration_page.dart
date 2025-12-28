import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:ui';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import 'database_helper.dart';
import 'models.dart';
import 'email_service.dart';
import 'doctor_login_page.dart';

class DoctorRegistrationPage extends StatefulWidget {
  const DoctorRegistrationPage({super.key});

  @override
  State<DoctorRegistrationPage> createState() => _DoctorRegistrationPageState();
}

class _DoctorRegistrationPageState extends State<DoctorRegistrationPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;
  bool _emailVerified = false;
  bool _isOtpSent = false;
  String? _demoOtp;

  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _clinicNameController = TextEditingController();
  final _clinicAddressController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _registrationNumberController = TextEditingController();
  final _otpController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
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
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _clinicNameController.dispose();
    _clinicAddressController.dispose();
    _specialtyController.dispose();
    _registrationNumberController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendVerificationOtp() async {
    if (_emailController.text.isEmpty) {
      _showSnackBar('Please enter email address first', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await EmailService.sendVerificationOtp(
        email: _emailController.text,
        userName: _nameController.text.isNotEmpty ? _nameController.text : 'Doctor',
      );

      if (success) {
        setState(() => _isOtpSent = true);
        
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
        setState(() => _emailVerified = true);
        _showSnackBar('Email verified successfully! ✓');
      } else {
        _showSnackBar(result.message, isError: true);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _registerDoctor() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedTerms) {
      _showSnackBar('Please accept terms and conditions', isError: true);
      return;
    }
    if (!_emailVerified) {
      _showSnackBar('Please verify your email first', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Check if username exists
      final existingUser = await DatabaseHelper.instance.getStaffByUsername(
        _usernameController.text,
      );
      if (existingUser != null) {
        _showSnackBar('Username already exists. Please choose another.', isError: true);
        setState(() => _isLoading = false);
        return;
      }

      // Generate salt and hash password
      final salt = const Uuid().v4();
      final bytes = utf8.encode(_passwordController.text + salt);
      final hash = sha256.convert(bytes).toString();

      // Create doctor account with all details
      final doctor = Staff(
        id: const Uuid().v4(),
        name: _nameController.text,
        username: _usernameController.text,
        passwordHash: hash,
        salt: salt,
        role: 'doctor',
        createdAt: DateTime.now(),
        email: _emailController.text,
        mobile: _mobileController.text,
        clinicName: _clinicNameController.text,
        clinicAddress: _clinicAddressController.text,
        specialty: _specialtyController.text,
        registrationNumber: _registrationNumberController.text,
      );

      await DatabaseHelper.instance.insertStaff(doctor);

      // Show success dialog
      if (mounted) {
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
                  'Registration Successful!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A237E),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Welcome, Dr. ${_nameController.text}!\nYour account has been created.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person, size: 18, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text('Username: ${_usernameController.text}'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.email, size: 18, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(child: Text('Email: ${_emailController.text}')),
                        ],
                      ),
                    ],
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
    } catch (e) {
      _showSnackBar('Registration failed: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
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
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: _buildRegistrationForm(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
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
                  'Create Account',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Doctor Registration',
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
              Icons.medical_services,
              color: Colors.white,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationForm() {
    return Container(
      margin: const EdgeInsets.all(16),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Form(
          key: _formKey,
          child: Stepper(
            currentStep: _currentStep,
            onStepContinue: () {
              if (_currentStep < 2) {
                setState(() => _currentStep++);
              } else {
                _registerDoctor();
              }
            },
            onStepCancel: () {
              if (_currentStep > 0) {
                setState(() => _currentStep--);
              }
            },
            controlsBuilder: (context, details) {
              return Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : details.onStepContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A237E),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isLoading && _currentStep == 2
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _currentStep == 2 ? 'Create Account' : 'Continue',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                    if (_currentStep > 0) ...[
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: details.onStepCancel,
                        child: const Text('Back'),
                      ),
                    ],
                  ],
                ),
              );
            },
            steps: [
              // Step 1: Personal Information
              Step(
                title: const Text('Personal Info'),
                subtitle: const Text('Your basic details'),
                isActive: _currentStep >= 0,
                state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                content: Column(
                  children: [
                    _buildInputField(
                      controller: _nameController,
                      label: 'Full Name',
                      hint: 'Dr. John Doe',
                      icon: Icons.person,
                      validator: (v) => v!.isEmpty ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      controller: _emailController,
                      label: 'Email Address',
                      hint: 'doctor@clinic.com',
                      icon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v!.isEmpty) return 'Email is required';
                        if (!v.contains('@')) return 'Enter valid email';
                        return null;
                      },
                      suffix: _emailVerified
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle,
                                      color: Colors.green.shade700, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Verified',
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : null,
                    ),
                    if (!_emailVerified) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (_isOtpSent) ...[
                            Expanded(
                              child: _buildInputField(
                                controller: _otpController,
                                label: 'Enter OTP',
                                hint: '123456',
                                icon: Icons.lock_clock,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(6),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _verifyOtp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Verify',
                                      style: TextStyle(color: Colors.white)),
                            ),
                          ],
                          if (!_isOtpSent)
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _isLoading ? null : _sendVerificationOtp,
                                icon: _isLoading
                                    ? const SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.verified_user),
                                label: const Text('Verify Email'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (_isOtpSent && _demoOtp != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.amber.shade800),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Fallback OTP: $_demoOtp (use if email not received)',
                                  style: TextStyle(
                                    color: Colors.amber.shade900,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                    const SizedBox(height: 16),
                    _buildInputField(
                      controller: _mobileController,
                      label: 'Mobile Number',
                      hint: '+91 98765 43210',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      validator: (v) {
                        if (v!.isEmpty) return 'Mobile is required';
                        if (v.length < 10) return 'Enter valid mobile';
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              // Step 2: Clinic Details
              Step(
                title: const Text('Clinic Details'),
                subtitle: const Text('Professional information'),
                isActive: _currentStep >= 1,
                state: _currentStep > 1 ? StepState.complete : StepState.indexed,
                content: Column(
                  children: [
                    _buildInputField(
                      controller: _clinicNameController,
                      label: 'Clinic / Hospital Name',
                      hint: 'ABC Medical Center',
                      icon: Icons.local_hospital,
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      controller: _clinicAddressController,
                      label: 'Clinic Address',
                      hint: '123 Main Street, City',
                      icon: Icons.location_on,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      controller: _specialtyController,
                      label: 'Specialty',
                      hint: 'General Physician / Cardiologist',
                      icon: Icons.medical_information,
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      controller: _registrationNumberController,
                      label: 'Medical Registration No.',
                      hint: 'MCI/State Registration Number',
                      icon: Icons.badge,
                    ),
                  ],
                ),
              ),

              // Step 3: Account Setup
              Step(
                title: const Text('Account Setup'),
                subtitle: const Text('Login credentials'),
                isActive: _currentStep >= 2,
                state: StepState.indexed,
                content: Column(
                  children: [
                    _buildInputField(
                      controller: _usernameController,
                      label: 'Username',
                      hint: 'doctor_john',
                      icon: Icons.account_circle,
                      validator: (v) {
                        if (v!.isEmpty) return 'Username is required';
                        if (v.length < 4) return 'Min 4 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      controller: _passwordController,
                      label: 'Password',
                      hint: '••••••••',
                      icon: Icons.lock,
                      obscureText: _obscurePassword,
                      suffix: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
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
                          _obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() =>
                              _obscureConfirmPassword = !_obscureConfirmPassword);
                        },
                      ),
                      validator: (v) {
                        if (v!.isEmpty) return 'Please confirm password';
                        if (v != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: CheckboxListTile(
                        value: _acceptedTerms,
                        onChanged: (v) => setState(() => _acceptedTerms = v!),
                        title: const Text(
                          'I accept the Terms & Conditions and Privacy Policy',
                          style: TextStyle(fontSize: 14),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Column(
          mainAxisAlignment: maxLines > 1 ? MainAxisAlignment.start : MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.only(top: maxLines > 1 ? 14 : 0),
              child: Icon(icon, color: const Color(0xFF1A237E)),
            ),
          ],
        ),
        suffixIcon: suffix,
        alignLabelWithHint: true,
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
}

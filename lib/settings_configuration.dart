import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'waiting_room_display.dart';
import 'sms_integration.dart';
import 'whatsapp_integration.dart';
import 'email_features.dart';
import 'lab_reports_management.dart';
import 'patient_feedback_system.dart';
import 'doctor_schedule_calendar.dart';
import 'database_helper.dart';
import 'responsive_helper.dart';

class SettingsConfiguration extends StatefulWidget {
  const SettingsConfiguration({super.key});

  @override
  State<SettingsConfiguration> createState() => _SettingsConfigurationState();
}

class _SettingsConfigurationState extends State<SettingsConfiguration> {
  bool _isLoading = true;
  bool _showBuiltInQR = false; // For built-in feedback form QR
  
  // Storage Info
  double _databaseSizeMB = 0.0;
  int _totalPatients = 0;
  int _totalConsultations = 0;
  int _totalPayments = 0;
  double _averagePerPatient = 0.0;
  
  // Profile settings
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _specializationController = TextEditingController();
  final TextEditingController _qualificationController = TextEditingController();
  final TextEditingController _registrationController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _feeController = TextEditingController();
  final TextEditingController _clinicNameController = TextEditingController();
  final TextEditingController _clinicAddressController = TextEditingController();
  final TextEditingController _clinicPhoneController = TextEditingController();
  final TextEditingController _clinicEmailController = TextEditingController();
  final TextEditingController _feedbackFormUrlController = TextEditingController();

  // Appointment settings
  int _slotDuration = 30;
  int _bufferTime = 5;
  final TextEditingController _maxAppointmentsController = TextEditingController();
  final TextEditingController _advanceBookingController = TextEditingController();

  // Token settings
  bool _autoReset = true;
  String _tokenMode = 'Sequential';
  final TextEditingController _tokenPrefixController = TextEditingController();
  final TextEditingController _startingNumberController = TextEditingController();

  // Billing settings
  final TextEditingController _consultationFeeController = TextEditingController();
  final TextEditingController _taxController = TextEditingController();

  // Notification settings
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _smsNotifications = true;
  bool _patientReminders = true;
  bool _appointmentAlerts = true;
  bool _paymentReminders = true;
  bool _dailyReports = true;
  bool _sound = true;
  bool _vibration = true;
  
  // Role check - Only doctor should see feedback analytics
  bool _isDoctor = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadStorageInfo();
    _loadUserRole();
  }
  
  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('logged_in_role') ?? 'doctor';
    if (mounted) {
      setState(() {
        _isDoctor = role == 'doctor';
      });
    }
  }

  Future<void> _loadStorageInfo() async {
    try {
      // Get database size
      if (!kIsWeb) {
        final dbPath = await getDatabasesPath();
        final dbFile = File(path.join(dbPath, 'patients.db'));
        if (await dbFile.exists()) {
          final size = await dbFile.length();
          _databaseSizeMB = size / (1024 * 1024);
        }
      }
      
      // Get counts
      final patients = await DatabaseHelper.instance.getAllPatients();
      _totalPatients = patients.length;
      
      // Calculate average per patient
      if (_totalPatients > 0) {
        _averagePerPatient = (_databaseSizeMB * 1024) / _totalPatients; // in KB
      }
      
      if (mounted) setState(() {});
    } catch (e) {
      print('Error loading storage info: $e');
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      // Profile
      _nameController.text = prefs.getString('doctor_name') ?? 'Dr. Modi';
      _specializationController.text = prefs.getString('specialization') ?? 'General Physician';
      _qualificationController.text = prefs.getString('qualification') ?? 'MBBS, MD';
      _registrationController.text = prefs.getString('registration_number') ?? '12345';
      _experienceController.text = prefs.getString('experience') ?? '10';
      _feeController.text = prefs.getString('consultation_fee') ?? '500';
      _clinicNameController.text = prefs.getString('clinic_name') ?? 'Modi Clinic';
      _clinicAddressController.text = prefs.getString('clinic_address') ?? '';
      _clinicPhoneController.text = prefs.getString('clinic_phone') ?? '';
      _clinicEmailController.text = prefs.getString('clinic_email') ?? '';
      _feedbackFormUrlController.text = prefs.getString('feedback_form_url') ?? '';
      
      // Appointment
      _slotDuration = prefs.getInt('slot_duration') ?? 30;
      _bufferTime = prefs.getInt('buffer_time') ?? 5;
      _maxAppointmentsController.text = prefs.getString('max_appointments') ?? '50';
      _advanceBookingController.text = prefs.getString('advance_booking') ?? '30';
      
      // Token
      _autoReset = prefs.getBool('auto_reset') ?? true;
      _tokenMode = prefs.getString('token_mode') ?? 'Sequential';
      _tokenPrefixController.text = prefs.getString('token_prefix') ?? 'A';
      _startingNumberController.text = prefs.getString('starting_number') ?? '1';
      
      // Billing
      _consultationFeeController.text = prefs.getString('default_fee') ?? '500';
      _taxController.text = prefs.getString('tax_percent') ?? '0';
      
      // Notifications
      _pushNotifications = prefs.getBool('push_notifications') ?? true;
      _emailNotifications = prefs.getBool('email_notifications') ?? true;
      _smsNotifications = prefs.getBool('sms_notifications') ?? true;
      _patientReminders = prefs.getBool('patient_reminders') ?? true;
      _appointmentAlerts = prefs.getBool('appointment_alerts') ?? true;
      _paymentReminders = prefs.getBool('payment_reminders') ?? true;
      _dailyReports = prefs.getBool('daily_reports') ?? true;
      _sound = prefs.getBool('sound') ?? true;
      _vibration = prefs.getBool('vibration') ?? true;
      
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Profile
    await prefs.setString('doctor_name', _nameController.text);
    await prefs.setString('specialization', _specializationController.text);
    await prefs.setString('qualification', _qualificationController.text);
    await prefs.setString('registration_number', _registrationController.text);
    await prefs.setString('experience', _experienceController.text);
    await prefs.setString('consultation_fee', _feeController.text);
    await prefs.setString('clinic_name', _clinicNameController.text);
    await prefs.setString('clinic_address', _clinicAddressController.text);
    await prefs.setString('clinic_phone', _clinicPhoneController.text);
    await prefs.setString('clinic_email', _clinicEmailController.text);
    await prefs.setString('feedback_form_url', _feedbackFormUrlController.text);
    
    // Appointment
    await prefs.setInt('slot_duration', _slotDuration);
    await prefs.setInt('buffer_time', _bufferTime);
    await prefs.setString('max_appointments', _maxAppointmentsController.text);
    await prefs.setString('advance_booking', _advanceBookingController.text);
    
    // Token
    await prefs.setBool('auto_reset', _autoReset);
    await prefs.setString('token_mode', _tokenMode);
    await prefs.setString('token_prefix', _tokenPrefixController.text);
    await prefs.setString('starting_number', _startingNumberController.text);
    
    // Billing
    await prefs.setString('default_fee', _consultationFeeController.text);
    await prefs.setString('tax_percent', _taxController.text);
    
    // Notifications
    await prefs.setBool('push_notifications', _pushNotifications);
    await prefs.setBool('email_notifications', _emailNotifications);
    await prefs.setBool('sms_notifications', _smsNotifications);
    await prefs.setBool('patient_reminders', _patientReminders);
    await prefs.setBool('appointment_alerts', _appointmentAlerts);
    await prefs.setBool('payment_reminders', _paymentReminders);
    await prefs.setBool('daily_reports', _dailyReports);
    await prefs.setBool('sound', _sound);
    await prefs.setBool('vibration', _vibration);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Text('Settings saved successfully!'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),
              
              // Content
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Storage Info Section
                              _buildStorageInfoCard(),
                              const SizedBox(height: 20),
                              
                              // Profile Settings
                              _buildSectionCard(
                                title: '👨‍⚕️ Profile Settings',
                                children: [
                                  _buildTextField(_nameController, 'Full Name', Icons.person),
                                  _buildTextField(_specializationController, 'Specialization', Icons.medical_services),
                                  _buildTextField(_qualificationController, 'Qualification', Icons.school),
                                  _buildTextField(_registrationController, 'Registration Number', Icons.badge),
                                  _buildTextField(_experienceController, 'Experience (years)', Icons.timeline, isNumber: true),
                                  _buildTextField(_feeController, 'Consultation Fee (₹)', Icons.currency_rupee, isNumber: true),
                                ],
                              ),
                              const SizedBox(height: 20),
                              
                              // Clinic Settings
                              _buildSectionCard(
                                title: '🏥 Clinic Settings',
                                children: [
                                  _buildTextField(_clinicNameController, 'Clinic Name', Icons.local_hospital),
                                  _buildTextField(_clinicAddressController, 'Address', Icons.location_on),
                                  _buildTextField(_clinicPhoneController, 'Phone', Icons.phone),
                                  _buildTextField(_clinicEmailController, 'Email', Icons.email),
                                  const SizedBox(height: 8),
                                  const Divider(),
                                  const SizedBox(height: 8),
                                  // Feedback Form URL
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.amber.shade300),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Row(
                                          children: [
                                            Icon(Icons.star, color: Colors.amber, size: 20),
                                            SizedBox(width: 8),
                                            Text(
                                              '⭐ Patient Feedback Options',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        
                                        // Option 1: Google Form
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withOpacity(0.05),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.blue.shade200),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Row(
                                                children: [
                                                  Icon(Icons.link, color: Colors.blue, size: 18),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    'Option 1: Google Form (External)',
                                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              const Text(
                                                'Paste Google Form URL. QR code will be generated for clinic display.',
                                                style: TextStyle(fontSize: 11, color: Colors.grey),
                                              ),
                                              const SizedBox(height: 8),
                                              _buildTextField(_feedbackFormUrlController, 'Google Form URL', Icons.link),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        
                                        // Option 2: Built-in Form
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.purple.withOpacity(0.05),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.purple.shade200),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Row(
                                                children: [
                                                  Icon(Icons.app_registration, color: Colors.purple, size: 18),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    'Option 2: Built-in Form (In-App)',
                                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              const Text(
                                                'Use app\'s built-in feedback form. QR code will open feedback page in app.',
                                                style: TextStyle(fontSize: 11, color: Colors.grey),
                                              ),
                                              const SizedBox(height: 8),
                                              ElevatedButton.icon(
                                                onPressed: () {
                                                  // Generate built-in feedback QR
                                                  setState(() {
                                                    _showBuiltInQR = !_showBuiltInQR;
                                                  });
                                                  if (_showBuiltInQR) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(
                                                        content: Text('✅ Built-in Feedback QR Code Generated!'),
                                                        backgroundColor: Colors.green,
                                                        duration: Duration(seconds: 2),
                                                      ),
                                                    );
                                                  }
                                                },
                                                icon: Icon(_showBuiltInQR ? Icons.qr_code_scanner : Icons.qr_code, size: 18),
                                                label: Text(_showBuiltInQR ? 'Hide QR Code' : 'Generate QR for Built-in Form'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: _showBuiltInQR ? Colors.green : Colors.purple,
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // QR Code Display Section - Shows for either option
                                  if (_feedbackFormUrlController.text.isNotEmpty || _showBuiltInQR) 
                                    _buildFeedbackQRSection(),
                                ],
                              ),
                              const SizedBox(height: 20),
                              
                              // Appointment Settings
                              _buildSectionCard(
                                title: '📅 Appointment Settings',
                                children: [
                                  _buildDropdownRow(
                                    'Slot Duration',
                                    _slotDuration,
                                    [15, 20, 30, 45, 60],
                                    (value) => setState(() => _slotDuration = value!),
                                    suffix: 'min',
                                  ),
                                  _buildDropdownRow(
                                    'Buffer Time',
                                    _bufferTime,
                                    [0, 5, 10, 15],
                                    (value) => setState(() => _bufferTime = value!),
                                    suffix: 'min',
                                  ),
                                  _buildTextField(_maxAppointmentsController, 'Max Appointments/Day', Icons.event_available, isNumber: true),
                                  _buildTextField(_advanceBookingController, 'Advance Booking (days)', Icons.date_range, isNumber: true),
                                ],
                              ),
                              const SizedBox(height: 20),
                              
                              // Token Settings
                              _buildSectionCard(
                                title: '🎫 Token Settings',
                                children: [
                                  _buildTextField(_tokenPrefixController, 'Token Prefix', Icons.tag),
                                  _buildTextField(_startingNumberController, 'Starting Number', Icons.format_list_numbered, isNumber: true),
                                  _buildSwitchTile('Auto-reset Daily', _autoReset, (v) => setState(() => _autoReset = v)),
                                  const SizedBox(height: 10),
                                  _buildTokenModeSelector(),
                                ],
                              ),
                              const SizedBox(height: 20),
                              
                              // Billing Settings
                              _buildSectionCard(
                                title: '💰 Billing Settings',
                                children: [
                                  _buildTextField(_consultationFeeController, 'Default Fee (₹)', Icons.currency_rupee, isNumber: true),
                                  _buildTextField(_taxController, 'Tax/GST (%)', Icons.receipt_long, isNumber: true),
                                ],
                              ),
                              const SizedBox(height: 20),
                              
                              // Notification Settings
                              _buildSectionCard(
                                title: '🔔 Notification Settings',
                                children: [
                                  _buildSwitchTile('Push Notifications', _pushNotifications, (v) => setState(() => _pushNotifications = v)),
                                  _buildSwitchTile('Email Notifications', _emailNotifications, (v) => setState(() => _emailNotifications = v)),
                                  _buildSwitchTile('SMS Notifications', _smsNotifications, (v) => setState(() => _smsNotifications = v)),
                                  _buildSwitchTile('Patient Reminders', _patientReminders, (v) => setState(() => _patientReminders = v)),
                                  _buildSwitchTile('Appointment Alerts', _appointmentAlerts, (v) => setState(() => _appointmentAlerts = v)),
                                  _buildSwitchTile('Payment Reminders', _paymentReminders, (v) => setState(() => _paymentReminders = v)),
                                  _buildSwitchTile('Daily Reports', _dailyReports, (v) => setState(() => _dailyReports = v)),
                                  _buildSwitchTile('Sound', _sound, (v) => setState(() => _sound = v)),
                                  _buildSwitchTile('Vibration', _vibration, (v) => setState(() => _vibration = v)),
                                ],
                              ),
                              const SizedBox(height: 20),
                              
                              // Additional Features
                              _buildSectionCard(
                                title: '⚙️ Additional Features',
                                children: [
                                  _buildFeatureItem('Waiting Room Display', Icons.tv, () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => const WaitingRoomDisplay()));
                                  }),
                                  _buildFeatureItem('SMS Integration', Icons.sms, () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => const SmsIntegration()));
                                  }),
                                  _buildFeatureItem('WhatsApp Integration', Icons.chat, () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => WhatsAppIntegration()));
                                  }),
                                  _buildFeatureItem('Email Features', Icons.email, () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => const EmailFeatures()));
                                  }),
                                  _buildFeatureItem('Lab Reports', Icons.science, () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => const LabReportsManagement()));
                                  }),
                                  _buildFeatureItem('Patient Feedback', Icons.feedback, () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => const PatientFeedbackSystem()));
                                  }),
                                  _buildFeatureItem('Schedule Calendar', Icons.calendar_month, () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => const DoctorScheduleCalendar()));
                                  }),
                                ],
                              ),
                              const SizedBox(height: 20),
                              
                              // Backup & Restore Section
                              _buildBackupRestoreCard(),
                              const SizedBox(height: 20),
                              
                              // Staff Feedback Analytics Card - ONLY FOR DOCTOR
                              // Staff should not see what customers rated them
                              if (_isDoctor) _buildFeedbackAnalyticsCard(),
                              if (_isDoctor) const SizedBox(height: 30),
                              
                              // Save Button
                              _buildSaveButton(),
                              const SizedBox(height: 30),
                            ],
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 10),
          const Text(
            'Settings & Configuration',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.storage, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                '💾 Storage Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Storage Stats Grid
          Row(
            children: [
              Expanded(
                child: _buildStorageStat(
                  'Database Size',
                  '${_databaseSizeMB.toStringAsFixed(2)} MB',
                  Icons.folder,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStorageStat(
                  'Total Patients',
                  '$_totalPatients',
                  Icons.people,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStorageStat(
                  'Avg per Patient',
                  '${_averagePerPatient.toStringAsFixed(1)} KB',
                  Icons.person,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStorageStat(
                  'Est. 1 Customer',
                  '~100 KB',
                  Icons.data_usage,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Info Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white70, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    kIsWeb 
                      ? 'Web: Data stored in browser storage'
                      : '1 customer with photo ≈ 100 KB\n10,000 customers ≈ 1 GB',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Refresh Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loadStorageInfo,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Refresh Storage Info'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF667eea),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageStat(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF667eea)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF667eea), width: 2),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
      ),
    );
  }

  Widget _buildDropdownRow(String label, int value, List<int> options, Function(int?) onChanged, {String suffix = ''}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: DropdownButton<int>(
              value: value,
              underline: const SizedBox(),
              items: options.map((int v) {
                return DropdownMenuItem<int>(
                  value: v,
                  child: Text('$v $suffix'),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String label, bool value, Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF667eea),
          ),
        ],
      ),
    );
  }

  Widget _buildTokenModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Token Generation Mode',
          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
        ),
        const SizedBox(height: 8),
        Row(
          children: ['Sequential', 'Doctor-wise', 'Department-wise'].map((mode) {
            final isSelected = _tokenMode == mode;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _tokenMode = mode),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                          )
                        : null,
                    color: isSelected ? null : Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? Colors.transparent : Colors.grey[300]!,
                    ),
                  ),
                  child: Text(
                    mode.split('-').first,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected ? Colors.white : Colors.grey[600],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(String label, IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: Colors.grey[50],
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        title: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      ),
    );
  }

  Widget _buildFeedbackAnalyticsCard() {
    return FutureBuilder<Map<String, dynamic>>(
      future: DatabaseHelper.instance.getFeedbackStatistics(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final stats = snapshot.data!;
        final totalReviews = stats['totalReviews'] as int;
        final avgStaff = stats['avgStaff'] as double;
        final staffBehavior = stats['staffBehavior'] as String;
        final aiSuggestion = stats['aiSuggestion'] as String;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.analytics, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '📊 Staff Feedback Analytics',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        Text(
                          'AI-powered behavior analysis',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Stats Row
              Row(
                children: [
                  Expanded(
                    child: _buildAnalyticsStat(
                      'Total Reviews',
                      '$totalReviews',
                      Icons.rate_review,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildAnalyticsStat(
                      'Staff Rating',
                      avgStaff.toStringAsFixed(1),
                      Icons.star,
                      Colors.amber,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildAnalyticsStat(
                      'Positive',
                      '${stats['positiveCount']}',
                      Icons.thumb_up,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Staff Behavior Status
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: avgStaff >= 4.0
                        ? [Colors.green.shade100, Colors.green.shade50]
                        : avgStaff >= 3.0
                            ? [Colors.orange.shade100, Colors.orange.shade50]
                            : [Colors.red.shade100, Colors.red.shade50],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: avgStaff >= 4.0
                        ? Colors.green.shade300
                        : avgStaff >= 3.0
                            ? Colors.orange.shade300
                            : Colors.red.shade300,
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Staff Behavior Status',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      staffBehavior,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: avgStaff >= 4.0
                            ? Colors.green.shade700
                            : avgStaff >= 3.0
                                ? Colors.orange.shade700
                                : Colors.red.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // AI Suggestion Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.psychology, color: Color(0xFF8B5CF6), size: 20),
                        SizedBox(width: 8),
                        Text(
                          '🤖 AI Suggestion',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF8B5CF6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      aiSuggestion,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF1F2937),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // View All Feedback Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PatientFeedbackSystem()),
                    );
                  },
                  icon: const Icon(Icons.feedback),
                  label: const Text('Collect New Feedback'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF667eea),
                    side: const BorderSide(color: Color(0xFF667eea)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnalyticsStat(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _saveSettings,
        icon: const Icon(Icons.save, color: Colors.white),
        label: const Text(
          'SAVE SETTINGS',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  // QR Code Section for Patient Feedback
  Widget _buildFeedbackQRSection() {
    final GlobalKey _qrKey = GlobalKey();
    
    // Determine which URL to use for QR code
    final String qrData = _feedbackFormUrlController.text.isNotEmpty 
        ? _feedbackFormUrlController.text 
        : 'modi://feedback'; // Deep link for built-in form
    
    final String feedbackType = _feedbackFormUrlController.text.isNotEmpty 
        ? 'Google Form' 
        : 'Built-in App Form';
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _feedbackFormUrlController.text.isNotEmpty
              ? [const Color(0xFF667eea), const Color(0xFF764ba2)]
              : [const Color(0xFF9333EA), const Color(0xFF7C3AED)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.qr_code_2, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📱 Patient Feedback QR Code',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Type: $feedbackType',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // QR Code Display
          RepaintBoundary(
            key: _qrKey,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 200,
                    backgroundColor: Colors.white,
                    errorCorrectionLevel: QrErrorCorrectLevel.H,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '📝 Scan to Share Feedback',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _clinicNameController.text.isNotEmpty 
                        ? _clinicNameController.text 
                        : 'MODI Clinic',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: _buildQRActionButton(
                  icon: Icons.download,
                  label: 'Download',
                  onTap: () => _downloadQRCode(_qrKey),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQRActionButton(
                  icon: Icons.print,
                  label: 'Print',
                  onTap: () => _printQRCode(_qrKey),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQRActionButton(
                  icon: Icons.share,
                  label: 'Share',
                  onTap: () => _shareQRCode(_qrKey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Instructions
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white70, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Print and display this QR code at reception or waiting area for patients to scan and provide feedback',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF667eea), size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF667eea),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Download QR Code as PNG
  Future<void> _downloadQRCode(GlobalKey qrKey) async {
    try {
      RenderRepaintBoundary boundary = qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      if (kIsWeb) {
        // For web, use printing package to save/download
        await Printing.sharePdf(
          bytes: pngBytes,
          filename: 'feedback_qr_code.png',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('QR Code ready for download!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // For mobile/desktop
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/feedback_qr_code.png';
        File imgFile = File(filePath);
        await imgFile.writeAsBytes(pngBytes);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('QR Code saved to: $filePath'),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: 'Open',
                textColor: Colors.white,
                onPressed: () async {
                  final uri = Uri.file(filePath);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading QR code: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Print QR Code
  Future<void> _printQRCode(GlobalKey qrKey) async {
    try {
      RenderRepaintBoundary boundary = qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final pdf = pw.Document();
      final pdfImage = pw.MemoryImage(pngBytes);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    'Patient Feedback',
                    style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Image(pdfImage, width: 300, height: 300),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    'Scan to Share Your Feedback',
                    style: pw.TextStyle(fontSize: 24),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    _clinicNameController.text.isNotEmpty 
                        ? _clinicNameController.text 
                        : 'MODI Clinic',
                    style: const pw.TextStyle(fontSize: 18, color: PdfColors.grey),
                  ),
                ],
              ),
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error printing QR code: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Share QR Code
  Future<void> _shareQRCode(GlobalKey qrKey) async {
    try {
      RenderRepaintBoundary boundary = qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/feedback_qr_code.png';
      File imgFile = File(filePath);
      await imgFile.writeAsBytes(pngBytes);

      final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent("Scan this QR code to share your feedback about our clinic:\n${_feedbackFormUrlController.text}")}');
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing QR code: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ==================== BACKUP & RESTORE SECTION ====================
  
  Widget _buildBackupRestoreCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.green.shade600, Colors.teal.shade700],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.backup, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                '💾 Backup & Restore',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white70, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Backup includes all patients, appointments, payments, and settings.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _createBackup,
              icon: const Icon(Icons.cloud_upload, size: 20),
              label: const Text('Create Backup', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.green.shade700,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _restoreBackup,
              icon: const Icon(Icons.cloud_download, size: 20),
              label: const Text('Restore from Backup', style: TextStyle(fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white, width: 2),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createBackup() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator(color: Colors.white)),
      );
      
      final backupJson = await DatabaseHelper.instance.exportBackupData();
      final stats = await DatabaseHelper.instance.getBackupStats();
      final now = DateTime.now();
      final filename = 'modi_backup_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.json';
      
      if (kIsWeb) {
        Navigator.pop(context);
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(children: [Icon(Icons.check_circle, color: Colors.green), SizedBox(width: 10), Text('Backup Created!')]),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📦 Patients: ${stats['patients'] ?? 0}'),
                Text('📅 Appointments: ${stats['appointments'] ?? 0}'),
                const SizedBox(height: 12),
                Container(
                  height: 150,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                  child: SingleChildScrollView(child: SelectableText(backupJson, style: const TextStyle(fontSize: 9, fontFamily: 'monospace'))),
                ),
                const SizedBox(height: 8),
                const Text('Copy and save this data securely!', style: TextStyle(color: Colors.orange, fontSize: 12)),
              ],
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
          ),
        );
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$filename');
        await file.writeAsString(backupJson);
        Navigator.pop(context);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Backup saved: $filename (${stats['patients']} patients)'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      Navigator.pop(context);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _restoreBackup() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [Icon(Icons.restore, color: Colors.orange), SizedBox(width: 10), Text('Restore Backup')]),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Paste your backup JSON data below:', style: TextStyle(fontSize: 13)),
              const SizedBox(height: 12),
              TextField(controller: controller, maxLines: 8, decoration: const InputDecoration(hintText: 'Paste backup JSON...', border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, controller.text), style: ElevatedButton.styleFrom(backgroundColor: Colors.green), child: const Text('Restore', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
    if (result == null || result.isEmpty) return;
    try {
      showDialog(context: context, barrierDismissible: false, builder: (ctx) => const Center(child: CircularProgressIndicator()));
      final restoreResult = await DatabaseHelper.instance.restoreFromBackup(result);
      Navigator.pop(context);
      if (restoreResult['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ Restored ${restoreResult['patientsRestored']} patients!'), backgroundColor: Colors.green));
          _loadStorageInfo();
        }
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ ${restoreResult['error']}'), backgroundColor: Colors.red));
      }
    } catch (e) {
      Navigator.pop(context);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _specializationController.dispose();
    _qualificationController.dispose();
    _registrationController.dispose();
    _experienceController.dispose();
    _feeController.dispose();
    _clinicNameController.dispose();
    _clinicAddressController.dispose();
    _clinicPhoneController.dispose();
    _clinicEmailController.dispose();
    _maxAppointmentsController.dispose();
    _advanceBookingController.dispose();
    _tokenPrefixController.dispose();
    _startingNumberController.dispose();
    _consultationFeeController.dispose();
    _taxController.dispose();
    super.dispose();
  }
}

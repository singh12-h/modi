import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'waiting_room_display.dart';
import 'sms_integration.dart';
import 'whatsapp_integration.dart';
import 'email_features.dart';
import 'lab_reports_management.dart';
import 'patient_feedback_system.dart';
import 'doctor_schedule_calendar.dart';
import 'database_helper.dart';

class SettingsConfiguration extends StatefulWidget {
  const SettingsConfiguration({super.key});

  @override
  State<SettingsConfiguration> createState() => _SettingsConfigurationState();
}

class _SettingsConfigurationState extends State<SettingsConfiguration> {
  bool _isLoading = true;
  
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

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadStorageInfo();
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
                              const SizedBox(height: 30),
                              
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

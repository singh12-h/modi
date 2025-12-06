import 'package:flutter/material.dart';
import 'waiting_room_display.dart';
import 'sms_integration.dart';
import 'whatsapp_integration.dart';
import 'email_features.dart';
import 'lab_reports_management.dart';
import 'patient_feedback_system.dart';
import 'doctor_schedule_calendar.dart';

class SettingsConfiguration extends StatefulWidget {
  const SettingsConfiguration({super.key});

  @override
  State<SettingsConfiguration> createState() => _SettingsConfigurationState();
}

class _SettingsConfigurationState extends State<SettingsConfiguration> {
  // Profile settings
  final TextEditingController _nameController = TextEditingController(text: 'Dr. John Doe');
  final TextEditingController _specializationController = TextEditingController(text: 'Cardiologist');
  final TextEditingController _qualificationController = TextEditingController(text: 'MBBS, MD');
  final TextEditingController _registrationController = TextEditingController(text: '12345');
  final TextEditingController _experienceController = TextEditingController(text: '10');
  final TextEditingController _feeController = TextEditingController(text: '500');
  final TextEditingController _clinicNameController = TextEditingController(text: 'City Hospital');
  final TextEditingController _clinicAddressController = TextEditingController(text: '123 Main St, City');
  final TextEditingController _clinicPhoneController = TextEditingController(text: '+91-98765-43210');
  final TextEditingController _clinicEmailController = TextEditingController(text: 'clinic@example.com');

  // Appointment settings
  int _slotDuration = 30;
  int _bufferTime = 5;

  // Token settings
  bool _autoReset = true;
  String _tokenMode = 'Sequential';

  // Billing settings
  final TextEditingController _consultationFeeController = TextEditingController(text: '500');
  final TextEditingController _taxController = TextEditingController(text: '18');

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Configuration'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 12.1 PROFILE SETTINGS
            const Text(
              '12.1 Profile Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Full Name'),
            ),
            TextField(
              controller: _specializationController,
              decoration: const InputDecoration(labelText: 'Specialization'),
            ),
            TextField(
              controller: _qualificationController,
              decoration: const InputDecoration(labelText: 'Qualification'),
            ),
            TextField(
              controller: _registrationController,
              decoration: const InputDecoration(labelText: 'Medical Registration Number'),
            ),
            TextField(
              controller: _experienceController,
              decoration: const InputDecoration(labelText: 'Experience (years)'),
            ),
            TextField(
              controller: _feeController,
              decoration: const InputDecoration(labelText: 'Consultation Fee'),
            ),
            const SizedBox(height: 20),
            const Text('Clinic Settings'),
            TextField(
              controller: _clinicNameController,
              decoration: const InputDecoration(labelText: 'Clinic Name'),
            ),
            TextField(
              controller: _clinicAddressController,
              decoration: const InputDecoration(labelText: 'Address'),
            ),
            TextField(
              controller: _clinicPhoneController,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
            TextField(
              controller: _clinicEmailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 20),
            // 12.2 APPOINTMENT SETTINGS
            const Text(
              '12.2 Appointment Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text('Slot Duration:'),
                DropdownButton<int>(
                  value: _slotDuration,
                  items: [15, 20, 30].map((int value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text('$value min'),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _slotDuration = value!),
                ),
              ],
            ),
            Row(
              children: [
                const Text('Buffer Time:'),
                DropdownButton<int>(
                  value: _bufferTime,
                  items: [0, 5, 10, 15].map((int value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text('$value min'),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _bufferTime = value!),
                ),
              ],
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Max Appointments per Day'),
              keyboardType: TextInputType.number, // Value not used, but kept for UI
              onChanged: (value) {}, // Placeholder
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Advance Booking Limit (days)'),
              keyboardType: TextInputType.number, // Value not used, but kept for UI
              onChanged: (value) {}, // Placeholder
            ),
            const SizedBox(height: 20),
            // 12.3 TOKEN SETTINGS
            const Text(
              '12.3 Token Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              decoration: const InputDecoration(labelText: 'Token Prefix'),
              onChanged: (value) {}, // Placeholder
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Starting Number'),
              keyboardType: TextInputType.number,
              onChanged: (value) {}, // Placeholder
            ),
            SwitchListTile(
              title: const Text('Auto-reset Daily'),
              value: _autoReset,
              onChanged: (value) => setState(() => _autoReset = value),
            ),
            Row(
              children: [
                const Text('Token Generation Mode:'),
                DropdownButton<String>(
                  value: _tokenMode,
                  items: ['Sequential', 'Doctor-wise', 'Department-wise'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _tokenMode = value!),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // 12.4 BILLING SETTINGS
            const Text(
              '12.4 Billing Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _consultationFeeController,
              decoration: const InputDecoration(labelText: 'Default Consultation Fee'),
            ),
            TextField(
              controller: _taxController,
              decoration: const InputDecoration(labelText: 'Tax (GST %)'),
            ),
            const SizedBox(height: 20),
            // 12.5 PRESCRIPTION SETTINGS
            const Text(
              '12.5 Prescription Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text('Prescription template design, header/footer customization, digital signature upload, default instructions, disclaimer text, Rx numbering format'),
            const SizedBox(height: 20),
            // 12.6 NOTIFICATION SETTINGS
            const Text(
              '12.6 Notification Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              title: const Text('Push Notifications'),
              value: _pushNotifications,
              onChanged: (value) => setState(() => _pushNotifications = value),
            ),
            SwitchListTile(
              title: const Text('Email Notifications'),
              value: _emailNotifications,
              onChanged: (value) => setState(() => _emailNotifications = value),
            ),
            SwitchListTile(
              title: const Text('SMS Notifications'),
              value: _smsNotifications,
              onChanged: (value) => setState(() => _smsNotifications = value),
            ),
            SwitchListTile(
              title: const Text('Patient Reminders'),
              value: _patientReminders,
              onChanged: (value) => setState(() => _patientReminders = value),
            ),
            SwitchListTile(
              title: const Text('New Appointment Alert'),
              value: _appointmentAlerts,
              onChanged: (value) => setState(() => _appointmentAlerts = value),
            ),
            SwitchListTile(
              title: const Text('Payment Reminder'),
              value: _paymentReminders,
              onChanged: (value) => setState(() => _paymentReminders = value),
            ),
            SwitchListTile(
              title: const Text('Daily Report'),
              value: _dailyReports,
              onChanged: (value) => setState(() => _dailyReports = value),
            ),
            SwitchListTile(
              title: const Text('Sound'),
              value: _sound,
              onChanged: (value) => setState(() => _sound = value),
            ),
            SwitchListTile(
              title: const Text('Vibration'),
              value: _vibration,
              onChanged: (value) => setState(() => _vibration = value),
            ),
            const SizedBox(height: 20),
            // 12.7 BACKUP & SYNC
            const Text(
              '12.7 Backup & Sync',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text('Auto backup to cloud, backup frequency, restore from backup, export all data, sync across devices'),
            const SizedBox(height: 20),
            // 12.8 SECURITY SETTINGS
            const Text(
              '12.8 Security Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text('Change Password, Two-Factor Authentication, Biometric Login, Auto Logout, Session Management'),
            const SizedBox(height: 20),
            // 12.9 APP SETTINGS
            const Text(
              '12.9 App Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text('Theme, Language, Font Size, Date/Time Format, Currency'),
            const SizedBox(height: 20),
            // 12.10 ABOUT
            const Text(
              '12.10 About',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text('Version, Terms, Privacy, Help, Contact, Rate, Share'),
            const SizedBox(height: 20),
            // Additional Features Navigation
            const Text(
              'Additional Features',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildNavigationItem('Waiting Room Display', Icons.tv, () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const WaitingRoomDisplay()));
            }),
            _buildNavigationItem('SMS Integration', Icons.sms, () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SmsIntegration()));
            }),
            _buildNavigationItem('WhatsApp Integration', Icons.message, () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => WhatsAppIntegration()));
            }),
            _buildNavigationItem('Email Features', Icons.email, () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const EmailFeatures()));
            }),
            _buildNavigationItem('Lab Reports Management', Icons.description, () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const LabReportsManagement()));
            }),
            _buildNavigationItem('Patient Feedback System', Icons.feedback, () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const PatientFeedbackSystem()));
            }),
            _buildNavigationItem('Doctor Schedule Calendar', Icons.calendar_view_month, () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const DoctorScheduleCalendar()));
            }),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Settings Saved')),
                  );
                },
                child: const Text('Save Settings'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationItem(String label, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: onTap,
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
    _consultationFeeController.dispose();
    _taxController.dispose();
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import 'doctor_login_page.dart';
import 'opd_staff_dashboard.dart';
import 'appointment_management.dart';
import 'patient_search.dart';
import 'book_appointment.dart';
import 'patient_registration_form.dart';
import 'prescription_page.dart';
import 'reports_analytics.dart';
import 'medicine_database.dart';
import 'notifications_center.dart';
import 'patient_history_timeline.dart';
import 'prescription_templates.dart';
import 'voice_prescription.dart';
import 'patient_qr_code.dart';
import 'waiting_room_display.dart';
import 'sms_integration.dart';
import 'whatsapp_integration.dart';
import 'email_features.dart';
import 'lab_reports_management.dart';
import 'patient_feedback_system.dart';
import 'doctor_schedule_calendar.dart';
import 'settings_configuration.dart';

class StaffDashboard extends StatefulWidget {
  const StaffDashboard({super.key});

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const OPDStaffDashboard(),
    const AppointmentManagement(),
    const PatientSearch(),
    const BookAppointment(),
    const PatientRegistrationForm(),
    const PrescriptionPage(),
    const ReportsAnalytics(),
    const MedicineDatabase(),
    const NotificationsCenter(),
    const PatientHistoryTimeline(),
    const PrescriptionTemplates(),
    const VoicePrescription(),
    const PatientQrCode(),
    const WaitingRoomDisplay(),
    const SmsIntegration(),
    WhatsAppIntegration(),
    const EmailFeatures(),
    const LabReportsManagement(),
    const PatientFeedbackSystem(),
    const DoctorScheduleCalendar(),
    const SettingsConfiguration(),
  ];

  final List<String> _pageTitles = [
    'OPD Staff Dashboard',
    'Appointment Management',
    'Patient Search',
    'Book Appointment',
    'Patient Registration',
    'Prescription',
    'Reports & Analytics',
    'Medicine Database',
    'Notifications Center',
    'Patient History Timeline',
    'Prescription Templates',
    'Voice Prescription',
    'Patient QR Code',
    'Waiting Room Display',
    'SMS Integration',
    'WhatsApp Integration',
    'Email Features',
    'Lab Reports Management',
    'Patient Feedback System',
    'Doctor Schedule Calendar',
    'Settings Configuration',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.teal,
              ),
              child: Text(
                'Staff Dashboard',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('OPD Staff Dashboard'),
              selected: _selectedIndex == 0,
              onTap: () => _onItemTapped(0),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Appointment Management'),
              selected: _selectedIndex == 1,
              onTap: () => _onItemTapped(1),
            ),
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Patient Search'),
              selected: _selectedIndex == 2,
              onTap: () => _onItemTapped(2),
            ),
            ListTile(
              leading: const Icon(Icons.book_online),
              title: const Text('Book Appointment'),
              selected: _selectedIndex == 3,
              onTap: () => _onItemTapped(3),
            ),
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Patient Registration'),
              selected: _selectedIndex == 4,
              onTap: () => _onItemTapped(4),
            ),
            ListTile(
              leading: const Icon(Icons.receipt),
              title: const Text('Prescription'),
              selected: _selectedIndex == 5,
              onTap: () => _onItemTapped(5),
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Reports & Analytics'),
              selected: _selectedIndex == 6,
              onTap: () => _onItemTapped(6),
            ),
            ListTile(
              leading: const Icon(Icons.local_pharmacy),
              title: const Text('Medicine Database'),
              selected: _selectedIndex == 7,
              onTap: () => _onItemTapped(7),
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notifications Center'),
              selected: _selectedIndex == 8,
              onTap: () => _onItemTapped(8),
            ),
            ListTile(
              leading: const Icon(Icons.timeline),
              title: const Text('Patient History Timeline'),
              selected: _selectedIndex == 9,
              onTap: () => _onItemTapped(9),
            ),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('Prescription Templates'),
              selected: _selectedIndex == 10,
              onTap: () => _onItemTapped(10),
            ),
            ListTile(
              leading: const Icon(Icons.mic),
              title: const Text('Voice Prescription'),
              selected: _selectedIndex == 11,
              onTap: () => _onItemTapped(11),
            ),
            ListTile(
              leading: const Icon(Icons.qr_code),
              title: const Text('Patient QR Code'),
              selected: _selectedIndex == 12,
              onTap: () => _onItemTapped(12),
            ),
            ListTile(
              leading: const Icon(Icons.tv),
              title: const Text('Waiting Room Display'),
              selected: _selectedIndex == 13,
              onTap: () => _onItemTapped(13),
            ),
            ListTile(
              leading: const Icon(Icons.sms),
              title: const Text('SMS Integration'),
              selected: _selectedIndex == 14,
              onTap: () => _onItemTapped(14),
            ),
            ListTile(
              leading: const Icon(Icons.message),
              title: const Text('WhatsApp Integration'),
              selected: _selectedIndex == 15,
              onTap: () => _onItemTapped(15),
            ),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Email Features'),
              selected: _selectedIndex == 16,
              onTap: () => _onItemTapped(16),
            ),
            ListTile(
              leading: const Icon(Icons.science),
              title: const Text('Lab Reports Management'),
              selected: _selectedIndex == 17,
              onTap: () => _onItemTapped(17),
            ),
            ListTile(
              leading: const Icon(Icons.feedback),
              title: const Text('Patient Feedback System'),
              selected: _selectedIndex == 18,
              onTap: () => _onItemTapped(18),
            ),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Doctor Schedule Calendar'),
              selected: _selectedIndex == 19,
              onTap: () => _onItemTapped(19),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings Configuration'),
              selected: _selectedIndex == 20,
              onTap: () => _onItemTapped(20),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            if (_selectedIndex != 0)
              Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _pageTitles[_selectedIndex],
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const DoctorLoginPage()),
                        (Route<dynamic> route) => false,
                      );
                    },
                  ),
                ],
              ),
            ),
            // Body
            Expanded(
              child: _pages[_selectedIndex],
            ),
          ],
        ),
      ),
    );
  }
}

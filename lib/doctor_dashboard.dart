import 'dart:ui';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:modi/appointment_management.dart';
import 'package:modi/patient_search.dart';
import 'package:modi/prescription_page.dart';
import 'package:modi/reports_analytics.dart';
import 'package:modi/medicine_database.dart';
import 'package:modi/notifications_center.dart';
import 'package:modi/sms_integration.dart';
import 'package:modi/whatsapp_integration.dart';
import 'package:modi/email_features.dart';
import 'package:modi/patient_feedback_system.dart';
import 'package:modi/doctor_schedule_calendar.dart';
import 'package:modi/patient_history_timeline.dart';
import 'package:modi/database_helper.dart';
import 'package:modi/book_appointment.dart';
import 'package:modi/appointment_verification_list.dart';
import 'package:modi/patient_detail_view.dart';
import 'package:modi/models.dart';
import 'package:modi/patient_registration_form.dart';
import 'package:modi/login_selection_page.dart';
import 'package:modi/patient_qr_code.dart';
import 'package:modi/waiting_room_display.dart';

import 'package:modi/payment_management.dart';
import 'package:modi/payment_installment_screen.dart';
import 'package:modi/staff_management.dart';
import 'package:modi/settings_configuration.dart';
import 'package:modi/lab_reports_management.dart';
import 'package:modi/doctor_schedule_calendar.dart';
import 'package:modi/follow_up_appointments.dart';
import 'package:modi/birthday_notification_widget.dart';

class MenuItem {
  final IconData icon;
  final String label;
  final String? route;

  MenuItem({
    required this.icon,
    required this.label,
    this.route,
  });
}

class Responsive extends StatelessWidget {
  final Widget mobile;
  final Widget tablet;
  final Widget desktop;

  const Responsive({
    super.key,
    required this.mobile,
    required this.tablet,
    required this.desktop,
  });

  static bool isMobile(BuildContext context) => MediaQuery.of(context).size.width < 600;
  static bool isTablet(BuildContext context) => MediaQuery.of(context).size.width >= 600 && MediaQuery.of(context).size.width < 1100;
  static bool isDesktop(BuildContext context) => MediaQuery.of(context).size.width >= 1100;

  @override
  Widget build(BuildContext context) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet;
    return mobile;
  }
}

class DoctorDashboard extends StatefulWidget {
  final Staff? loggedInDoctor;
  
  const DoctorDashboard({super.key, this.loggedInDoctor});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late TabController _tabController;
  bool _isSidebarExpanded = false;
  String _hoveredMenuItem = '';
  int _selectedMenuIndex = 0;
  List<Patient> patients = [];
  int _notificationCount = 0;
  int _followUpCount = 0;
  
  // Getter for doctor info
  Staff? get loggedInDoctor => widget.loggedInDoctor;
  String get clinicName => loggedInDoctor?.clinicName ?? 'MODI Clinic';
  String get doctorName => loggedInDoctor?.name ?? 'Doctor';
  String get specialty => loggedInDoctor?.specialty ?? 'General Medicine';


  final List<MenuItem> _menuItems = [
    MenuItem(icon: Icons.dashboard_rounded, label: 'Dashboard', route: null),
    MenuItem(icon: Icons.people_rounded, label: 'Patients', route: 'PatientSearch'),
    MenuItem(icon: Icons.calendar_month_rounded, label: 'Appointments', route: 'AppointmentManagement'),
    MenuItem(icon: Icons.book_online_rounded, label: 'Book Appointment', route: 'BookAppointment'),
    MenuItem(icon: Icons.person_add_rounded, label: 'Patient Registration', route: 'PatientRegistrationForm'),
    MenuItem(icon: Icons.qr_code_rounded, label: 'Patient QR Code', route: 'PatientQrCode'),
    MenuItem(icon: Icons.event_repeat_rounded, label: 'Follow-up Appointments', route: 'FollowUpAppointments'),
    MenuItem(icon: Icons.payment_rounded, label: 'Payment Management', route: 'PaymentManagement'),
    MenuItem(icon: Icons.medication_rounded, label: 'Medicine Database', route: 'MedicineDatabase'),
    MenuItem(icon: Icons.tv_rounded, label: 'Waiting Room Display', route: 'WaitingRoomDisplay'),
    MenuItem(icon: Icons.sms_rounded, label: 'SMS Integration', route: 'SmsIntegration'),
    MenuItem(icon: Icons.chat_rounded, label: 'WhatsApp Integration', route: 'WhatsappIntegration'),
    MenuItem(icon: Icons.feedback_rounded, label: 'Patient Feedback', route: 'PatientFeedbackSystem'),
    MenuItem(icon: Icons.analytics_rounded, label: 'Reports & Analytics', route: 'ReportsAnalytics'),
    MenuItem(icon: Icons.people_outline_rounded, label: 'Staff Management', route: 'StaffManagement'),
    MenuItem(icon: Icons.cake_rounded, label: 'Birthday Wishes', route: 'BirthdayCalendar'),
    MenuItem(icon: Icons.settings_rounded, label: 'Settings', route: 'SettingsConfiguration'),
    MenuItem(icon: Icons.logout_rounded, label: 'Logout', route: null),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPatients();
  }

  // Load patients from database
  Future<void> _loadPatients() async {
    try {
      await _syncAppointmentsToPatients();
      final dbPatients = await DatabaseHelper.instance.getPatientsByDate(DateTime.now());
      final notifCount = await DatabaseHelper.instance.getNotificationCount();
      final followUpCount = await DatabaseHelper.instance.getPendingFollowUpsCount();
      setState(() {
        patients = dbPatients;
        _notificationCount = notifCount;
        _followUpCount = followUpCount;
      });
    } catch (e) {
      print('Error loading patients: $e');
    }
  }

  Future<void> _syncAppointmentsToPatients() async {
    final today = DateTime.now();
    final appointments = await DatabaseHelper.instance.getAppointmentsByDate(today);
    
    for (final apt in appointments) {
      // Only process confirmed appointments
      if (apt.status != 'confirmed') continue;

      bool processed = false;
      
      if (apt.patientId != null) {
        final existing = await DatabaseHelper.instance.getPatient(apt.patientId!);
        if (existing != null) {
           final regDate = existing.registeredDate ?? existing.registrationTime;
           final isToday = regDate.year == today.year && regDate.month == today.month && regDate.day == today.day;
           
           if (!isToday) {
             // Update existing patient for today's visit (Check-in)
             final updated = existing.copyWith(
               registrationTime: DateTime.now(),
               registeredDate: DateTime.now(),
               status: PatientStatus.waiting,
               isAppointment: true,
               symptoms: apt.reason,
             );
             await DatabaseHelper.instance.updatePatient(updated);
           }
           processed = true;
        }
      }
      
      if (!processed) {
        // Create new Patient record for this appointment
        final token = 'APT-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
        final patient = Patient(
          id: apt.patientId ?? DateTime.now().millisecondsSinceEpoch.toString(),
          name: apt.patientName,
          token: token,
          age: 'N/A',
          gender: 'Other',
          mobile: apt.mobile,
          symptoms: apt.reason,
          status: PatientStatus.waiting,
          registrationTime: DateTime.now(),
          registeredDate: DateTime.now(),
          isAppointment: true,
        );
        
        await DatabaseHelper.instance.insertPatient(patient);
      }
    }
  }

  // Refresh patients list
  Future<void> _refreshPatients() async {
    await _loadPatients();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _updatePatientStatus(String patientId, PatientStatus newStatus) async {
    final patient = patients.firstWhere((p) => p.id == patientId);
    
    // Create updated patient object
    final updatedPatient = patient.copyWith(status: newStatus);

    // Update in Database
    await DatabaseHelper.instance.updatePatient(updatedPatient);

    // Update local state
    setState(() {
      final index = patients.indexWhere((p) => p.id == patientId);
      if (index != -1) {
        patients[index] = updatedPatient;
      }
      
      if (newStatus == PatientStatus.inProgress) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Patient ${patient.name} is now in consultation'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  Future<void> _deletePatient(String patientId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Patient'),
        content: const Text('Are you sure you want to delete this patient? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.deletePatient(patientId);
      await _refreshPatients();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Patient deleted successfully'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSearchOverlay() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SearchOverlay(patients: patients),
    );
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginSelectionPage()),
                  (Route<dynamic> route) => false,
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Logout', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: Responsive.isMobile(context) ? _buildModernDrawer() : null,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PatientRegistrationForm(),
            ),
          );
          // Refresh patients list after registration
          if (result == true) {
            await _refreshPatients();
          }
        },
        backgroundColor: const Color(0xFFA855F7), // Neon Purple
        foregroundColor: Colors.white,
        elevation: 8,
        child: const Icon(Icons.person_add_rounded, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Responsive(
        mobile: _buildMobileLayout(),
        tablet: _buildDesktopLayout(),
        desktop: _buildDesktopLayout(),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Stack(
      children: [
        // Premium Dark Gradient Background
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0F0F23), // Very Dark Navy
                Color(0xFF1A1A3E), // Dark Purple Navy
                Color(0xFF0D1B2A), // Deep Dark Blue
              ],
            ),
          ),
        ),
        // Subtle Purple Glow
        Positioned(
          top: -50,
          right: -50,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF6B21A8).withOpacity(0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Main Content
        Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E).withOpacity(0.8),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.05),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    _buildStatsCards(),
                    _buildTabsSection(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildPatientGrid('Waiting'),
                          _buildPatientGrid('In Progress'),
                          _buildPatientGrid('Completed'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }


  // Add this method inside _DoctorDashboardState
  void _navigateToRoute(String? route) {
    if (route == null) return;
    
    print('🔵 Navigating to route: $route');
  
    Widget? page;
    switch (route) {
      case 'PatientSearch':
        page = const PatientSearch();
        break;
      case 'AppointmentManagement':
        page = const AppointmentManagement();
        break;
      case 'BookAppointment':
        page = const BookAppointment();
        break;
      case 'PatientRegistrationForm':
        page = const PatientRegistrationForm();
        break;
      case 'PrescriptionPage':
        page = const PrescriptionPage();
        break;
      case 'MedicineDatabase':
        page = const MedicineDatabase();
        break;
      case 'SmsIntegration':
        page = const SmsIntegration();
        break;
      case 'WhatsappIntegration':
        page = WhatsAppIntegration();
        break;
      case 'EmailFeatures':
        page = const EmailFeatures();
        break;
      case 'PatientFeedbackSystem':
        page = const PatientFeedbackSystem();
        break;
      case 'PatientHistoryTimeline':
        page = const PatientHistoryTimeline();
        break;
      case 'ReportsAnalytics':
        page = const ReportsAnalytics();
        break;
      case 'WaitingRoomDisplay':
        page = const WaitingRoomDisplay();
        break;
      case 'PatientQrCode':
        print('🟢 Using named route for PatientQrCode...');
        Navigator.pushNamed(context, '/patient-qr').then((_) {
          print('🟢 Returned from PatientQrCode');
        });
        break;
      case 'StaffManagement':
        page = StaffManagement(loggedInDoctor: loggedInDoctor);
        break;
      case 'PaymentManagement':
        page = const PaymentManagement();
        break;
      case 'SettingsConfiguration':
        page = const SettingsConfiguration();
        break;
      case 'LabReportsManagement':
        page = const LabReportsManagement();
        break;
      case 'DoctorScheduleCalendar':
        page = const DoctorScheduleCalendar();
        break;
      case 'FollowUpAppointments':
        page = const FollowUpAppointments();
        break;
      case 'BirthdayCalendar':
        page = const BirthdayNotificationWidget(showAsCard: false);
        break;
    }

    if (page != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => page!),
      ).then((_) => _refreshPatients());
    }
  }

  Widget _buildDesktopLayout() {
    return Stack(
      children: [
        // Premium Dark Gradient Background
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0F0F23), // Very Dark Navy
                Color(0xFF1A1A3E), // Dark Purple Navy
                Color(0xFF0D1B2A), // Deep Dark Blue
                Color(0xFF1B263B), // Dark Slate
              ],
              stops: [0.0, 0.3, 0.7, 1.0],
            ),
          ),
        ),
        // Subtle Mesh Gradient Overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topLeft,
                radius: 1.5,
                colors: [
                  const Color(0xFF6B21A8).withOpacity(0.15),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.bottomRight,
                radius: 1.2,
                colors: [
                  const Color(0xFF0EA5E9).withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Decorative Circles
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFA855F7).withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -50,
          left: -50,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF22D3EE).withOpacity(0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Main Content
        Row(
          children: [
            _buildModernSidebar(),
            Expanded(
              child: Column(
                children: [
                  _buildTopBar(),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.08),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A2E).withOpacity(0.7),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Column(
                              children: [
                                _buildStatsCards(),
                                _buildTabsSection(),
                                Expanded(
                                  child: TabBarView(
                                    controller: _tabController,
                                    children: [
                                      _buildPatientGrid('Waiting'),
                                      _buildPatientGrid('In Progress'),
                                      _buildPatientGrid('Completed'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }


  // All the methods from _buildModernSidebar down to the end of the file
  // should be inside the _DoctorDashboardState class.

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.isMobile(context) ? 12 : 24, 
              vertical: Responsive.isMobile(context) ? 12 : 20
            ),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                if (Responsive.isMobile(context)) ...[
                  IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white),
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.search, color: Colors.white),
                    onPressed: _showSearchOverlay,
                  ),
                ] else ...[
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: const Color(0xFF22D3EE).withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        style: const TextStyle(color: Colors.white),
                        onTap: () => _showSearchOverlay(),
                        readOnly: true,
                        decoration: InputDecoration(
                          hintText: 'Search patients, medicines...',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                          border: InputBorder.none,
                          icon: Icon(Icons.search, color: Colors.white.withOpacity(0.8)),
                        ),
                      ),
                    ),
                  ),
                ],
                
                const SizedBox(width: 8),
                
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const FollowUpAppointments()),
                    );
                  },
                  child: _buildTopBarIcon(Icons.event_available, _followUpCount),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const NotificationsCenter()),
                    );
                  },
                  child: _buildTopBarIcon(Icons.notifications_rounded, _notificationCount),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AppointmentVerificationList()),
                    );
                    _refreshPatients();
                  },
                  child: _buildTopBarIcon(Icons.how_to_reg, 0),
                ),
                
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBarIcon(IconData icon, int badge) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        if (badge > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                badge.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatsCards() {
    // Calculate live stats
    final totalPatients = patients.length; // All patients in database
    final todayStart = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    
    // Today's new registrations (patients registered today)
    final todaysNewPatients = patients.where((p) {
      final regDate = p.registeredDate ?? p.registrationTime;
      return regDate.isAfter(todayStart) && regDate.isBefore(todayEnd);
    }).length;
    
    // Currently in progress
    final inProgressCount = patients.where((p) => p.status == PatientStatus.inProgress).length;
    
    // Today's completed consultations
    final todaysCompleted = patients.where((p) {
      if (p.status != PatientStatus.completed) return false;
      final regDate = p.registeredDate ?? p.registrationTime;
      return regDate.isAfter(todayStart) && regDate.isBefore(todayEnd);
    }).length;

    final stats = [
      {
        'title': 'Total Patients',
        'value': totalPatients.toString(),
        'icon': Icons.people_rounded,
        'color': const Color(0xFFA855F7), // Neon Purple
        'gradient': const LinearGradient(colors: [Color(0xFFA855F7), Color(0xFFEC4899)]), // Purple to Pink
      },
      {
        'title': "Today's New",
        'value': todaysNewPatients.toString(),
        'icon': Icons.person_add_rounded,
        'color': const Color(0xFFEC4899), // Hot Pink
        'gradient': const LinearGradient(colors: [Color(0xFFEC4899), Color(0xFFDC2626)]), // Pink to Red
      },
      {
        'title': 'In Progress',
        'value': inProgressCount.toString(),
        'icon': Icons.healing_rounded,
        'color': const Color(0xFF22D3EE), // Electric Cyan
        'gradient': const LinearGradient(colors: [Color(0xFF22D3EE), Color(0xFF0EA5E9)]), // Cyan to Blue
      },
      {
        'title': "Today's Done",
        'value': todaysCompleted.toString(),
        'icon': Icons.check_circle_rounded,
        'color': const Color(0xFF10B981), // Neon Green
        'gradient': const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]), // Green to Emerald
      },
    ];

    if (Responsive.isMobile(context)) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildSingleStatCard(stats[0], isCompact: true)),
                Expanded(child: _buildSingleStatCard(stats[1], isCompact: true)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildSingleStatCard(stats[2], isCompact: true)),
                Expanded(child: _buildSingleStatCard(stats[3], isCompact: true)),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: stats.map((stat) {
          return Expanded(
            child: _buildSingleStatCard(stat),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSingleStatCard(Map<String, dynamic> stat, {bool isCompact = false}) {
    return MouseRegion(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(horizontal: 4), // Reduced margin
        padding: EdgeInsets.all(isCompact ? 12 : 20), // Reduced padding for compact mode
        decoration: BoxDecoration(
          color: const Color(0xFF141428).withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: (stat['color'] as Color).withOpacity(0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: (stat['color'] as Color).withOpacity(0.5),
              blurRadius: isCompact ? 15 : 30, // Reduced blur
              spreadRadius: 0,
            ),
            if (!isCompact)
              BoxShadow(
                color: (stat['color'] as Color).withOpacity(0.3),
                blurRadius: 60,
                spreadRadius: 5,
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.all(isCompact ? 6 : 10), // Reduced icon padding
                  decoration: BoxDecoration(
                    gradient: stat['gradient'] as LinearGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: (stat['color'] as Color).withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(stat['icon'] as IconData, color: Colors.white, size: isCompact ? 18 : 24), // Smaller icon
                ),
                if (!isCompact)
                  Icon(Icons.trending_up, color: stat['color'] as Color, size: 20),
              ],
            ),
            SizedBox(height: isCompact ? 8 : 16),
            Text(
              stat['value'] as String,
              style: TextStyle(
                fontSize: isCompact ? 20 : 28, // Smaller font
                fontWeight: FontWeight.bold,
                color: stat['color'] as Color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              stat['title'] as String,
              style: TextStyle(
                fontSize: isCompact ? 11 : 14, // Smaller title
                color: Colors.white.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernSidebar() {
    return MouseRegion(
      onEnter: (_) => setState(() => _isSidebarExpanded = true),
      onExit: (_) => setState(() => _isSidebarExpanded = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        width: _isSidebarExpanded ? 280 : 80,
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(_isSidebarExpanded ? 24 : 0),
            bottomRight: Radius.circular(_isSidebarExpanded ? 24 : 0),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF6B21A8).withOpacity(0.8), // Deep Purple - more vibrant
                    const Color(0xFF0EA5E9).withOpacity(0.8), // Electric Blue - more vibrant
                    const Color(0xFF06B6D4).withOpacity(0.8), // Cyan - more vibrant
                  ],
                ),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(_isSidebarExpanded ? 24 : 0),
                  bottomRight: Radius.circular(_isSidebarExpanded ? 24 : 0),
                ),
                border: Border.all(
                  color: const Color(0xFFA855F7).withOpacity(0.5), // Neon Purple border
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFA855F7).withOpacity(0.3), // Neon glow
                    blurRadius: 30,
                    offset: const Offset(5, 0),
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: const Color(0xFF22D3EE).withOpacity(0.2), // Cyan glow
                    blurRadius: 60,
                    offset: const Offset(5, 0),
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    _buildSidebarHeader(),
                    const Divider(color: Colors.white24, height: 1, indent: 16, endIndent: 16),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        itemCount: _menuItems.length,
                        itemBuilder: (context, index) {
                          return _buildModernMenuItem(_menuItems[index], index);
                        },
                      ),
                    ),
                    const Divider(color: Colors.white24, height: 1, indent: 16, endIndent: 16),
                    _buildSidebarFooter(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.symmetric(horizontal: _isSidebarExpanded ? 16.0 : 12.0, vertical: 24.0),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _isSidebarExpanded
            ? Row(
                key: const ValueKey('expanded'),
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3B82F6).withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: const Color(0xFFA855F7).withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/icon/app_icon.png',
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          clinicName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Dr. $doctorName',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          specialty,
                          style: TextStyle(
                            color: Colors.cyan.shade200,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Center(
                key: const ValueKey('collapsed'),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: const Color(0xFFA855F7).withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/icon/app_icon.png',
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildMobileTabBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: const Color(0xFF1E3A8A),
        unselectedLabelColor: Colors.white,
        tabs: const [
          Tab(text: 'Waiting'),
          Tab(text: 'In Progress'),
          Tab(text: 'Completed'),
        ],
      ),
    );
  }

  Widget _buildMobilePatientList(String status) {
    final filteredPatients = patients.where((patient) {
      switch (status) {
        case 'Waiting':
          return patient.status == PatientStatus.waiting;
        case 'In Progress':
          return patient.status == PatientStatus.inProgress;
        case 'Completed':
          return patient.status == PatientStatus.completed;
        default:
          return false;
      }
    }).toList();

    if (filteredPatients.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medical_information_outlined, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No patients in $status',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredPatients.length,
      itemBuilder: (context, index) {
        final patient = filteredPatients[index];
        final isNewPatient = DateTime.now().difference(patient.registrationTime).inMinutes < 30;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isNewPatient 
                  ? const Color(0xFFA855F7).withOpacity(0.4)
                  : Colors.grey.shade200,
              width: isNewPatient ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isNewPatient
                    ? const Color(0xFFA855F7).withOpacity(0.2)
                    : Colors.grey.withOpacity(0.1),
                blurRadius: isNewPatient ? 12 : 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PatientDetailView(
                      patient: patient,
                      onStatusUpdate: (newStatus) => _updatePatientStatus(patient.id, newStatus),
                    ),
                  ),
                );
                _loadPatients();
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.blue[100],
                          child: Text(
                            patient.name[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                        ),
                        if (isNewPatient)
                          Positioned(
                            top: -4,
                            right: -4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFA855F7), Color(0xFFEC4899)],
                                ),
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFA855F7).withOpacity(0.5),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: const Text(
                                'NEW',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            patient.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E3A8A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                patient.token,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              if (isNewPatient) ...[
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 12,
                                  color: const Color(0xFFA855F7),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _getTimeAgo(patient.registrationTime),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFFA855F7),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${patient.age}y • ${patient.gender}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        _getStatusIcon(status),
                        color: _getStatusColor(status),
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernDrawer() {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header section
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
                child: Column(
                  children: [
                    // App Icon
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                          BoxShadow(
                            color: const Color(0xFFA855F7).withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/icon/app_icon.png',
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      clinicName,
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white24, height: 1, indent: 16, endIndent: 16),
              
              // Scrollable Menu Items
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: _menuItems.length,
                  itemBuilder: (context, index) {
                    final item = _menuItems[index];
                    final isSelected = _selectedMenuIndex == index;
                    
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: Icon(item.icon, color: Colors.white),
                        title: Text(
                          item.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                        onTap: () {
                          setState(() => _selectedMenuIndex = index);
                          Navigator.pop(context);
                          if (item.route != null) {
                            _navigateToRoute(item.route);
                          } else if (item.label == 'Logout') {
                            _logout(context);
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
              
              const Divider(color: Colors.white24, height: 1, indent: 16, endIndent: 16),
              
              // Footer section with User Info and Logout
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF3B82F6),
                    child: Text(
                      doctorName.isNotEmpty ? doctorName[0].toUpperCase() : 'D', 
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text('Dr. $doctorName', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text(specialty, style: const TextStyle(color: Colors.white70)),
                  trailing: IconButton(
                    icon: const Icon(Icons.logout_rounded, color: Colors.white),
                    onPressed: () {
                      Navigator.pop(context);
                      _logout(context);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabsSection() {
    // Calculate counts for each status
    final waitingCount = patients.where((p) => p.status == PatientStatus.waiting).length;
    final inProgressCount = patients.where((p) => p.status == PatientStatus.inProgress).length;
    final completedCount = patients.where((p) => p.status == PatientStatus.completed).length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF1e1e2e).withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF22D3EE).withOpacity(0.3),
            blurRadius: 25,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF22D3EE), Color(0xFF0EA5E9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF22D3EE).withOpacity(0.6),
                  blurRadius: 25,
                  spreadRadius: 3,
                ),
              ],
            ),
            indicatorPadding: const EdgeInsets.all(4),
            labelColor: Colors.black,
            unselectedLabelColor: Colors.black.withOpacity(0.6),
            labelStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            tabs: [
              _buildEnhancedTab(
                icon: Icons.schedule_rounded,
                label: 'Waiting',
                count: waitingCount,
                color: const Color(0xFFFFA726),
              ),
              _buildEnhancedTab(
                icon: Icons.healing_rounded,
                label: 'In Progress',
                count: inProgressCount,
                color: const Color(0xFF22D3EE),
              ),
              _buildEnhancedTab(
                icon: Icons.check_circle_rounded,
                label: 'Completed',
                count: completedCount,
                color: const Color(0xFF10B981),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedTab({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
  }) {
    return Tab(
      height: 70,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: color.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildPatientGrid(String status) {
    final filteredPatients = patients.where((patient) {
      switch (status) {
        case 'Waiting':
          return patient.status == PatientStatus.waiting;
        case 'In Progress':
          return patient.status == PatientStatus.inProgress;
        case 'Completed':
          return patient.status == PatientStatus.completed;
        default:
          return false;
      }
    }).toList();

    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: Responsive.isDesktop(context) ? 3 : (Responsive.isTablet(context) ? 2 : 1),
        childAspectRatio: Responsive.isMobile(context) ? 2.2 : 1.5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: filteredPatients.length,
      itemBuilder: (context, index) {
        return _buildPatientCard(filteredPatients[index], status);
      },
    );
  }

  Widget _buildPatientCard(Patient patient, String status) {
    final isNewPatient = DateTime.now().difference(patient.registrationTime).inMinutes < 30;
    final isMobile = Responsive.isMobile(context);
    
    return MouseRegion(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2E).withOpacity(0.7),
          border: Border.all(
            color: isNewPatient 
                ? const Color(0xFFA855F7).withOpacity(0.5)
                : Colors.white.withOpacity(0.15),
            width: isNewPatient ? 2 : 1.5,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isNewPatient 
                  ? const Color(0xFFA855F7).withOpacity(0.3)
                  : Colors.black.withOpacity(0.2),
              blurRadius: isNewPatient ? 20 : 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PatientDetailView(
                        patient: patient,
                        onStatusUpdate: (newStatus) => _updatePatientStatus(patient.id, newStatus),
                      ),
                    ),
                  );
                  _loadPatients();
                },
                child: Stack(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(isMobile ? 12 : 20),
                      child: isMobile ? _buildMobilePatientCardContent(patient, isNewPatient) : _buildDesktopPatientCardContent(patient, isNewPatient),
                    ),
                    if (patient.isAppointment)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.calendar_today, size: 10, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                'APPT',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobilePatientCardContent(Patient patient, bool isNewPatient) {
    return Row(
      children: [
        // Patient Photo
        Stack(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    patient.gender == 'Male' 
                      ? const Color(0xFF3B82F6) 
                      : const Color(0xFFEC4899),
                    patient.gender == 'Male' 
                      ? const Color(0xFF06B6D4) 
                      : const Color(0xFFA855F7),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: patient.photoPath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: kIsWeb
                          ? Image.network(
                              patient.photoPath!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Icon(
                                patient.gender == 'Male' ? Icons.person : Icons.person_outline,
                                color: Colors.white,
                                size: 30,
                              ),
                            )
                          : (patient.photoPath!.startsWith('assets/')
                              ? Image.asset(patient.photoPath!, fit: BoxFit.cover)
                              : Image.file(
                                  File(patient.photoPath!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Icon(
                                    patient.gender == 'Male' ? Icons.person : Icons.person_outline,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                )),
                    )
                  : Icon(
                      patient.gender == 'Male' ? Icons.person : Icons.person_outline,
                      color: Colors.white,
                      size: 30,
                    ),
            ),
            if (isNewPatient)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFA855F7), Color(0xFFEC4899)],
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'NEW',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 12),
        // Patient Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                patient.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE0E0E0),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              const SizedBox(height: 4),
              Text(
                patient.token,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.cake, size: 12, color: const Color(0xFF22D3EE)),
                  const SizedBox(width: 4),
                  Text(
                    '${patient.age}y',
                    style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11),
                  ),
                  const SizedBox(width: 12),
                  Icon(patient.gender == 'Male' ? Icons.male : Icons.female, size: 12, color: const Color(0xFF22D3EE)),
                  const SizedBox(width: 4),
                  Text(
                    patient.gender,
                    style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.phone, size: 12, color: const Color(0xFF22D3EE)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      patient.mobile,
                      style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopPatientCardContent(Patient patient, bool isNewPatient) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Patient Photo
            Stack(
              children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    patient.gender == 'Male' 
                      ? const Color(0xFF3B82F6) 
                      : const Color(0xFFEC4899),
                    patient.gender == 'Male' 
                      ? const Color(0xFF06B6D4) 
                      : const Color(0xFFA855F7),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: (patient.gender == 'Male' 
                      ? const Color(0xFF3B82F6) 
                      : const Color(0xFFEC4899)).withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: patient.photoPath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: kIsWeb
                          ? Image.network(
                              patient.photoPath!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Icon(
                                patient.gender == 'Male' ? Icons.person : Icons.person_outline,
                                color: Colors.white,
                                size: 36,
                              ),
                            )
                          : (patient.photoPath!.startsWith('assets/')
                              ? Image.asset(
                                  patient.photoPath!,
                                  fit: BoxFit.cover,
                                )
                              : Image.file(
                                  File(patient.photoPath!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Icon(
                                    patient.gender == 'Male' ? Icons.person : Icons.person_outline,
                                    color: Colors.white,
                                    size: 36,
                                  ),
                                )),
                    )
                  : Icon(
                      patient.gender == 'Male' ? Icons.person : Icons.person_outline,
                      color: Colors.white,
                      size: 36,
                    ),
            ),
            if (isNewPatient)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFA855F7), Color(0xFFEC4899)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFA855F7).withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Text(
                    'NEW',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                patient.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE0E0E0),
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    patient.token,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[400],
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                ],
              ),
            ],
          ),
        ),
      ],
    ),
    const SizedBox(height: 16),
    Divider(
      color: Colors.white.withOpacity(0.1),
      thickness: 1,
    ),
    const SizedBox(height: 8),
    Row(
      children: [
        Icon(Icons.calendar_today, size: 16, color: const Color(0xFF22D3EE)),
        const SizedBox(width: 8),
        Text('Age: ${patient.age}', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14)),
        const SizedBox(width: 16),
        Icon(patient.gender == 'Male' ? Icons.male : Icons.female, size: 16, color: const Color(0xFF22D3EE)),
        const SizedBox(width: 8),
        Text(patient.gender, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14)),
      ],
    ),
    const SizedBox(height: 8),
    Row(
      children: [
        Icon(Icons.phone, size: 16, color: const Color(0xFF22D3EE)),
        const SizedBox(width: 8),
        Text(patient.mobile, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14)),
      ],
    ),
  ],
);
  }

  Widget _buildModernMenuItem(MenuItem item, int index) {
    final isSelected = _selectedMenuIndex == index;
    final isHovered = _hoveredMenuItem == item.label && !isSelected;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredMenuItem = item.label),
      onExit: (_) => setState(() => _hoveredMenuItem = ''),
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedMenuIndex = index);
          if (item.route != null) {
            _navigateToRoute(item.route!);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
                  )
                : null,
            color: isHovered ? Colors.white.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _isSidebarExpanded
                ? Padding(
                    key: const ValueKey('expanded'),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(
                          item.icon,
                          color: isSelected ? Colors.white : Colors.white70,
                          size: 22,
                        ),
                        const SizedBox(width: 16),
                        Flexible(
                          child: Text(
                            item.label,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  )
                : Padding(
                    key: const ValueKey('collapsed'),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Center(
                      child: Icon(
                        item.icon,
                        color: isSelected ? Colors.white : Colors.white70,
                        size: 22,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarFooter() {
    return Padding( // Padding around the footer content
      padding: const EdgeInsets.all(12.0),
      child: InkWell( // Makes the entire footer area tappable for logout
        onTap: () => _logout(context), // Triggers logout dialog
        borderRadius: BorderRadius.circular(16), // Rounded corners for the ink splash
        child: Padding( // Inner padding for the content
          padding: const EdgeInsets.all(4.0),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _isSidebarExpanded
                ? Row(
                    key: const ValueKey('expanded'),
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // User Avatar
                      const CircleAvatar(
                        radius: 20,
                        backgroundColor: Color(0xFF3B82F6),
                        child: Text('JD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 12),
                      Flexible( // Prevents text overflow issues
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            // Doctor's Name
                            Text(
                              'Dr. John Doe',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 2),
                            // Logout Text/Action hint
                            Text(
                              'Logout',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : Center(
                    key: const ValueKey('collapsed'),
                    child: const CircleAvatar(
                      radius: 20,
                      backgroundColor: Color(0xFF3B82F6),
                      child: Text('JD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Waiting':
        return const Color(0xFFEC4899); // Hot Pink - more vibrant for waiting
      case 'In Progress':
        return const Color(0xFF06B6D4); // Bright Cyan - more electric
      case 'Completed':
        return const Color(0xFF10B981); // Emerald Green - vibrant success
      default:
        return Colors.grey;
    }
  }

  LinearGradient _getStatusGradient(String status) {
    switch (status) {
      case 'Waiting':
        return const LinearGradient(colors: [Color(0xFFA855F7), Color(0xFFEC4899)]); // Purple to Pink
      case 'In Progress':
        return const LinearGradient(colors: [Color(0xFF22D3EE), Color(0xFF0EA5E9)]); // Cyan to Blue
      case 'Completed':
        return const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]); // Green to Emerald
      default:
        return const LinearGradient(colors: [Colors.grey, Colors.grey]);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Waiting':
        return Icons.hourglass_empty_rounded;
      case 'In Progress':
        return Icons.healing_rounded;
      case 'Completed':
        return Icons.check_circle_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  // Get time ago string
  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  // Build mobile new patients section
  Widget _buildMobileNewPatientsSection() {
    // Get patients registered in the last hour, sorted by most recent
    final newPatients = patients
        .where((p) => DateTime.now().difference(p.registrationTime).inHours < 1)
        .toList()
      ..sort((a, b) => b.registrationTime.compareTo(a.registrationTime));

    if (newPatients.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container( // Removed const
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row( // Removed const
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFA855F7), Color(0xFFEC4899)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFA855F7).withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.fiber_new_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'New Patients',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Removed const
                    decoration: BoxDecoration(
                      color: const Color(0xFFA855F7).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${newPatients.length}',
                      style: const TextStyle(
                        fontSize: 14, // Removed const
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFA855F7),
                      ),
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () {
                  // Navigate to patient search or registration
                  _navigateToRoute('PatientSearch');
                },
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: const Text('View All'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFA855F7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: newPatients.length,
              itemBuilder: (context, index) {
                return _buildNewPatientCard(newPatients[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  // Build individual new patient card
  Widget _buildNewPatientCard(Patient patient) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6B21A8).withOpacity(0.1),
            const Color(0xFF0EA5E9).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFA855F7).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFA855F7).withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PatientDetailView(
                  patient: patient,
                  onStatusUpdate: (newStatus) => _updatePatientStatus(patient.id, newStatus),
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Patient Photo
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        patient.gender == 'Male' 
                          ? const Color(0xFF3B82F6) 
                          : const Color(0xFFEC4899),
                        patient.gender == 'Male' 
                          ? const Color(0xFF06B6D4) 
                          : const Color(0xFFA855F7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: (patient.gender == 'Male' 
                          ? const Color(0xFF3B82F6) 
                          : const Color(0xFFEC4899)).withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: patient.photoPath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            patient.photoPath!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(
                          patient.gender == 'Male' ? Icons.person : Icons.person_outline,
                          color: Colors.white,
                          size: 36,
                        ),
                ),
                const SizedBox(width: 16),
                // Patient Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        patient.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF22D3EE).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              patient.token,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0EA5E9),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getTimeAgo(patient.registrationTime),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            patient.gender == 'Male' ? Icons.male : Icons.female,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${patient.age}y',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Placeholder for FollowUpAppointments to resolve compile error
class FollowUpAppointments extends StatelessWidget {
  const FollowUpAppointments({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Follow-up Appointments')),
      body: const Center(child: Text('Follow-up Appointments Page')),
    );
  }
}

// Placeholder for PrescriptionTemplates
class PrescriptionTemplates extends StatelessWidget {
  const PrescriptionTemplates({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Prescription Templates')), body: const Center(child: Text('Prescription Templates')));
}

// Placeholder for VoicePrescription
class VoicePrescription extends StatelessWidget {
  const VoicePrescription({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Voice Prescription')), body: const Center(child: Text('Voice Prescription')));
}

// Placeholder for PatientQrCode
class PatientQrCode extends StatelessWidget {
  const PatientQrCode({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Patient QR Code')), body: const Center(child: Text('Patient QR Code')));
}

// Placeholder for LabReportsManagement
class LabReportsManagement extends StatelessWidget {
  const LabReportsManagement({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Lab Reports Management')), body: const Center(child: Text('Lab Reports Management')));
}



// Placeholder for SettingsConfiguration
class SettingsConfiguration extends StatelessWidget {
  const SettingsConfiguration({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Settings')), body: const Center(child: Text('Settings')));
}

// Search Overlay Widget
class _SearchOverlay extends StatefulWidget {
  final List<Patient> patients;

  const _SearchOverlay({required this.patients});

  @override
  State<_SearchOverlay> createState() => _SearchOverlayState();
}

class _SearchOverlayState extends State<_SearchOverlay> {
  final TextEditingController _searchController = TextEditingController();
  List<Patient> _filteredPatients = [];
  List<String> _filteredMedicines = [];
  bool _isSearching = false;

  // Sample medicine database (you can replace with actual database)
  final List<String> _allMedicines = [
    'Paracetamol 500mg',
    'Ibuprofen 400mg',
    'Amoxicillin 250mg',
    'Azithromycin 500mg',
    'Cetirizine 10mg',
    'Omeprazole 20mg',
    'Metformin 500mg',
    'Aspirin 75mg',
    'Cough Syrup',
    'Vitamin C',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    
    if (query.isEmpty) {
      setState(() {
        _filteredPatients = [];
        _filteredMedicines = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      
      // Search patients by name, mobile, or token
      _filteredPatients = widget.patients.where((patient) {
        return patient.name.toLowerCase().contains(query) ||
               patient.mobile.contains(query) ||
               patient.token.toLowerCase().contains(query);
      }).toList();

      // Search medicines
      _filteredMedicines = _allMedicines.where((medicine) {
        return medicine.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1976D2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.search, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Search',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Search TextField
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search patients or medicines...',
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF1976D2)),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => _searchController.clear(),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Results
          Expanded(
            child: _isSearching
                ? SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Patients Section
                        if (_filteredPatients.isNotEmpty) ...[
                          Row(
                            children: [
                              Icon(Icons.people, color: Colors.blue[700], size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Patients (${_filteredPatients.length})',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ..._filteredPatients.map((patient) => _buildPatientCard(patient)),
                          const SizedBox(height: 20),
                        ],
                        // Medicines Section
                        if (_filteredMedicines.isNotEmpty) ...[
                          Row(
                            children: [
                              Icon(Icons.medication, color: Colors.green[700], size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Medicines (${_filteredMedicines.length})',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ..._filteredMedicines.map((medicine) => _buildMedicineCard(medicine)),
                        ],
                        // No results
                        if (_filteredPatients.isEmpty && _filteredMedicines.isEmpty) ...[
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(40),
                              child: Column(
                                children: [
                                  Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No results found',
                                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Try searching with different keywords',
                                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search, size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'Start typing to search',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Search by patient name, mobile, or medicine',
                          style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientCard(Patient patient) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PatientDetailView(patient: patient),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.blue[100],
                backgroundImage: patient.photoPath != null
                    ? (kIsWeb
                        ? NetworkImage(patient.photoPath!) as ImageProvider
                        : FileImage(File(patient.photoPath!)))
                    : null,
                child: patient.photoPath == null
                    ? Text(
                        patient.name[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.badge, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Token: ${patient.token}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          patient.mobile,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMedicineCard(String medicine) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.medication, color: Colors.green[700], size: 20),
        ),
        title: Text(
          medicine,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        trailing: Icon(Icons.add_circle_outline, color: Colors.green[700]),
        onTap: () {
          // Can add to prescription or show details
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$medicine selected')),
          );
        },
      ),
    );
  }
}

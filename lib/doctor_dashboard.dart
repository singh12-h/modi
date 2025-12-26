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
import 'package:modi/feedback_analytics_page.dart';
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
import 'package:modi/widgets/storage_alert_widget.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'package:modi/responsive_helper.dart';
import 'package:modi/license_service.dart';
import 'package:flutter/services.dart';

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
  bool _showStorageAlert = false;
  bool _isConnected = true;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  
  // Hidden Admin Panel - 15 taps to activate
  int _secretTapCount = 0;
  DateTime? _lastTapTime;
  
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
    MenuItem(icon: Icons.storage_rounded, label: 'Storage Status', route: 'StorageAlert'),
    MenuItem(icon: Icons.cake_rounded, label: 'Birthday Wishes', route: 'BirthdayCalendar'),
    MenuItem(icon: Icons.settings_rounded, label: 'Settings', route: 'SettingsConfiguration'),
    MenuItem(icon: Icons.logout_rounded, label: 'Logout', route: null),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPatients();
    _checkStorageStatus();
    _checkConnectivity();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      _handleConnectivityChange(results);
    });
  }
  
  Future<void> _checkStorageStatus() async {
    final shouldShow = await StorageAlertService.shouldShowWarning();
    if (mounted) {
      setState(() => _showStorageAlert = shouldShow);
    }
  }

  Future<void> _checkConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    _handleConnectivityChange(results);
  }

  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final isConnected = results.isNotEmpty && !results.contains(ConnectivityResult.none);
    if (mounted && _isConnected != isConnected) {
      setState(() => _isConnected = isConnected);
      if (!isConnected) {
        _showNoInternetDialog();
      }
    }
  }

  void _showNoInternetDialog() {
    ResponsiveHelper.init(context);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        insetPadding: ResponsiveHelper.dialogPadding,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ResponsiveHelper.radiusLG)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: ResponsiveHelper.maxContentWidth,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: ResponsiveHelper.cardPadding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(ResponsiveHelper.spacingXL),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.wifi_off_rounded,
                      size: ResponsiveHelper.iconXL * 2,
                      color: Colors.red,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.spacingXL),
                  Text(
                    'No Internet Connection',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.fontXL,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E3A8A),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: ResponsiveHelper.spacingMD),
                  Text(
                    'Please check your internet connection and try again.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: ResponsiveHelper.fontMD,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.spacingXL),
                  SizedBox(
                    width: double.infinity,
                    height: ResponsiveHelper.buttonHeightMD,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _checkConnectivity();
                      },
                      icon: Icon(Icons.refresh, size: ResponsiveHelper.iconMD),
                      label: Text('Retry', style: TextStyle(fontSize: ResponsiveHelper.fontMD)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(ResponsiveHelper.radiusMD),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    _tabController.dispose();
    super.dispose();
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
  
  void _showStorageAlertDialog() {
    ResponsiveHelper.init(context);
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: ResponsiveHelper.dialogPadding,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ResponsiveHelper.radiusLG)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: ResponsiveHelper.maxContentWidth,
            maxHeight: ResponsiveHelper.hp(85),
          ),
          child: SingleChildScrollView(
            child: StorageAlertWidget(
              onDismiss: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
    );
  }

  // ==================== HIDDEN ADMIN PANEL ====================
  
  void _handleSecretTap() {
    final now = DateTime.now();
    
    // Reset if more than 500ms between taps
    if (_lastTapTime != null && now.difference(_lastTapTime!).inMilliseconds > 500) {
      _secretTapCount = 0;
    }
    
    _lastTapTime = now;
    _secretTapCount++;
    
    // Show progress hint after 10 taps
    if (_secretTapCount >= 10 && _secretTapCount < 15) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${15 - _secretTapCount} more taps...'),
          duration: const Duration(milliseconds: 300),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    
    // Trigger admin panel after 15 taps
    if (_secretTapCount >= 15) {
      _secretTapCount = 0;
      _showAdminPasswordDialog();
    }
  }

  void _showAdminPasswordDialog() {
    final passwordController = TextEditingController();
    bool obscurePassword = true;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.admin_panel_settings, color: Colors.red),
              ),
              const SizedBox(width: 12),
              const Text('🔐 Admin Access'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter admin password to access hidden features:',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: obscurePassword,
                decoration: InputDecoration(
                  hintText: 'Password',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(obscurePassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setDialogState(() => obscurePassword = !obscurePassword),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (passwordController.text == 'kripashankar') {
                  Navigator.pop(ctx);
                  _showHiddenAdminPanel();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('❌ Incorrect password'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Access', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showHiddenAdminPanel() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _HiddenAdminPage(onRefresh: _refreshPatients),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleSecretTap,
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
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
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Stack(
      children: [
        // Gray Gradient Background
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFD0D0D0), // Darker Gray
                Color(0xFFC5C5C5), // Medium Dark Gray
                Color(0xFFB8B8B8), // Dark Gray
              ],
            ),
          ),
        ),
        // Main Content with SafeArea for system notifications
        SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
            Expanded(
              child: Stack(
                children: [
                  // Main Container
                  Container(
                    margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Decorative Medical Icons/Emojis Pattern
                        Positioned(
                          top: 20,
                          left: 20,
                          child: Text('💊', style: TextStyle(fontSize: 20, color: Colors.grey.withOpacity(0.25))),
                        ),
                        Positioned(
                          top: 80,
                          right: 30,
                          child: Text('🩺', style: TextStyle(fontSize: 22, color: Colors.grey.withOpacity(0.22))),
                        ),
                        Positioned(
                          top: 150,
                          left: 50,
                          child: Text('❤️', style: TextStyle(fontSize: 18, color: Colors.grey.withOpacity(0.20))),
                        ),
                        Positioned(
                          top: 60,
                          left: 120,
                          child: Text('💉', style: TextStyle(fontSize: 16, color: Colors.grey.withOpacity(0.22))),
                        ),
                        Positioned(
                          bottom: 100,
                          right: 50,
                          child: Text('🏥', style: TextStyle(fontSize: 24, color: Colors.grey.withOpacity(0.20))),
                        ),
                        Positioned(
                          bottom: 180,
                          left: 30,
                          child: Text('💊', style: TextStyle(fontSize: 18, color: Colors.grey.withOpacity(0.22))),
                        ),
                        Positioned(
                          top: 200,
                          right: 80,
                          child: Text('🩹', style: TextStyle(fontSize: 20, color: Colors.grey.withOpacity(0.20))),
                        ),
                        Positioned(
                          bottom: 50,
                          left: 100,
                          child: Text('⚕️', style: TextStyle(fontSize: 22, color: Colors.grey.withOpacity(0.22))),
                        ),
                        Positioned(
                          top: 120,
                          right: 120,
                          child: Text('🧬', style: TextStyle(fontSize: 16, color: Colors.grey.withOpacity(0.20))),
                        ),
                        Positioned(
                          bottom: 140,
                          right: 20,
                          child: Text('💊', style: TextStyle(fontSize: 14, color: Colors.grey.withOpacity(0.22))),
                        ),
                        // Main Content
                        Column(
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
        page = const FeedbackAnalyticsPage();
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
      case 'StorageAlert':
        _showStorageAlertDialog();
        return;
    }

    if (page != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => page!),
      ).then((_) => _refreshPatients());
    }
  }

  Widget _buildDesktopLayout() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFD0D0D0), // Darker Gray
            Color(0xFFC5C5C5), // Medium Dark Gray
            Color(0xFFB8B8B8), // Dark Gray
          ],
        ),
      ),
      child: Row(
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
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Decorative Medical Icons/Emojis Pattern
                        Positioned(
                          top: 30,
                          left: 40,
                          child: Text('💊', style: TextStyle(fontSize: 28, color: Colors.grey.withOpacity(0.22))),
                        ),
                        Positioned(
                          top: 100,
                          right: 60,
                          child: Text('🩺', style: TextStyle(fontSize: 32, color: Colors.grey.withOpacity(0.20))),
                        ),
                        Positioned(
                          top: 180,
                          left: 100,
                          child: Text('❤️', style: TextStyle(fontSize: 24, color: Colors.grey.withOpacity(0.18))),
                        ),
                        Positioned(
                          top: 80,
                          left: 200,
                          child: Text('💉', style: TextStyle(fontSize: 22, color: Colors.grey.withOpacity(0.20))),
                        ),
                        Positioned(
                          bottom: 120,
                          right: 100,
                          child: Text('🏥', style: TextStyle(fontSize: 30, color: Colors.grey.withOpacity(0.18))),
                        ),
                        Positioned(
                          bottom: 200,
                          left: 60,
                          child: Text('💊', style: TextStyle(fontSize: 24, color: Colors.grey.withOpacity(0.20))),
                        ),
                        Positioned(
                          top: 250,
                          right: 180,
                          child: Text('🩹', style: TextStyle(fontSize: 26, color: Colors.grey.withOpacity(0.18))),
                        ),
                        Positioned(
                          bottom: 80,
                          left: 180,
                          child: Text('⚕️', style: TextStyle(fontSize: 28, color: Colors.grey.withOpacity(0.20))),
                        ),
                        Positioned(
                          top: 150,
                          right: 280,
                          child: Text('🧬', style: TextStyle(fontSize: 22, color: Colors.grey.withOpacity(0.18))),
                        ),
                        Positioned(
                          bottom: 160,
                          right: 40,
                          child: Text('💊', style: TextStyle(fontSize: 20, color: Colors.grey.withOpacity(0.20))),
                        ),
                        Positioned(
                          top: 60,
                          right: 350,
                          child: Text('🩺', style: TextStyle(fontSize: 18, color: Colors.grey.withOpacity(0.18))),
                        ),
                        Positioned(
                          bottom: 50,
                          left: 300,
                          child: Text('💉', style: TextStyle(fontSize: 20, color: Colors.grey.withOpacity(0.20))),
                        ),
                        // Main Content
                        Column(
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
                      ],
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


  // All the methods from _buildModernSidebar down to the end of the file
  // should be inside the _DoctorDashboardState class.

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.isMobile(context) ? 12 : 24, 
          vertical: Responsive.isMobile(context) ? 12 : 16
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF374151), // Dark gray matching sidebar
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
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
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
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
            SizedBox(width: Responsive.isMobile(context) ? 4 : 8),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FollowUpAppointments()),
                );
              },
              child: _buildTopBarIcon(Icons.event_available, _followUpCount),
            ),
            SizedBox(width: Responsive.isMobile(context) ? 4 : 8),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NotificationsCenter()),
                );
              },
              child: _buildTopBarIcon(Icons.notifications_rounded, _notificationCount),
            ),
            // Appointment verification icon - visible on all devices
            SizedBox(width: Responsive.isMobile(context) ? 4 : 8),
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
            SizedBox(width: Responsive.isMobile(context) ? 4 : 8),
            // Storage indicator - simple icon on mobile
            if (Responsive.isMobile(context))
              GestureDetector(
                onTap: _showStorageAlertDialog,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.storage_rounded, color: Colors.white, size: 20),
                ),
              )
            else
              CompactStorageIndicator(
                onTap: _showStorageAlertDialog,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBarIcon(IconData icon, int badge) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15), // Translucent white
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 22), // White icons
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
        decoration: BoxDecoration(
          color: const Color(0xFF374151), // Dark gray sidebar
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(2, 0),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildSidebarHeader(),
              Divider(color: Colors.white.withOpacity(0.2), height: 1, indent: 16, endIndent: 16),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  itemCount: _menuItems.length,
                  itemBuilder: (context, index) {
                    return _buildModernMenuItem(_menuItems[index], index);
                  },
                ),
              ),
              Divider(color: Colors.white.withOpacity(0.2), height: 1, indent: 16, endIndent: 16),
              _buildSidebarFooter(),
            ],
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
                            color: Colors.white, // White text
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Dr. $doctorName',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          specialty,
                          style: const TextStyle(
                            color: Color(0xFF60A5FA), // Light blue accent
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
    // Count patients in each status
    final waitingCount = patients.where((p) => p.status == PatientStatus.waiting).length;
    final progressCount = patients.where((p) => p.status == PatientStatus.inProgress).length;
    final completedCount = patients.where((p) => p.status == PatientStatus.completed).length;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      height: 80,
      child: Row(
        children: [
          Expanded(child: _buildStatusCard(
            icon: Icons.access_time_filled,
            label: 'Waiting',
            count: waitingCount,
            isSelected: _tabController.index == 0,
            color: const Color(0xFF3B82F6),
            onTap: () => _tabController.animateTo(0),
          )),
          const SizedBox(width: 10),
          Expanded(child: _buildStatusCard(
            icon: Icons.medical_services,
            label: 'In Progress',
            count: progressCount,
            isSelected: _tabController.index == 1,
            color: const Color(0xFF10B981),
            onTap: () => _tabController.animateTo(1),
          )),
          const SizedBox(width: 10),
          Expanded(child: _buildStatusCard(
            icon: Icons.check_circle,
            label: 'Completed',
            count: completedCount,
            isSelected: _tabController.index == 2,
            color: const Color(0xFF6B7280),
            onTap: () => _tabController.animateTo(2),
          )),
        ],
      ),
    );
  }

  Widget _buildStatusCard({
    required IconData icon,
    required String label,
    required int count,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: isSelected 
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, color.withOpacity(0.8)],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.9),
                  Colors.white.withOpacity(0.7),
                ],
              ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.grey.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                ? color.withOpacity(0.4) 
                : Colors.black.withOpacity(0.08),
              blurRadius: isSelected ? 12 : 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 28,
                    color: isSelected ? Colors.white : color,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.grey[700],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Count badge
            if (count > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : color,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: (isSelected ? Colors.black : color).withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: isSelected ? color : Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
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
          color: Color(0xFF374151), // Dark gray matching desktop sidebar
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
    final isMobile = Responsive.isMobile(context);

    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, child) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 24),
          height: isMobile ? 65 : 80,
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2E).withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              _buildCustomTabItem(0, isMobile ? 'Wait' : 'Waiting', Icons.access_time_filled_rounded, waitingCount, const Color(0xFFF59E0B)),
              _buildCustomTabItem(1, isMobile ? 'Active' : 'In Progress', Icons.medical_services_rounded, inProgressCount, const Color(0xFF06B6D4)),
              _buildCustomTabItem(2, isMobile ? 'Done' : 'Completed', Icons.check_circle_rounded, completedCount, const Color(0xFF10B981)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCustomTabItem(int index, String label, IconData icon, int count, Color color) {
    final isSelected = _tabController.index == index;
    final isMobile = Responsive.isMobile(context);
    
    return Expanded(
      child: GestureDetector(
        onTap: () => _tabController.animateTo(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          margin: EdgeInsets.all(isMobile ? 4 : 6),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            gradient: isSelected 
              ? LinearGradient(
                  colors: [color, color.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
            boxShadow: isSelected 
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 4 : 8, vertical: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        color: isSelected ? Colors.white : Colors.grey[400],
                        size: isMobile ? 18 : 22,
                      ),
                      if (count > 0) ...[
                        SizedBox(width: isMobile ? 4 : 6),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: isMobile ? 5 : 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white.withOpacity(0.25) : color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$count',
                            style: TextStyle(
                              color: isSelected ? Colors.white : color,
                              fontWeight: FontWeight.bold,
                              fontSize: isMobile ? 10 : 11,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: isMobile ? 2 : 4),
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[400],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: isMobile ? 11 : 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
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

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = Responsive.isMobile(context);
    
    // Adaptive aspect ratio based on actual screen width
    double aspectRatio;
    if (screenWidth < 350) {
      aspectRatio = 2.8; // Very small phones
    } else if (screenWidth < 400) {
      aspectRatio = 2.4; // Small phones
    } else if (isMobile) {
      aspectRatio = 2.2; // Regular phones
    } else if (Responsive.isTablet(context)) {
      aspectRatio = 1.6;
    } else {
      aspectRatio = 1.5; // Desktop
    }
    
    return GridView.builder(
      padding: EdgeInsets.all(isMobile ? 12 : 24),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: Responsive.isDesktop(context) ? 3 : (Responsive.isTablet(context) ? 2 : 1),
        childAspectRatio: aspectRatio,
        crossAxisSpacing: isMobile ? 10 : 16,
        mainAxisSpacing: isMobile ? 10 : 16,
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
    final statusColor = _getStatusColor(status);
    
    return MouseRegion(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2E).withOpacity(0.7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isNewPatient 
                ? const Color(0xFFA855F7).withOpacity(0.5)
                : Colors.white.withOpacity(0.1),
            width: isNewPatient ? 2 : 1,
          ),
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
                    // Status Strip Indicator
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 6,
                        decoration: BoxDecoration(
                          color: statusColor,
                          boxShadow: [
                            BoxShadow(
                              color: statusColor.withOpacity(0.6),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Main Content
                    Padding(
                      padding: EdgeInsets.fromLTRB(isMobile ? 20 : 28, isMobile ? 12 : 20, isMobile ? 12 : 20, isMobile ? 12 : 20),
                      child: isMobile ? _buildMobilePatientCardContent(patient, isNewPatient) : _buildDesktopPatientCardContent(patient, isNewPatient),
                    ),

                    // Status Badge (compact on mobile)
                    Positioned(
                      top: isMobile ? 8 : 12,
                      right: isMobile ? 8 : 12,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: isMobile ? 6 : 10, vertical: isMobile ? 3 : 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                          border: Border.all(color: statusColor.withOpacity(0.5)),
                        ),
                        child: isMobile 
                          ? Icon(_getStatusIcon(status), size: 14, color: statusColor)
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_getStatusIcon(status), size: 12, color: statusColor),
                                const SizedBox(width: 4),
                                Text(
                                  status.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                  ),
                                ),
                              ],
                            ),
                      ),
                    ),

                    if (patient.isAppointment)
                      Positioned(
                        top: isMobile ? 35 : 45, // Positioned below status badge
                        right: isMobile ? 8 : 12,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: isMobile ? 5 : 8, vertical: isMobile ? 2 : 4),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withOpacity(0.4),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: isMobile
                            ? const Icon(Icons.calendar_today, size: 10, color: Colors.white)
                            : const Row(
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
                  colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                )
              : null,
          color: isHovered ? Colors.white.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
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
                        color: isSelected ? Colors.white : Colors.white.withOpacity(0.8),
                        size: 22,
                      ),
                      const SizedBox(width: 16),
                      Flexible(
                        child: Text(
                          item.label,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white.withOpacity(0.9),
                            fontSize: 14,
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
                      color: isSelected ? Colors.white : Colors.white.withOpacity(0.8),
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
        return const Color(0xFFF59E0B); // Amber - consistent with tabs
      case 'In Progress':
        return const Color(0xFF06B6D4); // Bright Cyan
      case 'Completed':
        return const Color(0xFF10B981); // Emerald Green
      default:
        return Colors.grey;
    }
  }

  LinearGradient _getStatusGradient(String status) {
    switch (status) {
      case 'Waiting':
        return const LinearGradient(colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)]); // Amber Light to Dark
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

  void _onSearchChanged() async {
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
    });

    // Search patients from database (all patients, not just today's)
    try {
      final allPatients = await DatabaseHelper.instance.getAllPatients();
      final searchResults = allPatients.where((patient) {
        return patient.name.toLowerCase().contains(query) ||
               patient.mobile.contains(query) ||
               patient.token.toLowerCase().contains(query);
      }).toList();

      // Search medicines
      final medicineResults = _allMedicines.where((medicine) {
        return medicine.toLowerCase().contains(query);
      }).toList();

      if (mounted) {
        setState(() {
          _filteredPatients = searchResults;
          _filteredMedicines = medicineResults;
        });
      }
    } catch (e) {
      print('Search error: $e');
    }
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.badge, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Token: ${patient.token}',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              patient.mobile,
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
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

// ==================== HIDDEN ADMIN PAGE ====================

class _HiddenAdminPage extends StatefulWidget {
  final VoidCallback onRefresh;
  
  const _HiddenAdminPage({required this.onRefresh});

  @override
  State<_HiddenAdminPage> createState() => _HiddenAdminPageState();
}

class _HiddenAdminPageState extends State<_HiddenAdminPage> {
  Map<String, int> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await DatabaseHelper.instance.getBackupStats();
    setState(() {
      _stats = stats;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔐 Hidden Admin Panel'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.red.shade50, Colors.white],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Warning Banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade300),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning_amber, color: Colors.red, size: 30),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '⚠️ WARNING: This is a hidden admin panel. Actions here cannot be undone!',
                              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Database Stats
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('📊 Database Statistics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          _buildStatRow('👥 Patients', _stats['patients'] ?? 0),
                          _buildStatRow('📅 Appointments', _stats['appointments'] ?? 0),
                          _buildStatRow('👨‍⚕️ Staff', _stats['staff'] ?? 0),
                          _buildStatRow('💊 Prescriptions', _stats['prescriptions'] ?? 0),
                          _buildStatRow('💬 Consultations', _stats['consultations'] ?? 0),
                          _buildStatRow('💰 Payments', _stats['payments'] ?? 0),
                          _buildStatRow('⭐ Feedback', _stats['feedback'] ?? 0),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Backup Section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.green.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('💾 Backup', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _createBackup,
                              icon: const Icon(Icons.cloud_upload),
                              label: const Text('Create Full Backup'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // License Key Generator Section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.purple.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('🔑 License Key Generator', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple)),
                          const SizedBox(height: 8),
                          const Text('Generate keys for customers', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _generateLicenseKey(LicenseType.demo),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                                  child: const Text('Demo (7d)'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _generateLicenseKey(LicenseType.trial),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                                  child: const Text('Trial (30d)'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _generateLicenseKey(LicenseType.lifetime),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                  child: const Text('Lifetime'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Delete Data Section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('🗑️ Delete Data', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
                          const SizedBox(height: 12),
                          _buildDeleteButton('Delete Old Patients (30+ days)', Icons.person_remove, () => _deleteOldData('patients')),
                          const SizedBox(height: 8),
                          _buildDeleteButton('Delete Old Appointments', Icons.event_busy, () => _deleteOldData('appointments')),
                          const SizedBox(height: 8),
                          _buildDeleteButton('Clear All Feedback', Icons.feedback, () => _clearTable('feedback')),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _deleteAllData,
                              icon: const Icon(Icons.delete_forever),
                              label: const Text('⚠️ DELETE ALL DATA'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade700,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
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

  Widget _buildStatRow(String label, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('$count', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteButton(String label, IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  void _generateLicenseKey(LicenseType type) {
    final key = LicenseService.generateKey(type);
    final typeLabel = type == LicenseType.demo ? 'Demo (7 days)' 
                    : type == LicenseType.trial ? 'Trial (30 days)' 
                    : 'Lifetime';
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.key, color: Colors.purple),
            const SizedBox(width: 10),
            Text('$typeLabel Key Generated'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple.shade200),
              ),
              child: SelectableText(
                key,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  fontFamily: 'monospace',
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: key));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✅ Key copied to clipboard!'), backgroundColor: Colors.green),
                  );
                },
                icon: const Icon(Icons.copy),
                label: const Text('Copy Key'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Share this key with your customer via WhatsApp/SMS',
              style: TextStyle(fontSize: 11, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  Future<void> _createBackup() async {
    try {
      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
      final backup = await DatabaseHelper.instance.exportBackupData();
      Navigator.pop(context);
      
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('✅ Backup Created'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Total: ${(backup.length / 1024).toStringAsFixed(1)} KB'),
              const SizedBox(height: 12),
              Container(
                height: 150,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                child: SingleChildScrollView(child: SelectableText(backup, style: const TextStyle(fontSize: 8))),
              ),
            ],
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _deleteOldData(String type) async {
    final confirm = await _showConfirmDialog('Delete old $type?', 'This will delete $type older than 30 days.');
    if (confirm != true) return;
    
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Deleting old $type...'), backgroundColor: Colors.orange));
    // TODO: Implement actual deletion based on type
    await Future.delayed(const Duration(seconds: 1));
    await _loadStats();
    widget.onRefresh();
  }

  Future<void> _clearTable(String table) async {
    final confirm = await _showConfirmDialog('Clear $table?', 'All $table data will be permanently deleted.');
    if (confirm != true) return;
    
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Clearing $table...'), backgroundColor: Colors.orange));
    await Future.delayed(const Duration(seconds: 1));
    await _loadStats();
  }

  Future<void> _deleteAllData() async {
    final confirm = await _showConfirmDialog(
      '⚠️ DELETE ALL DATA?',
      'This will PERMANENTLY delete ALL patients, appointments, payments, and feedback. This action CANNOT be undone!\n\nType "DELETE" to confirm:',
      requireConfirmText: true,
    );
    if (confirm != true) return;
    
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Feature disabled for safety'), backgroundColor: Colors.orange));
  }

  Future<bool?> _showConfirmDialog(String title, String content, {bool requireConfirmText = false}) {
    final controller = TextEditingController();
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(content),
            if (requireConfirmText) ...[
              const SizedBox(height: 16),
              TextField(controller: controller, decoration: const InputDecoration(hintText: 'Type DELETE', border: OutlineInputBorder())),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (requireConfirmText && controller.text != 'DELETE') {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please type DELETE to confirm'), backgroundColor: Colors.red));
                return;
              }
              Navigator.pop(ctx, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

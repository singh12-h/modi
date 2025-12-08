import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'database_helper.dart';
import 'models.dart';
import 'patient_registration_form.dart';
import 'patient_search.dart';
import 'book_appointment.dart';
import 'payment_management.dart';
import 'payment_installment_screen.dart';
import 'sms_integration.dart';
import 'whatsapp_integration.dart';
import 'appointment_verification_list.dart';
import 'package:path_provider/path_provider.dart';
import 'staff_login_page.dart';
import 'doctor_login_page.dart';
import 'package:flutter/services.dart';
import 'birthday_notification_widget.dart';

class OPDStaffDashboard extends StatefulWidget {
  const OPDStaffDashboard({super.key});

  @override
  State<OPDStaffDashboard> createState() => _OPDStaffDashboardState();
}

class _OPDStaffDashboardState extends State<OPDStaffDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isSidebarExpanded = false;
  int _selectedMenuIndex = 0;
  String _hoveredMenuItem = '';
  
  // Data
  List<Patient> _patients = [];
  List<Patient> _waitingQueue = [];
  Patient? _currentPatient;
  final ScrollController _waitingQueueScrollController = ScrollController();
  
  // Menu Items
  final List<StaffMenuItem> _menuItems = [
    StaffMenuItem(icon: Icons.dashboard_rounded, label: 'Dashboard', route: null),
    StaffMenuItem(icon: Icons.person_add_rounded, label: 'Register Patient', route: 'PatientRegistrationForm'),
    StaffMenuItem(icon: Icons.calendar_month_rounded, label: 'Book Appointment', route: 'BookAppointment'),
    StaffMenuItem(icon: Icons.how_to_reg_rounded, label: 'Verify Appointments', route: 'AppointmentVerificationList'),
    StaffMenuItem(icon: Icons.check_circle_rounded, label: 'Completed Patients', route: 'CompletedPatientsList'),
    StaffMenuItem(icon: Icons.search_rounded, label: 'Search Patient', route: 'PatientSearch'),
    StaffMenuItem(icon: Icons.payment_rounded, label: 'Payment Management', route: 'PaymentManagement'),
    StaffMenuItem(icon: Icons.cake_rounded, label: 'Birthday Wishes', route: 'BirthdayCalendar'),
    StaffMenuItem(icon: Icons.sms_rounded, label: 'SMS Reminders', route: 'SmsIntegration'),
    StaffMenuItem(icon: Icons.chat_rounded, label: 'WhatsApp', route: 'WhatsAppIntegration'),
  ];

  @override
  void initState() {
    super.initState();
    
    // Make status bar transparent
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    
    _loadData();
    // Auto-refresh every 30 seconds
    Future.delayed(const Duration(seconds: 30), _periodicRefresh);
  }

  void _periodicRefresh() {
    if (mounted) {
      _loadData();
      Future.delayed(const Duration(seconds: 30), _periodicRefresh);
    }
  }

  Future<void> _loadData() async {
    final patients = await DatabaseHelper.instance.getAllPatients();
    setState(() {
      _patients = patients;
      _waitingQueue = patients.where((p) => p.status == PatientStatus.waiting).toList();
      _currentPatient = patients.where((p) => p.status == PatientStatus.inProgress).firstOrNull;
    });
  }

  ImageProvider? _getImageProvider(String? path) {
    if (path == null) return null;
    if (kIsWeb) {
      if (path.startsWith('data:image')) {
        try {
          return MemoryImage(base64Decode(path.split(',').last));
        } catch (e) {
          print('Error decoding base64 image: $e');
          return null;
        }
      }
      return NetworkImage(path);
    }
    if (File(path).existsSync()) {
      return FileImage(File(path));
    }
    return null;
  }

  void _navigateTo(String? route) {
    if (route == null) {
      // Handle Home
      setState(() => _selectedMenuIndex = 0); // Home
      return;
    }

    Widget page;
    switch (route) {
      case 'PatientRegistrationForm':
        page = const PatientRegistrationForm();
        break;
      case 'BookAppointment':
        page = const BookAppointment();
        break;
      case 'PatientSearch':
        page = const PatientSearch();
        break;
      case 'PaymentManagement':
        page = const PaymentManagement(isStaff: true);
        break;
      case 'SmsIntegration':
        page = const SmsIntegration();
        break;
      case 'WhatsAppIntegration':
        page = const WhatsAppIntegration();
        break;
      case 'AppointmentVerificationList':
        page = const AppointmentVerificationList();
        break;
      case 'CompletedPatientsList':
        page = const CompletedPatientsPage();
        break;
      case 'BirthdayCalendar':
        page = const BirthdayNotificationWidget(showAsCard: false);
        break;
      default:
        return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    ).then((_) => _loadData()); // Refresh on return
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = _isMobile(context);
    
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: isMobile ? Drawer(
        child: _buildSidebar(),
      ) : null,
      body: SafeArea(
        top: false, // Remove top safe area to eliminate the teal header
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isMobile) _buildSidebar(),
            Expanded(
              child: Column(
                children: [
                  _buildTopBar(),
                  Expanded(
                    child: _buildMainContent(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isMobile(BuildContext context) => MediaQuery.of(context).size.width < 800;

  Widget _buildSidebar() {
    final isMobile = _isMobile(context);
    final sidebarWidth = isMobile ? double.infinity : (_isSidebarExpanded ? 260.0 : 75.0);
    
    return MouseRegion(
      onEnter: isMobile ? null : (_) => setState(() => _isSidebarExpanded = true),
      onExit: isMobile ? null : (_) => setState(() => _isSidebarExpanded = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: sidebarWidth,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E3A8A), // Deep blue
              Color(0xFF3B82F6), // Bright blue
              Color(0xFF60A5FA), // Light blue
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(4, 0),
            ),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Logo Area with Animation
            Padding(
              padding: EdgeInsets.symmetric(horizontal: _isSidebarExpanded ? 10 : 8),
              child: _isSidebarExpanded
                  ? ClipRect(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const NeverScrollableScrollPhysics(),
                        child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFFFFF), Color(0xFFE0F2FE)],
                              ),
                              borderRadius: BorderRadius.circular(11),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.3),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.local_hospital_rounded,
                              color: Color(0xFF1E3A8A),
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 160, // Fixed width for text area
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'MODI CLINIC',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1.1,
                                  ),
                                  overflow: TextOverflow.clip,
                                  maxLines: 1,
                                  softWrap: false,
                                ),
                                Text(
                                  'Staff Portal',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white.withOpacity(0.8),
                                    letterSpacing: 0.4,
                                  ),
                                  overflow: TextOverflow.clip,
                                  maxLines: 1,
                                  softWrap: false,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  : Center(
                      child: Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFFFFF), Color(0xFFE0F2FE)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.local_hospital_rounded,
                          color: Color(0xFF1E3A8A),
                          size: 28,
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 30),
            
            // Divider with gradient
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.0),
                    Colors.white.withOpacity(0.3),
                    Colors.white.withOpacity(0.0),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Menu Items - Now Scrollable!
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    children: List.generate(_menuItems.length, (index) {
                      final item = _menuItems[index];
                      final isSelected = _selectedMenuIndex == index;
                      final isHovered = _hoveredMenuItem == item.label;

                      return MouseRegion(
                        onEnter: (_) => setState(() => _hoveredMenuItem = item.label),
                        onExit: (_) => setState(() => _hoveredMenuItem = ''),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                if (item.route != null) {
                                  _navigateTo(item.route);
                                } else {
                                  setState(() => _selectedMenuIndex = index);
                                }
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                                decoration: BoxDecoration(
                                  color: isSelected 
                                      ? Colors.white.withOpacity(0.2)
                                      : isHovered
                                          ? Colors.white.withOpacity(0.1)
                                          : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected 
                                        ? Colors.white.withOpacity(0.3)
                                        : Colors.transparent,
                                    width: 1,
                                  ),
                                ),
                                child: (isMobile || _isSidebarExpanded)
                                    ? LayoutBuilder(
                                        builder: (context, constraints) {
                                          return SizedBox(
                                            width: isMobile ? double.infinity : 220,
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  item.icon,
                                                  color: Colors.white,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    item.label,
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                                      fontSize: 13,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      )
                                    : Center(
                                        child: Icon(
                                          item.icon,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
            
            // Bottom decoration
            if (_isSidebarExpanded)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),
                child: ClipRect(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.info_outline,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 140, // Fixed width for version text
                        child: Text(
                          'v1.0.0',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 10,
                          ),
                          overflow: TextOverflow.clip,
                          maxLines: 1,
                          softWrap: false,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final isMobile = _isMobile(context);
    final isVerySmall = MediaQuery.of(context).size.width < 600;
    
    return Container(
      height: 70,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          if (isMobile)
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
          Expanded(
            child: Text(
              'OPD Staff Dashboard',
              style: TextStyle(
                fontSize: isMobile ? 18 : 20,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Date and Time Section - Always visible
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                DateFormat(isMobile ? 'd MMM' : 'EEE, d MMM y').format(DateTime.now()),
                style: TextStyle(
                  color: Colors.grey[800],
                  fontSize: isMobile ? 12 : 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                DateFormat('h:mm a').format(DateTime.now()),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: isMobile ? 11 : 12,
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const DoctorLoginPage()),
                  (Route<dynamic> route) => false,
                );
              }
            },
            child: CircleAvatar(
              radius: isMobile ? 18 : 20,
              backgroundColor: const Color(0xFF0EA5E9),
              child: Icon(
                Icons.person,
                color: Colors.white,
                size: isMobile ? 20 : 24,
              ),
            ),
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'profile',
                child: ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Profile'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Logout'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    // If we are on the "Dashboard" tab (index 0), show the dashboard widgets
    // Other tabs are handled by navigation push, so we only render Dashboard here
    if (_selectedMenuIndex != 0) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Row - Responsive
          _isMobile(context)
              ? Column(
                  children: [
                    _buildStatCard('Waiting', '${_waitingQueue.length}', Icons.people, Colors.orange),
                    const SizedBox(height: 12),
                    _buildStatCard('Total Today', '${_patients.length}', Icons.today, Colors.blue),
                    const SizedBox(height: 12),
                    _buildStatCard('In Progress', _currentPatient != null ? '1' : '0', Icons.medical_services, Colors.green),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _buildStatCard('Waiting', '${_waitingQueue.length}', Icons.people, Colors.orange)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildStatCard('Total Today', '${_patients.length}', Icons.today, Colors.blue)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildStatCard('In Progress', _currentPatient != null ? '1' : '0', Icons.medical_services, Colors.green)),
                  ],
                ),
          const SizedBox(height: 24),
          
          // Current Patient & Queue - Responsive
          _isMobile(context)
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Current Patient Card
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Colors.black,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(26),
                        child: Stack(
                          children: [
                            // Animated Gradient Background
                            // Animated Gradient Background
                        Positioned.fill(
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF667EEA), // Purple-blue
                                  Color(0xFF764BA2), // Purple
                                  Color(0xFFF093FB), // Pink
                                  Color(0xFF4FACFE), // Light blue
                                ],
                                stops: [0.0, 0.3, 0.7, 1.0],
                              ),
                            ),
                          ),
                        ),
                        
                        // Animated circles/particles
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
                                  Colors.white.withOpacity(0.1),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -30,
                          left: -30,
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Colors.white.withOpacity(0.08),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                        // Glass morphism overlay
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withOpacity(0.1),
                                  Colors.white.withOpacity(0.05),
                                ],
                              ),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(26),
                            ),
                          ),
                        ),
                        
                        // Content
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // NOW SERVING Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.4),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        gradient: const RadialGradient(
                                          colors: [
                                            Color(0xFF22C55E), // Bright green center
                                            Color(0xFF16A34A), // Dark green edge
                                          ],
                                        ),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF22C55E).withOpacity(0.8),
                                            blurRadius: 8,
                                            spreadRadius: 2,
                                          ),
                                          BoxShadow(
                                            color: const Color(0xFF16A34A).withOpacity(0.6),
                                            blurRadius: 12,
                                            spreadRadius: 3,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ShaderMask(
                                      shaderCallback: (bounds) => const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color(0xFFFFFFFF), // Pure white
                                          Color(0xFFFFF0F5), // Lavender blush
                                          Color(0xFFFFB6C1), // Light pink
                                          Color(0xFFFF69B4), // Hot pink
                                          Color(0xFFDA70D6), // Orchid
                                          Color(0xFF9370DB), // Medium purple
                                        ],
                                        stops: [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
                                      ).createShader(bounds),
                                      child: const Text(
                                        'NOW SERVING',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.5,
                                          color: Colors.white,
                                          shadows: [
                                            // 3D Effect - Multiple shadow layers
                                            Shadow(
                                              color: Color(0xFF000000),
                                              blurRadius: 1,
                                              offset: Offset(1, 1),
                                            ),
                                            Shadow(
                                              color: Color(0xFF000000),
                                              blurRadius: 2,
                                              offset: Offset(2, 2),
                                            ),
                                            Shadow(
                                              color: Color(0xFF000000),
                                              blurRadius: 3,
                                              offset: Offset(3, 3),
                                            ),
                                            Shadow(
                                              color: Color(0xFF000000),
                                              blurRadius: 4,
                                              offset: Offset(4, 4),
                                            ),
                                            // Premium glow effects
                                            Shadow(
                                              color: Color(0xFFFF69B4),
                                              blurRadius: 10,
                                              offset: Offset(0, 0),
                                            ),
                                            Shadow(
                                              color: Color(0xFF9370DB),
                                              blurRadius: 15,
                                              offset: Offset(0, 0),
                                            ),
                                            Shadow(
                                              color: Color(0xFFFFFFFF),
                                              blurRadius: 20,
                                              offset: Offset(0, 0),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Patient Photo with glow - Centered
                              Center(
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.3),
                                        blurRadius: 20,
                                        spreadRadius: 6,
                                      ),
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 3,
                                      ),
                                      image: _getImageProvider(_currentPatient?.photoPath) != null
                                          ? DecorationImage(
                                              image: _getImageProvider(_currentPatient!.photoPath!)!,
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                      gradient: _getImageProvider(_currentPatient?.photoPath) == null
                                          ? const LinearGradient(
                                              colors: [Color(0xFFE0E7FF), Color(0xFFC7D2FE)],
                                            )
                                          : null,
                                    ),
                                    child: _getImageProvider(_currentPatient?.photoPath) == null
                                        ? const Icon(
                                            Icons.person_rounded,
                                            size: 50,
                                            color: Color(0xFF6366F1),
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 12),
                              
                              // Patient Name with 3D Gradient - Centered
                              ShaderMask(
                                shaderCallback: (bounds) => const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFFFFFFFF), // Pure white
                                    Color(0xFFF8F8FF), // Ghost white
                                    Color(0xFFE6E6FA), // Lavender
                                    Color(0xFFDDA0DD), // Plum
                                    Color(0xFFBA55D3), // Medium orchid
                                    Color(0xFF8B008B), // Dark magenta
                                  ],
                                  stops: [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
                                ).createShader(bounds),
                                child: Text(
                                  _currentPatient?.name ?? 'No Patient',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    shadows: [
                                      // 3D depth shadows
                                      Shadow(
                                        color: Color(0xFF000000),
                                        blurRadius: 2,
                                        offset: Offset(1, 1),
                                      ),
                                      Shadow(
                                        color: Color(0xFF000000),
                                        blurRadius: 3,
                                        offset: Offset(2, 2),
                                      ),
                                      Shadow(
                                        color: Color(0xFF000000),
                                        blurRadius: 4,
                                        offset: Offset(3, 3),
                                      ),
                                      Shadow(
                                        color: Color(0xFF000000),
                                        blurRadius: 5,
                                        offset: Offset(4, 4),
                                      ),
                                      // Premium glow effects
                                      Shadow(
                                        color: Color(0xFFBA55D3),
                                        blurRadius: 12,
                                        offset: Offset(0, 0),
                                      ),
                                      Shadow(
                                        color: Color(0xFFFFFFFF),
                                        blurRadius: 18,
                                        offset: Offset(0, 0),
                                      ),
                                      Shadow(
                                        color: Color(0xFF9370DB),
                                        blurRadius: 25,
                                        offset: Offset(0, 0),
                                      ),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              
                              const SizedBox(height: 10),
                              
                              // Token Badge - Centered
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Colors.white, Color(0xFFF3F4F6)],
                                  ),
                                  borderRadius: BorderRadius.circular(25),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 12,
                                      offset: const Offset(0, 5),
                                    ),
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.5),
                                      blurRadius: 8,
                                      offset: const Offset(0, -2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.confirmation_number_rounded,
                                        color: Colors.white,
                                        size: 15,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Token: ${_currentPatient?.token ?? "--"}',
                                      style: const TextStyle(
                                        color: Color(0xFF1F2937),
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
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
                ),
                const SizedBox(height: 16),
                    
                    // Waiting Queue Card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.people_alt_rounded, color: Color(0xFF1E3A8A), size: 28),
                                    SizedBox(width: 12),
                                    Text(
                                      'Waiting Queue',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E3A8A),
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.orange[400]!, Colors.orange[600]!],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.orange.withOpacity(0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    '${_waitingQueue.length} Waiting',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Divider(height: 1, color: Colors.grey[200]),
                          SizedBox(
                            height: 320, // Height for approx 3 items
                            child: Scrollbar(
                              controller: _waitingQueueScrollController,
                              thumbVisibility: true,
                              trackVisibility: true,
                              child: ListView.separated(
                            controller: _waitingQueueScrollController,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: _waitingQueue.length,
                            separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[100]),
                            itemBuilder: (context, index) {
                              final patient = _waitingQueue[index];
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [Colors.blue[300]!, Colors.blue[500]!],
                                        ),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.blue.withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                        image: _getImageProvider(patient.photoPath) != null
                                            ? DecorationImage(
                                                image: _getImageProvider(patient.photoPath)!,
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                      ),
                                      child: _getImageProvider(patient.photoPath) == null
                                          ? Center(
                                              child: Text(
                                                patient.name[0].toUpperCase(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 20,
                                                ),
                                              ),
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            patient.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Token: ${patient.token}',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.orange[50],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.orange[200]!),
                                      ),
                                      child: Text(
                                        'Waiting',
                                        style: TextStyle(
                                          color: Colors.orange[700],
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      ],
                      ),
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: Colors.black, width: 2),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 30, offset: const Offset(0, 15), spreadRadius: 5)],
                      ),
                      child: ClipRRect(borderRadius: BorderRadius.circular(26), child: Stack(children: [
                        Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF667EEA), Color(0xFF764BA2), Color(0xFFF093FB), Color(0xFF4FACFE)], stops: [0.0, 0.3, 0.7, 1.0]))),
                        Positioned(top: -50, right: -50, child: Container(width: 200, height: 200, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [Colors.white.withOpacity(0.1), Colors.transparent])))),
                        Positioned(bottom: -30, left: -30, child: Container(width: 150, height: 150, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [Colors.white.withOpacity(0.08), Colors.transparent])))),
                        Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)]), border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5), borderRadius: BorderRadius.circular(26))),
                        Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [
                          Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 3))]), child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Container(width: 8, height: 8, decoration: BoxDecoration(gradient: const RadialGradient(colors: [Color(0xFF22C55E), Color(0xFF16A34A)]), shape: BoxShape.circle, boxShadow: [BoxShadow(color: const Color(0xFF22C55E).withOpacity(0.8), blurRadius: 8, spreadRadius: 2), BoxShadow(color: const Color(0xFF16A34A).withOpacity(0.6), blurRadius: 12, spreadRadius: 3)])),
                            const SizedBox(width: 8),
                            ShaderMask(shaderCallback: (bounds) => const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFFFFFF), Color(0xFFFFF0F5), Color(0xFFFFB6C1), Color(0xFFFF69B4), Color(0xFFDA70D6), Color(0xFF9370DB)], stops: [0.0, 0.2, 0.4, 0.6, 0.8, 1.0]).createShader(bounds), child: const Text('NOW SERVING', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.white, shadows: [Shadow(color: Color(0xFF000000), blurRadius: 1, offset: Offset(1, 1)), Shadow(color: Color(0xFF000000), blurRadius: 2, offset: Offset(2, 2)), Shadow(color: Color(0xFF000000), blurRadius: 3, offset: Offset(3, 3)), Shadow(color: Color(0xFF000000), blurRadius: 4, offset: Offset(4, 4)), Shadow(color: Color(0xFFFF69B4), blurRadius: 10, offset: Offset(0, 0)), Shadow(color: Color(0xFF9370DB), blurRadius: 15, offset: Offset(0, 0)), Shadow(color: Color(0xFFFFFFFF), blurRadius: 20, offset: Offset(0, 0))]))),
                          ])),
                          const SizedBox(height: 16),
                          Center(child: Container(width: 100, height: 100, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.3), blurRadius: 20, spreadRadius: 6), BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 6))]), child: Container(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3), image: _getImageProvider(_currentPatient?.photoPath) != null ? DecorationImage(image: _getImageProvider(_currentPatient!.photoPath!)!, fit: BoxFit.cover) : null, gradient: _getImageProvider(_currentPatient?.photoPath) == null ? const LinearGradient(colors: [Color(0xFFE0E7FF), Color(0xFFC7D2FE)]) : null), child: _getImageProvider(_currentPatient?.photoPath) == null ? const Icon(Icons.person_rounded, size: 50, color: Color(0xFF6366F1)) : null))),
                          const SizedBox(height: 12),
                          ShaderMask(shaderCallback: (bounds) => const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFFFFFF), Color(0xFFF8F8FF), Color(0xFFE6E6FA), Color(0xFFDDA0DD), Color(0xFFBA55D3), Color(0xFF8B008B)], stops: [0.0, 0.2, 0.4, 0.6, 0.8, 1.0]).createShader(bounds), child: Text(_currentPatient?.name ?? 'No Patient', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, shadows: [Shadow(color: Color(0xFF000000), blurRadius: 2, offset: Offset(1, 1)), Shadow(color: Color(0xFF000000), blurRadius: 3, offset: Offset(2, 2)), Shadow(color: Color(0xFF000000), blurRadius: 4, offset: Offset(3, 3)), Shadow(color: Color(0xFF000000), blurRadius: 5, offset: Offset(4, 4)), Shadow(color: Color(0xFFBA55D3), blurRadius: 12, offset: Offset(0, 0)), Shadow(color: Color(0xFFFFFFFF), blurRadius: 18, offset: Offset(0, 0)), Shadow(color: Color(0xFF9370DB), blurRadius: 25, offset: Offset(0, 0))]), textAlign: TextAlign.center)),
                          const SizedBox(height: 10),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Colors.white, Color(0xFFF3F4F6)]), borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 5)), BoxShadow(color: Colors.white.withOpacity(0.5), blurRadius: 8, offset: const Offset(0, -2))]), child: Row(mainAxisSize: MainAxisSize.min, children: [Container(padding: const EdgeInsets.all(5), decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]), shape: BoxShape.circle), child: const Icon(Icons.confirmation_number_rounded, color: Colors.white, size: 15)), const SizedBox(width: 10), Text('Token: ${_currentPatient?.token ?? "--"}', style: const TextStyle(color: Color(0xFF1F2937), fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: 0.5))])),
                        ])),
                      ])),
                    )),
                    const SizedBox(width: 24),
                    Expanded(flex: 7, child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 8), spreadRadius: 2)]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Padding(padding: const EdgeInsets.all(24), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        const Row(children: [Icon(Icons.people_alt_rounded, color: Color(0xFF1E3A8A), size: 28), SizedBox(width: 12), Text('Waiting Queue', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)))]),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.orange[400]!, Colors.orange[600]!]), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]), child: Text('${_waitingQueue.length} Waiting', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
                      ])),
                      Divider(height: 1, color: Colors.grey[200]),
                      SizedBox(height: 320, child: Scrollbar(controller: _waitingQueueScrollController, thumbVisibility: true, trackVisibility: true, child: ListView.separated(controller: _waitingQueueScrollController, padding: const EdgeInsets.symmetric(vertical: 8), physics: const AlwaysScrollableScrollPhysics(), itemCount: _waitingQueue.length, separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[100]), itemBuilder: (context, index) {
                        final patient = _waitingQueue[index];
                        return Container(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)), child: Row(children: [
                          Container(width: 50, height: 50, decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.blue[300]!, Colors.blue[500]!]), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))], image: _getImageProvider(patient.photoPath) != null ? DecorationImage(image: _getImageProvider(patient.photoPath)!, fit: BoxFit.cover) : null), child: _getImageProvider(patient.photoPath) == null ? Center(child: Text(patient.name[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20))) : null),
                          const SizedBox(width: 16),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(patient.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)), const SizedBox(height: 4), Text('Token: ${patient.token}', style: TextStyle(color: Colors.grey[600], fontSize: 13))])),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange[200]!)), child: Text('Waiting', style: TextStyle(color: Colors.orange[700], fontSize: 12, fontWeight: FontWeight.w600))),
                        ]));
                      }))),
                    ]))),
                  ],
                ),
          
          const SizedBox(height: 24),
          
          // Quick Actions Grid
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: _isMobile(context) ? 2 : 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: _isMobile(context) ? 1.1 : 1.5,
            children: [
              _buildActionCard('Register Patient', Icons.person_add, Colors.blue, 'PatientRegistrationForm'),
              _buildActionCard('Book Appointment', Icons.calendar_today, Colors.purple, 'BookAppointment'),
              _buildActionCard('Collect Payment', Icons.payment, Colors.green, 'PaymentManagement'),
              _buildActionCard('Verify Appts', Icons.how_to_reg, Colors.teal, 'AppointmentVerificationList'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color, color.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: color,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, String route) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: () => _navigateTo(route),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.15),
                color.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.15),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color, color.withOpacity(0.7)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: color.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StaffMenuItem {
  final IconData icon;
  final String label;
  final String? route;

  StaffMenuItem({required this.icon, required this.label, required this.route});
}

class CompletedPatientsPage extends StatefulWidget {
  const CompletedPatientsPage({super.key});

  @override
  State<CompletedPatientsPage> createState() => _CompletedPatientsPageState();
}

class _CompletedPatientsPageState extends State<CompletedPatientsPage> {
  List<Patient> _completedPatients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCompletedPatients();
  }

  Future<void> _loadCompletedPatients() async {
    final allPatients = await DatabaseHelper.instance.getAllPatients();
    if (mounted) {
      setState(() {
        _completedPatients = allPatients.where((p) => p.status == PatientStatus.completed).toList();
        _isLoading = false;
      });
    }
  }

  ImageProvider? _getImageProvider(String? path) {
    if (path == null) return null;
    if (kIsWeb) {
      if (path.startsWith('data:image')) {
        try {
          return MemoryImage(base64Decode(path.split(',').last));
        } catch (e) {
          return null;
        }
      }
      return NetworkImage(path);
    }
    if (File(path).existsSync()) {
      return FileImage(File(path));
    }
    return null;
  }

  Future<void> _downloadReport(Patient patient) async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report download is not supported on Web yet.')),
      );
      return;
    }
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/report_${patient.token}_${DateTime.now().millisecondsSinceEpoch}.txt');
      
      final StringBuffer report = StringBuffer();
      report.writeln('MEDICAL REPORT');
      report.writeln('================');
      report.writeln('Date: ${DateFormat('dd MMM yyyy HH:mm').format(DateTime.now())}');
      report.writeln('\nPATIENT DETAILS');
      report.writeln('Name: ${patient.name}');
      report.writeln('Token: ${patient.token}');
      report.writeln('Age/Gender: ${patient.age} / ${patient.gender}');
      report.writeln('Mobile: ${patient.mobile}');
      
      if (patient.history.isNotEmpty) {
        final lastConsultation = patient.history.last;
        report.writeln('\nCONSULTATION SUMMARY');
        report.writeln('Doctor: ${lastConsultation.doctorName}');
        report.writeln('Diagnosis: ${lastConsultation.diagnosis}');
        report.writeln('Prescription: ${lastConsultation.prescription}');
        report.writeln('Notes: ${lastConsultation.notes}');
      } else {
        report.writeln('\nNo consultation history found.');
      }
      
      await file.writeAsString(report.toString());
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report saved to Documents folder'),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () {
                // In a real app, we might try to open the file
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving report: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Completed Patients',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _completedPatients.isEmpty
              ? const Center(child: Text('No completed patients found today'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _completedPatients.length,
                  itemBuilder: (context, index) {
                    final patient = _completedPatients[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.withOpacity(0.1),
                          backgroundImage: _getImageProvider(patient.photoPath),
                          child: _getImageProvider(patient.photoPath) == null
                              ? const Icon(Icons.check, color: Colors.green)
                              : null,
                        ),
                        title: Text(patient.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Token: ${patient.token} | ${DateFormat('hh:mm a').format(patient.registrationTime)}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.download_rounded, color: Colors.blue),
                          onPressed: () => _downloadReport(patient),
                          tooltip: 'Download Report',
                        ),
                      ),
                    );
                  },
                ),
            ),
          ],
        ),
      ),
    );
  }
}

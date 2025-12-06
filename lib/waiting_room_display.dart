import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'database_helper.dart';
import 'models.dart';

class WaitingRoomDisplay extends StatefulWidget {
  const WaitingRoomDisplay({super.key});

  @override
  State<WaitingRoomDisplay> createState() => _WaitingRoomDisplayState();
}

class _WaitingRoomDisplayState extends State<WaitingRoomDisplay> with TickerProviderStateMixin {
  // Data Lists
  List<Patient> _allWaitingPatients = [];
  List<Patient> _visibleWaitingPatients = [];
  List<Patient> _servingPatients = [];
  
  // Pagination State
  int _waitingPageIndex = 0;
  int _servingPatientIndex = 0;
  final int _itemsPerPage = 5;
  
  // Timers
  Timer? _dataRefreshTimer;
  Timer? _waitingScrollTimer;
  Timer? _servingScrollTimer;
  Timer? _languageTimer;
  
  // UI State
  bool _isFullScreen = false;
  String? _previousServingId;
  int _currentLanguageIndex = 0;
  bool _isHeaderHovered = false;
  ScrollController _waitingListScrollController = ScrollController();
  
  // Multi-language messages
  final List<Map<String, String>> _messages = [
    {
      'language': 'English',
      'message': 'Please wait for your token number to be called',
    },
    {
      'language': 'हिंदी',
      'message': 'कृपया अपने टोकन नंबर की प्रतीक्षा करें',
    },
    {
      'language': 'ગુજરાતી',
      'message': 'કૃપા કરીને તમારા ટોકન નંબર માટે રાહ જુઓ',
    },
  ];
  
  // Animation Controllers
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    print('📺 WaitingRoomDisplay: initState called');
    
    _initAnimations();
    _loadData();
    
    // Auto-refresh data every 5 seconds
    _dataRefreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) => _loadData());
    
    // Scroll waiting list every 2 minutes
    _waitingScrollTimer = Timer.periodic(const Duration(minutes: 2), (timer) => _nextWaitingPage());
    
    // Rotate serving patients every 10 seconds (if multiple)
    _servingScrollTimer = Timer.periodic(const Duration(seconds: 10), (timer) => _nextServingPatient());
    
    // Rotate language messages every 5 seconds
    _languageTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          _currentLanguageIndex = (_currentLanguageIndex + 1) % _messages.length;
        });
      }
    });
    
    // Update clock every second
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _dataRefreshTimer?.cancel();
    _waitingScrollTimer?.cancel();
    _servingScrollTimer?.cancel();
    _languageTimer?.cancel();
    _pulseController.dispose();
    _slideController.dispose();
    _waitingListScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final patients = await DatabaseHelper.instance.getAllPatients();
      
      // Filter lists
      final serving = patients.where((p) => p.status == PatientStatus.inProgress).toList();
      final waiting = patients.where((p) => p.status == PatientStatus.waiting).toList();

      // Check for new serving patient to trigger sound/animation
      if (serving.isNotEmpty) {
        // If the *current* displayed serving patient changes, or if the list changes significantly
        // For simplicity, we check if the first patient ID changed or if count changed
        final currentId = serving.isNotEmpty ? serving[0].id : null;
        if (currentId != _previousServingId) {
           _previousServingId = currentId;
           _playNotificationSound();
           _slideController.forward(from: 0.0);
        }
      }

      if (mounted) {
        setState(() {
          _servingPatients = serving;
          _allWaitingPatients = waiting;
          _updateVisibleWaitingPatients();
        });
      }
    } catch (e) {
      print('🔴 WaitingRoomDisplay Error: $e');
    }
  }

  void _updateVisibleWaitingPatients() {
    if (_allWaitingPatients.isEmpty) {
      _visibleWaitingPatients = [];
      return;
    }
    
    final totalPages = (_allWaitingPatients.length / _itemsPerPage).ceil();
    if (_waitingPageIndex >= totalPages) _waitingPageIndex = 0;
    
    final start = _waitingPageIndex * _itemsPerPage;
    final end = (start + _itemsPerPage < _allWaitingPatients.length) 
        ? start + _itemsPerPage 
        : _allWaitingPatients.length;
        
    _visibleWaitingPatients = _allWaitingPatients.sublist(start, end);
  }

  void _nextWaitingPage() {
    if (_allWaitingPatients.isEmpty) return;
    
    final totalPages = (_allWaitingPatients.length / _itemsPerPage).ceil();
    if (totalPages <= 1) return; // No need to scroll if only 1 page

    setState(() {
      _waitingPageIndex = (_waitingPageIndex + 1) % totalPages;
      _updateVisibleWaitingPatients();
    });
  }

  void _nextServingPatient() {
    if (_servingPatients.isEmpty || _servingPatients.length <= 1) return;
    
    setState(() {
      _servingPatientIndex = (_servingPatientIndex + 1) % _servingPatients.length;
      _slideController.forward(from: 0.0); // Re-trigger slide animation
    });
  }

  void _playNotificationSound() {
    SystemSound.play(SystemSoundType.alert);
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });
    if (_isFullScreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final now = DateTime.now();
    
    // Responsive font sizes
    final headingSize = screenWidth > 1200 ? 55.0 : (screenWidth > 800 ? 40.0 : 30.0);
    final tokenSize = screenWidth > 1200 ? 90.0 : (screenWidth > 800 ? 60.0 : 40.0);
    final nameSize = screenWidth > 1200 ? 65.0 : (screenWidth > 800 ? 45.0 : 30.0);
    final statusSize = screenWidth > 1200 ? 35.0 : (screenWidth > 800 ? 25.0 : 18.0);
    final waitingHeadingSize = screenWidth > 1200 ? 40.0 : (screenWidth > 800 ? 30.0 : 22.0);
    final waitingNameSize = screenWidth > 1200 ? 35.0 : (screenWidth > 800 ? 25.0 : 18.0);
    
    // Get current serving patient to display
    Patient? currentServing;
    if (_servingPatients.isNotEmpty) {
      if (_servingPatientIndex >= _servingPatients.length) _servingPatientIndex = 0;
      currentServing = _servingPatients[_servingPatientIndex];
    }

    return WillPopScope(
      onWillPop: () async {
        if (_isFullScreen) {
          _toggleFullScreen();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: GestureDetector(
          onDoubleTap: () {
            if (_isFullScreen) {
              _toggleFullScreen();
            }
          },
          child: Stack(
            children: [
              Column(
                children: [
            // Professional TV Header with Branding, Clock & Live Indicator
            MouseRegion(
              onEnter: (_) => setState(() => _isHeaderHovered = true),
              onExit: (_) => setState(() => _isHeaderHovered = false),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E293B), Color(0xFF334155)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Back Button - Show on hover
                    AnimatedOpacity(
                      opacity: _isHeaderHovered ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: _isHeaderHovered ? 48 : 0,
                        child: _isHeaderHovered
                            ? IconButton(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(Icons.arrow_back, color: Colors.white),
                                tooltip: 'Back to Dashboard',
                                iconSize: 28,
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                    if (_isHeaderHovered) const SizedBox(width: 8),
                    
                    // Fullscreen Toggle - Show on hover
                    AnimatedOpacity(
                      opacity: _isHeaderHovered ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: _isHeaderHovered ? 48 : 0,
                        child: _isHeaderHovered
                            ? IconButton(
                                onPressed: _toggleFullScreen,
                                icon: Icon(
                                  _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                                  color: Colors.white,
                                ),
                                tooltip: _isFullScreen ? 'Exit Fullscreen' : 'Fullscreen',
                                iconSize: 28,
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                    if (_isHeaderHovered) const SizedBox(width: 16),
                    
                    // Clinic Logo/Icon
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.local_hospital,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 20),
                  
                  // Clinic Name
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MODI CLINIC',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                      Text(
                        'Patient Queue Management System',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  
                  const Spacer(),
                  
                  // Live Indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFDC2626).withOpacity(0.5),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'LIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 24),
                  
                  // Date & Time
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${_formatTime(now.hour)}:${_formatTime(now.minute)}:${_formatTime(now.second)}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      Text(
                        '${_getDayName(now.weekday)}, ${now.day} ${_getMonthName(now.month)} ${now.year}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ),
            
            // Main Content Area - Responsive Layout
            Expanded(
              child: screenWidth > 800
                  ? Row(
                      children: [
                        // DESKTOP/TV: LEFT SIDE - NOW SERVING
                        Expanded(
                          flex: 6,
                          child: Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Header - Multi-language "NOW SERVING"
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 600),
                                transitionBuilder: (Widget child, Animation<double> animation) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: ScaleTransition(
                                      scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                                        CurvedAnimation(parent: animation, curve: Curves.easeOut),
                                      ),
                                      child: child,
                                    ),
                                  );
                                },
                                child: ScaleTransition(
                                  key: ValueKey<int>(_currentLanguageIndex),
                                  scale: _pulseAnimation,
                                  child: Text(
                                    _getNowServingText(),
                                    style: TextStyle(
                                      fontSize: headingSize,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF1E293B),
                                      letterSpacing: 4,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 50),
                              
                              if (currentServing != null) ...[
                                // Animated Switcher for smooth transition
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 500),
                                  child: Column(
                                    key: ValueKey(currentServing.id),
                                    children: [
                                      // Patient Photo
                                      Container(
                                        width: 300,
                                        height: 300,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(35),
                                          border: Border.all(color: const Color(0xFF8B5CF6), width: 6),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF8B5CF6).withOpacity(0.4),
                                              blurRadius: 30,
                                              offset: const Offset(0, 15),
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(30),
                                          child: currentServing.photoPath != null && currentServing.photoPath!.isNotEmpty
                                              ? Image.network(
                                                  currentServing.photoPath!,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return Container(
                                                      color: const Color(0xFFF1F5F9),
                                                      child: const Icon(Icons.person, size: 150, color: Color(0xFF8B5CF6)),
                                                    );
                                                  },
                                                )
                                              : Container(
                                                  color: const Color(0xFFF1F5F9),
                                                  child: const Icon(Icons.person, size: 150, color: Color(0xFF8B5CF6)),
                                                ),
                                        ),
                                      ),
                                      const SizedBox(height: 50),
                                      
                                      // Token Number
                                      ScaleTransition(
                                        scale: _pulseAnimation,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 30),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(colors: [Color(0xFFDC2626), Color(0xFFEF4444)]),
                                            borderRadius: BorderRadius.circular(25),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFFDC2626).withOpacity(0.5),
                                                blurRadius: 20,
                                                offset: const Offset(0, 10),
                                              ),
                                            ],
                                          ),
                                          child: AnimatedSwitcher(
                                            duration: const Duration(milliseconds: 500),
                                            transitionBuilder: (Widget child, Animation<double> animation) {
                                              return FadeTransition(
                                                opacity: animation,
                                                child: child,
                                              );
                                            },
                                            child: Text(
                                              '${_getTokenText()}: ${currentServing.token}',
                                              key: ValueKey<int>(_currentLanguageIndex),
                                              style: TextStyle(
                                                fontSize: tokenSize,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.white,
                                                letterSpacing: 5,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 40),
                                      
                                      // Patient Name
                                      Text(
                                        currentServing.name.toUpperCase(),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: nameSize,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF1E293B),
                                          letterSpacing: 3,
                                        ),
                                      ),
                                      const SizedBox(height: 30),
                                      
                                      // Status Badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981),
                                          borderRadius: BorderRadius.circular(35),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF10B981).withOpacity(0.5),
                                              blurRadius: 15,
                                              offset: const Offset(0, 8),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.medical_services, color: Colors.white, size: statusSize),
                                            const SizedBox(width: 15),
                                            AnimatedSwitcher(
                                              duration: const Duration(milliseconds: 500),
                                              transitionBuilder: (Widget child, Animation<double> animation) {
                                                return FadeTransition(
                                                  opacity: animation,
                                                  child: ScaleTransition(
                                                    scale: Tween<double>(begin: 0.9, end: 1.0).animate(animation),
                                                    child: child,
                                                  ),
                                                );
                                              },
                                              child: Text(
                                                _getInConsultationText(),
                                                key: ValueKey<int>(_currentLanguageIndex),
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: statusSize,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 2,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      
                                      // Pagination Indicator for Serving (if multiple)
                                      if (_servingPatients.length > 1) ...[
                                        const SizedBox(height: 20),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: List.generate(_servingPatients.length, (index) {
                                            return Container(
                                              margin: const EdgeInsets.symmetric(horizontal: 4),
                                              width: 10,
                                              height: 10,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: index == _servingPatientIndex 
                                                    ? const Color(0xFF8B5CF6) 
                                                    : Colors.grey.withOpacity(0.3),
                                              ),
                                            );
                                          }),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ] else ...[
                                const Icon(Icons.hourglass_empty, size: 120, color: Colors.grey),
                                const SizedBox(height: 30),
                                const Text(
                                  'Please Wait...',
                                  style: TextStyle(fontSize: 50, color: Colors.grey, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // RIGHT SIDE: WAITING PATIENTS
                  Expanded(
                    flex: 4,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)]),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.access_time, color: Colors.white, size: waitingHeadingSize * 0.875),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 600),
                                    transitionBuilder: (Widget child, Animation<double> animation) {
                                      return FadeTransition(
                                        opacity: animation,
                                        child: SlideTransition(
                                          position: Tween<Offset>(
                                            begin: const Offset(0.0, -0.5),
                                            end: Offset.zero,
                                          ).animate(
                                            CurvedAnimation(parent: animation, curve: Curves.easeOut),
                                          ),
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: Text(
                                      _getUpcomingPatientsText(),
                                      key: ValueKey<int>(_currentLanguageIndex),
                                      style: TextStyle(
                                        fontSize: waitingHeadingSize,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          Expanded(
                            child: _visibleWaitingPatients.isEmpty
                                 ? const Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.event_available, size: 80, color: Colors.white38),
                                        SizedBox(height: 20),
                                        Text('No waiting patients', style: TextStyle(color: Colors.white70, fontSize: 28)),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    controller: _waitingListScrollController,
                                    physics: const BouncingScrollPhysics(),
                                    itemCount: _visibleWaitingPatients.length,
                                    itemBuilder: (context, index) {
                                      final patient = _visibleWaitingPatients[index];
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              const Color(0xFF1E293B).withOpacity(0.9),
                                              const Color(0xFF334155).withOpacity(0.9),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(24),
                                          border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.3), width: 2),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.3),
                                              blurRadius: 15,
                                              offset: const Offset(0, 8),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            // Patient Photo
                                            Container(
                                              width: screenWidth > 800 ? 80 : 60,
                                              height: screenWidth > 800 ? 80 : 60,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(color: Colors.white, width: screenWidth > 800 ? 4 : 2),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: const Color(0xFF8B5CF6).withOpacity(0.4),
                                                    blurRadius: 12,
                                                    offset: const Offset(0, 6),
                                                  ),
                                                ],
                                              ),
                                              child: ClipOval(
                                                child: patient.photoPath != null && patient.photoPath!.isNotEmpty
                                                    ? Image.network(
                                                        patient.photoPath!,
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (context, error, stackTrace) {
                                                          return Container(
                                                            color: const Color(0xFFF1F5F9),
                                                            child: Icon(Icons.person, size: screenWidth > 800 ? 50 : 35, color: const Color(0xFF8B5CF6)),
                                                          );
                                                        },
                                                      )
                                                    : Container(
                                                        color: const Color(0xFFF1F5F9),
                                                        child: Icon(Icons.person, size: screenWidth > 800 ? 50 : 35, color: const Color(0xFF8B5CF6)),
                                                      ),
                                              ),
                                            ),
                                            SizedBox(width: screenWidth > 800 ? 24 : 12),
                                            
                                            // Token Badge
                                            Container(
                                              width: screenWidth > 800 ? 70 : 50,
                                              height: screenWidth > 800 ? 70 : 50,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)]),
                                                shape: BoxShape.circle,
                                                border: Border.all(color: Colors.white, width: screenWidth > 800 ? 3 : 2),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: const Color(0xFF8B5CF6).withOpacity(0.5),
                                                    blurRadius: 10,
                                                    offset: const Offset(0, 5),
                                                  ),
                                                ],
                                              ),
                                              child: Text(
                                                patient.token,
                                                style: TextStyle(
                                                  fontSize: screenWidth > 800 ? 35 : 20,
                                                  fontWeight: FontWeight.w900,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: screenWidth > 800 ? 24 : 12),
                                            
                                            // Patient Info
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    patient.name.toUpperCase(),
                                                    style: TextStyle(
                                                      fontSize: screenWidth > 800 ? waitingNameSize : 16,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white,
                                                      letterSpacing: 1.5,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.access_time,
                                                        color: Colors.white70,
                                                        size: screenWidth > 800 ? 22 : 16,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Flexible(
                                                        child: Text(
                                                          'WAITING',
                                                          style: TextStyle(
                                                            fontSize: screenWidth > 800 ? 22 : 14,
                                                            color: Colors.white70,
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                          
                          // Pagination Indicator for Waiting List
                          if (_allWaitingPatients.length > _itemsPerPage) ...[
                             const SizedBox(height: 10),
                             Row(
                               mainAxisAlignment: MainAxisAlignment.center,
                               children: [
                                 Text(
                                   'Page ${_waitingPageIndex + 1} of ${(_allWaitingPatients.length / _itemsPerPage).ceil()}',
                                   style: const TextStyle(color: Colors.white54, fontSize: 16),
                                 ),
                               ],
                             ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              )
                  : Column(
                      children: [
                        // MOBILE: TOP - NOW SERVING (Compact - 40% screen)
                        Expanded(
                          flex: 4,
                          child: Container(
                            margin: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: currentServing != null
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _getNowServingText(),
                                        style: TextStyle(
                                          fontSize: headingSize * 0.6,
                                          fontWeight: FontWeight.w900,
                                          color: const Color(0xFF1E293B),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      // Token
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(colors: [Color(0xFFDC2626), Color(0xFFEF4444)]),
                                          borderRadius: BorderRadius.circular(15),
                                        ),
                                        child: Text(
                                          currentServing.token,
                                          style: TextStyle(
                                            fontSize: tokenSize * 0.5,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      // Name
                                      Text(
                                        currentServing.name.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: nameSize * 0.5,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF1E293B),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  )
                                : const Center(
                                    child: Text(
                                      'Please Wait...',
                                      style: TextStyle(fontSize: 24, color: Colors.grey),
                                    ),
                                  ),
                          ),
                        ),
                        // MOBILE: BOTTOM - WAITING LIST (60% screen)
                        Expanded(
                          flex: 6,
                          child: Container(
                            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)]),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _getUpcomingPatientsText(),
                                        style: TextStyle(
                                          fontSize: waitingHeadingSize * 0.8,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.3),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          '${_allWaitingPatients.length}',
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Expanded(
                                  child: _allWaitingPatients.isEmpty
                                      ? const Center(
                                          child: Text(
                                            'No patients waiting',
                                            style: TextStyle(fontSize: 18, color: Colors.white70),
                                          ),
                                        )
                                      : ListView.builder(
                                          itemCount: _allWaitingPatients.length,
                                          itemBuilder: (context, index) {
                                            final patient = _allWaitingPatients[index];
                                            return Container(
                                              margin: const EdgeInsets.only(bottom: 12),
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    const Color(0xFF1E293B).withOpacity(0.9),
                                                    const Color(0xFF334155).withOpacity(0.9),
                                                  ],
                                                ),
                                                borderRadius: BorderRadius.circular(16),
                                                border: Border.all(
                                                  color: const Color(0xFF8B5CF6).withOpacity(0.3),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  // Token Badge
                                                  Container(
                                                    width: 50,
                                                    height: 50,
                                                    decoration: BoxDecoration(
                                                      gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)]),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        patient.token,
                                                        style: const TextStyle(
                                                          fontSize: 18,
                                                          fontWeight: FontWeight.w900,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 16),
                                                  // Patient Info
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          patient.name.toUpperCase(),
                                                          style: TextStyle(
                                                            fontSize: waitingNameSize * 0.8,
                                                            fontWeight: FontWeight.bold,
                                                            color: Colors.white,
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                        const SizedBox(height: 4),
                                                        Text(
                                                          'WAITING',
                                                          style: TextStyle(
                                                            fontSize: waitingNameSize * 0.6,
                                                            color: Colors.white70,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
            
            // Multi-language Message Banner
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 800),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, 0.3),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: Container(
                key: ValueKey<int>(_currentLanguageIndex),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF8B5CF6).withOpacity(0.9),
                      const Color(0xFF6366F1).withOpacity(0.9),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Language Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Text(
                        _messages[_currentLanguageIndex]['language']!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    
                    // Message
                    Flexible(
                      child: Text(
                        _messages[_currentLanguageIndex]['message']!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(int value) => value.toString().padLeft(2, '0');
  
  String _getDayName(int day) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[day - 1];
  }
  
  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
  
  String _getNowServingText() {
    switch (_currentLanguageIndex) {
      case 0: // English
        return 'NOW SERVING';
      case 1: // Hindi
        return 'अब सेवा कर रहे हैं';
      case 2: // Gujarati
        return 'હવે સેવા આપી રહ્યા છીએ';
      default:
        return 'NOW SERVING';
    }
  }
  
  String _getUpcomingPatientsText() {
    switch (_currentLanguageIndex) {
      case 0: // English
        return 'UPCOMING PATIENTS';
      case 1: // Hindi
        return 'आगामी मरीज़';
      case 2: // Gujarati
        return 'આગામી દર્દીઓ';
      default:
        return 'UPCOMING PATIENTS';
    }
  }
  
  String _getTokenText() {
    switch (_currentLanguageIndex) {
      case 0: // English
        return 'TOKEN';
      case 1: // Hindi
        return 'टोकन';
      case 2: // Gujarati
        return 'ટોકન';
      default:
        return 'TOKEN';
    }
  }
  
  String _getInConsultationText() {
    switch (_currentLanguageIndex) {
      case 0: // English
        return 'IN CONSULTATION';
      case 1: // Hindi
        return 'परामर्श में';
      case 2: // Gujarati
        return 'પરામર્શમાં';
      default:
        return 'IN CONSULTATION';
    }
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'database_helper.dart';
import 'models.dart';
import 'book_appointment.dart';
import 'indian_holiday_service.dart';
import 'doctor_leave_service.dart';
import 'responsive_helper.dart';

class AppointmentManagement extends StatefulWidget {
  const AppointmentManagement({super.key});

  @override
  State<AppointmentManagement> createState() => _AppointmentManagementState();
}

class _AppointmentManagementState extends State<AppointmentManagement> {
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDate = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  
  List<Appointment> _appointments = [];
  bool _isLoading = false;

  // Indian festival dates - loaded dynamically from service
  Map<DateTime, String> _festivalDates = {};
  bool _festivalsLoaded = false;

  // Doctor's custom leaves - using shared service
  final DoctorLeaveService _leaveService = DoctorLeaveService();

  @override
  void initState() {
    super.initState();
    _loadFestivals();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() => _isLoading = true);
    try {
      final appointments = await DatabaseHelper.instance.getAppointmentsByDate(_selectedDate);
      setState(() {
        _appointments = appointments;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading appointments: $e');
      setState(() => _isLoading = false);
    }
  }

  // Load festivals for current and next year
  Future<void> _loadFestivals() async {
    final currentYear = DateTime.now().year;
    final festivals = <DateTime, String>{};
    
    // Load festivals for current year and next 2 years
    for (int year = currentYear; year <= currentYear + 2; year++) {
      final yearFestivals = await IndianHolidayService.getHolidaysForYear(year);
      festivals.addAll(yearFestivals);
    }
    
    setState(() {
      _festivalDates = festivals;
      _festivalsLoaded = true;
    });
  }

  // Helper to check doctor availability
  bool _isDoctorAvailable(DateTime date) {
    if (date.weekday == DateTime.sunday) return false;
    final only = DateTime(date.year, date.month, date.day);
    if (_festivalDates.containsKey(only)) return false;
    
    // Check doctor leaves using shared service
    if (_leaveService.isLeaveDay(date)) return false;
    
    return true;
  }

  String _getUnavailabilityReason(DateTime date) {
    if (date.weekday == DateTime.sunday) return 'Sunday (Closed)';
    final only = DateTime(date.year, date.month, date.day);
    if (_festivalDates.containsKey(only)) return _festivalDates[only]!;
    
    // Get leave reason from shared service
    final leaveReason = _leaveService.getLeaveReason(date);
    if (leaveReason != null) return 'Doctor Leave: $leaveReason';
    
    return '';
  }

  // Add custom leave dialog
  void _showAddLeaveDialog() {
    DateTime selectedLeaveDate = DateTime.now();
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Doctor Leave'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Date:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedLeaveDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setDialogState(() {
                      selectedLeaveDate = picked;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 20),
                      const SizedBox(width: 8),
                      Text(DateFormat('dd MMM yyyy').format(selectedLeaveDate)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Reason:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  hintText: 'e.g., Personal Leave, Medical Emergency',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (reasonController.text.trim().isNotEmpty) {
                  _leaveService.addLeave(selectedLeaveDate, reasonController.text.trim());
                  setState(() {});
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Leave added for ${DateFormat('dd MMM yyyy').format(selectedLeaveDate)}'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a reason'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Add Leave'),
            ),
          ],
        ),
      ),
    );
  }

  // View and manage leaves dialog
  void _showManageLeavesDialog() {
    final leaves = _leaveService.getAllLeaves();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manage Doctor Leaves'),
        content: SizedBox(
          width: double.maxFinite,
          child: leaves.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text('No custom leaves added yet.'),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: leaves.length,
                  itemBuilder: (context, index) {
                    final leave = leaves[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: const Icon(Icons.event_busy, color: Colors.red),
                        title: Text(DateFormat('dd MMM yyyy').format(leave['date'])),
                        subtitle: Text(leave['reason']),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _leaveService.removeLeave(index);
                            setState(() {});
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Leave removed'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Management'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.event_busy),
            tooltip: 'Manage Leaves',
            onPressed: _showManageLeavesDialog,
          ),
          IconButton(
            icon: const Icon(Icons.add_circle),
            tooltip: 'Add Leave',
            onPressed: _showAddLeaveDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showAddLeaveDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Leave'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showManageLeavesDialog,
                    icon: const Icon(Icons.list),
                    label: const Text('View Leaves'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 400;
                    return TableCalendar(
                      firstDay: DateTime.utc(2024, 1, 1),
                      lastDay: DateTime.utc(2026, 12, 31),
                      focusedDay: _focusedDate,
                      selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
                      calendarFormat: _calendarFormat,
                      rowHeight: isMobile ? 42 : 52,
                      daysOfWeekHeight: isMobile ? 20 : 24,
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDate = selectedDay;
                          _focusedDate = focusedDay;
                        });
                        _loadAppointments();
                      },
                      onFormatChanged: (format) {
                        setState(() {
                          _calendarFormat = format;
                        });
                      },
                      onPageChanged: (focusedDay) {
                        _focusedDate = focusedDay;
                      },
                      calendarStyle: CalendarStyle(
                        todayDecoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        weekendTextStyle: const TextStyle(color: Colors.red),
                        outsideDaysVisible: false,
                        cellMargin: EdgeInsets.all(isMobile ? 2 : 4),
                      ),
                      daysOfWeekStyle: DaysOfWeekStyle(
                        weekdayStyle: TextStyle(
                          fontSize: isMobile ? 11 : 13,
                          fontWeight: FontWeight.bold,
                        ),
                        weekendStyle: TextStyle(
                          fontSize: isMobile ? 11 : 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      headerStyle: HeaderStyle(
                        formatButtonVisible: true,
                        titleCentered: true,
                        formatButtonShowsNext: false,
                        titleTextStyle: TextStyle(fontSize: isMobile ? 14 : 17),
                        formatButtonTextStyle: TextStyle(fontSize: isMobile ? 11 : 14),
                      ),
                      calendarBuilders: CalendarBuilders(
                        defaultBuilder: (context, day, focusedDay) {
                          return _buildCalendarDay(day);
                        },
                        selectedBuilder: (context, day, focusedDay) {
                          return _buildCalendarDay(day, isSelected: true);
                        },
                        todayBuilder: (context, day, focusedDay) {
                          return _buildCalendarDay(day, isToday: true);
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Day View
            Text(
              'Day View - ${DateFormat('EEEE, dd MMMM yyyy').format(_selectedDate)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            
            // Show festival/unavailability info
            if (!_isDoctorAvailable(_selectedDate))
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.cancel, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getUnavailabilityReason(_selectedDate),
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (_festivalDates.containsKey(DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day)))
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Row(
                    children: [
                      const Text('🎉', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _festivalDates[DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day)]!,
                          style: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: 10),
            _buildDayView(),
            const SizedBox(height: 20),
            
            // Book Appointment Button
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const BookAppointment()),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Book New Appointment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarDay(DateTime day, {bool isSelected = false, bool isToday = false}) {
    final only = DateTime(day.year, day.month, day.day);
    final isFestival = _festivalDates.containsKey(only);
    final isAvailable = _isDoctorAvailable(day);

    return LayoutBuilder(
      builder: (context, constraints) {   
        final size = constraints.maxWidth < constraints.maxHeight 
            ? constraints.maxWidth 
            : constraints.maxHeight;
        final isSmallScreen = size < 40;

        return Container(
          margin: EdgeInsets.all(isSmallScreen ? 2 : 4),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.blue
                : isToday
                    ? Colors.blue.withOpacity(0.3)
                    : isFestival 
                        ? Colors.orange.withOpacity(0.1)
                        : Colors.transparent,
            shape: BoxShape.circle,
            border: isFestival 
                ? Border.all(color: Colors.orange, width: isSmallScreen ? 1 : 2) 
                : (!isAvailable ? Border.all(color: Colors.red.withOpacity(0.5), width: 1) : null),
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '${day.day}',
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 14,
                  color: isSelected || isToday
                      ? Colors.white
                      : !isAvailable
                          ? Colors.red
                          : day.weekday == DateTime.sunday
                              ? Colors.red
                              : isFestival 
                                  ? Colors.orange.shade800
                                  : Colors.black,
                  fontWeight: isSelected || isToday || isFestival ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDayView() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_appointments.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text('No appointments scheduled for this day.'),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _appointments.length,
      itemBuilder: (context, index) {
        final appointment = _appointments[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${appointment.time} - ${appointment.patientName}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(appointment.type),
                      if (appointment.reason != null && appointment.reason!.isNotEmpty)
                        Text(
                          'Reason: ${appointment.reason}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Calling ${appointment.patientName}')),
                        );
                      },
                      child: const Text('Call'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Rescheduling ${appointment.patientName}')),
                        );
                      },
                      child: const Text('Reschedule'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

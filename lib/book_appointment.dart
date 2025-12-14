import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:modi/database_helper.dart';
import 'package:modi/models.dart';
import 'doctor_leave_service.dart';
import 'indian_holiday_service.dart';
import 'responsive_helper.dart';

class BookAppointment extends StatefulWidget {
  const BookAppointment({super.key});

  @override
  State<BookAppointment> createState() => _BookAppointmentState();
}

class _BookAppointmentState extends State<BookAppointment> {
  final TextEditingController _patientController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _selectedTime = '09:00 AM';
  String _appointmentType = 'New Consultation';
  bool _sendSMS = true;
  bool _sendEmail = false;

  // Services
  final DoctorLeaveService _leaveService = DoctorLeaveService();
  Map<DateTime, String> _festivalDates = {};
  bool _festivalsLoaded = false;

  // Time slots for appointments
  final List<String> _timeSlots = [
    '09:00 AM', '09:30 AM', '10:00 AM', '10:30 AM', '11:00 AM', '11:30 AM',
    '12:00 PM', '12:30 PM', '01:00 PM', '01:30 PM', '02:00 PM', '02:30 PM',
    '03:00 PM', '03:30 PM', '04:00 PM', '04:30 PM', '05:00 PM', '05:30 PM'
  ];

  // Appointment types
  final List<String> _appointmentTypes = [
    'New Consultation',
    'Follow-up',
    'Check-up',
    'Emergency',
    'Vaccination',
    'Lab Test'
  ];

  @override
  void initState() {
    super.initState();
    _loadFestivals();
    _leaveService.addListener(_onLeavesChanged);
  }

  @override
  void dispose() {
    _leaveService.removeListener(_onLeavesChanged);
    _patientController.dispose();
    _mobileController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _onLeavesChanged() {
    setState(() {});
  }

  Future<void> _loadFestivals() async {
    final currentYear = DateTime.now().year;
    final festivals = <DateTime, String>{};
    
    for (int year = currentYear; year <= currentYear + 1; year++) {
      final yearFestivals = await IndianHolidayService.getHolidaysForYear(year);
      festivals.addAll(yearFestivals);
    }
    
    setState(() {
      _festivalDates = festivals;
      _festivalsLoaded = true;
    });
  }

  // Helper to check doctor availability (no weekends, no festivals, no leaves)
  bool _isDoctorAvailable(DateTime date) {
    // Check Sunday
    if (date.weekday == DateTime.sunday) return false;
    
    // Check festivals
    final dateOnly = DateTime(date.year, date.month, date.day);
    if (_festivalDates.containsKey(dateOnly)) return false;
    
    // Check doctor leaves
    if (_leaveService.isLeaveDay(date)) return false;
    
    return true;
  }

  String _getUnavailabilityReason(DateTime date) {
    if (date.weekday == DateTime.sunday) return 'Sunday (Closed)';
    
    final dateOnly = DateTime(date.year, date.month, date.day);
    if (_festivalDates.containsKey(dateOnly)) {
      return _festivalDates[dateOnly]!;
    }
    
    final leaveReason = _leaveService.getLeaveReason(date);
    if (leaveReason != null) {
      return 'Doctor Leave: $leaveReason';
    }
    
    return '';
  }

  void _selectDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      selectableDayPredicate: (date) {
        return true;
      },
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFA855F7), // Purple instead of blue
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _bookAppointment() async {
    if (_patientController.text.isEmpty || _mobileController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_isDoctorAvailable(_selectedDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Doctor is not available on the selected date.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final patientId = DateTime.now().millisecondsSinceEpoch.toString();

    final appointment = Appointment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      patientName: _patientController.text,
      mobile: _mobileController.text,
      date: _selectedDate,
      time: _selectedTime,
      type: _appointmentType,
      reason: _reasonController.text,
      status: 'pending',
      patientId: patientId,
    );

    await DatabaseHelper.instance.insertAppointment(appointment);

    final now = DateTime.now();
    final isToday = _selectedDate.year == now.year && 
                    _selectedDate.month == now.month && 
                    _selectedDate.day == now.day;

    if (isToday) {
      final token = 'APT-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
      final patient = Patient(
        id: patientId,
        name: _patientController.text,
        token: token,
        age: 'N/A',
        gender: 'Other',
        mobile: _mobileController.text,
        symptoms: _reasonController.text,
        status: PatientStatus.waiting,
        registrationTime: DateTime.now(),
        registeredDate: DateTime.now(),
        isAppointment: true,
      );
      
      await DatabaseHelper.instance.insertPatient(patient);
    }

    if (mounted) {
      _showSuccessNotification();
    }

    _patientController.clear();
    _mobileController.clear();
    _reasonController.clear();
    setState(() {
      _selectedDate = DateTime.now();
      _selectedTime = '09:00 AM';
      _appointmentType = 'New Consultation';
      _sendSMS = true;
      _sendEmail = false;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pop(context, true);
      }
    });
  }

  void _showSuccessNotification() {
    final dateStr = DateFormat('dd MMM yyyy').format(_selectedDate);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFA855F7), Color(0xFFEC4899)], // Purple gradient
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFA855F7).withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 60,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Appointment Booked!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 12),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(fontSize: 16, color: Color(0xFF6B7280), height: 1.5),
                    children: [
                      const TextSpan(text: 'Successfully scheduled for\n'),
                      TextSpan(
                        text: '$dateStr at $_selectedTime',
                        style: const TextStyle(
                          color: Color(0xFFA855F7), // Purple
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFA855F7), // Purple
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text('Book Appointment', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFA855F7), Color(0xFFEC4899)], // Purple gradient
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFA855F7).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.event_note, color: Colors.white, size: 36),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Schedule Appointment',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Book a new patient visit',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(Icons.person, 'Patient Information'),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _patientController,
                label: 'Patient Name',
                hint: 'Enter patient full name',
                icon: Icons.person_rounded,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _mobileController,
                label: 'Mobile Number',
                hint: 'Enter 10-digit mobile number',
                icon: Icons.phone_rounded,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(Icons.event, 'Appointment Details'),
              const SizedBox(height: 12),
              // Date Selection
              InkWell(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFA855F7).withOpacity(0.1), // Purple
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.calendar_month_rounded, color: Color(0xFFA855F7), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Appointment Date',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('EEEE, dd MMMM yyyy').format(_selectedDate),
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              if (!_isDoctorAvailable(_selectedDate))
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Doctor Not Available',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getUnavailabilityReason(_selectedDate),
                                style: TextStyle(
                                  color: Colors.red[700],
                                  fontSize: 13,
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
              _buildDropdown(
                label: 'Time Slot',
                value: _selectedTime,
                items: _timeSlots,
                icon: Icons.access_time_filled_rounded,
                onChanged: (value) => setState(() => _selectedTime = value!),
              ),
              const SizedBox(height: 16),
              _buildDropdown(
                label: 'Appointment Type',
                value: _appointmentType,
                items: _appointmentTypes,
                icon: Icons.medical_services_rounded,
                onChanged: (value) => setState(() => _appointmentType = value!),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _reasonController,
                label: 'Reason for Visit',
                hint: 'Describe symptoms or reason',
                icon: Icons.description_rounded,
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(Icons.notifications_active_rounded, 'Notifications'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  children: [
                    _buildCheckbox(
                      value: _sendSMS,
                      label: 'Send SMS Reminder',
                      subtitle: 'Patient will receive SMS confirmation',
                      onChanged: (value) => setState(() => _sendSMS = value ?? false),
                    ),
                    const Divider(),
                    _buildCheckbox(
                      value: _sendEmail,
                      label: 'Send Email Reminder',
                      subtitle: 'Patient will receive email confirmation',
                      onChanged: (value) => setState(() => _sendEmail = value ?? false),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isDoctorAvailable(_selectedDate) ? _bookAppointment : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isDoctorAvailable(_selectedDate) 
                        ? const Color(0xFFA855F7) // Purple
                        : Colors.grey[400],
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    disabledForegroundColor: Colors.grey[500],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: _isDoctorAvailable(_selectedDate) ? 2 : 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, size: 24),
                      SizedBox(width: 12),
                      Text(
                        'BOOK APPOINTMENT',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFA855F7), size: 22), // Purple
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF374151))),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              prefixIcon: Icon(icon, color: const Color(0xFFA855F7), size: 20), // Purple
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFA855F7), width: 1.5), // Purple
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF374151))),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFFA855F7)), // Purple
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Row(
                    children: [
                      Icon(icon, size: 18, color: const Color(0xFFA855F7)), // Purple
                      const SizedBox(width: 12),
                      Text(item, style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckbox({
    required bool value,
    required String label,
    required String subtitle,
    required Function(bool?) onChanged,
  }) {
    return CheckboxListTile(
      value: value,
      onChanged: (val) => onChanged(val ?? false),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      activeColor: const Color(0xFFA855F7), // Purple
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}

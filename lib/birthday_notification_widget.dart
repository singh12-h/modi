import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'models.dart';
import 'database_helper.dart';
import 'patient_detail_view.dart';

/// Birthday Notification Widget - Shows patients with birthday today or upcoming
/// Provides easy WhatsApp/SMS wish functionality
class BirthdayNotificationWidget extends StatefulWidget {
  final bool showAsCard; // Show as a dashboard card or full page
  
  const BirthdayNotificationWidget({
    super.key,
    this.showAsCard = true,
  });

  @override
  State<BirthdayNotificationWidget> createState() => _BirthdayNotificationWidgetState();
}

class _BirthdayNotificationWidgetState extends State<BirthdayNotificationWidget> {
  List<Patient> _todayBirthdays = [];
  List<Patient> _upcomingBirthdays = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBirthdays();
  }

  Future<void> _loadBirthdays() async {
    setState(() => _isLoading = true);
    
    try {
      final today = await DatabaseHelper.instance.getTodayBirthdayPatients();
      final upcoming = await DatabaseHelper.instance.getUpcomingBirthdayPatients(days: 7);
      
      // Filter out today's birthdays from upcoming
      final upcomingFiltered = upcoming.where((p) {
        final now = DateTime.now();
        if (p.birthDate == null) return false;
        return !(p.birthDate!.month == now.month && p.birthDate!.day == now.day);
      }).toList();
      
      setState(() {
        _todayBirthdays = today;
        _upcomingBirthdays = upcomingFiltered;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading birthdays: $e');
      setState(() => _isLoading = false);
    }
  }

  // Calculate age
  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month || 
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  // Send WhatsApp Birthday Wish
  Future<void> _sendBirthdayWish(Patient patient, {bool viaSms = false}) async {
    final age = patient.birthDate != null ? _calculateAge(patient.birthDate!) : 0;
    
    final String message = '''🎂 *Happy Birthday ${patient.name}!* 🎉

✨ आपको जन्मदिन की हार्दिक शुभकामनाएं! ✨

May this special day bring you:
🌟 Good Health & Happiness
💪 Strength & Wellness
🙏 Peace & Prosperity

Wishing you a wonderful year ahead filled with joy and excellent health!

🏥 *With Warm Wishes,*
*Dr. Modi & MODI CLINIC Team*

📞 For appointments: Contact us anytime!
🎁 *Special Birthday Offer:* Get 10% off on your next health checkup this month!''';

    String phoneNumber = patient.mobile.replaceAll(RegExp(r'[^0-9]'), '');
    if (!phoneNumber.startsWith('91') && phoneNumber.length == 10) {
      phoneNumber = '91$phoneNumber';
    }

    try {
      if (viaSms) {
        final Uri smsUri = Uri(
          scheme: 'sms',
          path: patient.mobile,
          queryParameters: {'body': message},
        );
        if (await canLaunchUrl(smsUri)) {
          await launchUrl(smsUri);
        }
      } else {
        final Uri whatsappUri = Uri.parse(
          'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}'
        );
        if (await canLaunchUrl(whatsappUri)) {
          await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_todayBirthdays.isEmpty && _upcomingBirthdays.isEmpty) {
      if (widget.showAsCard) {
        return const SizedBox.shrink(); // Hide if no birthdays
      }
      return _buildEmptyState();
    }

    if (widget.showAsCard) {
      return _buildDashboardCard();
    }
    
    return _buildFullPage();
  }

  Widget _buildDashboardCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B95), Color(0xFFFF8C42)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B95).withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showBirthdayBottomSheet(context),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.cake,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🎂 Birthday Wishes',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _todayBirthdays.isNotEmpty
                            ? '${_todayBirthdays.length} patient${_todayBirthdays.length > 1 ? 's have' : ' has'} birthday today!'
                            : '${_upcomingBirthdays.length} upcoming birthday${_upcomingBirthdays.length > 1 ? 's' : ''} this week',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_todayBirthdays.length + _upcomingBirthdays.length}',
                    style: const TextStyle(
                      color: Color(0xFFFF6B95),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
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

  void _showBirthdayBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF6B95), Color(0xFFFF8C42)],
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cake, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    const Text(
                      '🎂 Birthday Calendar',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Today's Birthdays
                    if (_todayBirthdays.isNotEmpty) ...[
                      _buildSectionHeader('🎉 Today\'s Birthdays', Colors.red),
                      const SizedBox(height: 8),
                      ..._todayBirthdays.map((p) => _buildBirthdayCard(p, isToday: true)),
                      const SizedBox(height: 20),
                    ],
                    // Upcoming Birthdays
                    if (_upcomingBirthdays.isNotEmpty) ...[
                      _buildSectionHeader('📅 Upcoming Birthdays (7 days)', Colors.orange),
                      const SizedBox(height: 8),
                      ..._upcomingBirthdays.map((p) => _buildBirthdayCard(p, isToday: false)),
                    ],
                    // Empty state
                    if (_todayBirthdays.isEmpty && _upcomingBirthdays.isEmpty)
                      _buildEmptyState(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildBirthdayCard(Patient patient, {required bool isToday}) {
    final age = patient.birthDate != null ? _calculateAge(patient.birthDate!) : 0;
    final birthDateStr = patient.birthDate != null 
        ? DateFormat('dd MMM').format(patient.birthDate!)
        : 'N/A';
    
    return Card(
      elevation: isToday ? 4 : 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isToday 
            ? const BorderSide(color: Color(0xFFFF6B95), width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Avatar with birthday indicator
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: isToday ? const Color(0xFFFF6B95) : Colors.grey[200],
                  child: Text(
                    patient.name.isNotEmpty ? patient.name[0].toUpperCase() : 'P',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isToday ? Colors.white : Colors.grey[700],
                    ),
                  ),
                ),
                if (isToday)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFD700),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.cake, size: 12, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patient.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isToday ? const Color(0xFFFF6B95) : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        birthDateStr,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isToday 
                              ? const Color(0xFFFF6B95).withOpacity(0.1)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Turning $age',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isToday ? const Color(0xFFFF6B95) : Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '📱 ${patient.mobile}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            // Action Buttons
            Column(
              children: [
                // WhatsApp Button
                IconButton(
                  onPressed: () => _sendBirthdayWish(patient),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.chat, color: Colors.white, size: 18),
                  ),
                  tooltip: 'Send WhatsApp Wish',
                ),
                // SMS Button
                IconButton(
                  onPressed: () => _sendBirthdayWish(patient, viaSms: true),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[600],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.sms, color: Colors.white, size: 18),
                  ),
                  tooltip: 'Send SMS Wish',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cake_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No birthdays this week',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Birthday notifications will appear here',
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildFullPage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎂 Birthday Calendar'),
        backgroundColor: const Color(0xFFFF6B95),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadBirthdays,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadBirthdays,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Today's Birthdays
            if (_todayBirthdays.isNotEmpty) ...[
              _buildSectionHeader('🎉 Today\'s Birthdays', Colors.red),
              const SizedBox(height: 8),
              ..._todayBirthdays.map((p) => _buildBirthdayCard(p, isToday: true)),
              const SizedBox(height: 20),
            ],
            // Upcoming Birthdays
            if (_upcomingBirthdays.isNotEmpty) ...[
              _buildSectionHeader('📅 Upcoming Birthdays (7 days)', Colors.orange),
              const SizedBox(height: 8),
              ..._upcomingBirthdays.map((p) => _buildBirthdayCard(p, isToday: false)),
            ],
            // Empty state
            if (_todayBirthdays.isEmpty && _upcomingBirthdays.isEmpty)
              _buildEmptyState(),
          ],
        ),
      ),
    );
  }
}

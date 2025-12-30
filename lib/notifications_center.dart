import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'database_helper.dart';
import 'models.dart';
import 'dart:ui';

class NotificationsCenter extends StatefulWidget {
  const NotificationsCenter({super.key});

  @override
  State<NotificationsCenter> createState() => _NotificationsCenterState();
}

class _NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime time;
  final String type; // 'appointment', 'payment', 'followup'
  final Color color;
  final IconData icon;

  _NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.type,
    required this.color,
    required this.icon,
  });
}

class _NotificationsCenterState extends State<NotificationsCenter> with SingleTickerProviderStateMixin {
  List<_NotificationItem> _notifications = [];
  bool _isLoading = true;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _loadNotifications();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    
    final List<_NotificationItem> items = [];

    try {
      // 1. Fetch Pending Appointments
      final appointments = await DatabaseHelper.instance.getPendingAppointments();
      for (var apt in appointments) {
        items.add(_NotificationItem(
          id: 'apt_${apt.id}',
          title: 'New Appointment Request',
          message: '${apt.patientName} requested an appointment for ${apt.type}',
          time: apt.createdAt, // Assuming createdAt is available
          type: 'appointment',
          color: const Color(0xFFF59E0B), // Amber
          icon: Icons.calendar_today_rounded,
        ));
      }

      // 2. Fetch Pending Payments
      final payments = await DatabaseHelper.instance.getPaymentsByStatus('pending');
      for (var pay in payments) {
        items.add(_NotificationItem(
          id: 'pay_${pay.id}',
          title: 'Payment Pending',
          message: '₹${pay.amount} pending from ${pay.patientName}',
          time: pay.date,
          type: 'payment',
          color: const Color(0xFFEF4444), // Red
          icon: Icons.payment_rounded,
        ));
      }

      // 3. Fetch Today's Follow-ups
      final followUps = await DatabaseHelper.instance.getTodayFollowUps();
      for (var fu in followUps) {
        // We need patient name here. Consultation might have doctor_name but maybe not patient name directly if not joined.
        // But the Consultation model usually has patientId. We might need to fetch patient name or if it's stored.
        // Looking at Consultation model in database_helper, it has patient_id.
        // For efficiency, we might just show "Patient ID: ..." or fetch patient.
        // Let's try to fetch patient details for better UX, or if Consultation has it.
        // Checking DatabaseHelper schema... Consultation table doesn't seem to store patient_name explicitly in the CREATE statement in step 36.
        // However, let's check the Consultation model definition if possible.
        // For now, I'll fetch the patient for each follow up. It might be slightly slow but okay for small numbers.
        
        String patientName = 'Unknown Patient';
        final patient = await DatabaseHelper.instance.getPatient(fu.patientId);
        if (patient != null) {
          patientName = patient.name;
        }

        items.add(_NotificationItem(
          id: 'fu_${fu.id}',
          title: 'Follow-up Scheduled',
          message: 'Follow-up with $patientName today',
          time: fu.followUpDate!, // followUpDate is already DateTime
          type: 'followup',
          color: const Color(0xFF3B82F6), // Blue
          icon: Icons.event_repeat_rounded,
        ));
      }

      // Sort by time (newest first)
      items.sort((a, b) => b.time.compareTo(a.time));

    } catch (e) {
      print('Error loading notifications: $e');
    }

    if (mounted) {
      setState(() {
        _notifications = items;
        _isLoading = false;
      });
      _controller.forward();
    }
  }

  Future<void> _dismissNotification(int index) async {
    final removedItem = _notifications[index];
    
    // Actually handle the notification based on type
    try {
      await _handleNotificationAction(removedItem);
    } catch (e) {
      print('Error handling notification action: $e');
    }
    
    setState(() {
      _notifications.removeAt(index);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Notification cleared'),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'Undo',
          textColor: Colors.white,
          onPressed: () {
            setState(() {
              _notifications.insert(index, removedItem);
            });
          },
        ),
      ),
    );
  }

  Future<void> _handleNotificationAction(_NotificationItem notification) async {
    // Extract ID from notification id (format: type_actualId)
    final parts = notification.id.split('_');
    if (parts.length < 2) return;
    
    final type = parts[0];
    final actualId = parts.sublist(1).join('_');
    
    switch (type) {
      case 'apt':
        // Mark appointment as confirmed/processed
        await DatabaseHelper.instance.updateAppointmentStatus(actualId, 'confirmed');
        break;
      case 'pay':
        // Mark payment as read (we can add a 'read' field or just skip for now)
        // For now, payments require manual action in payment screen
        break;
      case 'fu':
        // Follow-up notifications are informational - just dismissed locally
        break;
    }
  }

  Future<void> _clearAllNotifications() async {
    setState(() {
      _notifications.clear();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications cleared'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF6B21A8).withOpacity(0.9),
                    const Color(0xFF0EA5E9).withOpacity(0.9),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
        ),
        actions: [
          if (_notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all_rounded, color: Colors.white),
              tooltip: 'Clear All',
              onPressed: _clearAllNotifications,
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadNotifications,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF3F4F6), Color(0xFFE5E7EB)],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _notifications.isEmpty
                ? _buildEmptyState()
                : _buildNotificationList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.notifications_off_rounded,
              size: 64,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'All caught up!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No new notifications at the moment.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 100, 16, 20), // Top padding for AppBar
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        return Dismissible(
          key: Key(notification.id),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => _dismissNotification(index),
          background: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.red.shade400,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 32),
          ),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.5),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _controller,
              curve: Interval(
                index * 0.1,
                1.0,
                curve: Curves.easeOutQuint,
              ),
            )),
            child: FadeTransition(
              opacity: Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
                parent: _controller,
                curve: Interval(index * 0.1, 1.0, curve: Curves.easeOut),
              )),
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        // Handle tap if needed (e.g., navigate to details)
                      },
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              width: 6,
                              color: notification.color,
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: notification.color.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        notification.icon,
                                        color: notification.color,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  notification.title,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: Color(0xFF1F2937),
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                _getTimeAgo(notification.time),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[400],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            notification.message,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                              height: 1.4,
                                            ),
                                          ),
                                        ],
                                      ),
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
            ),
          ),
        );
      },
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

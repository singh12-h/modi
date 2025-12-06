import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'database_helper.dart';
import 'models.dart';
import 'patient_detail_view.dart'; // Assuming this exists for navigation

class FollowUpAppointments extends StatefulWidget {
  const FollowUpAppointments({super.key});

  @override
  State<FollowUpAppointments> createState() => _FollowUpAppointmentsState();
}

class _FollowUpAppointmentsState extends State<FollowUpAppointments> with SingleTickerProviderStateMixin {
  List<Consultation> _followUps = [];
  bool _isLoading = true;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _loadFollowUps();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadFollowUps() async {
    setState(() => _isLoading = true);
    final followUps = await DatabaseHelper.instance.getUpcomingFollowUps();
    
    if (mounted) {
      setState(() {
        _followUps = followUps;
        _isLoading = false;
      });
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Follow-up Schedule', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
                    const Color(0xFF6B21A8).withOpacity(0.8),
                    const Color(0xFF0EA5E9).withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadFollowUps,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E1E2E), // Dark background
              Color(0xFF2D2D44),
            ],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF22D3EE)))
            : _followUps.isEmpty
                ? _buildEmptyState()
                : _buildFollowUpList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF22D3EE).withOpacity(0.1),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: const Icon(
              Icons.event_available_rounded,
              size: 80,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Upcoming Follow-ups',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your schedule is clear for now.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowUpList() {
    // Group by date
    final grouped = <String, List<Consultation>>{};
    for (var fu in _followUps) {
      if (fu.followUpDate == null) continue;
      final dateKey = _getDateLabel(fu.followUpDate!);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(fu);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 100, 16, 20),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final dateKey = grouped.keys.elementAt(index);
        final consultations = grouped[dateKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getDateColor(dateKey).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _getDateColor(dateKey).withOpacity(0.5)),
                    ),
                    child: Text(
                      dateKey,
                      style: TextStyle(
                        color: _getDateColor(dateKey),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Divider(
                      color: Colors.white.withOpacity(0.1),
                      thickness: 1,
                    ),
                  ),
                ],
              ),
            ),
            ...consultations.map((c) => _buildFollowUpCard(c, index)).toList(),
          ],
        );
      },
    );
  }

  Color _getDateColor(String label) {
    if (label == 'Today') return const Color(0xFF22D3EE); // Cyan
    if (label == 'Tomorrow') return const Color(0xFFA855F7); // Purple
    return Colors.white70;
  }

  String _getDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final checkDate = DateTime(date.year, date.month, date.day);

    if (checkDate == today) return 'Today';
    if (checkDate == tomorrow) return 'Tomorrow';
    return DateFormat('EEEE, d MMM').format(date);
  }

  Widget _buildFollowUpCard(Consultation consultation, int index) {
    return FutureBuilder<Patient?>(
      future: DatabaseHelper.instance.getPatient(consultation.patientId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final patient = snapshot.data!;

        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.2),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: _controller,
            curve: Interval(
              index * 0.05,
              1.0,
              curve: Curves.easeOutQuint,
            ),
          )),
          child: FadeTransition(
            opacity: _controller,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PatientDetailView(patient: patient),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Avatar
                        Hero(
                          tag: 'avatar_${patient.id}',
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: patient.gender == 'Male'
                                    ? [const Color(0xFF3B82F6), const Color(0xFF06B6D4)]
                                    : [const Color(0xFFEC4899), const Color(0xFFA855F7)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (patient.gender == 'Male'
                                          ? const Color(0xFF3B82F6)
                                          : const Color(0xFFEC4899))
                                      .withOpacity(0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                patient.name[0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                patient.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.phone_rounded, size: 14, color: Colors.white.withOpacity(0.6)),
                                  const SizedBox(width: 4),
                                  Text(
                                    patient.mobile,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      patient.token,
                                      style: const TextStyle(
                                        color: Color(0xFF22D3EE),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Last Visit Reason
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.history_rounded, size: 14, color: Color(0xFFA855F7)),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Prev: ${consultation.diagnosis.isNotEmpty ? consultation.diagnosis : "Consultation"}',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.8),
                                          fontSize: 12,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Action Button
                        const SizedBox(width: 8),
                        Column(
                          children: [
                            IconButton(
                              onPressed: () {
                                // Call functionality
                              },
                              icon: const Icon(Icons.call, color: Color(0xFF22D3EE)),
                              style: IconButton.styleFrom(
                                backgroundColor: const Color(0xFF22D3EE).withOpacity(0.1),
                              ),
                            ),
                          ],
                        ),
                      ],
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
}

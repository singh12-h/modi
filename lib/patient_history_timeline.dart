import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'models.dart';
import 'database_helper.dart';

class PatientHistoryTimeline extends StatefulWidget {
  final Patient? patient;

  const PatientHistoryTimeline({super.key, this.patient});

  @override
  State<PatientHistoryTimeline> createState() => _PatientHistoryTimelineState();
}

class _PatientHistoryTimelineState extends State<PatientHistoryTimeline> {
  List<Consultation> _consultations = [];
  List<Payment> _payments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    if (widget.patient == null) return;

    setState(() => _isLoading = true);

    try {
      final consultations = await DatabaseHelper.instance.getConsultations(widget.patient!.id);
      final payments = await DatabaseHelper.instance.getPaymentsByPatient(widget.patient!.id);

      setState(() {
        _consultations = consultations;
        _payments = payments;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading history: $e');
      setState(() => _isLoading = false);
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.patient?.name ?? "Patient"} - History Timeline'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _consultations.isEmpty && _payments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No History Available',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildPatientSummary(),
                    const SizedBox(height: 24),
                    if (_consultations.isNotEmpty) ...[
                      _buildSectionHeader('Consultations', Icons.medical_services, Colors.blue),
                      const SizedBox(height: 12),
                      ..._consultations.map((consultation) => _buildConsultationCard(consultation)),
                      const SizedBox(height: 24),
                    ],
                    if (_payments.isNotEmpty) ...[
                      _buildSectionHeader('Payment History', Icons.payment, Colors.green),
                      const SizedBox(height: 12),
                      ..._payments.map((payment) => _buildPaymentCard(payment)),
                    ],
                  ],
                ),
    );
  }

  Widget _buildPatientSummary() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFF1976D2),
                  child: Text(
                    widget.patient?.name[0].toUpperCase() ?? 'P',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.patient?.name ?? 'Unknown',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.patient?.age ?? 'N/A'}y • ${widget.patient?.gender ?? 'N/A'}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem('Total Visits', '${_consultations.length}', Icons.medical_services, Colors.blue),
                _buildSummaryItem('Total Payments', '${_payments.length}', Icons.payment, Colors.green),
                _buildSummaryItem('Total Amount', '₹${_payments.fold<double>(0, (sum, p) => sum + p.amount).toStringAsFixed(0)}', Icons.currency_rupee, Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildConsultationCard(Consultation consultation) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDate(consultation.date),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1976D2)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Visit #${_consultations.indexOf(consultation) + 1}',
                    style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                  ),
                ),
              ],
            ),
            if (consultation.diagnosis.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildInfoRow('Diagnosis', consultation.diagnosis, Icons.healing),
            ],
            if (consultation.reason.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInfoRow('Reason', consultation.reason, Icons.sick),
            ],
            if (consultation.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInfoRow('Notes', consultation.notes, Icons.note),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard(Payment payment) {
    final isPaid = payment.status.toLowerCase() == 'paid';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isPaid ? Colors.green[50] : Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isPaid ? Icons.check_circle : Icons.pending,
                color: isPaid ? Colors.green : Colors.orange,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '₹${payment.amount.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(payment.date),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  if (payment.paymentMethod != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'via ${payment.paymentMethod}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isPaid ? Colors.green : Colors.orange,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isPaid ? 'PAID' : 'PENDING',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

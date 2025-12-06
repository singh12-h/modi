import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'prescription_page.dart';
import 'consultation_screen.dart';
import 'models.dart';
import 'patient_history_timeline.dart';
import 'database_helper.dart';


class PatientDetailView extends StatefulWidget {
  final Patient? patient;
  final Function(PatientStatus)? onStatusUpdate;

  const PatientDetailView({super.key, this.patient, this.onStatusUpdate});

  @override
  State<PatientDetailView> createState() => _PatientDetailViewState();
}

class _PatientDetailViewState extends State<PatientDetailView> {
  Patient? _patient;
  final DatabaseHelper _db = DatabaseHelper.instance;
  MedicalHistory? _medicalHistory;
  List<Prescription> _currentPrescriptions = [];
  List<Consultation> _consultations = [];
  List<Payment> _payments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _patient = widget.patient;
    _loadPatientData();
  }

  Future<void> _loadPatientData() async {
    if (_patient == null) return;

    setState(() => _isLoading = true);

    try {
      print('PatientDetailView: Loading data for patient ${_patient!.id}');
      // Reload patient to get latest status
      final updatedPatient = await _db.getPatient(_patient!.id);
      if (updatedPatient != null) {
        print('PatientDetailView: Updated patient status: ${updatedPatient.status}');
        _patient = updatedPatient;
        // Notify parent about status change
        if (widget.onStatusUpdate != null) {
          widget.onStatusUpdate!(_patient!.status);
        }
      }

      final medHistory = await _db.getMedicalHistory(_patient!.id);
      final prescriptions = await _db.getCurrentPrescriptions(_patient!.id);
      final consultations = await _db.getConsultations(_patient!.id);
      final payments = await _db.getPaymentsByPatient(_patient!.id);
      
      print('PatientDetailView: Loaded ${consultations.length} consultations, ${payments.length} payments');

      setState(() {
        _medicalHistory = medHistory;
        _currentPrescriptions = prescriptions;
        _consultations = consultations;
        _payments = payments;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading patient data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markPaymentAsPaid(Payment payment) async {
    // Show dialog to select payment mode
    String? selectedMode = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('Select Payment Mode'),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'Cash'),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Row(children: [Icon(Icons.money, color: Colors.green), SizedBox(width: 10), Text('Cash')]),
              ),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'UPI'),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Row(children: [Icon(Icons.qr_code, color: Colors.blue), SizedBox(width: 10), Text('UPI / GPay / PhonePe')]),
              ),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'Card'),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Row(children: [Icon(Icons.credit_card, color: Colors.orange), SizedBox(width: 10), Text('Card')]),
              ),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'Online'),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Row(children: [Icon(Icons.language, color: Colors.purple), SizedBox(width: 10), Text('Online / Net Banking')]),
              ),
            ),
          ],
        );
      },
    );

    if (selectedMode == null) return; // User cancelled

    try {
      final updatedPayment = Payment(
        id: payment.id,
        patientId: payment.patientId,
        patientName: payment.patientName,
        token: payment.token,
        amount: payment.amount,
        status: 'paid',
        date: payment.date,
        paymentDate: DateTime.now(),
        paymentMethod: selectedMode,
        notes: payment.notes,
      );
      
      await _db.updatePayment(updatedPayment);
      _loadPatientData(); // Reload to reflect changes
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment marked as PAID via $selectedMode'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      print('Error updating payment: $e');
    }
  }

  // ... (existing methods)

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Patient Details', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPatientData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildCompactHeader(),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        _buildQuickStats(),
                        const SizedBox(height: 12),
                        _buildPaymentStatus(), // Added Payment Status
                        const SizedBox(height: 12),
                        _buildContactInfo(),
                        const SizedBox(height: 10),
                        _buildMedicalHistory(),
                        const SizedBox(height: 10),
                        _buildCurrentPrescription(),
                        const SizedBox(height: 10),
                        _buildPreviousVisits(),
                        const SizedBox(height: 12),
                        _buildActionButtons(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _createManualPayment() async {
    final amountController = TextEditingController(text: '500');
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Payment Record'),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Consultation Fee (₹)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (amountController.text.isNotEmpty && _patient != null) {
                final payment = Payment(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  patientId: _patient!.id,
                  patientName: _patient!.name,
                  token: _patient!.token,
                  amount: double.tryParse(amountController.text) ?? 500.0,
                  status: 'pending',
                  date: DateTime.now(),
                  notes: 'Manual Entry',
                );
                await _db.insertPayment(payment);
                Navigator.pop(context);
                _loadPatientData();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentStatus() {
    // Find the most recent pending payment, or the most recent payment
    Payment? displayPayment;
    if (_payments.isNotEmpty) {
      // Prefer pending payments
      displayPayment = _payments.firstWhere(
        (p) => p.status.toLowerCase() == 'pending',
        orElse: () => _payments.first, // Assuming sorted by date desc, or just take first
      );
    }

    if (displayPayment == null) {
      return Card(
        elevation: 2,
        color: Colors.grey[100],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey.withOpacity(0.5)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.grey),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'No Payment Record',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54),
                ),
              ),
              ElevatedButton(
                onPressed: _createManualPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text('Add Fee'),
              ),
            ],
          ),
        ),
      );
    }

    final isPending = displayPayment.status.toLowerCase() == 'pending';

    return Card(
      elevation: 2,
      color: isPending ? const Color(0xFFFFF3E0) : const Color(0xFFE8F5E9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: isPending ? Colors.orange.withOpacity(0.5) : Colors.green.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isPending ? Colors.orange : Colors.green,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPending ? Icons.pending_actions : Icons.check_circle,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isPending ? 'Payment Pending' : 'Payment Complete',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isPending ? Colors.orange[900] : Colors.green[900],
                    ),
                  ),
                  Text(
                    'Amount: ₹${displayPayment.amount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: isPending ? Colors.orange[800] : Colors.green[800],
                    ),
                  ),
                ],
              ),
            ),
            if (isPending)
              ElevatedButton(
                onPressed: () => _markPaymentAsPaid(displayPayment!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text('Collect'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF1976D2), Colors.blue[700]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _showPhotoDialog(),
            child: Hero(
              tag: 'patient_photo_${_patient?.id}',
              child: CircleAvatar(
                radius: 35,
                backgroundColor: Colors.white,
                backgroundImage: _patient?.photoPath != null
                    ? (kIsWeb
                        ? NetworkImage(_patient!.photoPath!) as ImageProvider
                        : FileImage(File(_patient!.photoPath!)))
                    : null,
                child: _patient?.photoPath == null
                    ? Text(
                        _patient?.name[0].toUpperCase() ?? 'P',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1976D2)),
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _patient?.name ?? 'Unknown',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Token: ${_patient?.token ?? 'N/A'}',
                        style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_patient?.age ?? 'N/A'}y • ${_patient?.gender ?? 'N/A'}',
                      style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPhotoDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(
              child: Hero(
                tag: 'patient_photo_${_patient?.id}',
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400, maxHeight: 400),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _patient?.photoPath != null
                        ? (kIsWeb
                            ? Image.network(
                                _patient!.photoPath!,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => _buildPlaceholderPhoto(),
                              )
                            : Image.file(
                                File(_patient!.photoPath!),
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => _buildPlaceholderPhoto(),
                              ))
                        : _buildPlaceholderPhoto(),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 40,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withOpacity(0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderPhoto() {
    return Container(
      width: 400,
      height: 400,
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _patient?.gender == 'Male' ? Icons.person : Icons.person_outline,
            size: 120,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _patient?.name ?? 'No Photo',
            style: TextStyle(fontSize: 20, color: Colors.grey[600], fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(child: _buildStatCard(Icons.calendar_today, 'Registered', _formatDate(_patient?.registeredDate ?? _patient?.registrationTime ?? DateTime.now()), Colors.blue)),
        const SizedBox(width: 8),
        Expanded(child: _buildStatCard(Icons.medical_services, 'Total Visits', '${_patient?.consultationCount ?? 0}', Colors.green)),
        const SizedBox(width: 8),
        Expanded(child: _buildStatCard(Icons.access_time, 'Last Visit', _patient?.lastVisit != null ? _formatDate(_patient!.lastVisit!) : 'Never', Colors.orange)),
      ],
    );
  }

  Widget _buildStatCard(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600]), textAlign: TextAlign.center),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildContactInfo() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.contact_phone, color: Colors.blue[700], size: 18),
                const SizedBox(width: 8),
                const Text('Contact', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 12),
            _buildCompactInfoRow(Icons.phone, _patient?.mobile ?? 'N/A'),
            if (_patient?.address != null && _patient!.address!.isNotEmpty) ...[
              const SizedBox(height: 6),
              _buildCompactInfoRow(Icons.location_on, _patient!.address!),
            ],
            if (_patient?.emergencyContact != null && _patient!.emergencyContact!.isNotEmpty) ...[
              const SizedBox(height: 6),
              _buildCompactInfoRow(Icons.emergency, _patient!.emergencyContact!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalHistory() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.medical_information, color: Colors.red[700], size: 18),
                const SizedBox(width: 8),
                const Text('Medical History', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 12),
            if (_medicalHistory != null) ...[
              if (_medicalHistory!.currentDiagnosis.isNotEmpty) _buildCompactInfoRow(Icons.healing, _medicalHistory!.currentDiagnosis),
              if (_medicalHistory!.bloodGroup.isNotEmpty) ...[
                const SizedBox(height: 6),
                _buildCompactInfoRow(Icons.bloodtype, 'Blood: ${_medicalHistory!.bloodGroup}'),
              ],
              if (_medicalHistory!.allergies.isNotEmpty) ...[
                const SizedBox(height: 6),
                _buildCompactInfoRow(Icons.warning, 'Allergies: ${_medicalHistory!.allergies}'),
              ],
            ] else
              Text('No medical history', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentPrescription() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.medication, color: Colors.green[700], size: 18),
                const SizedBox(width: 8),
                const Text('Current Prescription', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 12),
            if (_currentPrescriptions.isNotEmpty)
              ..._currentPrescriptions.map((rx) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(Icons.circle, size: 5, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('${rx.medicineName} - ${rx.dosage}, ${rx.frequency}', style: const TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
              ))
            else
              Text('No active prescription', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviousVisits() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.history, color: Colors.purple[700], size: 18),
                    const SizedBox(width: 8),
                    Text('Previous Visits (${_consultations.length})', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  ],
                ),
                if (_consultations.length > 3)
                  TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => PatientHistoryTimeline(patient: _patient)));
                    },
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30)),
                    child: const Text('View All', style: TextStyle(fontSize: 13)),
                  ),
              ],
            ),
            const Divider(height: 12),
            if (_consultations.isNotEmpty)
              ..._consultations.take(3).map((visit) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(color: Colors.purple[700], shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_formatDate(visit.date), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          if (visit.diagnosis.isNotEmpty) Text(visit.diagnosis, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                        ],
                      ),
                    ),
                  ],
                ),
              ))
            else
              Text('No previous visits', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ConsultationScreen(patient: _patient)),
                  );
                  // Always reload to reflect status changes (e.g. In Progress)
                  _loadPatientData();
                },
                icon: Icon(_patient?.status == PatientStatus.inProgress ? Icons.play_arrow : Icons.add_circle, size: 18),
                label: Text(_patient?.status == PatientStatus.inProgress ? 'Continue Consultation' : 'Start Consultation', style: const TextStyle(fontSize: 14)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _patient?.status == PatientStatus.inProgress ? Colors.orange[700] : Colors.green[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => PatientHistoryTimeline(patient: _patient)));
                },
                icon: const Icon(Icons.timeline, size: 16),
                label: const Text('Timeline', style: TextStyle(fontSize: 14)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue[700],
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _sendWhatsApp,
            icon: const Icon(Icons.chat, size: 18),
            label: const Text('Send WhatsApp Message', style: TextStyle(fontSize: 14)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _sendWhatsApp({String? customMessage}) async {
    if (_patient == null) return;
    
    try {
      final String message = customMessage ?? '''🏥 *MODI CLINIC*

Dear *${_patient!.name}*,

📋 *Token Number:* ${_patient!.token}
👨‍⚕️ *Doctor's Message*

Your consultation details and prescription are ready.

For any queries, please contact us.

Thank you! 🙏''';

      // WhatsApp URL scheme
      String phoneNumber = _patient!.mobile.replaceAll(RegExp(r'[^0-9]'), '');
      
      // Add country code if not present (assuming India +91)
      if (!phoneNumber.startsWith('91') && phoneNumber.length == 10) {
        phoneNumber = '91$phoneNumber';
      }

      final Uri whatsappUri = Uri.parse(
        'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}'
      );

      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open WhatsApp'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error sending WhatsApp: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

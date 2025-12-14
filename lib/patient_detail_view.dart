import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'prescription_page.dart';
import 'consultation_screen.dart';
import 'models.dart';
import 'patient_history_timeline.dart';
import 'database_helper.dart';
import 'responsive_helper.dart';


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
  List<PaymentInstallment> _installmentPayments = [];
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
      final installments = await _db.getPaymentInstallmentsByPatient(_patient!.id);
      
      print('PatientDetailView: Loaded ${consultations.length} consultations, ${payments.length} payments, ${installments.length} installments');

      setState(() {
        _medicalHistory = medHistory;
        _currentPrescriptions = prescriptions;
        _consultations = consultations;
        _payments = payments;
        _installmentPayments = installments;
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
    // Load fee settings first
    final settings = await _db.getPaymentSettings();
    final doctorFees = settings?['doctorFees'] ?? 500.0;
    
    final amountController = TextEditingController(text: doctorFees.toStringAsFixed(0));
    final otherChargesController = TextEditingController(text: '0');
    String paymentFor = 'Consultation';
    bool useInstallment = false;
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final consultationFee = double.tryParse(amountController.text) ?? 0.0;
          final otherCharges = double.tryParse(otherChargesController.text) ?? 0.0;
          final totalAmount = consultationFee + otherCharges;
          
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.add_card, color: Color(0xFF6B21A8)),
                const SizedBox(width: 8),
                const Text('💳 Add Payment', style: TextStyle(fontSize: 18)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Payment Purpose Dropdown
                  const Text('Payment For', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: paymentFor,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: InputBorder.none,
                      ),
                      items: [
                        'Consultation',
                        'Follow-up',
                        'Medicine',
                        'Procedure',
                        'Lab Test',
                        'Surgery',
                        'Physiotherapy',
                        'Injection',
                        'Dressing',
                        'Other',
                      ].map((purpose) => DropdownMenuItem(
                        value: purpose,
                        child: Row(
                          children: [
                            Icon(_getPaymentPurposeIcon(purpose), size: 18, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Text(purpose),
                          ],
                        ),
                      )).toList(),
                      onChanged: (value) => setState(() => paymentFor = value!),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Consultation/Service Fee
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: paymentFor == 'Consultation' ? 'Consultation Fee' : '$paymentFor Fee',
                      prefixText: '₹ ',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.refresh, size: 18),
                        tooltip: 'Reset to default fee',
                        onPressed: () {
                          amountController.text = doctorFees.toStringAsFixed(0);
                          setState(() {});
                        },
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  
                  // Other Charges
                  TextField(
                    controller: otherChargesController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Other Charges (Medicine/Instruments)',
                      prefixText: '₹ ',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  
                  // Total Amount Display
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B21A8).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF6B21A8).withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Amount:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          '₹${totalAmount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6B21A8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Installment Option
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CheckboxListTile(
                      value: useInstallment,
                      onChanged: (value) => setState(() => useInstallment = value!),
                      title: const Text('Enable Installment', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Allow partial payments', style: TextStyle(fontSize: 12)),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton.icon(
                onPressed: () async {
                  if (amountController.text.isNotEmpty && _patient != null) {
                    final serviceFee = double.tryParse(amountController.text) ?? doctorFees;
                    final otherCharges = double.tryParse(otherChargesController.text) ?? 0.0;
                    final total = serviceFee + otherCharges;
                    
                    if (useInstallment) {
                      // Create installment payment
                      final installment = PaymentInstallment(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        patientId: _patient!.id,
                        patientName: _patient!.name,
                        totalAmount: total,
                        serviceCharges: serviceFee,
                        instrumentCharges: otherCharges,
                        status: 'PENDING',
                        paymentFor: paymentFor,
                      );
                      await _db.insertPaymentInstallment(installment);
                    } else {
                      // Create regular payment
                      final payment = Payment(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        patientId: _patient!.id,
                        patientName: _patient!.name,
                        token: _patient!.token,
                        amount: total,
                        status: 'pending',
                        date: DateTime.now(),
                        notes: '$paymentFor${otherCharges > 0 ? " + Other Charges" : ""}',
                      );
                      await _db.insertPayment(payment);
                    }
                    Navigator.pop(context);
                    _loadPatientData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✅ Payment added: ₹${total.toStringAsFixed(0)} for $paymentFor'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.save),
                label: const Text('Add Payment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B21A8),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  IconData _getPaymentPurposeIcon(String purpose) {
    switch (purpose) {
      case 'Consultation': return Icons.medical_services;
      case 'Follow-up': return Icons.replay;
      case 'Medicine': return Icons.medication;
      case 'Procedure': return Icons.healing;
      case 'Lab Test': return Icons.science;
      case 'Surgery': return Icons.local_hospital;
      case 'Physiotherapy': return Icons.accessibility_new;
      case 'Injection': return Icons.vaccines;
      case 'Dressing': return Icons.personal_injury;
      default: return Icons.receipt;
    }
  }


  Widget _buildPaymentStatus() {
    // Check for installment payments first
    if (_installmentPayments.isNotEmpty) {
      final installment = _installmentPayments.first;
      final isFullPaid = installment.status == 'FULL_PAID';
      final isPartial = installment.status == 'PARTIAL';
      
      Color statusColor;
      IconData statusIcon;
      String statusText;
      
      if (isFullPaid) {
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Payment Complete';
      } else if (isPartial) {
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        statusText = 'Partial Payment';
      } else {
        statusColor = Colors.red;
        statusIcon = Icons.pending_actions;
        statusText = 'Payment Pending';
      }

      return Card(
        elevation: 2,
        color: isFullPaid ? const Color(0xFFE8F5E9) : (isPartial ? const Color(0xFFFFF3E0) : const Color(0xFFFFEBEE)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: statusColor.withOpacity(0.5)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(statusIcon, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              'Total: ₹${installment.totalAmount.toStringAsFixed(0)}',
                              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                            ),
                            if (installment.paymentFor != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6B21A8).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(_getPaymentPurposeIcon(installment.paymentFor!), size: 12, color: const Color(0xFF6B21A8)),
                                    const SizedBox(width: 4),
                                    Text(
                                      installment.paymentFor!,
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF6B21A8), fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Edit Button - Only when not full paid
                  if (!isFullPaid)
                    IconButton(
                      onPressed: () => _showEditInstallmentDialog(installment),
                      icon: const Icon(Icons.edit, color: Color(0xFF6B21A8)),
                      tooltip: 'Edit Bill',
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // Payment Details Row
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildPaymentInfoChip('Paid', '₹${installment.paidAmount.toStringAsFixed(0)}', Colors.green),
                    _buildPaymentInfoChip('Remaining', '₹${installment.remainingAmount.toStringAsFixed(0)}', Colors.red),
                  ],
                ),
              ),
              // Action Buttons
              if (!isFullPaid) ...[

                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _addInstallmentPayment(installment),
                        icon: const Icon(Icons.payment, size: 18),
                        label: const Text('Add Payment'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6B21A8),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _markInstallmentFullPaid(installment),
                        icon: const Icon(Icons.check_circle, size: 18),
                        label: const Text('Full Paid'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              // View Transaction History Button
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showPaymentAccountDialog(installment),
                  icon: const Icon(Icons.history, size: 16),
                  label: const Text('View All Transactions'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF6B21A8),
                    side: const BorderSide(color: Color(0xFF6B21A8)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }


    // Fallback to regular payment display
    Payment? displayPayment;
    if (_payments.isNotEmpty) {
      displayPayment = _payments.firstWhere(
        (p) => p.status.toLowerCase() == 'pending',
        orElse: () => _payments.first,
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

  Widget _buildPaymentInfoChip(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  // Show Payment Account Dialog - All transactions with account-style view
  Future<void> _showPaymentAccountDialog(PaymentInstallment installment) async {
    // Load all transactions for this installment
    final transactions = await _db.getPaymentTransactions(installment.id);
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF6B21A8),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                installment.patientName,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              Text(
                                'Payment Account',
                                style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8)),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Bill Summary Row
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildAccountSummaryItem('Total Bill', '₹${installment.totalAmount.toStringAsFixed(0)}', Colors.white),
                          Container(width: 1, height: 30, color: Colors.white.withOpacity(0.3)),
                          _buildAccountSummaryItem('Paid', '₹${installment.paidAmount.toStringAsFixed(0)}', Colors.greenAccent),
                          Container(width: 1, height: 30, color: Colors.white.withOpacity(0.3)),
                          _buildAccountSummaryItem('Due', '₹${installment.remainingAmount.toStringAsFixed(0)}', Colors.redAccent),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Transactions List
              Flexible(
                child: transactions.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.receipt_long, size: 60, color: Colors.grey[300]),
                            const SizedBox(height: 12),
                            Text('No transactions yet', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                            const SizedBox(height: 8),
                            Text('Payment history will appear here', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        shrinkWrap: true,
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          final txn = transactions[index];
                          return _buildTransactionItem(txn, index + 1);
                        },
                      ),
              ),
              
              // Footer with details
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                  border: Border(top: BorderSide(color: Colors.grey[200]!)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_getPaymentPurposeIcon(installment.paymentFor ?? 'Consultation'), size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${installment.paymentFor ?? 'Consultation'} • ${DateFormat('dd MMM yy').format(installment.createdAt)}',
                            style: TextStyle(color: Colors.grey[600], fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: installment.status == 'FULL_PAID' 
                            ? Colors.green.withOpacity(0.1) 
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: installment.status == 'FULL_PAID' ? Colors.green : Colors.orange,
                        ),
                      ),
                      child: Text(
                        installment.status == 'FULL_PAID' 
                            ? '✓ Account Settled' 
                            : 'Due: ₹${installment.remainingAmount.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: installment.status == 'FULL_PAID' ? Colors.green : Colors.orange,
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

  Widget _buildAccountSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.7))),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildTransactionItem(PaymentTransaction txn, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Transaction Number Circle
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF6B21A8).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#$index',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6B21A8),
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Transaction Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      DateFormat('dd MMM yyyy').format(txn.paymentDate),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getPaymentModeColor(txn.paymentMode).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        txn.paymentMode,
                        style: TextStyle(fontSize: 10, color: _getPaymentModeColor(txn.paymentMode), fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Receipt: ${txn.receiptNumber}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (txn.notes != null && txn.notes!.isNotEmpty)
                  Text(
                    txn.notes!,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600], fontStyle: FontStyle.italic),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          // Amount
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+₹${txn.amountPaid.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              Text(
                DateFormat('hh:mm a').format(txn.paymentDate),
                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getPaymentModeColor(String mode) {
    switch (mode.toLowerCase()) {
      case 'cash': return Colors.green;
      case 'upi': return Colors.blue;
      case 'card': return Colors.orange;
      case 'cheque': return Colors.purple;
      default: return Colors.grey;
    }
  }

  // Add payment to installment
  Future<void> _addInstallmentPayment(PaymentInstallment installment) async {
    final amountController = TextEditingController();
    String paymentMode = 'Cash';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('💵 Add Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.pending, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(
                      'Remaining: ₹${installment.remainingAmount.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount Paying',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                autofocus: true,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: paymentMode,
                decoration: const InputDecoration(
                  labelText: 'Payment Mode',
                  border: OutlineInputBorder(),
                ),
                items: ['Cash', 'UPI', 'Card', 'Cheque']
                    .map((mode) => DropdownMenuItem(value: mode, child: Text(mode)))
                    .toList(),
                onChanged: (value) => setState(() => paymentMode = value!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(amountController.text) ?? 0.0;
                if (amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('❌ Amount must be greater than 0'), backgroundColor: Colors.red),
                  );
                  return;
                }
                if (amount > installment.remainingAmount) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('❌ Amount exceeds remaining balance'), backgroundColor: Colors.red),
                  );
                  return;
                }
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6B21A8), foregroundColor: Colors.white),
              child: const Text('Add Payment'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      final amount = double.tryParse(amountController.text) ?? 0.0;
      final receiptNumber = _db.generateReceiptNumber();
      const uuid = Uuid();
      
      final transaction = PaymentTransaction(
        id: uuid.v4(),
        paymentId: installment.id,
        amountPaid: amount,
        paymentMode: paymentMode,
        receivedBy: 'Doctor',
        receiptNumber: receiptNumber,
        notes: 'Payment added',
      );
      
      await _db.addPaymentTransaction(transaction);
      _loadPatientData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Payment added: ₹${amount.toStringAsFixed(0)}'), backgroundColor: Colors.green),
        );
      }
    }
  }

  // Mark installment as full paid
  Future<void> _markInstallmentFullPaid(PaymentInstallment installment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('✅ Mark as Full Paid?'),
        content: Text('Patient: ${installment.patientName}\n\nPaying: ₹${installment.remainingAmount.toStringAsFixed(0)}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      const uuid = Uuid();
      final receiptNumber = _db.generateReceiptNumber();
      
      final transaction = PaymentTransaction(
        id: uuid.v4(),
        paymentId: installment.id,
        amountPaid: installment.remainingAmount,
        paymentMode: 'Cash',
        receivedBy: 'Doctor',
        receiptNumber: receiptNumber,
        notes: 'Final Payment - Full Paid',
      );
      
      await _db.addPaymentTransaction(transaction);
      _loadPatientData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('🎉 ${installment.patientName} - FULL PAID!'), backgroundColor: Colors.green),
        );
      }
    }
  }

  // Edit installment bill
  Future<void> _showEditInstallmentDialog(PaymentInstallment installment) async {
    // Load fee settings
    final settings = await _db.getPaymentSettings();
    final doctorFees = settings?['doctorFees'] ?? 500.0;
    
    final consultationController = TextEditingController(text: installment.serviceCharges.toStringAsFixed(0));
    final otherController = TextEditingController(text: installment.instrumentCharges.toStringAsFixed(0));
    String paymentFor = installment.paymentFor ?? 'Consultation';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final consultation = double.tryParse(consultationController.text) ?? 0.0;
          final other = double.tryParse(otherController.text) ?? 0.0;
          final newTotal = consultation + other;
          final newRemaining = newTotal - installment.paidAmount;
          
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.edit, color: Color(0xFF6B21A8)),
                const SizedBox(width: 8),
                const Expanded(child: Text('✏️ Edit Bill', style: TextStyle(fontSize: 16))),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Already Paid Warning
                  if (installment.paidAmount > 0)
                    Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.orange, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Already Paid: ₹${installment.paidAmount.toStringAsFixed(0)}\nNew total must be ≥ paid amount',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Payment Purpose Dropdown
                  const Text('Payment For', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: paymentFor,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: InputBorder.none,
                      ),
                      items: [
                        'Consultation',
                        'Follow-up',
                        'Medicine',
                        'Procedure',
                        'Lab Test',
                        'Surgery',
                        'Physiotherapy',
                        'Injection',
                        'Dressing',
                        'Other',
                      ].map((purpose) => DropdownMenuItem(
                        value: purpose,
                        child: Row(
                          children: [
                            Icon(_getPaymentPurposeIcon(purpose), size: 18, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Text(purpose),
                          ],
                        ),
                      )).toList(),
                      onChanged: (value) => setState(() => paymentFor = value!),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Service/Consultation Fee
                  TextField(
                    controller: consultationController,
                    decoration: InputDecoration(
                      labelText: paymentFor == 'Consultation' ? 'Consultation Fees' : '$paymentFor Fees',
                      prefixText: '₹ ',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.refresh, size: 18),
                        tooltip: 'Reset to default fee (₹${doctorFees.toStringAsFixed(0)})',
                        onPressed: () {
                          consultationController.text = doctorFees.toStringAsFixed(0);
                          setState(() {});
                        },
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  
                  // Other Charges
                  TextField(
                    controller: otherController,
                    decoration: const InputDecoration(
                      labelText: 'Other Charges (Medicine/Instruments)',
                      prefixText: '₹ ',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  
                  // Summary Box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B21A8).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('New Total:', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('₹${newTotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF6B21A8))),
                          ],
                        ),
                        if (installment.paidAmount > 0) ...[
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Already Paid:'),
                              Text(
                                '₹${installment.paidAmount.toStringAsFixed(0)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('New Remaining:'),
                              Text(
                                '₹${newRemaining.toStringAsFixed(0)}',
                                style: TextStyle(fontWeight: FontWeight.bold, color: newRemaining <= 0 ? Colors.green : Colors.red),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Delete Bill Option
                  if (installment.paidAmount == 0) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('🗑️ Delete Bill?'),
                            content: const Text('This will permanently delete this payment record.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await _db.deletePaymentInstallment(installment.id);
                          Navigator.pop(context, false);
                          _loadPatientData();
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(content: Text('🗑️ Bill deleted'), backgroundColor: Colors.red),
                          );
                        }
                      },
                      icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                      label: const Text('Delete Bill', style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              ElevatedButton.icon(
                onPressed: () {
                  if (newTotal <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('❌ Total must be > 0'), backgroundColor: Colors.red),
                    );
                    return;
                  }
                  if (newTotal < installment.paidAmount) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('❌ Total cannot be less than paid amount'), backgroundColor: Colors.red),
                    );
                    return;
                  }
                  Navigator.pop(context, true);
                },
                icon: const Icon(Icons.save),
                label: const Text('Save'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6B21A8), foregroundColor: Colors.white),
              ),
            ],
          );
        },
      ),
    );

    if (result == true) {
      final consultation = double.tryParse(consultationController.text) ?? 0.0;
      final other = double.tryParse(otherController.text) ?? 0.0;
      final newTotal = consultation + other;
      final newRemaining = newTotal - installment.paidAmount;
      
      final updatedInstallment = PaymentInstallment(
        id: installment.id,
        patientId: installment.patientId,
        patientName: installment.patientName,
        totalAmount: newTotal,
        instrumentCharges: other,
        serviceCharges: consultation,
        paidAmount: installment.paidAmount,
        remainingAmount: newRemaining > 0 ? newRemaining : 0,
        status: newRemaining <= 0 ? 'FULL_PAID' : installment.status,
        createdAt: installment.createdAt,
        appointmentId: installment.appointmentId,
        paymentFor: paymentFor,
      );

      await _db.updatePaymentInstallment(updatedInstallment);
      _loadPatientData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Bill updated: ₹${newTotal.toStringAsFixed(0)} for $paymentFor'), backgroundColor: Colors.green),
        );
      }
    }
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
      barrierColor: Colors.black87,
      builder: (context) => Center(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Photo Container
            Hero(
              tag: 'patient_photo_${_patient?.id}',
              child: Container(
                constraints: const BoxConstraints(maxWidth: 350, maxHeight: 350),
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
            // Close Button - On top-right corner OF the photo
            Positioned(
              top: -15,
              right: -15,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
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
            // Birth Date Display
            if (_patient?.birthDate != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.cake, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          DateFormat('dd MMM yyyy').format(_patient!.birthDate!),
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8E2DE2).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_calculateAge(_patient!.birthDate!)} yrs',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF8E2DE2),
                            ),
                          ),
                        ),
                        // Birthday indicator
                        if (_isBirthdayToday(_patient!.birthDate!)) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF0080), Color(0xFFFF8C00)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.celebration, size: 12, color: Colors.white),
                                SizedBox(width: 4),
                                Text(
                                  'Birthday Today! 🎂',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
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

  // Calculate age from birth date
  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month || 
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  // Check if birthday is today
  bool _isBirthdayToday(DateTime birthDate) {
    final now = DateTime.now();
    return birthDate.month == now.month && birthDate.day == now.day;
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
              ..._consultations.take(3).map((visit) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date and Diagnosis Row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.purple[100],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _formatDate(visit.date),
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.purple[700]),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (visit.diagnosis.isNotEmpty)
                          Expanded(
                            child: Text(
                              visit.diagnosis,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                    
                    // Medicines Section
                    if (visit.medications != null && visit.medications!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.medication, size: 14, color: Colors.green[700]),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '💊 ${visit.medications}',
                              style: TextStyle(fontSize: 12, color: Colors.green[700]),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    
                    // Notes/Prescription
                    if (visit.notes != null && visit.notes!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '📝 ${visit.notes}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    
                    // Follow-up Date
                    if (visit.followUpDate != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.calendar_today, size: 12, color: Colors.orange[700]),
                            const SizedBox(width: 4),
                            Text(
                              'Follow-up: ${visit.followUpDate}',
                              style: TextStyle(fontSize: 11, color: Colors.orange[700], fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ],
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
    // Use ResponsiveHelper for consistent responsive behavior
    ResponsiveHelper.init(context);
    
    return Column(
      children: [
        // Use ResponsiveRow for automatic wrapping on very small screens
        ResponsiveHelper.isVerySmallPhone
          ? Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ResponsiveButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ConsultationScreen(patient: _patient)),
                      );
                      _loadPatientData();
                    },
                    label: _patient?.status == PatientStatus.inProgress 
                      ? 'Continue Consultation' 
                      : 'Start Consultation',
                    icon: _patient?.status == PatientStatus.inProgress ? Icons.play_arrow : Icons.add_circle,
                    color: _patient?.status == PatientStatus.inProgress ? Colors.orange[700]! : Colors.green[600]!,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.spacingSM),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => PatientHistoryTimeline(patient: _patient)));
                    },
                    icon: Icon(Icons.timeline, size: ResponsiveHelper.iconSM),
                    label: Text('View Timeline', style: TextStyle(fontSize: ResponsiveHelper.fontSM)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue[700],
                      padding: EdgeInsets.symmetric(vertical: ResponsiveHelper.spacingSM, horizontal: ResponsiveHelper.spacingMD),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ResponsiveHelper.radiusSM)),
                    ),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  flex: 2,
                  child: ResponsiveButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ConsultationScreen(patient: _patient)),
                      );
                      _loadPatientData();
                    },
                    label: _patient?.status == PatientStatus.inProgress 
                      ? 'Continue Consultation' 
                      : 'Start Consultation',
                    icon: _patient?.status == PatientStatus.inProgress ? Icons.play_arrow : Icons.add_circle,
                    color: _patient?.status == PatientStatus.inProgress ? Colors.orange[700]! : Colors.green[600]!,
                  ),
                ),
                SizedBox(width: ResponsiveHelper.spacingSM),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => PatientHistoryTimeline(patient: _patient)));
                    },
                    icon: Icon(Icons.timeline, size: ResponsiveHelper.iconSM),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Timeline', style: TextStyle(fontSize: ResponsiveHelper.fontSM)),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue[700],
                      padding: EdgeInsets.symmetric(vertical: ResponsiveHelper.spacingSM, horizontal: ResponsiveHelper.spacingMD),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ResponsiveHelper.radiusSM)),
                    ),
                  ),
                ),
              ],
            ),
        SizedBox(height: ResponsiveHelper.spacingSM),
        SizedBox(
          width: double.infinity,
          child: ResponsiveButton(
            onPressed: () => _sendWhatsApp(),
            label: ResponsiveHelper.isVerySmallPhone ? 'WhatsApp' : 'Send WhatsApp Message',
            icon: Icons.chat,
            color: const Color(0xFF25D366),
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

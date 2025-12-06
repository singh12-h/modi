import 'package:flutter/material.dart';
import 'package:modi/database_helper.dart';
import 'package:modi/models.dart';
import 'package:intl/intl.dart';
import 'pdf_service.dart';
import 'payment_installment_screen.dart';

class PaymentManagement extends StatefulWidget {
  final bool isStaff;
  const PaymentManagement({super.key, this.isStaff = false});

  @override
  State<PaymentManagement> createState() => _PaymentManagementState();
}

class _PaymentManagementState extends State<PaymentManagement> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Payment> _allPayments = [];
  List<Payment> _pendingPayments = [];
  List<Payment> _completedPayments = [];
  
  // Settings
  double _doctorFees = 500.0;
  double _followUpFees = 250.0;
  int _followUpMonths = 3;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: widget.isStaff ? 3 : 4, vsync: this);
    _loadPayments();
    _loadSettings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPayments() async {
    final payments = await DatabaseHelper.instance.getAllPayments();
    setState(() {
      _allPayments = payments;
      _pendingPayments = payments.where((p) => p.status == 'pending').toList();
      _completedPayments = payments.where((p) => p.status == 'paid').toList();
    });
  }

  Future<void> _loadSettings() async {
    final settings = await DatabaseHelper.instance.getPaymentSettings();
    if (settings != null) {
      setState(() {
        _doctorFees = settings['doctorFees'] ?? 500.0;
        _followUpFees = settings['followUpFees'] ?? 250.0;
        _followUpMonths = settings['followUpMonths'] ?? 3;
      });
    }
  }

  Future<void> _saveSettings() async {
    await DatabaseHelper.instance.savePaymentSettings({
      'doctorFees': _doctorFees,
      'followUpFees': _followUpFees,
      'followUpMonths': _followUpMonths,
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved successfully')),
    );
  }

  double _calculateFees(Patient patient) {
    // Check if patient has previous visit
    final lastVisit = patient.registeredDate ?? patient.registrationTime;
    final monthsSinceLastVisit = DateTime.now().difference(lastVisit).inDays ~/ 30;
    
    if (monthsSinceLastVisit < _followUpMonths) {
      return _followUpFees; // Follow-up fees
    } else {
      return _doctorFees; // Fresh consultation fees
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Management'),
        backgroundColor: const Color(0xFF6B21A8),
        foregroundColor: Colors.white,
        actions: [
          // Installment Payments Button
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PaymentInstallmentScreen(
                    isStaff: widget.isStaff,
                    userName: widget.isStaff ? 'Staff' : 'Doctor',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.receipt_long, color: Colors.white),
            label: const Text(
              'Installments',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        tabs: [
            const Tab(icon: Icon(Icons.payment), text: 'All Payments'),
            const Tab(icon: Icon(Icons.pending_actions), text: 'Pending'),
            const Tab(icon: Icon(Icons.check_circle), text: 'Completed'),
            if (!widget.isStaff) const Tab(icon: Icon(Icons.settings), text: 'Settings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllPaymentsTab(),
          _buildPendingPaymentsTab(),
          _buildCompletedPaymentsTab(),
          if (!widget.isStaff) _buildSettingsTab(),
        ],
      ),
    );
  }

  Widget _buildAllPaymentsTab() {
    return Column(
      children: [
        if (!widget.isStaff) _buildPaymentSummaryCards(),
        Expanded(
          child: _allPayments.isEmpty
              ? const Center(child: Text('No payments found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _allPayments.length,
                  itemBuilder: (context, index) {
                    return _buildPaymentCard(_allPayments[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPaymentSummaryCards() {
    final totalPending = _pendingPayments.fold<double>(0, (sum, p) => sum + p.amount);
    final totalCollected = _completedPayments.fold<double>(0, (sum, p) => sum + p.amount);
    final totalAmount = totalPending + totalCollected;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'Total',
              '₹${totalAmount.toStringAsFixed(0)}',
              Icons.account_balance_wallet,
              const Color(0xFF6B21A8),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              'Collected',
              '₹${totalCollected.toStringAsFixed(0)}',
              Icons.check_circle,
              const Color(0xFF10B981),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              'Pending',
              '₹${totalPending.toStringAsFixed(0)}',
              Icons.pending,
              const Color(0xFFEF4444),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String amount, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 8),
            Text(
              amount,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard(Payment payment) {
    final isPaid = payment.status == 'paid';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showPaymentDetails(payment),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Leading Icon
              CircleAvatar(
                backgroundColor: isPaid ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                child: Icon(
                  isPaid ? Icons.check : Icons.pending,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment.patientName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Token: ${payment.token}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      'Date: ${DateFormat('dd MMM yyyy').format(payment.date)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (payment.paymentDate != null)
                      Text(
                        'Paid: ${DateFormat('dd MMM yyyy').format(payment.paymentDate!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[700],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Trailing - Amount & Status
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '₹${payment.amount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6B21A8),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isPaid ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isPaid ? 'PAID' : 'PENDING',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
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

  Widget _buildPendingPaymentsTab() {
    return _pendingPayments.isEmpty
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No pending payments', style: TextStyle(fontSize: 18)),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _pendingPayments.length,
            itemBuilder: (context, index) {
              return _buildPaymentCard(_pendingPayments[index]);
            },
          );
  }

  Widget _buildCompletedPaymentsTab() {
    return _completedPayments.isEmpty
        ? const Center(child: Text('No completed payments'))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _completedPayments.length,
            itemBuilder: (context, index) {
              return _buildPaymentCard(_completedPayments[index]);
            },
          );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Fee Settings',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  
                  // Doctor Fees
                  const Text('Fresh Consultation Fees', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      prefixText: '₹ ',
                      border: const OutlineInputBorder(),
                      hintText: 'Enter doctor fees',
                      suffixIcon: const Icon(Icons.currency_rupee),
                    ),
                    controller: TextEditingController(text: _doctorFees.toStringAsFixed(0)),
                    onChanged: (value) {
                      setState(() {
                        _doctorFees = double.tryParse(value) ?? 500.0;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  // Follow-up Months
                  const Text('Follow-up Period (Months)', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter months',
                      suffixIcon: Icon(Icons.calendar_month),
                    ),
                    controller: TextEditingController(text: _followUpMonths.toString()),
                    onChanged: (value) {
                      setState(() {
                        _followUpMonths = int.tryParse(value) ?? 3;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  // Follow-up Fees
                  const Text('Follow-up Consultation Fees', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      prefixText: '₹ ',
                      border: const OutlineInputBorder(),
                      hintText: 'Enter follow-up fees',
                      suffixIcon: const Icon(Icons.currency_rupee),
                    ),
                    controller: TextEditingController(text: _followUpFees.toStringAsFixed(0)),
                    onChanged: (value) {
                      setState(() {
                        _followUpFees = double.tryParse(value) ?? 250.0;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // Info Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B21A8).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF6B21A8).withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.info_outline, color: Color(0xFF6B21A8)),
                            SizedBox(width: 8),
                            Text(
                              'How it works:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('• Fresh Consultation: ₹${_doctorFees.toStringAsFixed(0)}'),
                        Text('• Follow-up (within $_followUpMonths months): ₹${_followUpFees.toStringAsFixed(0)}'),
                        Text('• After $_followUpMonths months: ₹${_doctorFees.toStringAsFixed(0)} (Fresh)'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  ElevatedButton.icon(
                    onPressed: _saveSettings,
                    icon: const Icon(Icons.save),
                    label: const Text('Save Settings'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6B21A8),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentDetails(Payment payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(payment.patientName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Token', payment.token),
            _buildDetailRow('Amount', '₹${payment.amount.toStringAsFixed(0)}'),
            _buildDetailRow('Date', DateFormat('dd MMM yyyy').format(payment.date)),
            _buildDetailRow('Status', payment.status.toUpperCase()),
            if (payment.paymentDate != null)
              _buildDetailRow('Payment Date', DateFormat('dd MMM yyyy').format(payment.paymentDate!)),
            if (payment.paymentMethod != null)
              _buildDetailRow('Method', payment.paymentMethod!),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          // PDF Button - Always visible
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                try {
                  final patient = await DatabaseHelper.instance.getPatient(payment.patientId);
                  if (patient != null) {
                    await PdfService.generatePaymentReceipt(payment, patient);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.picture_as_pdf, size: 20),
              label: const Text('Download Receipt PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B21A8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Mark as Paid Button - Only for pending payments
          if (payment.status == 'pending')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _markAsPaid(payment);
                },
                icon: const Icon(Icons.check, size: 20),
                label: const Text('Mark as Paid'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          if (payment.status == 'pending') const SizedBox(height: 8),
          // Close Button
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  Future<void> _markAsPaid(Payment payment) async {
    final method = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Method'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.money),
              title: const Text('Cash'),
              onTap: () => Navigator.pop(context, 'Cash'),
            ),
            ListTile(
              leading: const Icon(Icons.credit_card),
              title: const Text('Card'),
              onTap: () => Navigator.pop(context, 'Card'),
            ),
            ListTile(
              leading: const Icon(Icons.phone_android),
              title: const Text('UPI'),
              onTap: () => Navigator.pop(context, 'UPI'),
            ),
          ],
        ),
      ),
    );

    if (method != null) {
      final updatedPayment = payment.copyWith(
        status: 'paid',
        paymentDate: DateTime.now(),
        paymentMethod: method,
      );
      
      await DatabaseHelper.instance.updatePayment(updatedPayment);
      _loadPayments();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment marked as paid via $method')),
        );
      }
    }
  }
}

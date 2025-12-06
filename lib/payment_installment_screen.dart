import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'database_helper.dart';
import 'models.dart';
import 'pdf_service.dart';

// Payment Installment Screen - For tracking bills with partial payments
// Both Staff and Doctor can use this screen

class PaymentInstallmentScreen extends StatefulWidget {
  final bool isStaff;
  final String userName; // Staff or Doctor name
  final bool embedded; // If true, no AppBar (used inside Payment Management)
  
  const PaymentInstallmentScreen({
    super.key,
    this.isStaff = false,
    required this.userName,
    this.embedded = false,
  });

  @override
  State<PaymentInstallmentScreen> createState() => _PaymentInstallmentScreenState();
}

class _PaymentInstallmentScreenState extends State<PaymentInstallmentScreen> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  List<PaymentInstallment> _allInstallments = [];
  List<PaymentInstallment> _pendingInstallments = [];
  List<PaymentInstallment> _fullPaidInstallments = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    if (!widget.embedded) {
      _tabController = TabController(length: 4, vsync: this);
    }
    _loadInstallments();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadInstallments() async {
    setState(() => _isLoading = true);
    
    try {
      final all = await DatabaseHelper.instance.getAllPaymentInstallments();
      
      setState(() {
        _allInstallments = all;
        _pendingInstallments = all.where((i) => i.status == 'PENDING' || i.status == 'PARTIAL').toList();
        _fullPaidInstallments = all.where((i) => i.status == 'FULL_PAID').toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading installments: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Embedded mode - no AppBar, simple list with FAB
    if (widget.embedded) {
      return Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildInstallmentList(_allInstallments),
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              onPressed: () => _showCreateBillDialog(),
              icon: const Icon(Icons.add),
              label: const Text('New Bill'),
              backgroundColor: const Color(0xFF6B21A8),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      );
    }

    // Standalone mode - full screen with AppBar and tabs
    return Scaffold(
      appBar: AppBar(
        title: const Text('💰 Installment Payments'),
        backgroundColor: const Color(0xFF6B21A8),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle),
            onPressed: () => _showCreateBillDialog(),
            tooltip: 'Create New Bill',
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () => _showSummaryDialog(),
            tooltip: 'Payment Summary',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.list_alt), text: 'All Bills'),
            Tab(icon: Icon(Icons.pending_actions), text: 'Pending'),
            Tab(icon: Icon(Icons.check_circle), text: 'Paid'),
            Tab(icon: Icon(Icons.info), text: 'Info'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildInstallmentList(_allInstallments),
                _buildInstallmentList(_pendingInstallments),
                _buildInstallmentList(_fullPaidInstallments),
                _buildInfoTab(),
              ],
            ),
    );
  }

  Widget _buildInstallmentList(List<PaymentInstallment> installments) {
    if (installments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No bills found',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showCreateBillDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Create First Bill'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B21A8),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadInstallments,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: installments.length,
        itemBuilder: (context, index) {
          return _buildInstallmentCard(installments[index]);
        },
      ),
    );
  }

  Widget _buildInstallmentCard(PaymentInstallment installment) {
    Color statusColor;
    IconData statusIcon;
    
    switch (installment.status) {
      case 'FULL_PAID':
        statusColor = const Color(0xFF10B981);
        statusIcon = Icons.check_circle;
        break;
      case 'PARTIAL':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      default:
        statusColor = const Color(0xFFEF4444);
        statusIcon = Icons.error_outline;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showPaymentDetails(installment),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          installment.patientName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Bill #${installment.id.substring(0, 8)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          DateFormat('dd MMM yyyy, hh:mm a')
                              .format(installment.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor, width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 16, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          installment.status.replaceAll('_', ' '),
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              // Amount Row
              Row(
                children: [
                  Expanded(
                    child: _buildAmountColumn(
                      'Total',
                      '₹${installment.totalAmount.toStringAsFixed(0)}',
                      const Color(0xFF6B21A8),
                    ),
                  ),
                  Expanded(
                    child: _buildAmountColumn(
                      'Paid',
                      '₹${installment.paidAmount.toStringAsFixed(0)}',
                      const Color(0xFF10B981),
                    ),
                  ),
                  Expanded(
                    child: _buildAmountColumn(
                      'Remaining',
                      '₹${installment.remainingAmount.toStringAsFixed(0)}',
                      const Color(0xFFEF4444),
                    ),
                  ),
                ],
              ),
              // Add Payment Button
              if (installment.status != 'FULL_PAID') ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddPaymentDialog(installment),
                    icon: const Icon(Icons.payment, size: 18),
                    label: const Text('Add Payment'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6B21A8),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountColumn(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    '📋 How Installment Payment Works',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  Text(
                    '1️⃣ Create a Bill\n'
                    '   • Enter instrument charges\n'
                    '   • Enter service charges\n'
                    '   • Total is calculated automatically\n\n'
                    '2️⃣ Receive Partial Payments\n'
                    '   • Patient can pay in parts\n'
                    '   • Each payment generates a receipt\n'
                    '   • Remaining balance updates automatically\n\n'
                    '3️⃣ Track Payment Status\n'
                    '   • PENDING - No payment received\n'
                    '   • PARTIAL - Some payment received\n'
                    '   • FULL PAID - Complete payment\n\n'
                    '4️⃣ Generate Receipts\n'
                    '   • Every payment has unique receipt\n'
                    '   • Print or share receipts\n'
                    '   • Shows remaining balance',
                    style: TextStyle(fontSize: 14, height: 1.6),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 4,
            color: const Color(0xFF6B21A8).withOpacity(0.1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.lightbulb, color: Color(0xFF6B21A8)),
                      SizedBox(width: 8),
                      Text(
                        'Example',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Bill Total: ₹5000\n'
                    '├─ 1st Visit: Pay ₹1000 → Remaining: ₹4000\n'
                    '├─ 2nd Visit: Pay ₹2000 → Remaining: ₹2000\n'
                    '└─ 3rd Visit: Pay ₹2000 → FULL PAID ✓',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'monospace',
                      color: Colors.grey[800],
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

  void _showCreateBillDialog() async {
    // First select a patient
    final patients = await DatabaseHelper.instance.getAllPatients();
    
    if (!mounted) return;
    
    final selectedPatient = await showDialog<Patient>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Patient'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: patients.isEmpty
              ? const Center(child: Text('No patients found'))
              : ListView.builder(
                  itemCount: patients.length,
                  itemBuilder: (context, index) {
                    final patient = patients[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF6B21A8),
                        child: Text(
                          patient.name[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(patient.name),
                      subtitle: Text('Token: ${patient.token} | ${patient.mobile}'),
                      onTap: () => Navigator.pop(context, patient),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selectedPatient == null || !mounted) return;

    // Now show bill creation dialog
    final instrumentController = TextEditingController();
    final serviceController = TextEditingController();
    final totalController = TextEditingController(text: '0');

    void updateTotal() {
      final instrument = double.tryParse(instrumentController.text) ?? 0.0;
      final service = double.tryParse(serviceController.text) ?? 0.0;
      totalController.text = (instrument + service).toStringAsFixed(0);
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('📝 Create Bill for ${selectedPatient.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: instrumentController,
                  decoration: const InputDecoration(
                    labelText: 'Instrument Charges',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(),
                    hintText: 'e.g. 3000',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(updateTotal),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: serviceController,
                  decoration: const InputDecoration(
                    labelText: 'Service Charges',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(),
                    hintText: 'e.g. 2000',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(updateTotal),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: totalController,
                  decoration: const InputDecoration(
                    labelText: 'Total Amount',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.black12,
                  ),
                  readOnly: true,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final total = double.tryParse(totalController.text) ?? 0.0;
                if (total <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('❌ Total amount must be greater than 0'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B21A8),
                foregroundColor: Colors.white,
              ),
              child: const Text('Create Bill'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      final installment = PaymentInstallment(
        id: const Uuid().v4(),
        patientId: selectedPatient.id,
        patientName: selectedPatient.name,
        totalAmount: double.tryParse(totalController.text) ?? 0.0,
        instrumentCharges: double.tryParse(instrumentController.text) ?? 0.0,
        serviceCharges: double.tryParse(serviceController.text) ?? 0.0,
        status: 'PENDING',
      );

      await DatabaseHelper.instance.createPaymentInstallment(installment);
      await _loadInstallments();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Bill created: ₹${installment.totalAmount.toStringAsFixed(0)}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _showAddPaymentDialog(PaymentInstallment installment) async {
    final amountController = TextEditingController();
    String paymentMode = 'Cash';
    final notesController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('💵 Add Payment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.pending, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(
                        'Remaining: ₹${installment.remainingAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount to Pay',
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
                      .map((mode) => DropdownMenuItem(
                            value: mode,
                            child: Text(mode),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => paymentMode = value!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
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
                    const SnackBar(
                      content: Text('❌ Amount must be greater than 0'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                if (amount > installment.remainingAmount) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '❌ Amount exceeds remaining balance (₹${installment.remainingAmount.toStringAsFixed(0)})',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B21A8),
                foregroundColor: Colors.white,
              ),
              child: const Text('Add Payment'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      final amount = double.tryParse(amountController.text) ?? 0.0;
      final receiptNumber = DatabaseHelper.instance.generateReceiptNumber();

      final transaction = PaymentTransaction(
        id: const Uuid().v4(),
        paymentId: installment.id,
        amountPaid: amount,
        paymentMode: paymentMode,
        receivedBy: widget.userName,
        receiptNumber: receiptNumber,
        notes: notesController.text.isEmpty ? null : notesController.text,
      );

      await DatabaseHelper.instance.addPaymentTransaction(transaction);
      await _loadInstallments();

      // Get updated installment
      final updated = await DatabaseHelper.instance.getPaymentInstallment(installment.id);

      if (mounted) {
        final isFullPaid = updated?.status == 'FULL_PAID';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isFullPaid
                  ? '🎉 Payment Complete! FULL PAID'
                  : '✅ Payment added: ₹${amount.toStringAsFixed(0)}',
            ),
            backgroundColor: isFullPaid ? Colors.green : const Color(0xFF6B21A8),
            duration: const Duration(seconds: 3),
          ),
        );

        // Show receipt dialog
        _showReceiptDialog(transaction, updated!);
      }
    }
  }

  void _showReceiptDialog(PaymentTransaction transaction, PaymentInstallment installment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.receipt_long, color: Color(0xFF6B21A8)),
            SizedBox(width: 8),
            Text('Receipt Generated'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildReceiptRow('Receipt No:', transaction.receiptNumber),
            _buildReceiptRow('Amount:', '₹${transaction.amountPaid.toStringAsFixed(0)}'),
            _buildReceiptRow('Mode:', transaction.paymentMode),
            _buildReceiptRow('Received By:', transaction.receivedBy),
            const Divider(),
            _buildReceiptRow(
              installment.status == 'FULL_PAID' ? 'Status:' : 'Remaining:',
              installment.status == 'FULL_PAID'
                  ? '✅ FULL PAID'
                  : '₹${installment.remainingAmount.toStringAsFixed(0)}',
              valueColor: installment.status == 'FULL_PAID'
                  ? Colors.green
                  : Colors.orange,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await PdfService.generateInstallmentReceipt(
                transaction: transaction,
                installment: installment,
              );
            },
            icon: const Icon(Icons.print),
            label: const Text('Print Receipt'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B21A8),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentDetails(PaymentInstallment installment) async {
    final transactions = await DatabaseHelper.instance.getPaymentTransactions(installment.id);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF6B21A8),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          installment.patientName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Bill #${installment.id.substring(0, 8)}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
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
                      installment.status.replaceAll('_', ' '),
                      style: TextStyle(
                        color: installment.status == 'FULL_PAID'
                            ? Colors.green
                            : installment.status == 'PARTIAL'
                                ? Colors.orange
                                : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  // Bill Summary Card
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '📋 Bill Summary',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          _buildSummaryRow('Instrument Charges', installment.instrumentCharges),
                          const SizedBox(height: 8),
                          _buildSummaryRow('Service Charges', installment.serviceCharges),
                          const Divider(height: 24),
                          _buildSummaryRow('Total Amount', installment.totalAmount, isBold: true),
                          const SizedBox(height: 8),
                          _buildSummaryRow('Paid Amount', installment.paidAmount, color: Colors.green),
                          const SizedBox(height: 8),
                          _buildSummaryRow('Remaining', installment.remainingAmount, 
                              color: Colors.red, isBold: true),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Payment History
                  const Text(
                    '📄 Payment History',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (transactions.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('No payments yet'),
                      ),
                    )
                  else
                    ...transactions.map((txn) => _buildTransactionCard(txn, installment)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, {Color? color, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          '₹${amount.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionCard(PaymentTransaction txn, PaymentInstallment installment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green,
          child: const Icon(Icons.payment, color: Colors.white, size: 20),
        ),
        title: Text(
          '₹${txn.amountPaid.toStringAsFixed(0)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(DateFormat('dd MMM yyyy, hh:mm a').format(txn.paymentDate)),
            Text('Mode: ${txn.paymentMode} | By: ${txn.receivedBy}'),
            if (txn.notes != null && txn.notes!.isNotEmpty)
              Text(
                'Note: ${txn.notes}',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.print, color: Color(0xFF6B21A8)),
              onPressed: () async {
                await PdfService.generateInstallmentReceipt(
                  transaction: txn,
                  installment: installment,
                );
              },
              tooltip: 'Print Receipt',
            ),
            Text(
              txn.receiptNumber,
              style: const TextStyle(fontSize: 8),
            ),
          ],
        ),
      ),
    );
  }

  void _showSummaryDialog() async {
    final summary = await DatabaseHelper.instance.getInstallmentSummary();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.analytics, color: Color(0xFF6B21A8)),
            SizedBox(width: 8),
            Text('Payment Summary'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSummaryItem(
              'Total Bills',
              '${summary['total_bills']}',
              Icons.receipt,
              Colors.blue,
            ),
            _buildSummaryItem(
              'Total Amount',
              '₹${(summary['total_amount'] as num).toStringAsFixed(0)}',
              Icons.account_balance_wallet,
              const Color(0xFF6B21A8),
            ),
            _buildSummaryItem(
              'Collected',
              '₹${(summary['total_paid'] as num).toStringAsFixed(0)}',
              Icons.check_circle,
              Colors.green,
            ),
            _buildSummaryItem(
              'Pending',
              '₹${(summary['total_remaining'] as num).toStringAsFixed(0)}',
              Icons.pending,
              Colors.red,
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCountBadge('Pending', summary['pending_count'], Colors.red),
                _buildCountBadge('Partial', summary['partial_count'], Colors.orange),
                _buildCountBadge('Paid', summary['full_paid_count'], Colors.green),
              ],
            ),
          ],
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

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountBadge(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

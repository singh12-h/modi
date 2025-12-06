import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'models.dart';

class PdfService {
  // Generate Payment Receipt PDF
  static Future<void> generatePaymentReceipt(Payment payment, Patient patient) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(40),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.purple100,
                    borderRadius: pw.BorderRadius.circular(10),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'MODI CLINIC',
                            style: pw.TextStyle(
                              fontSize: 24,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.purple900,
                            ),
                          ),
                          pw.SizedBox(height: 5),
                          pw.Text(
                            'Payment Receipt',
                            style: const pw.TextStyle(
                              fontSize: 14,
                              color: PdfColors.purple700,
                            ),
                          ),
                        ],
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(10),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.green,
                          borderRadius: pw.BorderRadius.circular(8),
                        ),
                        child: pw.Text(
                          payment.status.toUpperCase(),
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 30),

                // Receipt Details
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow('Receipt No:', payment.id.substring(0, 8).toUpperCase()),
                        pw.SizedBox(height: 8),
                        _buildDetailRow('Date:', DateFormat('dd MMM yyyy, hh:mm a').format(payment.paymentDate ?? payment.date)),
                        pw.SizedBox(height: 8),
                        _buildDetailRow('Token:', payment.token),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        _buildDetailRow('Patient:', patient.name),
                        pw.SizedBox(height: 8),
                        _buildDetailRow('Mobile:', patient.mobile),
                        pw.SizedBox(height: 8),
                        _buildDetailRow('Payment Mode:', payment.paymentMethod ?? 'N/A'),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 40),

                // Amount Section
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.purple200, width: 2),
                    borderRadius: pw.BorderRadius.circular(10),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Total Amount:',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        '₹${payment.amount.toStringAsFixed(2)}',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.purple900,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                if (payment.notes != null && payment.notes!.isNotEmpty) ...[
                  pw.Text(
                    'Notes:',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    payment.notes!,
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.SizedBox(height: 20),
                ],

                pw.Spacer(),

                // Footer
                pw.Divider(color: PdfColors.grey300),
                pw.SizedBox(height: 10),
                pw.Center(
                  child: pw.Text(
                    'Thank you for choosing MODI CLINIC',
                    style: const pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey700,
                    ),
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Center(
                  child: pw.Text(
                    'This is a computer-generated receipt',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey600,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  // Generate Prescription PDF
  static Future<void> generatePrescriptionPdf(Patient patient, List<Prescription> prescriptions, String doctorName) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(40),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    gradient: const pw.LinearGradient(
                      colors: [PdfColors.purple700, PdfColors.pink500],
                    ),
                    borderRadius: pw.BorderRadius.circular(10),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'MODI CLINIC',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Dr. $doctorName',
                        style: const pw.TextStyle(
                          fontSize: 14,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 30),

                // Patient Info
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow('Patient:', patient.name),
                        pw.SizedBox(height: 8),
                        _buildDetailRow('Age/Gender:', '${patient.age} / ${patient.gender}'),
                        pw.SizedBox(height: 8),
                        _buildDetailRow('Mobile:', patient.mobile),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        _buildDetailRow('Date:', DateFormat('dd MMM yyyy').format(DateTime.now())),
                        pw.SizedBox(height: 8),
                        _buildDetailRow('Token:', patient.token),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 30),

                // Prescription Header
                pw.Text(
                  'Rx',
                  style: pw.TextStyle(
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.purple900,
                  ),
                ),
                pw.Divider(color: PdfColors.purple200, thickness: 2),
                pw.SizedBox(height: 20),

                // Medicines List
                ...prescriptions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final prescription = entry.value;
                  return pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 15),
                    padding: const pw.EdgeInsets.all(15),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          '${index + 1}. ${prescription.medicineName}',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          'Dosage: ${prescription.dosage}',
                          style: const pw.TextStyle(fontSize: 11),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          'Frequency: ${prescription.frequency}',
                          style: const pw.TextStyle(fontSize: 11),
                        ),
                        if (prescription.duration != null) ...[
                          pw.SizedBox(height: 3),
                          pw.Text(
                            'Duration: ${prescription.duration} days',
                            style: const pw.TextStyle(fontSize: 11),
                          ),
                        ],
                        if (prescription.instructions != null) ...[
                          pw.SizedBox(height: 3),
                          pw.Text(
                            'Instructions: ${prescription.instructions}',
                            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),

                pw.Spacer(),

                // Footer
                pw.Divider(color: PdfColors.grey300),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Doctor\'s Signature: __________________',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.Text(
                      'Date: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  // Generate Patient Summary Report PDF
  static Future<void> generatePatientSummaryPdf(Patient patient, List<Consultation> consultations, List<Prescription> prescriptions) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            // Header
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                gradient: const pw.LinearGradient(
                  colors: [PdfColors.purple700, PdfColors.pink500],
                ),
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'PATIENT SUMMARY REPORT',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'MODI CLINIC',
                        style: const pw.TextStyle(
                          fontSize: 14,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                  pw.Text(
                    DateFormat('dd MMM yyyy').format(DateTime.now()),
                    style: const pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.white,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 30),

            // Patient Information
            pw.Text(
              'Patient Information',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.purple900,
              ),
            ),
            pw.Divider(color: PdfColors.purple200),
            pw.SizedBox(height: 10),
            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Name:', patient.name),
                      pw.SizedBox(height: 8),
                      _buildDetailRow('Age:', patient.age),
                      pw.SizedBox(height: 8),
                      _buildDetailRow('Gender:', patient.gender),
                      pw.SizedBox(height: 8),
                      _buildDetailRow('Mobile:', patient.mobile),
                    ],
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Token:', patient.token),
                      pw.SizedBox(height: 8),
                      _buildDetailRow('Registered:', DateFormat('dd MMM yyyy').format(patient.registeredDate ?? patient.registrationTime)),
                      pw.SizedBox(height: 8),
                      _buildDetailRow('Total Visits:', '${patient.consultationCount}'),
                      pw.SizedBox(height: 8),
                      if (patient.bloodGroup != null)
                        _buildDetailRow('Blood Group:', patient.bloodGroup!),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            if (patient.medicalHistory != null && patient.medicalHistory!.isNotEmpty) ...[
              pw.Text(
                'Medical History',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                patient.medicalHistory!,
                style: const pw.TextStyle(fontSize: 11),
              ),
              pw.SizedBox(height: 15),
            ],

            if (patient.allergies != null && patient.allergies!.isNotEmpty) ...[
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.red50,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: PdfColors.red200),
                ),
                child: pw.Row(
                  children: [
                    pw.Icon(
                      const pw.IconData(0xe88e),
                      color: PdfColors.red,
                      size: 20,
                    ),
                    pw.SizedBox(width: 10),
                    pw.Text(
                      'Allergies: ${patient.allergies}',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.red900,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
            ],

            // Consultation History
            if (consultations.isNotEmpty) ...[
              pw.Text(
                'Consultation History',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.purple900,
                ),
              ),
              pw.Divider(color: PdfColors.purple200),
              pw.SizedBox(height: 10),
              ...consultations.take(5).map((consultation) {
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 15),
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            DateFormat('dd MMM yyyy').format(consultation.date),
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            'Dr. ${consultation.doctorName}',
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Diagnosis: ${consultation.diagnosis}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      if (consultation.notes.isNotEmpty) ...[
                        pw.SizedBox(height: 3),
                        pw.Text(
                          'Notes: ${consultation.notes}',
                          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ],

            // Current Prescriptions
            if (prescriptions.isNotEmpty) ...[
              pw.SizedBox(height: 20),
              pw.Text(
                'Current Medications',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.purple900,
                ),
              ),
              pw.Divider(color: PdfColors.purple200),
              pw.SizedBox(height: 10),
              ...prescriptions.map((prescription) {
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 10),
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue50,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          prescription.medicineName,
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Text(
                        '${prescription.dosage} - ${prescription.frequency}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  static pw.Widget _buildDetailRow(String label, String value) {
    return pw.Row(
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Text(
          value,
          style: const pw.TextStyle(
            fontSize: 11,
            color: PdfColors.black,
          ),
        ),
      ],
    );
  }

  // Generate Installment Payment Receipt PDF
  static Future<void> generateInstallmentReceipt({
    required PaymentTransaction transaction,
    required PaymentInstallment installment,
    String clinicName = 'MODI CLINIC',
    String? clinicAddress,
    String? clinicPhone,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(40),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.purple100,
                    borderRadius: pw.BorderRadius.circular(10),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            clinicName,
                            style: pw.TextStyle(
                              fontSize: 24,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.purple900,
                            ),
                          ),
                          pw.SizedBox(height: 5),
                          pw.Text(
                            'PAYMENT RECEIPT',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.purple700,
                            ),
                          ),
                          if (clinicAddress != null)
                            pw.Text(
                              clinicAddress,
                              style: const pw.TextStyle(
                                fontSize: 10,
                                color: PdfColors.grey700,
                              ),
                            ),
                        ],
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(12),
                        decoration: pw.BoxDecoration(
                          color: installment.status == 'FULL_PAID'
                              ? PdfColors.green
                              : installment.status == 'PARTIAL'
                                  ? PdfColors.orange
                                  : PdfColors.red,
                          borderRadius: pw.BorderRadius.circular(8),
                        ),
                        child: pw.Text(
                          installment.status.replaceAll('_', ' '),
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 30),

                // Receipt Info
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          _buildDetailRow('Receipt No:', transaction.receiptNumber),
                          _buildDetailRow(
                            'Date:',
                            DateFormat('dd MMM yyyy, hh:mm a')
                                .format(transaction.paymentDate),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 12),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          _buildDetailRow('Patient Name:', installment.patientName),
                          _buildDetailRow('Received By:', transaction.receivedBy),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 25),

                // Payment Details
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.purple200, width: 2),
                    borderRadius: pw.BorderRadius.circular(10),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Payment Details',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Divider(color: PdfColors.grey300),
                      pw.SizedBox(height: 10),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Payment Mode:'),
                          pw.Text(
                            transaction.paymentMode,
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 12),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Amount Paid:',
                            style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            '₹${transaction.amountPaid.toStringAsFixed(2)}',
                            style: pw.TextStyle(
                              fontSize: 20,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.green700,
                            ),
                          ),
                        ],
                      ),
                      if (transaction.notes != null && transaction.notes!.isNotEmpty) ...[
                        pw.SizedBox(height: 12),
                        pw.Text('Notes:', style: const pw.TextStyle(fontSize: 10)),
                        pw.Text(
                          transaction.notes!,
                          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                        ),
                      ],
                    ],
                  ),
                ),
                pw.SizedBox(height: 25),

                // Bill Summary
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: installment.status == 'FULL_PAID'
                        ? PdfColors.green50
                        : PdfColors.orange50,
                    border: pw.Border.all(
                      color: installment.status == 'FULL_PAID'
                          ? PdfColors.green
                          : PdfColors.orange,
                      width: 2,
                    ),
                    borderRadius: pw.BorderRadius.circular(10),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'Bill Summary',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 12),
                      _buildSummaryRow('Instrument Charges:', installment.instrumentCharges),
                      pw.SizedBox(height: 6),
                      _buildSummaryRow('Service Charges:', installment.serviceCharges),
                      pw.Divider(color: PdfColors.grey400),
                      _buildSummaryRow('Total Bill Amount:', installment.totalAmount, isBold: true),
                      pw.SizedBox(height: 6),
                      _buildSummaryRow('Total Paid:', installment.paidAmount, color: PdfColors.green700),
                      pw.SizedBox(height: 6),
                      pw.Divider(color: PdfColors.grey400),
                      pw.SizedBox(height: 6),
                      if (installment.status == 'FULL_PAID')
                        pw.Container(
                          padding: const pw.EdgeInsets.all(10),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.green,
                            borderRadius: pw.BorderRadius.circular(8),
                          ),
                          child: pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            children: [
                              pw.Text(
                                '✓ FULLY PAID - Thank You!',
                                style: pw.TextStyle(
                                  color: PdfColors.white,
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        _buildSummaryRow(
                          'Remaining Balance:',
                          installment.remainingAmount,
                          color: PdfColors.red,
                          isBold: true,
                          fontSize: 14,
                        ),
                    ],
                  ),
                ),

                pw.Spacer(),

                // Footer
                pw.Divider(color: PdfColors.grey300),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Authorized Signature',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                        pw.SizedBox(height: 25),
                        pw.Container(
                          width: 120,
                          height: 1,
                          color: PdfColors.black,
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'This is a computer-generated receipt',
                          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Thank you for your payment!',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.purple700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Receipt_${transaction.receiptNumber}.pdf',
    );
  }

  static pw.Widget _buildSummaryRow(
    String label,
    double amount, {
    PdfColor? color,
    bool isBold = false,
    double fontSize = 12,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: color,
          ),
        ),
        pw.Text(
          '₹${amount.toStringAsFixed(2)}',
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: color,
          ),
        ),
      ],
    );
  }
}


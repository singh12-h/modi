import 'package:flutter/material.dart';

class PrescriptionPage extends StatefulWidget {
  const PrescriptionPage({super.key});

  @override
  State<PrescriptionPage> createState() => _PrescriptionPageState();
}

class _PrescriptionPageState extends State<PrescriptionPage> {
  final List<Map<String, String>> _medicines = [];
  final TextEditingController _chiefComplaintsController = TextEditingController();
  final TextEditingController _vitalSignsController = TextEditingController();
  final TextEditingController _diagnosisController = TextEditingController();
  final TextEditingController _investigationsController = TextEditingController();
  final TextEditingController _adviceController = TextEditingController();
  final TextEditingController _followUpController = TextEditingController();
  final TextEditingController _signatureController = TextEditingController();

  void _addMedicine() {
    setState(() {
      _medicines.add({
        'name': '',
        'manufacturer': '',
        'mrName': '',
        'startDate': DateTime.now().toString().split(' ')[0],
        'dosage': '',
        'duration': '',
        'instructions': '',
      });
    });
  }

  void _removeMedicine(int index) {
    setState(() {
      _medicines.removeAt(index);
    });
  }

  void _updateMedicine(int index, String key, String value) {
    setState(() {
      _medicines[index][key] = value;
    });
  }

  void _emailRx() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Email sent')),
    );
  }

  void _smsRx() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('SMS sent')),
    );
  }

  void _whatsappRx() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('WhatsApp message sent')),
    );
  }

  void _printRx() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Printing prescription')),
    );
  }

  void _savePdf() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PDF saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prescription'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Clinic Info
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.local_hospital, size: 40),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'DR. SHARMA',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              Text('MBBS, MD'),
                              Text('Cardiologist'),
                              Text('Reg. No: 12345'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text('Clinic Name & Address'),
                    const Text('📱 Phone | 📧 Email'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Patient Info
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Patient Info',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    const Text('Patient: Alice Johnson        Age: 30/F'),
                    const Text('Date: 15 Nov 2024       Token: A001'),
                    const Text('Mobile: +1 234 567 8900'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Chief Complaints
            const Text(
              'Chief Complaints',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _chiefComplaintsController,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'List of symptoms',
              ),
            ),
            const SizedBox(height: 20),
            // Vital Signs
            const Text(
              'Vital Signs',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _vitalSignsController,
              maxLines: 2,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'BP, Temp, Pulse, SpO2',
              ),
            ),
            const SizedBox(height: 20),
            // Diagnosis
            const Text(
              'Diagnosis',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _diagnosisController,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Primary and secondary diagnosis',
              ),
            ),
            const SizedBox(height: 20),
            // Rx (Medicines)
            const Text(
              'Rx (Medicines)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _medicines.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                decoration: const InputDecoration(labelText: 'Medicine Name'),
                                onChanged: (value) => _updateMedicine(index, 'name', value),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeMedicine(index),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                decoration: const InputDecoration(labelText: 'Manufacturer'),
                                onChanged: (value) => _updateMedicine(index, 'manufacturer', value),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                decoration: const InputDecoration(labelText: 'MR Name'),
                                onChanged: (value) => _updateMedicine(index, 'mrName', value),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Start Date',
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          readOnly: true,
                          onTap: () async {
                            DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now().subtract(const Duration(days: 365)),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (pickedDate != null) {
                              _updateMedicine(index, 'startDate', pickedDate.toString().split(' ')[0]);
                            }
                          },
                          controller: TextEditingController(
                            text: _medicines[index]['startDate'] ?? DateTime.now().toString().split(' ')[0],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                decoration: const InputDecoration(labelText: 'Dosage'),
                                onChanged: (value) => _updateMedicine(index, 'dosage', value),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                decoration: const InputDecoration(labelText: 'Duration (days)'),
                                onChanged: (value) => _updateMedicine(index, 'duration', value),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'Instructions (Before/After food)'),
                          onChanged: (value) => _updateMedicine(index, 'instructions', value),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            ElevatedButton.icon(
              onPressed: _addMedicine,
              icon: const Icon(Icons.add),
              label: const Text('Add Medicine'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
            ),
            const SizedBox(height: 20),
            // Investigations
            const Text(
              'Investigations',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _investigationsController,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'CBC, Blood Sugar, X-Ray Chest, etc.',
              ),
            ),
            const SizedBox(height: 20),
            // Advice
            const Text(
              'Advice',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _adviceController,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Diet instructions, rest advice, precautions',
              ),
            ),
            const SizedBox(height: 20),
            // Follow-up
            const Text(
              'Follow-up',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _followUpController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Next visit date',
                suffixIcon: Icon(Icons.calendar_today),
              ),
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (pickedDate != null) {
                  _followUpController.text = pickedDate.toString().split(' ')[0];
                }
              },
            ),
            const SizedBox(height: 20),
            // Footer: Doctor's Signature
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _signatureController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Dr. Sharma',
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text('"This is computer generated Rx"'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            // Actions: Email, SMS, WhatsApp, Print, Save PDF
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _emailRx,
                  icon: const Icon(Icons.email),
                  label: const Text('Email'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                ),
                ElevatedButton.icon(
                  onPressed: _smsRx,
                  icon: const Icon(Icons.sms),
                  label: const Text('SMS'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
                ElevatedButton.icon(
                  onPressed: _whatsappRx,
                  icon: const Icon(Icons.message),
                  label: const Text('WhatsApp'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.lightGreen),
                ),
                ElevatedButton.icon(
                  onPressed: _printRx,
                  icon: const Icon(Icons.print),
                  label: const Text('Print'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                ),
                ElevatedButton.icon(
                  onPressed: _savePdf,
                  icon: const Icon(Icons.save),
                  label: const Text('Save PDF'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _chiefComplaintsController.dispose();
    _vitalSignsController.dispose();
    _diagnosisController.dispose();
    _investigationsController.dispose();
    _adviceController.dispose();
    _followUpController.dispose();
    _signatureController.dispose();
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'prescription_page.dart';
import 'models.dart';
import 'database_helper.dart';

class ConsultationScreen extends StatefulWidget {
  final Patient? patient;
  
  const ConsultationScreen({super.key, this.patient});

  @override
  State<ConsultationScreen> createState() => _ConsultationScreenState();
}

class _ConsultationScreenState extends State<ConsultationScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  
  // Controllers for vital signs
  final TextEditingController _bpController = TextEditingController();
  final TextEditingController _tempController = TextEditingController();
  final TextEditingController _pulseController = TextEditingController();
  final TextEditingController _spo2Controller = TextEditingController();
  final TextEditingController _respRateController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();

  // Controllers for examination notes
  final TextEditingController _examNotesController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  // Controllers for diagnosis
  final TextEditingController _primaryDiagnosisController = TextEditingController();
  final TextEditingController _secondaryDiagnosisController = TextEditingController();
  final TextEditingController _icd10Controller = TextEditingController();

  // Controllers for instructions
  final TextEditingController _instructionsController = TextEditingController();

  // Medicines list
  final List<Map<String, String>> _medicines = [];

  // Tests list
  final List<String> _labTests = ['CBC', 'Blood Sugar', 'Lipid Profile', 'Liver Function Test'];
  final List<String> _radiologyTests = ['X-Ray Chest', 'ECG', 'Ultrasound Abdomen'];
  final List<String> _selectedLabTests = [];
  final List<String> _selectedRadiologyTests = [];

  // Timer for consultation duration
  late DateTime _startTime;
  String _duration = '00:00:00';
  
  // Follow-up date
  DateTime? _followUpDate;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _updateTimer();
    _setInProgress();
  }

  Future<void> _setInProgress() async {
    if (widget.patient != null) {
      final updatedPatient = widget.patient!.copyWith(status: PatientStatus.inProgress);
      await _db.updatePatient(updatedPatient);
    }
  }

  void _updateTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          final now = DateTime.now();
          final difference = now.difference(_startTime);
          _duration = '${difference.inHours.toString().padLeft(2, '0')}:${(difference.inMinutes % 60).toString().padLeft(2, '0')}:${(difference.inSeconds % 60).toString().padLeft(2, '0')}';
        });
        _updateTimer();
      }
    });
  }

  void _addMedicine() {
    showDialog(
      context: context,
      builder: (context) {
        final nameController = TextEditingController();
        final dosageController = TextEditingController();
        final frequencyController = TextEditingController();
        final instructionsController = TextEditingController();
        
        return AlertDialog(
          title: const Text('Add Medicine'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Medicine Name'),
                ),
                TextField(
                  controller: dosageController,
                  decoration: const InputDecoration(labelText: 'Dosage (e.g., 500mg)'),
                ),
                TextField(
                  controller: frequencyController,
                  decoration: const InputDecoration(labelText: 'Frequency (e.g., Twice daily)'),
                ),
                TextField(
                  controller: instructionsController,
                  decoration: const InputDecoration(labelText: 'Instructions (optional)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty && dosageController.text.isNotEmpty) {
                  setState(() {
                    _medicines.add({
                      'name': nameController.text,
                      'dosage': dosageController.text,
                      'frequency': frequencyController.text,
                      'instructions': instructionsController.text,
                    });
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _editMedicine(int index) {
    final medicine = _medicines[index];
    final nameController = TextEditingController(text: medicine['name']);
    final dosageController = TextEditingController(text: medicine['dosage']);
    final frequencyController = TextEditingController(text: medicine['frequency']);
    final instructionsController = TextEditingController(text: medicine['instructions']);
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Medicine'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Medicine Name'),
                ),
                TextField(
                  controller: dosageController,
                  decoration: const InputDecoration(labelText: 'Dosage'),
                ),
                TextField(
                  controller: frequencyController,
                  decoration: const InputDecoration(labelText: 'Frequency'),
                ),
                TextField(
                  controller: instructionsController,
                  decoration: const InputDecoration(labelText: 'Instructions'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _medicines[index] = {
                    'name': nameController.text,
                    'dosage': dosageController.text,
                    'frequency': frequencyController.text,
                    'instructions': instructionsController.text,
                  };
                });
                Navigator.pop(context);
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  void _deleteMedicine(int index) {
    setState(() {
      _medicines.removeAt(index);
    });
  }

  void _selectFollowUpDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _followUpDate = picked;
      });
    }
  }

  Future<void> _completeConsultation() async {
    if (widget.patient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No patient data')),
      );
      return;
    }

    if (_primaryDiagnosisController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a diagnosis')),
      );
      return;
    }

    try {
      const uuid = Uuid();
      final patientId = widget.patient!.id;
      final diagnosis = _primaryDiagnosisController.text;
      
      // 1. Create consultation record
      final consultation = Consultation(
        id: uuid.v4(),
        patientId: patientId,
        date: DateTime.now(),
        reason: _reasonController.text.isNotEmpty ? _reasonController.text : 'General consultation',
        doctorId: 'DOC001', // TODO: Get from logged-in doctor
        doctorName: 'Dr. Smith', // TODO: Get from logged-in doctor
        diagnosis: diagnosis,
        medications: _medicines.map((m) => '${m['name']} - ${m['dosage']}').toList(),
        notes: _examNotesController.text,
        prescription: _medicines.map((m) => '${m['name']} ${m['dosage']} ${m['frequency']}').join(', '),
        followUpDate: _followUpDate,
        checkupDetails: 'BP: ${_bpController.text}, Temp: ${_tempController.text}, Pulse: ${_pulseController.text}',
      );
      await _db.insertConsultation(consultation);

      // 2. Update/Create medical history
      final existingHistory = await _db.getMedicalHistory(patientId);
      if (existingHistory != null) {
        final updatedHistory = MedicalHistory(
          id: existingHistory.id,
          patientId: patientId,
          previousConditions: existingHistory.previousConditions,
          currentDiagnosis: diagnosis,
          notes: _examNotesController.text,
          allergies: existingHistory.allergies,
          bloodGroup: existingHistory.bloodGroup,
          createdAt: DateTime.now(),
        );
        await _db.updateMedicalHistory(updatedHistory);
      } else {
        final newHistory = MedicalHistory(
          id: uuid.v4(),
          patientId: patientId,
          previousConditions: [],
          currentDiagnosis: diagnosis,
          notes: _examNotesController.text,
          allergies: '',
          bloodGroup: '',
          createdAt: DateTime.now(),
        );
        await _db.insertMedicalHistory(newHistory);
      }

      // 3. Mark old prescriptions as inactive
      await _db.markPrescriptionsAsOld(patientId);

      // 4. Add new prescriptions
      for (var medicine in _medicines) {
        final prescription = Prescription(
          id: uuid.v4(),
          patientId: patientId,
          medicineName: medicine['name']!,
          dosage: medicine['dosage']!,
          frequency: medicine['frequency']!,
          createdAt: DateTime.now(),
          isCurrent: true,
        );
        await _db.insertPrescription(prescription);
      }

      // 5. Update patient statistics and status
      await _db.updatePatientStats(patientId);
      
      if (widget.patient != null) {
        final completedPatient = widget.patient!.copyWith(status: PatientStatus.completed);
        await _db.updatePatient(completedPatient);
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Consultation completed successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Return to patient detail view with success
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('Error completing consultation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Consultation', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: const Color(0xFF1976D2),
                      child: const Icon(Icons.person, size: 30, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.patient?.name ?? 'Unknown Patient',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text('Token: ${widget.patient?.token ?? 'N/A'}'),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _duration,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1976D2)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Reason for Visit
            _buildSection(
              'Reason for Visit',
              Icons.description,
              Colors.blue,
              [
                TextField(
                  controller: _reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Chief Complaint',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            
            // Vital Signs
            _buildSection(
              'Vital Signs',
              Icons.favorite,
              Colors.red,
              [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _bpController,
                        decoration: const InputDecoration(labelText: 'BP (120/80)'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _tempController,
                        decoration: const InputDecoration(labelText: 'Temp (°F)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _pulseController,
                        decoration: const InputDecoration(labelText: 'Pulse (bpm)'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _spo2Controller,
                        decoration: const InputDecoration(labelText: 'SpO2 (%)'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            // Examination Notes
            _buildSection(
              'Examination Notes',
              Icons.note_alt,
              Colors.orange,
              [
                TextField(
                  controller: _examNotesController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter examination findings...',
                  ),
                ),
              ],
            ),
            
            // Diagnosis
            _buildSection(
              'Diagnosis',
              Icons.medical_information,
              Colors.purple,
              [
                TextField(
                  controller: _primaryDiagnosisController,
                  decoration: const InputDecoration(
                    labelText: 'Primary Diagnosis *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _secondaryDiagnosisController,
                  decoration: const InputDecoration(
                    labelText: 'Secondary Diagnosis (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            
            // Medicines
            _buildSection(
              'Prescription',
              Icons.medication,
              Colors.green,
              [
                ElevatedButton.icon(
                  onPressed: _addMedicine,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Medicine'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                if (_medicines.isNotEmpty)
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _medicines.length,
                    itemBuilder: (context, index) {
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          title: Text(_medicines[index]['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${_medicines[index]['dosage']} - ${_medicines[index]['frequency']}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _editMedicine(index),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteMedicine(index),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
            
            // Follow-up
            _buildSection(
              'Follow-up',
              Icons.calendar_today,
              Colors.teal,
              [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _followUpDate != null
                            ? 'Follow-up: ${_followUpDate!.day}/${_followUpDate!.month}/${_followUpDate!.year}'
                            : 'No follow-up date set',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _selectFollowUpDate,
                      icon: const Icon(Icons.calendar_month),
                      label: const Text('Select Date'),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 30),
            
            // Action Buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _completeConsultation,
                icon: const Icon(Icons.check_circle),
                label: const Text('COMPLETE CONSULTATION', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, Color color, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...children,
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  void dispose() {
    _bpController.dispose();
    _tempController.dispose();
    _pulseController.dispose();
    _spo2Controller.dispose();
    _respRateController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _examNotesController.dispose();
    _reasonController.dispose();
    _primaryDiagnosisController.dispose();
    _secondaryDiagnosisController.dispose();
    _icd10Controller.dispose();
    _instructionsController.dispose();
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:modi/database_helper.dart';
import 'package:modi/models.dart';
import 'package:intl/intl.dart';

class WhatsAppIntegration extends StatefulWidget {
  final String? patientName;
  final String? mobileNumber;

  const WhatsAppIntegration({super.key, this.patientName, this.mobileNumber});

  @override
  State<WhatsAppIntegration> createState() => _WhatsAppIntegrationState();
}

class _WhatsAppIntegrationState extends State<WhatsAppIntegration> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Controllers
  late TextEditingController _phoneController;
  late TextEditingController _messageController;
  late TextEditingController _nameController;
  
  // Data
  List<Patient> _allPatients = [];
  List<Patient> _filteredPatients = [];
  List<Patient> _selectedPatients = [];
  String _selectedTemplate = 'custom';
  String _currentFilter = 'All'; // 'All', 'Appointments', 'FollowUps'
  bool _isLoading = true;
  bool _selectAll = false;
  
  // Message Templates
  final Map<String, String> _messageTemplates = {
    'custom': 'Custom Message',
    'reminder': 'Dear [Name], this is a reminder for your appointment at Modi Clinic on [Date] at [Time]. Please arrive 10 minutes early. Thank you!',
    'followup': 'Dear [Name], thank you for visiting Modi Clinic. Please remember to take your medicines as prescribed and return for follow-up. For any queries, contact us.',
    'wishes': 'Dear [Name], wishing you good health and happiness! Take care. - Modi Clinic',
    'appointment': 'Dear [Name], your appointment is confirmed for [Date] at [Time]. Token: [Token]. Please arrive on time. - Modi Clinic',
    'offer': 'Dear [Name], special health checkup offer at Modi Clinic! Get 20% off on full body checkup. Valid till [Date]. Book now!',
    'report': 'Dear [Name], your medical reports are ready for collection. You can collect them from Modi Clinic during working hours. Thank you!',
    'birthday': 'Dear [Name], wishing you a very Happy Birthday! May you be blessed with good health and happiness. - Modi Clinic',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _phoneController = TextEditingController(text: widget.mobileNumber ?? '');
    _nameController = TextEditingController(text: widget.patientName ?? '');
    _messageController = TextEditingController();
    _loadPatients();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _phoneController.dispose();
    _nameController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadPatients() async {
    setState(() => _isLoading = true);
    final patients = await DatabaseHelper.instance.getAllPatients();
    setState(() {
      _allPatients = patients;
      _filteredPatients = patients;
      _isLoading = false;
    });
  }

  void _applyFilter(String filter) async {
    setState(() {
      _currentFilter = filter;
      _isLoading = true;
      _selectedPatients.clear();
      _selectAll = false;
    });

    List<Patient> filtered = [];

    if (filter == 'All') {
      filtered = _allPatients;
      _selectedTemplate = 'custom';
      _messageController.clear();
    } else if (filter == 'Appointments') {
      // Filter for patients with appointments tomorrow
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final appointments = await DatabaseHelper.instance.getAppointmentsByDate(tomorrow);
      
      // Find patients who match these appointments
      filtered = _allPatients.where((p) => appointments.any((a) => a.mobile == p.mobile)).toList();
      
      // Auto-select Appointment Reminder template
      _selectedTemplate = 'appointment';
      _updateMessageFromTemplate();
      
    } else if (filter == 'FollowUps') {
      final followUps = await DatabaseHelper.instance.getUpcomingFollowUps();
      // Filter for tomorrow's follow-ups
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final tomorrowStr = DateFormat('yyyy-MM-dd').format(tomorrow);
      
      final relevantFollowUps = followUps.where((f) => f.followUpDate != null && 
          DateFormat('yyyy-MM-dd').format(f.followUpDate!) == tomorrowStr).toList();
          
      filtered = _allPatients.where((p) => relevantFollowUps.any((f) => f.patientId == p.id)).toList();
      
      // Auto-select Follow-up template
      _selectedTemplate = 'followup';
      _updateMessageFromTemplate();
    }

    setState(() {
      _filteredPatients = filtered;
      _isLoading = false;
      // Auto-select all for convenience when filtering
      if (filter != 'All' && filtered.isNotEmpty) {
        _selectAll = true;
        _selectedPatients = List.from(filtered);
      }
    });
  }

  Patient? _directMessagePatient;

  void _updateMessageFromTemplate() {
    if (_selectedTemplate != 'custom') {
      String message = _messageTemplates[_selectedTemplate] ?? '';
      
      Patient? targetPatient = _directMessagePatient;
      
      // If no patient selected via autocomplete, try to find by name
      if (targetPatient == null && _nameController.text.isNotEmpty) {
        try {
          targetPatient = _allPatients.firstWhere(
            (p) => p.name.toLowerCase() == _nameController.text.toLowerCase()
          );
        } catch (_) {}
      }
      
      if (targetPatient != null) {
        message = _personalizeMessage(message, targetPatient);
      } else if (_nameController.text.isNotEmpty) {
        message = message.replaceAll(RegExp(r'\[Name\]', caseSensitive: false), _nameController.text);
      }
      
      // Also replace Date/Time even if no patient is selected (generic)
      final now = DateTime.now();
      final formattedDate = "${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}";
      message = message
          .replaceAll(RegExp(r'\[Date\]', caseSensitive: false), formattedDate)
          .replaceAll(RegExp(r'\[Time\]', caseSensitive: false), '10:00 AM');
      
      setState(() {
        _messageController.text = message;
      });
    }
  }

  Future<void> _launchWhatsApp(String phone, String message) async {
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number is required')),
      );
      return;
    }

    final url = Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(message)}');
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch WhatsApp')),
        );
      }
    }
  }

  String _personalizeMessage(String template, Patient patient) {
    final now = DateTime.now();
    final formattedDate = "${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}";
    
    return template
        .replaceAll(RegExp(r'\[Name\]', caseSensitive: false), patient.name)
        .replaceAll(RegExp(r'\[Token\]', caseSensitive: false), patient.token.isNotEmpty ? patient.token : 'N/A')
        .replaceAll(RegExp(r'\[Date\]', caseSensitive: false), formattedDate)
        .replaceAll(RegExp(r'\[Time\]', caseSensitive: false), '10:00 AM');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WhatsApp Integration'),
        backgroundColor: const Color(0xFF25D366),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.message), text: 'Direct Message'),
            Tab(icon: Icon(Icons.people), text: 'Select Patients'),
            Tab(icon: Icon(Icons.send), text: 'Bulk Send'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDirectMessageTab(),
          _buildSelectPatientsTab(),
          _buildBulkSendTab(),
        ],
      ),
    );
  }

  Widget _buildDirectMessageTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Patient Selection Search
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Patient (Optional)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Autocomplete<Patient>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text == '') {
                        return const Iterable<Patient>.empty();
                      }
                      return _allPatients.where((Patient option) {
                        return option.name.toLowerCase().contains(textEditingValue.text.toLowerCase()) ||
                               option.mobile.contains(textEditingValue.text);
                      });
                    },
                    displayStringForOption: (Patient option) => '${option.name} (${option.mobile})',
                    onSelected: (Patient selection) {
                      setState(() {
                        _directMessagePatient = selection;
                        _nameController.text = selection.name;
                        _phoneController.text = selection.mobile;
                        // Re-apply template if one is selected to personalize it
                        if (_selectedTemplate != 'custom') {
                          _updateMessageFromTemplate();
                        }
                      });
                    },
                    fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                      return TextField(
                        controller: textEditingController,
                        focusNode: focusNode,
                        decoration: const InputDecoration(
                          labelText: 'Search Patient by Name or Mobile',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                          helperText: 'Select a patient to auto-fill details and personalize message',
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Template Selection
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Message Template',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildTemplateChip('custom', 'Custom', Icons.edit),
                      _buildTemplateChip('reminder', 'Reminder', Icons.alarm),
                      _buildTemplateChip('followup', 'Follow-up', Icons.medical_services),
                      _buildTemplateChip('wishes', 'Wishes', Icons.favorite),
                      _buildTemplateChip('appointment', 'Appointment', Icons.calendar_today),
                      _buildTemplateChip('offer', 'Offer', Icons.local_offer),
                      _buildTemplateChip('report', 'Report Ready', Icons.description),
                      _buildTemplateChip('birthday', 'Birthday', Icons.cake),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Patient Details
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    onChanged: (value) {
                      // If user manually changes name, clear the selected patient object to avoid mismatch
                      if (_directMessagePatient != null && value != _directMessagePatient!.name) {
                        setState(() {
                          _directMessagePatient = null;
                        });
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Patient Name',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number (with country code)',
                      hintText: 'e.g., 919876543210',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _messageController,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      labelText: 'Message',
                      alignLabelWithHint: true,
                      prefixIcon: Icon(Icons.chat_bubble_outline),
                      border: OutlineInputBorder(),
                      hintText: 'Type your message or select a template above',
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _launchWhatsApp(_phoneController.text.trim(), _messageController.text.trim()),
                    icon: const Icon(Icons.send),
                    label: const Text('Send via WhatsApp'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
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

  Widget _buildTemplateChip(String key, String label, IconData icon) {
    final isSelected = _selectedTemplate == key;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : const Color(0xFF25D366)),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      onSelected: (selected) {
        setState(() {
          _selectedTemplate = key;
          _updateMessageFromTemplate();
        });
      },
      selectedColor: const Color(0xFF25D366),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildSelectPatientsTab() {
    return Column(
      children: [
        // Filter Chips
        Container(
          padding: const EdgeInsets.all(8),
          color: Colors.grey[100],
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', 'All Patients'),
                const SizedBox(width: 8),
                _buildFilterChip('Appointments', 'Tomorrow\'s Appts'),
                const SizedBox(width: 8),
                _buildFilterChip('FollowUps', 'Tomorrow\'s Follow-ups'),
              ],
            ),
          ),
        ),
        
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFF25D366).withOpacity(0.1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Selected: ${_selectedPatients.length} patients',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedPatients.clear();
                        _selectAll = false;
                      });
                    },
                    child: const Text('Clear All'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedPatients = List.from(_filteredPatients);
                        _selectAll = true;
                      });
                    },
                    child: const Text('Select All'),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredPatients.isEmpty
                  ? Center(child: Text('No patients found for $_currentFilter'))
                  : ListView.builder(
                      itemCount: _filteredPatients.length,
                      itemBuilder: (context, index) {
                        final patient = _filteredPatients[index];
                        final isSelected = _selectedPatients.any((p) => p.id == patient.id);
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: CheckboxListTile(
                            value: isSelected,
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  _selectedPatients.add(patient);
                                } else {
                                  _selectedPatients.removeWhere((p) => p.id == patient.id);
                                }
                                _selectAll = _selectedPatients.length == _filteredPatients.length;
                              });
                            },
                            title: Text(patient.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${patient.mobile} • Token: ${patient.token}'),
                            secondary: CircleAvatar(
                              backgroundColor: const Color(0xFF25D366),
                              child: Text(
                                patient.name[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ),
        if (_selectedPatients.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () {
                _tabController.animateTo(2); // Go to Bulk Send tab
              },
              icon: const Icon(Icons.arrow_forward),
              label: Text('Continue with ${_selectedPatients.length} patients'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFilterChip(String filter, String label) {
    final isSelected = _currentFilter == filter;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) _applyFilter(filter);
      },
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFF25D366).withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? Colors.green[900] : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      checkmarkColor: Colors.green[900],
    );
  }

  Widget _buildBulkSendTab() {
    return _selectedPatients.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.people_outline, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'No patients selected',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('Go to "Select Patients" tab to choose patients'),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => _tabController.animateTo(1),
                  child: const Text('Select Patients'),
                ),
              ],
            ),
          )
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select Message Template',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildTemplateChip('reminder', 'Reminder', Icons.alarm),
                            _buildTemplateChip('followup', 'Follow-up', Icons.medical_services),
                            _buildTemplateChip('wishes', 'Wishes', Icons.favorite),
                            _buildTemplateChip('appointment', 'Appointment', Icons.calendar_today),
                            _buildTemplateChip('offer', 'Offer', Icons.local_offer),
                            _buildTemplateChip('birthday', 'Birthday', Icons.cake),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _messageController,
                          maxLines: 5,
                          decoration: const InputDecoration(
                            labelText: 'Message Template',
                            border: OutlineInputBorder(),
                            hintText: '[Name] will be replaced with patient name',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selected Patients (${_selectedPatients.length})',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        ..._selectedPatients.map((patient) => ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF25D366),
                                child: Text(patient.name[0].toUpperCase()),
                              ),
                              title: Text(patient.name),
                              subtitle: Text(patient.mobile),
                              trailing: IconButton(
                                icon: const Icon(Icons.close, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _selectedPatients.remove(patient);
                                  });
                                },
                              ),
                            )),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _startBulkSend,
                  icon: const Icon(Icons.send),
                  label: Text('Send to ${_selectedPatients.length} patients'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
          );
  }

  Future<void> _startBulkSend() async {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a message')),
      );
      return;
    }

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Bulk Send'),
        content: Text('Send message to ${_selectedPatients.length} patients via WhatsApp?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366)),
            child: const Text('Send'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Send messages one by one
    for (int i = 0; i < _selectedPatients.length; i++) {
      final patient = _selectedPatients[i];
      final personalizedMessage = _personalizeMessage(_messageController.text, patient);
      
      await _launchWhatsApp(patient.mobile, personalizedMessage);
      
      // Wait for user to send in WhatsApp and come back
      if (i < _selectedPatients.length - 1) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Patient ${i + 1}/${_selectedPatients.length}'),
            content: Text('Message sent to ${patient.name}. Click Next to continue.'),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Next'),
              ),
            ],
          ),
        );
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Completed! Messages sent to ${_selectedPatients.length} patients')),
      );
    }
  }
}

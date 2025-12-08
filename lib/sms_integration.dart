import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'database_helper.dart';
import 'models.dart';

class SmsIntegration extends StatefulWidget {
  const SmsIntegration({super.key});

  @override
  State<SmsIntegration> createState() => _SmsIntegrationState();
}

class _SmsIntegrationState extends State<SmsIntegration> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // State for Send Message Tab
  List<Patient> _allPatients = [];
  List<Patient> _filteredPatients = [];
  List<Patient> _selectedPatients = [];
  bool _isLoading = true;
  bool _selectAll = false;
  String _currentFilter = 'All'; // 'All', 'TodayAppts', 'TomorrowAppts', 'TodayFollowUps', 'TomorrowFollowUps'
  
  final TextEditingController _messageController = TextEditingController();
  String? _selectedTemplateId;
  
  // State for Templates Tab
  List<SmsTemplate> _templates = [
    SmsTemplate(
      id: '1',
      title: 'Registration Confirmation',
      content: 'Dear {name}, welcome to Modi Clinic. Your registration is successful. Token: {token}. Date: {date}.',
      category: 'Registration',
    ),
    SmsTemplate(
      id: '2',
      title: 'Festival Wish',
      content: 'Wishing you and your family a very Happy Festival! May this special day bring joy, health, and prosperity. - Dr. Modi',
      category: 'Festival',
    ),
    SmsTemplate(
      id: '3',
      title: 'Birthday Wish',
      content: '''🎂 *Happy Birthday {name}!* 🎉

✨ आपको जन्मदिन की हार्दिक शुभकामनाएं! ✨

May this special day bring you:
🌟 Good Health & Happiness
💪 Strength & Wellness
🙏 Peace & Prosperity

Wishing you a wonderful year ahead filled with joy and good health!

🏥 *With Warm Wishes,*
*Dr. Modi & MODI CLINIC Team*
📞 Contact: [Your Number]''',
      category: 'Birthday',
    ),
    SmsTemplate(
      id: '4',
      title: 'General Reminder',
      content: 'Dear {name}, this is a gentle reminder for your check-up. Please visit the clinic at your earliest convenience.',
      category: 'Reminder',
    ),
    SmsTemplate(
      id: '5',
      title: 'Appointment Reminder',
      content: 'Dear {name}, reminder for your appointment tomorrow at Modi Clinic. Please arrive 10 mins early.',
      category: 'Reminder',
    ),
    SmsTemplate(
      id: '6',
      title: 'Today Appointment',
      content: 'Dear {name}, you have an appointment today at Modi Clinic. Please arrive on time. Token: {token}.',
      category: 'Reminder',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
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
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final tomorrowStr = DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 1)));

    if (filter == 'All') {
      filtered = _allPatients;
      _selectedTemplateId = null;
      _messageController.clear();
      
    } else if (filter == 'TodayAppts') {
      final appointments = await DatabaseHelper.instance.getAppointmentsByDate(now);
      filtered = _allPatients.where((p) => appointments.any((a) => a.mobile == p.mobile)).toList();
      
      final template = _templates.firstWhere((t) => t.title == 'Today Appointment', orElse: () => _templates[0]);
      _applyTemplate(template);
      
    } else if (filter == 'TomorrowAppts') {
      final appointments = await DatabaseHelper.instance.getAppointmentsByDate(now.add(const Duration(days: 1)));
      filtered = _allPatients.where((p) => appointments.any((a) => a.mobile == p.mobile)).toList();
      
      final template = _templates.firstWhere((t) => t.title == 'Appointment Reminder', orElse: () => _templates[0]);
      _applyTemplate(template);
      
    } else if (filter == 'TodayFollowUps') {
      final followUps = await DatabaseHelper.instance.getTodayFollowUps();
      filtered = _allPatients.where((p) => followUps.any((f) => f.patientId == p.id)).toList();
      
      final template = _templates.firstWhere((t) => t.title == 'General Reminder', orElse: () => _templates[0]);
      _applyTemplate(template);
      
    } else if (filter == 'TomorrowFollowUps') {
      final followUps = await DatabaseHelper.instance.getUpcomingFollowUps();
      final relevantFollowUps = followUps.where((f) => f.followUpDate != null && 
          DateFormat('yyyy-MM-dd').format(f.followUpDate!) == tomorrowStr).toList();
      filtered = _allPatients.where((p) => relevantFollowUps.any((f) => f.patientId == p.id)).toList();
      
      final template = _templates.firstWhere((t) => t.title == 'General Reminder', orElse: () => _templates[0]);
      _applyTemplate(template);
    } else if (filter == 'TodayBirthday') {
      // Filter patients with birthday today
      filtered = await DatabaseHelper.instance.getTodayBirthdayPatients();
      
      final template = _templates.firstWhere((t) => t.title == 'Birthday Wish', orElse: () => _templates[0]);
      _applyTemplate(template);
    }

    setState(() {
      _filteredPatients = filtered;
      _isLoading = false;
      if (filter != 'All' && filtered.isNotEmpty) {
        _selectAll = true;
        _selectedPatients = List.from(filtered);
      }
    });
  }

  void _toggleSelectAll(bool? value) {
    setState(() {
      _selectAll = value ?? false;
      if (_selectAll) {
        _selectedPatients = List.from(_filteredPatients);
      } else {
        _selectedPatients.clear();
      }
    });
  }

  void _togglePatientSelection(Patient patient, bool? selected) {
    setState(() {
      if (selected == true) {
        _selectedPatients.add(patient);
      } else {
        _selectedPatients.removeWhere((p) => p.id == patient.id);
      }
      _selectAll = _selectedPatients.length == _filteredPatients.length;
    });
  }

  void _applyTemplate(SmsTemplate template) {
    setState(() {
      _selectedTemplateId = template.id;
      _messageController.text = template.content;
    });
  }

  String _personalizeMessage(String template, Patient patient) {
    final now = DateTime.now();
    final formattedDate = "${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}";
    
    return template
        .replaceAll(RegExp(r'\{name\}', caseSensitive: false), patient.name)
        .replaceAll(RegExp(r'\{token\}', caseSensitive: false), patient.token.isNotEmpty ? patient.token : 'N/A')
        .replaceAll(RegExp(r'\{date\}', caseSensitive: false), formattedDate);
  }

  Future<void> _launchSms(String phone, String message) async {
    final Uri smsLaunchUri = Uri(
      scheme: 'sms',
      path: phone,
      queryParameters: <String, String>{
        'body': message,
      },
    );
    
    try {
      if (await canLaunchUrl(smsLaunchUri)) {
        await launchUrl(smsLaunchUri);
      } else {
        // Fallback for some devices
        final Uri fallbackUri = Uri.parse('sms:$phone?body=$message');
        if (await canLaunchUrl(fallbackUri)) {
           await launchUrl(fallbackUri);
        } else {
           throw 'Could not launch SMS';
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error launching SMS: $e')),
        );
      }
    }
  }

  Future<void> _sendBulkSms() async {
    if (_selectedPatients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one patient')),
      );
      return;
    }
    if (_messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a message')),
      );
      return;
    }

    // Confirmation
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Bulk SMS'),
        content: Text('This will open your SMS app for ${_selectedPatients.length} patients one by one. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Start')),
        ],
      ),
    );

    if (confirm != true) return;

    // Send Queue
    for (int i = 0; i < _selectedPatients.length; i++) {
      final patient = _selectedPatients[i];
      final message = _personalizeMessage(_messageController.text, patient);
      
      await _launchSms(patient.mobile, message);
      
      // If there are more patients, wait for user confirmation to proceed
      if (i < _selectedPatients.length - 1) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text('Sending ${i + 1}/${_selectedPatients.length}'),
            content: Text('SMS opened for ${patient.name}. Send it, then come back here and click Next.'),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Next Patient'),
              ),
            ],
          ),
        );
      }
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Completed! Processed ${_selectedPatients.length} patients.')),
      );
      // Reset
      setState(() {
        _selectedPatients.clear();
        _selectAll = false;
        if (_currentFilter == 'All') {
             _messageController.clear();
             _selectedTemplateId = null;
        }
      });
    }
  }

  void _addNewTemplate() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Template'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Template Title',
                hintText: 'e.g., Diwali Wish',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(
                labelText: 'Message Content',
                hintText: 'Use {name}, {token}, {date} as placeholders',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty && contentController.text.isNotEmpty) {
                setState(() {
                  _templates.add(SmsTemplate(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: titleController.text,
                    content: contentController.text,
                    category: 'Custom',
                  ));
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SMS & Reminders'),
        backgroundColor: const Color(0xFF0EA5E9), // Sky Blue
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.send), text: 'Compose & Send'),
            Tab(icon: Icon(Icons.library_books), text: 'Templates'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildComposeTab(),
          _buildTemplatesTab(),
        ],
      ),
    );
  }

  Widget _buildComposeTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 800) {
          // Mobile Layout (Vertical)
          return Column(
            children: [
              // Top: Patient Selection
              Expanded(
                flex: 6,
                child: _buildPatientSelection(isMobile: true),
              ),
              const Divider(height: 1, thickness: 1),
              // Bottom: Message Composition
              Expanded(
                flex: 4,
                child: _buildMessageComposition(isMobile: true),
              ),
            ],
          );
        } else {
          // Desktop Layout (Horizontal)
          return Row(
            children: [
              // Left Side: Patient Selection
              Expanded(
                flex: 4,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(right: BorderSide(color: Colors.grey[300]!)),
                  ),
                  child: _buildPatientSelection(isMobile: false),
                ),
              ),
              
              // Right Side: Message Composition
              Expanded(
                flex: 6,
                child: _buildMessageComposition(isMobile: false),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildPatientSelection({required bool isMobile}) {
    return Column(
      children: [
        // Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              _buildFilterChip('All', 'All'),
              const SizedBox(width: 8),
              _buildFilterChip('TodayBirthday', '🎂 Birthday Today', isBirthday: true),
              const SizedBox(width: 8),
              _buildFilterChip('TodayAppts', 'Today\'s Appts'),
              const SizedBox(width: 8),
              _buildFilterChip('TomorrowAppts', 'Tmrw Appts'),
              const SizedBox(width: 8),
              _buildFilterChip('TodayFollowUps', 'Today Follow-up'),
              const SizedBox(width: 8),
              _buildFilterChip('TomorrowFollowUps', 'Tmrw Follow-up'),
            ],
          ),
        ),
        const Divider(height: 1),
        
        // Search
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search in list...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onChanged: (value) {
              // Implement local filtering
            },
          ),
        ),
        
        CheckboxListTile(
          title: const Text('Select All', style: TextStyle(fontWeight: FontWeight.bold)),
          value: _selectAll,
          onChanged: _toggleSelectAll,
          controlAffinity: ListTileControlAffinity.leading,
        ),
        const Divider(height: 1),
        
        // Patient List
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
                        return ListTile(
                          leading: Checkbox(
                            value: isSelected,
                            onChanged: (val) => _togglePatientSelection(patient, val),
                          ),
                          title: Text(patient.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                          subtitle: Text('${patient.mobile}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.send, color: Colors.blue),
                            tooltip: 'Send SMS to this patient only',
                            onPressed: () {
                              // Quick send to single patient
                              if (_messageController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please enter a message first')),
                                );
                                return;
                              }
                              final msg = _personalizeMessage(_messageController.text, patient);
                              _launchSms(patient.mobile, msg);
                            },
                          ),
                          onTap: () => _togglePatientSelection(patient, !isSelected),
                        );
                      },
                    ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.grey[100],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${_selectedPatients.length} Selected', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageComposition({required bool isMobile}) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      color: Colors.grey[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMobile) ...[
            const Text('Compose Message', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
          ],
          
          // Template Selector
          DropdownButtonFormField<String>(
            value: _selectedTemplateId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Choose Template',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.description),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: _templates.map((t) => DropdownMenuItem(
              value: t.id,
              child: Text(t.title, overflow: TextOverflow.ellipsis),
            )).toList(),
            onChanged: (val) {
              final template = _templates.firstWhere((t) => t.id == val);
              _applyTemplate(template);
            },
          ),
          const SizedBox(height: 16),
          
          // Message Body
          Expanded(
            child: TextField(
              controller: _messageController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(
                labelText: 'Message',
                hintText: 'Type your message here...',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Placeholders Help
          if (!isMobile)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[100]!),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.blue),
                SizedBox(width: 8),
                Text('Available Placeholders: {name}, {token}, {date}'),
              ],
            ),
          ),
          if (!isMobile) const SizedBox(height: 20),
          if (isMobile) const SizedBox(height: 12),
          
          // Send Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _sendBulkSms,
              icon: const Icon(Icons.send),
              label: Text('Send to ${_selectedPatients.length} Patients'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0EA5E9),
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filter, String label, {bool isBirthday = false}) {
    final isSelected = _currentFilter == filter;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) _applyFilter(filter);
      },
      backgroundColor: isBirthday ? const Color(0xFFFFE4EC) : Colors.white,
      selectedColor: isBirthday ? const Color(0xFFFF6B95) : Colors.blue[100],
      labelStyle: TextStyle(
        color: isSelected 
            ? (isBirthday ? Colors.white : Colors.blue[900]) 
            : (isBirthday ? const Color(0xFFFF6B95) : Colors.black87),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildTemplatesTab() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewTemplate,
        backgroundColor: const Color(0xFF0EA5E9),
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _templates.length,
        itemBuilder: (context, index) {
          final template = _templates[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.message, color: Colors.blue[700]),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                template.title,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                template.category,
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _templates.removeAt(index);
                          });
                        },
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Text(
                    template.content,
                    style: TextStyle(color: Colors.grey[800], height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          _tabController.animateTo(0);
                          _applyTemplate(template);
                        },
                        icon: const Icon(Icons.reply),
                        label: const Text('Use this Template'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class SmsTemplate {
  final String id;
  final String title;
  final String content;
  final String category;

  SmsTemplate({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
  });
}

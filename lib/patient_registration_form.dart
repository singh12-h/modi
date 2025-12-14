import 'package:flutter/material.dart';
import 'dart:math';
import 'database_helper.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'models.dart';
import 'patient_qr_code.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_cropper/image_cropper.dart';

class PatientRegistrationForm extends StatefulWidget {
  final Appointment? appointment;

  const PatientRegistrationForm({super.key, this.appointment});

  @override
  State<PatientRegistrationForm> createState() =>
      _PatientRegistrationFormState();
}

class _PatientRegistrationFormState extends State<PatientRegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _medicalHistoryController =
      TextEditingController();
  final TextEditingController _symptomsController = TextEditingController();
  final TextEditingController _emergencyContactController =
      TextEditingController();
  String? _selectedGender;
  DateTime? _selectedBirthDate; // New: Birth date for auto age calculation
  String _visitType = 'New Patient'; // New field
  bool _isPreviousPatient = false; // Track if patient visited before
  Patient? _previousVisit; // Store previous visit data
  late String _token = 'Loading...'; // Initial state
  
  // Name search functionality
  List<Patient> _nameSearchResults = [];
  bool _showNameSuggestions = false;

  @override
  void initState() {
    super.initState();
    _generateToken();
    if (widget.appointment != null) {
      _prefillData();
    }
    // Listen to mobile number changes to detect previous patients
    _mobileController.addListener(_checkPreviousVisit);
    // Listen to name changes for autocomplete search
    _nameController.addListener(_onNameChanged);
  }

  // Name search for autocomplete
  void _onNameChanged() async {
    final query = _nameController.text;
    if (query.length >= 2) {
      final results = await DatabaseHelper.instance.searchPatientsByName(query);
      setState(() {
        _nameSearchResults = results;
        _showNameSuggestions = results.isNotEmpty;
      });
    } else {
      setState(() {
        _nameSearchResults = [];
        _showNameSuggestions = false;
      });
    }
  }

  // Select patient from name suggestions
  void _selectPatientFromSuggestion(Patient patient) {
    setState(() {
      _nameController.text = patient.name;
      _ageController.text = patient.age;
      _selectedGender = patient.gender;
      _mobileController.text = patient.mobile;
      if (patient.address != null) _addressController.text = patient.address!;
      if (patient.medicalHistory != null) _medicalHistoryController.text = patient.medicalHistory!;
      if (patient.emergencyContact != null) _emergencyContactController.text = patient.emergencyContact!;
      _selectedBirthDate = patient.birthDate;
      _isPreviousPatient = true;
      _previousVisit = patient;
      _visitType = 'Follow-up';
      _showNameSuggestions = false;
      _nameSearchResults = [];
      
      // Load patient photo
      if (patient.photoPath != null && patient.photoPath!.isNotEmpty) {
        if (kIsWeb) {
          _webImagePath = patient.photoPath;
        } else {
          _selectedImage = File(patient.photoPath!);
        }
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Welcome back ${patient.name}! Photo & data loaded.'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }


  Future<void> _checkPreviousVisit() async {
    final mobile = _mobileController.text;
    if (mobile.length == 10) {
      final previousPatients = await DatabaseHelper.instance
          .getPatientsByMobile(mobile);
      if (previousPatients.isNotEmpty) {
        setState(() {
          _isPreviousPatient = true;
          _previousVisit = previousPatients.first;
          _visitType = 'Follow-up';

          // Auto-fill data from previous visit
          if (_nameController.text.isEmpty) {
            _nameController.text = _previousVisit!.name;
          }
          if (_ageController.text.isEmpty) {
            _ageController.text = _previousVisit!.age;
          }
          if (_selectedGender == null) {
            _selectedGender = _previousVisit!.gender;
          }
          if (_addressController.text.isEmpty &&
              _previousVisit!.address != null) {
            _addressController.text = _previousVisit!.address!;
          }
          if (_medicalHistoryController.text.isEmpty &&
              _previousVisit!.medicalHistory != null) {
            _medicalHistoryController.text = _previousVisit!.medicalHistory!;
          }
          if (_emergencyContactController.text.isEmpty &&
              _previousVisit!.emergencyContact != null) {
            _emergencyContactController.text =
                _previousVisit!.emergencyContact!;
          }
        });

        // Show notification
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Welcome back ${_previousVisit!.name}! Last visit: ${_formatDate(_previousVisit!.lastVisit ?? _previousVisit!.registeredDate!)}',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        setState(() {
          _isPreviousPatient = false;
          _previousVisit = null;
          _visitType = 'New Patient';
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _prefillData() {
    _nameController.text = widget.appointment!.patientName;
    _mobileController.text = widget.appointment!.mobile;
    _symptomsController.text = widget.appointment!.reason;
  }

  Future<void> _generateToken() async {
    try {
      final patients = await DatabaseHelper.instance.getPatientsByDate(
        DateTime.now(),
      );
      // Get the count and add 1
      final nextToken = patients.length + 1;
      setState(() {
        _token = 'A$nextToken'; // Format: A1, A2, A3...
      });
    } catch (e) {
      print('Error generating token: $e');
      // Fallback if database fails
      setState(() {
        _token = 'A${Random().nextInt(1000)}';
      });
    }
  }

  File? _selectedImage;
  String? _webImagePath;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    // Show choice dialog
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Wrap(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'Select Photo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.blue),
                  ),
                  title: const Text('Take Photo'),
                  subtitle: const Text('Use camera to capture'),
                  onTap: () {
                    Navigator.pop(context);
                    _getImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.photo_library, color: Colors.purple),
                  ),
                  title: const Text('Choose from Gallery'),
                  subtitle: const Text('Select existing photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _getImage(ImageSource.gallery);
                  },
                ),
                if (_selectedImage != null || _webImagePath != null)
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.delete, color: Colors.red),
                    ),
                    title: const Text('Remove Photo'),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _selectedImage = null;
                        _webImagePath = null;
                      });
                    },
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      // Request permission for camera
      if (source == ImageSource.camera && !kIsWeb) {
        final status = await Permission.camera.request();
        if (status.isDenied || status.isPermanentlyDenied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Camera permission required'),
                action: SnackBarAction(
                  label: 'Settings',
                  onPressed: () => openAppSettings(),
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      // Request permission for gallery
      if (source == ImageSource.gallery && !kIsWeb) {
        final status = await Permission.photos.request();
        // On older Android, use storage permission
        if (status.isDenied) {
          await Permission.storage.request();
        }
      }

      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (image != null) {
        // Crop the image (only on mobile)
        if (!kIsWeb) {
          final croppedFile = await ImageCropper().cropImage(
            sourcePath: image.path,
            aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
            uiSettings: [
              AndroidUiSettings(
                toolbarTitle: 'Crop Photo',
                toolbarColor: const Color(0xFF8E2DE2),
                toolbarWidgetColor: Colors.white,
                initAspectRatio: CropAspectRatioPreset.square,
                lockAspectRatio: false,
                activeControlsWidgetColor: const Color(0xFFFF0080),
              ),
              IOSUiSettings(
                title: 'Crop Photo',
                aspectRatioLockEnabled: false,
              ),
            ],
          );
          
          if (croppedFile != null) {
            setState(() {
              _selectedImage = File(croppedFile.path);
            });
          } else {
            // User cancelled cropping, use original
            setState(() {
              _selectedImage = File(image.path);
            });
          }
        } else {
          // Web - no cropping
          setState(() {
            _webImagePath = image.path;
          });
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 10),
                  Text('Photo selected successfully!'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } on PlatformException catch (e) {
      print('Platform Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Image Picker Error: $e');
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

  Widget _buildPhotoSection() {
    return Center(
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white,
              backgroundImage: kIsWeb && _webImagePath != null
                  ? NetworkImage(_webImagePath!) as ImageProvider
                  : (_selectedImage != null
                        ? FileImage(_selectedImage!)
                        : null),
              child: (_selectedImage == null && _webImagePath == null)
                  ? const Icon(
                      Icons.person_add_alt_1_rounded,
                      size: 50,
                      color: Color(0xFFE0E0E0),
                    )
                  : null,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFFFF0080),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F0FC), // Light Purple background
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 15),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.grey[400], size: 22),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF8E2DE2), width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Future<void> _sendSMS(Patient patient) async {
    try {
      final String message =
          '''Dear ${patient.name},

Your registration is confirmed at MODI CLINIC.

Token Number: ${patient.token}
Registration Time: ${patient.registrationTime.hour}:${patient.registrationTime.minute.toString().padLeft(2, '0')}

Please arrive 10 minutes before your appointment.

Thank you!
MODI CLINIC''';

      final Uri smsUri = Uri(
        scheme: 'sms',
        path: patient.mobile,
        queryParameters: {'body': message},
      );

      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open SMS app'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error sending SMS: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _sendWhatsApp(Patient patient, {String? customMessage}) async {
    try {
      final String message =
          customMessage ??
          '''🏥 *MODI CLINIC*

Dear *${patient.name}*,

✅ Your registration is confirmed!

📋 *Token Number:* ${patient.token}
⏰ *Registration Time:* ${patient.registrationTime.hour}:${patient.registrationTime.minute.toString().padLeft(2, '0')}
📅 *Date:* ${patient.registrationTime.day}/${patient.registrationTime.month}/${patient.registrationTime.year}

👨‍⚕️ Please arrive 10 minutes before your appointment.

Thank you for choosing MODI CLINIC! 🙏''';

      // WhatsApp URL scheme
      // Remove country code if present and format properly
      String phoneNumber = patient.mobile.replaceAll(RegExp(r'[^0-9]'), '');

      // Add country code if not present (assuming India +91)
      if (!phoneNumber.startsWith('91') && phoneNumber.length == 10) {
        phoneNumber = '91$phoneNumber';
      }

      final Uri whatsappUri = Uri.parse(
        'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}',
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
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _submitForm() async {
    print('Button clicked!');
    if (_formKey.currentState!.validate()) {
      print('Form validated successfully');
      try {
        // Use existing patient ID if linked to an appointment, otherwise generate new
        final String patientId =
            widget.appointment?.patientId ??
            Random().nextInt(1000000).toString();

        final patient = Patient(
          id: patientId,
          name: _nameController.text,
          token: _token,
          age: _ageController.text,
          gender: _selectedGender!,
          mobile: _mobileController.text,
          photoPath: kIsWeb ? _webImagePath : _selectedImage?.path,
          address: _addressController.text,
          medicalHistory: _medicalHistoryController.text,
          symptoms: _symptomsController.text,
          emergencyContact: _emergencyContactController.text,
          status: PatientStatus.waiting, // Explicitly set default status
          registrationTime: DateTime.now(),
          registeredDate: DateTime.now(),
          isAppointment: widget.appointment != null,
          birthDate: _selectedBirthDate, // For birthday notification
        );

        await DatabaseHelper.instance.insertPatient(patient);

        if (widget.appointment != null) {
          await DatabaseHelper.instance.confirmAppointment(
            widget.appointment!.id,
            patient.id,
            patient.photoPath,
          );
        }

        if (mounted) {
          // Show dialog with SMS option
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext dialogContext) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Registration Successful!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Patient: ${patient.name}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Token: ${patient.token}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF8B5CF6),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Send registration confirmation to patient:',
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      Navigator.pop(context, true);
                      if (widget.appointment != null) {
                        Navigator.pop(context);
                      }
                    },
                    child: const Text(
                      'Skip',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.of(dialogContext).pop();
                      await _sendSMS(patient);
                      Navigator.pop(context, true);
                      if (widget.appointment != null) {
                        Navigator.pop(context);
                      }
                    },
                    icon: const Icon(Icons.sms, color: Colors.white, size: 18),
                    label: const Text(
                      'SMS',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.of(dialogContext).pop();
                      await _sendWhatsApp(patient);
                      Navigator.pop(context, true);
                      if (widget.appointment != null) {
                        Navigator.pop(context);
                      }
                    },
                    icon: const Icon(Icons.chat, color: Colors.white, size: 18),
                    label: const Text(
                      'WhatsApp',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
                actionsOverflowButtonSpacing: 8,
                actionsAlignment: MainAxisAlignment.spaceEvenly,
              );
            },
          );
        }
      } catch (e) {
        print('Error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error registering patient: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // Focus Nodes
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _ageFocus = FocusNode();
  final FocusNode _genderFocus = FocusNode();
  final FocusNode _mobileFocus = FocusNode();
  final FocusNode _addressFocus = FocusNode();
  final FocusNode _symptomsFocus = FocusNode();
  final FocusNode _historyFocus = FocusNode();
  final FocusNode _emergencyFocus = FocusNode();

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    _medicalHistoryController.dispose();
    _symptomsController.dispose();
    _emergencyContactController.dispose();

    // Dispose Focus Nodes
    _nameFocus.dispose();
    _ageFocus.dispose();
    _genderFocus.dispose();
    _mobileFocus.dispose();
    _addressFocus.dispose();
    _symptomsFocus.dispose();
    _historyFocus.dispose();
    _emergencyFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFE8ECEF,
      ), // Darker gray background for better contrast
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8E2DE2), Color(0xFFFF0080)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'New Patient Registration',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            // Body
            Expanded(
              child: Shortcuts(
                shortcuts: <LogicalKeySet, Intent>{
                  LogicalKeySet(LogicalKeyboardKey.arrowDown):
                      const NextFocusIntent(),
                  LogicalKeySet(LogicalKeyboardKey.arrowUp):
                      const PreviousFocusIntent(),
                },
                child: Actions(
                  actions: <Type, Action<Intent>>{
                    NextFocusIntent: CallbackAction<NextFocusIntent>(
                      onInvoke: (NextFocusIntent intent) {
                        FocusScope.of(context).nextFocus();
                        return null;
                      },
                    ),
                    PreviousFocusIntent: CallbackAction<PreviousFocusIntent>(
                      onInvoke: (PreviousFocusIntent intent) {
                        FocusScope.of(context).previousFocus();
                        return null;
                      },
                    ),
                  },
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildPhotoSection(),
                          const SizedBox(height: 24),

                          // Visit Type Indicator
                          if (_isPreviousPatient)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF10B981),
                                    Color(0xFF059669),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF10B981,
                                    ).withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.history,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'FOLLOW-UP VISIT',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Last visit: ${_formatDate(_previousVisit!.lastVisit ?? _previousVisit!.registeredDate!)} • Total visits: ${_previousVisit!.consultationCount + 1}',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (_isPreviousPatient) const SizedBox(height: 24),

                          _buildCard(
                            title: 'Personal Information',
                            icon: Icons.person_outline,
                            color: const Color(0xFF8E2DE2),
                            children: [
                              _buildTextField(
                                _nameController,
                                'Full Name',
                                Icons.badge_outlined,
                                focusNode: _nameFocus,
                                nextFocus: _ageFocus,
                              ),
                              // Name Search Suggestions
                              if (_showNameSuggestions && _nameSearchResults.isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFF8E2DE2).withOpacity(0.3)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.purple.withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Text(
                                          '🔍 Existing Patients Found (${_nameSearchResults.length})',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      const Divider(height: 1),
                                      ..._nameSearchResults.map((patient) => InkWell(
                                        onTap: () => _selectPatientFromSuggestion(patient),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                          decoration: BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(color: Colors.grey.shade200),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              // Patient Photo
                                              CircleAvatar(
                                                radius: 22,
                                                backgroundColor: const Color(0xFFE0E7FF),
                                                backgroundImage: patient.photoPath != null
                                                    ? (kIsWeb 
                                                        ? NetworkImage(patient.photoPath!) as ImageProvider
                                                        : FileImage(File(patient.photoPath!)))
                                                    : null,
                                                child: patient.photoPath == null
                                                    ? Text(
                                                        patient.name.isNotEmpty ? patient.name[0].toUpperCase() : '?',
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          color: Color(0xFF8E2DE2),
                                                        ),
                                                      )
                                                    : null,
                                              ),
                                              const SizedBox(width: 12),
                                              // Patient Info
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      patient.name,
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    Text(
                                                      '${patient.age}yrs • ${patient.gender} • ${patient.mobile}',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              // Visit count badge
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF10B981).withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  '${patient.consultationCount ?? 0} visits',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Color(0xFF10B981),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 16),

                              
                              // Birthdate Picker with Auto Age Calculation
                              _buildBirthDatePicker(),
                              const SizedBox(height: 16),
                              
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildTextField(
                                      _ageController,
                                      'Age',
                                      Icons.cake_outlined,
                                      isNumber: true,
                                      focusNode: _ageFocus,
                                      nextFocus: _genderFocus,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(child: _buildGenderDropdown()),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                _mobileController,
                                'Mobile Number',
                                Icons.phone_android,
                                isNumber: true,
                                focusNode: _mobileFocus,
                                nextFocus: _addressFocus,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                _addressController,
                                'Address',
                                Icons.location_on_outlined,
                                maxLines: 2,
                                focusNode: _addressFocus,
                                nextFocus: _symptomsFocus,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          _buildCard(
                            title: 'Medical Information',
                            icon: Icons.medical_services_outlined,
                            color: const Color(0xFFFF0080),
                            children: [
                              _buildTextField(
                                _symptomsController,
                                'Current Symptoms',
                                Icons.sick_outlined,
                                maxLines: 2,
                                focusNode: _symptomsFocus,
                                nextFocus: _historyFocus,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                _medicalHistoryController,
                                'Medical History',
                                Icons.history_edu_outlined,
                                maxLines: 2,
                                focusNode: _historyFocus,
                                nextFocus: _emergencyFocus,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                _emergencyContactController,
                                'Emergency Contact',
                                Icons.contact_phone_outlined,
                                isNumber: true,
                                focusNode: _emergencyFocus,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          _buildCard(
                            title: 'Token Details',
                            icon: Icons.confirmation_number_outlined,
                            color: Colors.orange,
                            children: [
                              TextFormField(
                                key: ValueKey(_token),
                                initialValue: _token,
                                readOnly: true,
                                decoration: _inputDecoration(
                                  'Token Number',
                                  Icons.confirmation_number_outlined,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),

                          Container(
                            width: double.infinity,
                            height: 55,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF8E2DE2), Color(0xFFFF0080)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFFF0080,
                                  ).withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _submitForm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: const Text(
                                'SAVE & REGISTER PATIENT',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isNumber = false,
    int maxLines = 1,
    FocusNode? focusNode,
    FocusNode? nextFocus,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      textInputAction: nextFocus != null
          ? TextInputAction.next
          : TextInputAction.done,
      onFieldSubmitted: (_) {
        if (nextFocus != null) {
          FocusScope.of(context).requestFocus(nextFocus);
        }
      },
      decoration: _inputDecoration(label, icon),
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      validator: (value) {
        if (label.contains('Fee') || label.contains('History')) return null;
        if (value == null || value.isEmpty) return '$label is required';
        return null;
      },
    );
  }

  // Calculate age from birthdate
  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month || 
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  // Birthdate Picker Widget with Auto Age Calculation
  Widget _buildBirthDatePicker() {
    return InkWell(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: _selectedBirthDate ?? DateTime(2000, 1, 1),
          firstDate: DateTime(1920),
          lastDate: DateTime.now(),
          helpText: 'जन्म तिथि चुनें / Select Birth Date',
          cancelText: 'रद्द करें',
          confirmText: 'चुनें',
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: Color(0xFF8E2DE2),
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: Colors.black,
                ),
              ),
              child: child!,
            );
          },
        );
        
        if (picked != null) {
          setState(() {
            _selectedBirthDate = picked;
            // Auto calculate and fill age
            final age = _calculateAge(picked);
            _ageController.text = age.toString();
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedBirthDate != null 
                ? const Color(0xFF8E2DE2) 
                : Colors.grey[300]!,
            width: _selectedBirthDate != null ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.cake_outlined,
              color: _selectedBirthDate != null 
                  ? const Color(0xFF8E2DE2) 
                  : Colors.grey[400],
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Birth Date (जन्म तिथि)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedBirthDate != null
                        ? DateFormat('dd MMM yyyy').format(_selectedBirthDate!)
                        : 'Tap to select date',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: _selectedBirthDate != null 
                          ? FontWeight.w600 
                          : FontWeight.normal,
                      color: _selectedBirthDate != null 
                          ? Colors.black87 
                          : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            if (_selectedBirthDate != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8E2DE2), Color(0xFFFF0080)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_calculateAge(_selectedBirthDate!)} yrs',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ] else ...[
              Icon(Icons.calendar_today, color: Colors.grey[400], size: 20),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedGender,
      focusNode: _genderFocus,
      decoration: _inputDecoration('Gender', Icons.wc),
      items: ['Male', 'Female', 'Other'].map((String value) {
        return DropdownMenuItem<String>(value: value, child: Text(value));
      }).toList(),
      onChanged: (value) {
        setState(() => _selectedGender = value);
        FocusScope.of(context).requestFocus(_mobileFocus); // Auto move focus
      },
      validator: (value) => value == null ? 'Required' : null,
    );
  }
}

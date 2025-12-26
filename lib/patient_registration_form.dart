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
import 'responsive_helper.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:typed_data';

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
  final TextEditingController _birthDateController = TextEditingController(); // For manual date entry
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

  // ============ SMART IMAGE COMPRESSION TO ~50KB WITHOUT QUALITY LOSS ============
  // This function intelligently compresses images to approximately 50KB
  // while maintaining the best possible quality
  Future<File?> _compressImageTo50KB(File imageFile) async {
    try {
      final int targetSize = 50 * 1024; // 50KB in bytes
      final Uint8List originalBytes = await imageFile.readAsBytes();
      final int originalSize = originalBytes.length;
      
      print('📸 Original image size: ${(originalSize / 1024).toStringAsFixed(2)} KB');
      
      // If already under 50KB, no compression needed
      if (originalSize <= targetSize) {
        print('✅ Image already under 50KB, no compression needed');
        return imageFile;
      }

      // Calculate initial quality based on size ratio
      // Higher original size = lower starting quality
      int quality = (targetSize / originalSize * 100).clamp(20, 95).toInt();
      int minWidth = 800;
      int minHeight = 800;
      
      Uint8List? compressedBytes;
      int attempts = 0;
      const int maxAttempts = 10;
      
      // Iteratively compress until we hit target size or max attempts
      while (attempts < maxAttempts) {
        attempts++;
        
        compressedBytes = await FlutterImageCompress.compressWithList(
          originalBytes,
          minWidth: minWidth,
          minHeight: minHeight,
          quality: quality,
          format: CompressFormat.jpeg,
        );
        
        final int compressedSize = compressedBytes?.length ?? 0;
        print('🔄 Attempt $attempts: Quality=$quality, Size=${(compressedSize / 1024).toStringAsFixed(2)} KB');
        
        if (compressedSize <= targetSize) {
          print('✅ Target size achieved! Final size: ${(compressedSize / 1024).toStringAsFixed(2)} KB');
          break;
        }
        
        // Adjust parameters for next attempt
        if (quality > 30) {
          quality -= 10;
        } else {
          // If quality is already low, reduce dimensions
          minWidth = (minWidth * 0.85).toInt();
          minHeight = (minHeight * 0.85).toInt();
          quality = 60; // Reset quality for new dimensions
        }
        
        // Minimum dimension check
        if (minWidth < 200 || minHeight < 200) {
          print('⚠️ Reached minimum dimensions, using current compression');
          break;
        }
      }
      
      if (compressedBytes != null && compressedBytes.isNotEmpty) {
        // Save compressed image to a new file
        final String dir = imageFile.parent.path;
        final String newPath = '$dir/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final File compressedFile = File(newPath);
        await compressedFile.writeAsBytes(compressedBytes);
        
        final int finalSize = await compressedFile.length();
        print('✅ Compression complete!');
        print('   Original: ${(originalSize / 1024).toStringAsFixed(2)} KB');
        print('   Compressed: ${(finalSize / 1024).toStringAsFixed(2)} KB');
        print('   Saved: ${((originalSize - finalSize) / 1024).toStringAsFixed(2)} KB (${((1 - finalSize / originalSize) * 100).toStringAsFixed(1)}%)');
        
        // Delete original cropped file to save space
        try {
          if (imageFile.existsSync() && imageFile.path != compressedFile.path) {
            await imageFile.delete();
          }
        } catch (e) {
          print('Warning: Could not delete original file: $e');
        }
        
        return compressedFile;
      }
      
      return imageFile;
    } catch (e) {
      print('❌ Error compressing image: $e');
      return imageFile; // Return original if compression fails
    }
  }
  // ============ END SMART COMPRESSION ============

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
          
          File? imageToProcess;
          if (croppedFile != null) {
            imageToProcess = File(croppedFile.path);
          } else {
            // User cancelled cropping, use original
            imageToProcess = File(image.path);
          }
          
          // Show loading indicator while compressing
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text('Optimizing photo to 50KB...'),
                  ],
                ),
                backgroundColor: Color(0xFF8E2DE2),
                duration: Duration(seconds: 5),
              ),
            );
          }
          
          // ✨ SMART COMPRESSION TO 50KB
          final File? compressedImage = await _compressImageTo50KB(imageToProcess);
          
          setState(() {
            _selectedImage = compressedImage ?? imageToProcess;
          });
          
          // Show success with file size
          if (mounted && compressedImage != null) {
            final int fileSize = await compressedImage.length();
            final String sizeText = (fileSize / 1024).toStringAsFixed(1);
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('Photo optimized! Size: ${sizeText}KB ✨'),
                    ),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } else {
          // Web - no cropping or compression
          setState(() {
            _webImagePath = image.path;
          });
          
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
      prefixIcon: Padding(
        padding: const EdgeInsets.only(top: 0),
        child: Icon(icon, color: Colors.grey[400], size: 22),
      ),
      alignLabelWithHint: true,
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
          ResponsiveHelper.init(context);
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext dialogContext) {
              return ResponsiveDialog(
                title: 'Registration Successful!',
                titleIcon: Container(
                  padding: EdgeInsets.all(ResponsiveHelper.spacingSM),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                    ),
                    borderRadius: BorderRadius.circular(ResponsiveHelper.radiusSM),
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: ResponsiveHelper.iconMD,
                  ),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ResponsiveText(
                      'Patient: ${patient.name}',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.fontMD,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.spacingSM),
                    ResponsiveText(
                      'Token: ${patient.token}',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.fontMD,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF8B5CF6),
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.spacingMD),
                    ResponsiveText(
                      'Send registration confirmation:',
                      style: TextStyle(fontSize: ResponsiveHelper.fontSM, color: Colors.black87),
                    ),
                  ],
                ),
                actions: ResponsiveHelper.isVerySmallPhone
                    ? [
                        // Stack buttons vertically on very small screens
                        ResponsiveButton(
                          onPressed: () async {
                            Navigator.of(dialogContext).pop();
                            await _sendSMS(patient);
                            Navigator.pop(context, true);
                            if (widget.appointment != null) {
                              Navigator.pop(context);
                            }
                          },
                          label: 'Send SMS',
                          icon: Icons.sms,
                          color: const Color(0xFF8B5CF6),
                        ),
                        SizedBox(height: ResponsiveHelper.spacingSM),
                        ResponsiveButton(
                          onPressed: () async {
                            Navigator.of(dialogContext).pop();
                            await _sendWhatsApp(patient);
                            Navigator.pop(context, true);
                            if (widget.appointment != null) {
                              Navigator.pop(context);
                            }
                          },
                          label: 'WhatsApp',
                          icon: Icons.chat,
                          color: const Color(0xFF25D366),
                        ),
                        SizedBox(height: ResponsiveHelper.spacingSM),
                        TextButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                            Navigator.pop(context, true);
                            if (widget.appointment != null) {
                              Navigator.pop(context);
                            }
                          },
                          child: ResponsiveText('Skip', style: TextStyle(color: Colors.grey, fontSize: ResponsiveHelper.fontSM)),
                        ),
                      ]
                    : [
                        // Horizontal layout for larger screens
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(dialogContext).pop();
                                Navigator.pop(context, true);
                                if (widget.appointment != null) {
                                  Navigator.pop(context);
                                }
                              },
                              child: ResponsiveText('Skip', style: TextStyle(color: Colors.grey, fontSize: ResponsiveHelper.fontSM)),
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
                              icon: Icon(Icons.sms, color: Colors.white, size: ResponsiveHelper.iconSM),
                              label: ResponsiveText('SMS', style: TextStyle(color: Colors.white, fontSize: ResponsiveHelper.fontSM)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8B5CF6),
                                padding: EdgeInsets.symmetric(horizontal: ResponsiveHelper.spacingMD, vertical: ResponsiveHelper.spacingSM),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ResponsiveHelper.radiusSM)),
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
                              icon: Icon(Icons.chat, color: Colors.white, size: ResponsiveHelper.iconSM),
                              label: ResponsiveText('WhatsApp', style: TextStyle(color: Colors.white, fontSize: ResponsiveHelper.fontSM)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF25D366),
                                padding: EdgeInsets.symmetric(horizontal: ResponsiveHelper.spacingMD, vertical: ResponsiveHelper.spacingSM),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ResponsiveHelper.radiusSM)),
                              ),
                            ),
                          ],
                        ),
                      ],
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
    _birthDateController.dispose();

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
                              
                              Builder(
                                builder: (context) {
                                  ResponsiveHelper.init(context);
                                  final isVerySmall = ResponsiveHelper.screenWidth < 340;
                                  final gapWidth = ResponsiveHelper.screenWidth < 380 ? 8.0 : 16.0;
                                  
                                  // Stack vertically on very small screens
                                  if (isVerySmall) {
                                    return Column(
                                      children: [
                                        _buildTextField(
                                          _ageController,
                                          'Age',
                                          Icons.cake_outlined,
                                          isNumber: true,
                                          focusNode: _ageFocus,
                                          nextFocus: _genderFocus,
                                        ),
                                        const SizedBox(height: 12),
                                        _buildGenderDropdown(),
                                      ],
                                    );
                                  }
                                  
                                  return Row(
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
                                      SizedBox(width: gapWidth),
                                      Expanded(child: _buildGenderDropdown()),
                                    ],
                                  );
                                },
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

  // Birthdate Picker Widget with Auto Age Calculation and Manual Entry
  Widget _buildBirthDatePicker() {
    return TextFormField(
      controller: _birthDateController,
      decoration: InputDecoration(
        labelText: 'Birth Date (जन्म तिथि)',
        hintText: 'DD/MM/YYYY or any format',
        prefixIcon: Icon(Icons.cake_outlined, color: Colors.grey[600]),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Clear button
            if (_birthDateController.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear, size: 20),
                onPressed: () {
                  setState(() {
                    _birthDateController.clear();
                    _selectedBirthDate = null;
                    _ageController.clear();
                  });
                },
              ),
            // Calendar button
            IconButton(
              icon: const Icon(Icons.calendar_month, color: Color(0xFF8E2DE2)),
              onPressed: () => _showDatePickerDialog(),
            ),
          ],
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF8E2DE2), width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      keyboardType: TextInputType.datetime,
      onChanged: (value) {
        // Try to parse the date in various formats
        _tryParseDate(value);
      },
    );
  }

  // Try to parse date from various formats
  void _tryParseDate(String value) {
    if (value.isEmpty) {
      setState(() {
        _selectedBirthDate = null;
        _ageController.clear();
      });
      return;
    }

    DateTime? parsed;
    
    // Try various date formats
    final formats = [
      'dd/MM/yyyy', 'dd-MM-yyyy', 'dd.MM.yyyy',
      'MM/dd/yyyy', 'yyyy-MM-dd', 'yyyy/MM/dd',
      'd/M/yyyy', 'd-M-yyyy', 'dd/M/yyyy', 'd/MM/yyyy',
      'ddMMyyyy', 'd M yyyy', 'dd M yyyy',
    ];
    
    for (final format in formats) {
      try {
        parsed = DateFormat(format).parseStrict(value);
        break;
      } catch (_) {}
    }
    
    // Also try natural parsing
    if (parsed == null) {
      try {
        // Try parsing simple numbers like "15 10 1990"
        final parts = value.split(RegExp(r'[\s/\-.]+')).where((p) => p.isNotEmpty).toList();
        if (parts.length == 3) {
          int? day = int.tryParse(parts[0]);
          int? month = int.tryParse(parts[1]);
          int? year = int.tryParse(parts[2]);
          
          if (day != null && month != null && year != null) {
            // Handle 2-digit year
            if (year < 100) {
              year = year > 50 ? 1900 + year : 2000 + year;
            }
            if (day >= 1 && day <= 31 && month >= 1 && month <= 12) {
              parsed = DateTime(year, month, day);
            }
          }
        }
      } catch (_) {}
    }
    
    if (parsed != null && parsed.year >= 1900 && parsed.isBefore(DateTime.now())) {
      setState(() {
        _selectedBirthDate = parsed;
        final age = _calculateAge(parsed!);
        _ageController.text = age.toString();
      });
    }
  }

  // Custom calendar date picker with month/year selector
  Future<void> _showDatePickerDialog() async {
    DateTime selectedDate = _selectedBirthDate ?? DateTime(2000, 1, 1);
    DateTime currentMonth = DateTime(selectedDate.year, selectedDate.month, 1);
    bool showMonthPicker = false;
    bool showYearPicker = false;
    
    final List<String> monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final List<String> weekDays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Helper functions
            int getDaysInMonth(DateTime date) => DateTime(date.year, date.month + 1, 0).day;
            int getFirstDayOfMonth(DateTime date) => DateTime(date.year, date.month, 1).weekday % 7;
            
            List<int?> generateCalendarDays() {
              final daysInMonth = getDaysInMonth(currentMonth);
              final firstDay = getFirstDayOfMonth(currentMonth);
              final List<int?> days = [];
              for (int i = 0; i < firstDay; i++) days.add(null);
              for (int day = 1; day <= daysInMonth; day++) days.add(day);
              return days;
            }
            
            bool isSelectedDate(int? day) {
              if (day == null) return false;
              return day == selectedDate.day &&
                  currentMonth.month == selectedDate.month &&
                  currentMonth.year == selectedDate.year;
            }
            
            bool isToday(int? day) {
              if (day == null) return false;
              final today = DateTime.now();
              return day == today.day &&
                  currentMonth.month == today.month &&
                  currentMonth.year == today.year;
            }
            
            // Get screen size for responsive design
            final screenWidth = MediaQuery.of(context).size.width;
            final isMobile = screenWidth < 400;
            final dialogWidth = isMobile ? screenWidth - 32 : 380.0;
            final headerFontSize = isMobile ? 24.0 : 32.0;
            final headerPadding = isMobile ? 16.0 : 24.0;
            
            return Dialog(
              insetPadding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 40, vertical: 24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: dialogWidth,
                  maxHeight: MediaQuery.of(context).size.height * 0.85, // Limit height to 85% of screen
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header with selected date
                      Container(
                        padding: EdgeInsets.all(headerPadding),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF8E2DE2), Color(0xFFFF0080)],
                          ),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SELECT DATE',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: isMobile ? 10 : 12,
                                fontWeight: FontWeight.w300,
                                letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${weekDays[selectedDate.weekday % 7]}, ${monthNames[selectedDate.month - 1].substring(0, 3)} ${selectedDate.day}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: headerFontSize,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Month and Year selector
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left, size: 28),
                            onPressed: () => setDialogState(() {
                              currentMonth = DateTime(currentMonth.year, currentMonth.month - 1, 1);
                            }),
                            color: const Color(0xFF8E2DE2),
                          ),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Month selector - CLICKABLE
                                InkWell(
                                  onTap: () => setDialogState(() {
                                    showMonthPicker = !showMonthPicker;
                                    showYearPicker = false;
                                  }),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: showMonthPicker ? const Color(0xFF8E2DE2).withOpacity(0.1) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          isMobile ? monthNames[currentMonth.month - 1].substring(0, 3) : monthNames[currentMonth.month - 1],
                                          style: TextStyle(fontSize: isMobile ? 13 : 16, fontWeight: FontWeight.w600),
                                        ),
                                        Icon(
                                          showMonthPicker ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                          color: const Color(0xFF8E2DE2),
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Year selector - CLICKABLE
                                InkWell(
                                  onTap: () => setDialogState(() {
                                    showYearPicker = !showYearPicker;
                                    showMonthPicker = false;
                                  }),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: showYearPicker ? const Color(0xFF8E2DE2).withOpacity(0.1) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          '${currentMonth.year}',
                                          style: TextStyle(fontSize: isMobile ? 13 : 16, fontWeight: FontWeight.w600),
                                        ),
                                        Icon(
                                          showYearPicker ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                          color: const Color(0xFF8E2DE2),
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right, size: 28),
                            onPressed: () => setDialogState(() {
                              currentMonth = DateTime(currentMonth.year, currentMonth.month + 1, 1);
                            }),
                            color: const Color(0xFF8E2DE2),
                          ),
                        ],
                      ),
                    ),
                    
                    // Content - Calendar or Month/Year picker
                    if (!showMonthPicker && !showYearPicker)
                      // Calendar Grid
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 16),
                        child: Column(
                          children: [
                            // Weekday headers
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: weekDays.map((day) => Expanded(
                                child: SizedBox(
                                  height: isMobile ? 32 : 40,
                                  child: Center(
                                    child: Text(
                                      day,
                                      style: TextStyle(
                                        fontSize: isMobile ? 12 : 14,
                                        fontWeight: FontWeight.w600,
                                        color: day == 'S' ? Colors.red[400] : Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                ),
                              )).toList(),
                            ),
                            const SizedBox(height: 4),
                            // Calendar days - Fixed height with proper grid
                            SizedBox(
                              height: isMobile ? 230 : 260,
                              child: GridView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 7,
                                  childAspectRatio: isMobile ? 1.0 : 1.1,
                                  mainAxisSpacing: isMobile ? 2 : 4,
                                  crossAxisSpacing: isMobile ? 2 : 4,
                                ),
                                itemCount: 42, // 6 rows * 7 days
                                itemBuilder: (context, index) {
                                  final calendarDays = generateCalendarDays();
                                  final day = index < calendarDays.length ? calendarDays[index] : null;
                                  final selected = isSelectedDate(day);
                                  final today = isToday(day);
                                  
                                  return GestureDetector(
                                    onTap: () {
                                      if (day != null) {
                                        setDialogState(() {
                                          selectedDate = DateTime(currentMonth.year, currentMonth.month, day);
                                        });
                                      }
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: selected 
                                            ? const Color(0xFF8E2DE2) // Solid purple for selected
                                            : today 
                                                ? const Color(0xFFF3E8FF) // Light purple for today
                                                : Colors.transparent,
                                        borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
                                        boxShadow: selected ? [
                                          BoxShadow(
                                            color: const Color(0xFF8E2DE2).withOpacity(0.4),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ] : null,
                                      ),
                                      child: Center(
                                        child: day != null ? Text(
                                          '$day',
                                          style: TextStyle(
                                            fontSize: isMobile ? 13 : 14,
                                            fontWeight: selected || today ? FontWeight.bold : FontWeight.normal,
                                            color: selected ? Colors.white : Colors.black87,
                                          ),
                                        ) : null,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (showMonthPicker)
                      // Month Picker Grid
                      Container(
                        height: isMobile ? 160 : 200,
                        padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 16),
                        child: GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: isMobile ? 2.2 : 2,
                            crossAxisSpacing: isMobile ? 4 : 8,
                            mainAxisSpacing: isMobile ? 4 : 8,
                          ),
                          itemCount: 12,
                          itemBuilder: (context, index) {
                            final isSelected = currentMonth.month == index + 1;
                            return InkWell(
                              onTap: () => setDialogState(() {
                                currentMonth = DateTime(currentMonth.year, index + 1, 1);
                                showMonthPicker = false;
                              }),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: isSelected ? const LinearGradient(
                                    colors: [Color(0xFF8E2DE2), Color(0xFFFF0080)],
                                  ) : null,
                                  color: isSelected ? null : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    monthNames[index].substring(0, 3),
                                    style: TextStyle(
                                      fontSize: isMobile ? 12 : 14,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      color: isSelected ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    else
                      // Year Picker Grid - Scrollable with better height
                      Container(
                        height: isMobile ? 220 : 280,
                        padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 16),
                        child: GridView.builder(
                          physics: const BouncingScrollPhysics(), // Better scrolling
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4, // 4 columns for better fit
                            childAspectRatio: isMobile ? 1.8 : 2,
                            crossAxisSpacing: isMobile ? 6 : 10,
                            mainAxisSpacing: isMobile ? 6 : 10,
                          ),
                          itemCount: DateTime.now().year - 1919,
                          itemBuilder: (context, index) {
                            final year = DateTime.now().year - index;
                            final isSelected = currentMonth.year == year;
                            return InkWell(
                              onTap: () => setDialogState(() {
                                currentMonth = DateTime(year, currentMonth.month, 1);
                                showYearPicker = false;
                              }),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: isSelected ? const LinearGradient(
                                    colors: [Color(0xFF8E2DE2), Color(0xFFFF0080)],
                                  ) : null,
                                  color: isSelected ? null : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    '$year',
                                    style: TextStyle(
                                      fontSize: isMobile ? 12 : 14,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      color: isSelected ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    
                    // Action Buttons
                    Padding(
                      padding: EdgeInsets.all(isMobile ? 12 : 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: Text(
                              'Cancel',
                              style: TextStyle(color: Colors.grey[600], fontSize: isMobile ? 14 : 16, fontWeight: FontWeight.w600),
                            ),
                          ),
                          SizedBox(width: isMobile ? 8 : 16),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(dialogContext, selectedDate),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8E2DE2),
                              padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 32, vertical: isMobile ? 10 : 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: Text('OK', style: TextStyle(color: Colors.white, fontSize: isMobile ? 14 : 16, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).then((picked) {
      if (picked != null) {
        final pickedDate = picked as DateTime;
        setState(() {
          _selectedBirthDate = pickedDate;
          _birthDateController.text = DateFormat('dd/MM/yyyy').format(pickedDate);
          final age = _calculateAge(pickedDate);
          _ageController.text = age.toString();
        });
      }
    });
  }

  Widget _buildGenderDropdown() {
    ResponsiveHelper.init(context);
    final isSmall = ResponsiveHelper.screenWidth < 380;
    final fontSize = isSmall ? 13.0 : 16.0;
    
    return DropdownButtonFormField<String>(
      value: _selectedGender,
      focusNode: _genderFocus,
      isExpanded: true, // Prevent overflow
      decoration: _inputDecoration('Gender', Icons.wc),
      style: TextStyle(
        fontSize: fontSize,
        color: Colors.black87,
      ),
      items: ['Male', 'Female', 'Other'].map((String value) {
        return DropdownMenuItem<String>(
          value: value, 
          child: Text(
            value,
            style: TextStyle(fontSize: fontSize),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() => _selectedGender = value);
        FocusScope.of(context).requestFocus(_mobileFocus);
      },
      validator: (value) => value == null ? 'Required' : null,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AdminBrandingPage extends StatefulWidget {
  const AdminBrandingPage({super.key});

  @override
  State<AdminBrandingPage> createState() => _AdminBrandingPageState();
}

class _AdminBrandingPageState extends State<AdminBrandingPage> {
  final TextEditingController _appNameController = TextEditingController();
  String? _logoPath;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _appNameController.text = prefs.getString('custom_app_title') ?? '';
      _logoPath = prefs.getString('custom_logo_path');
      _isLoading = false;
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _logoPath = pickedFile.path;
      });
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_app_title', _appNameController.text.trim());
    if (_logoPath != null) {
      await prefs.setString('custom_logo_path', _logoPath!);
    } else {
      await prefs.remove('custom_logo_path');
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Branding settings saved! Restart app or go back to see changes.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true); // Return true to indicate changes
    }
  }

  Future<void> _resetToDefault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('custom_app_title');
    await prefs.remove('custom_logo_path');
    
    setState(() {
      _appNameController.clear();
      _logoPath = null;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reset to default branding')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Branding Configuration'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Customize Login Screen',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Change the application name and logo displayed on the login and welcome screens.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 30),

                  // App Name
                  const Text(
                    'Application Name',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _appNameController,
                    decoration: const InputDecoration(
                      hintText: 'e.g., My Clinic App',
                      border: OutlineInputBorder(),
                      helperText: 'Leave empty to use default "MODI Healthcare System"',
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Logo
                  const Text(
                    'Application Logo',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey[400]!),
                          image: _logoPath != null
                              ? DecorationImage(
                                  image: FileImage(File(_logoPath!)),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _logoPath == null
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                                  SizedBox(height: 5),
                                  Text('Tap to pick', style: TextStyle(color: Colors.grey)),
                                ],
                              )
                            : null,
                      ),
                    ),
                  ),
                  if (_logoPath != null)
                    Center(
                      child: TextButton.icon(
                        onPressed: () => setState(() => _logoPath = null),
                        icon: const Icon(Icons.delete, color: Colors.red),
                        label: const Text('Remove Custom Logo', style: TextStyle(color: Colors.red)),
                      ),
                    ),
                  
                  const SizedBox(height: 40),

                  // Buttons
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saveSettings,
                      icon: const Icon(Icons.save),
                      label: const Text('Save Changes'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF667eea),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _resetToDefault,
                      icon: const Icon(Icons.restore),
                      label: const Text('Reset to Defaults'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

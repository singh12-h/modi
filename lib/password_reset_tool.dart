import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'database_helper.dart';
import 'models.dart';

class PasswordResetTool extends StatefulWidget {
  const PasswordResetTool({super.key});

  @override
  State<PasswordResetTool> createState() => _PasswordResetToolState();
}

class _PasswordResetToolState extends State<PasswordResetTool> {
  List<Staff> _staffList = [];
  bool _isLoading = true;
  final TextEditingController _passwordController = TextEditingController();
  Staff? _selectedStaff;

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    setState(() => _isLoading = true);
    final staff = await DatabaseHelper.instance.getAllStaff();
    setState(() {
      _staffList = staff;
      _isLoading = false;
    });
  }

  Future<void> _resetPassword() async {
    if (_selectedStaff == null || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select staff and enter password')),
      );
      return;
    }

    try {
      // Generate new salt and hash
      final newSalt = const Uuid().v4();
      final bytes = utf8.encode(_passwordController.text + newSalt);
      final newHash = sha256.convert(bytes).toString();

      final updatedStaff = Staff(
        id: _selectedStaff!.id,
        name: _selectedStaff!.name,
        username: _selectedStaff!.username,
        passwordHash: newHash,
        salt: newSalt,
        role: _selectedStaff!.role,
        createdAt: _selectedStaff!.createdAt,
      );

      await DatabaseHelper.instance.updateStaff(updatedStaff);

      // Verify authentication
      final authResult = await DatabaseHelper.instance.authenticate(
        _selectedStaff!.username,
        _passwordController.text,
      );

      if (authResult != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ Password reset successful for ${_selectedStaff!.name}!\nYou can now login with the new password.'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
            ),
          );
          _passwordController.clear();
          setState(() => _selectedStaff = null);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✗ Password reset failed - authentication check failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Password Reset Tool'),
        backgroundColor: Colors.deepOrange,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '🔧 Emergency Password Reset',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Use this tool to reset staff passwords if login is not working',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  const Text('Select Staff:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<Staff>(
                    value: _selectedStaff,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    hint: const Text('Choose staff member'),
                    items: _staffList.map((staff) {
                      return DropdownMenuItem<Staff>(
                        value: staff,
                        child: Row(
                          children: [
                            Icon(
                              staff.role == 'doctor' ? Icons.medical_services : Icons.person,
                              color: staff.role == 'doctor' ? Colors.teal : Colors.purple,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(staff.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text('@${staff.username}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedStaff = value),
                  ),
                  const SizedBox(height: 24),
                  const Text('New Password:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      hintText: 'Enter new password',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[100],
                      prefixIcon: const Icon(Icons.lock),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _resetPassword,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset Password', style: TextStyle(fontSize: 18)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Quick Reset for Admin:', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text('1. Select "admin" from dropdown'),
                        Text('2. Enter new password (e.g., "admin123")'),
                        Text('3. Click "Reset Password"'),
                        Text('4. Use the new password to login'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'database_helper.dart';
import 'models.dart';
import 'glassmorphism.dart';

class StaffManagement extends StatefulWidget {
  const StaffManagement({super.key});

  @override
  State<StaffManagement> createState() => _StaffManagementState();
}

class _StaffManagementState extends State<StaffManagement> {
  List<Staff> _staffList = [];
  bool _isLoading = true;

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

  Future<void> _showAddEditDialog([Staff? staff]) async {
    final nameController = TextEditingController(text: staff?.name);
    final usernameController = TextEditingController(text: staff?.username);
    final passwordController = TextEditingController();
    String role = staff?.role ?? 'staff';
    final formKey = GlobalKey<FormState>();
    bool obscurePassword = true;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(staff == null ? 'Add Staff' : 'Edit Staff'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: usernameController,
                    decoration: const InputDecoration(labelText: 'Username'),
                    validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: role,
                    decoration: const InputDecoration(labelText: 'Role'),
                    items: const [
                      DropdownMenuItem(value: 'staff', child: Text('Staff')),
                      DropdownMenuItem(value: 'doctor', child: Text('Doctor')),
                    ],
                    onChanged: (value) => setState(() => role = value!),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      labelText: staff == null ? 'Password' : 'New Password (Optional)',
                      suffixIcon: IconButton(
                        icon: Icon(obscurePassword ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => obscurePassword = !obscurePassword),
                      ),
                    ),
                    obscureText: obscurePassword,
                    validator: (value) {
                      if (staff == null && (value?.isEmpty ?? true)) {
                        return 'Password is required for new staff';
                      }
                      if (value != null && value.isNotEmpty && value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  try {
                    String passwordHash = staff?.passwordHash ?? '';
                    String salt = staff?.salt ?? const Uuid().v4();

                    if (passwordController.text.isNotEmpty) {
                      // Generate new salt and hash whenever password is changed
                      salt = const Uuid().v4(); // Always generate new salt when password changes
                      final bytes = utf8.encode(passwordController.text + salt);
                      passwordHash = sha256.convert(bytes).toString();
                    }

                    final newStaff = Staff(
                      id: staff?.id ?? const Uuid().v4(),
                      name: nameController.text,
                      username: usernameController.text,
                      passwordHash: passwordHash,
                      salt: salt,
                      role: role,
                      createdAt: staff?.createdAt,
                    );

                    if (staff == null) {
                      // Check if username exists
                      final existing = await DatabaseHelper.instance.getStaffByUsername(newStaff.username);
                      if (existing != null) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Username already exists')),
                          );
                        }
                        return;
                      }
                      await DatabaseHelper.instance.insertStaff(newStaff);
                    } else {
                      await DatabaseHelper.instance.updateStaff(newStaff);
                    }

                    if (mounted) Navigator.pop(context);
                    _loadStaff();
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteStaff(Staff staff) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Staff'),
        content: Text('Are you sure you want to delete ${staff.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.deleteStaff(staff.id);
      _loadStaff();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Management'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _staffList.length,
              itemBuilder: (context, index) {
                final staff = _staffList[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: staff.role == 'doctor' ? Colors.teal.withAlpha(51) : Colors.purple.withAlpha(51),
                      child: Icon(
                        staff.role == 'doctor' ? Icons.medical_services : Icons.person,
                        color: staff.role == 'doctor' ? Colors.teal : Colors.purple,
                      ),
                    ),
                    title: Text(staff.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('@${staff.username} • ${staff.role.toUpperCase()}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showAddEditDialog(staff),
                        ),
                        if (staff.username != 'admin') // Prevent deleting default admin
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteStaff(staff),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
      ),
    );
  }
}

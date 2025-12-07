import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'database_helper.dart';
import 'models.dart';

class StaffManagement extends StatefulWidget {
  final Staff? loggedInDoctor;
  
  const StaffManagement({super.key, this.loggedInDoctor});

  @override
  State<StaffManagement> createState() => _StaffManagementState();
}

class _StaffManagementState extends State<StaffManagement> {
  List<Staff> _staffList = [];
  bool _isLoading = true;
  
  Staff? get loggedInDoctor => widget.loggedInDoctor;
  String get doctorId => loggedInDoctor?.id ?? '';
  String get clinicName => loggedInDoctor?.clinicName ?? 'Clinic';

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    setState(() => _isLoading = true);
    
    List<Staff> staff;
    if (doctorId.isNotEmpty) {
      // Load only this doctor's staff
      staff = await DatabaseHelper.instance.getStaffByDoctorId(doctorId);
    } else {
      // Fallback: load all staff (for admin or legacy)
      staff = await DatabaseHelper.instance.getAllStaff();
    }
    
    setState(() {
      _staffList = staff;
      _isLoading = false;
    });
  }

  Future<void> _showAddEditDialog([Staff? staff]) async {
    final nameController = TextEditingController(text: staff?.name);
    final usernameController = TextEditingController(text: staff?.username);
    final emailController = TextEditingController(text: staff?.email);
    final mobileController = TextEditingController(text: staff?.mobile);
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscurePassword = true;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(
                staff == null ? Icons.person_add : Icons.edit,
                color: Colors.teal,
              ),
              const SizedBox(width: 10),
              Text(staff == null ? 'Add Staff Member' : 'Edit Staff'),
            ],
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Clinic info banner
                  if (loggedInDoctor != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.teal.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.local_hospital, color: Colors.teal.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Staff for: $clinicName',
                              style: TextStyle(
                                color: Colors.teal.shade900,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Staff Name',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value?.isEmpty ?? true ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(Icons.account_circle),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value?.isEmpty ?? true ? 'Username is required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email (Optional)',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: mobileController,
                    decoration: const InputDecoration(
                      labelText: 'Mobile (Optional)',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      labelText: staff == null ? 'Password' : 'New Password (Optional)',
                      prefixIcon: const Icon(Icons.lock),
                      border: const OutlineInputBorder(),
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
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Save'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  try {
                    String passwordHash = staff?.passwordHash ?? '';
                    String salt = staff?.salt ?? const Uuid().v4();

                    if (passwordController.text.isNotEmpty) {
                      salt = const Uuid().v4();
                      final bytes = utf8.encode(passwordController.text + salt);
                      passwordHash = sha256.convert(bytes).toString();
                    }

                    final newStaff = Staff(
                      id: staff?.id ?? const Uuid().v4(),
                      name: nameController.text,
                      username: usernameController.text,
                      passwordHash: passwordHash,
                      salt: salt,
                      role: 'staff', // Always staff when created by doctor
                      createdAt: staff?.createdAt,
                      email: emailController.text.isNotEmpty ? emailController.text : null,
                      mobile: mobileController.text.isNotEmpty ? mobileController.text : null,
                      doctorId: doctorId, // Link to parent doctor
                      clinicName: clinicName, // Inherit clinic name
                    );

                    if (staff == null) {
                      // Check if username exists
                      final existing = await DatabaseHelper.instance.getStaffByUsername(newStaff.username);
                      if (existing != null) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Username already exists! Please choose another.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                        return;
                      }
                      await DatabaseHelper.instance.insertStaff(newStaff);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${newStaff.name} added successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } else {
                      await DatabaseHelper.instance.updateStaff(newStaff);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${newStaff.name} updated successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }

                    if (mounted) Navigator.pop(context);
                    _loadStaff();
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                      );
                    }
                  }
                }
              },
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 10),
            Text('Delete Staff'),
          ],
        ),
        content: Text('Are you sure you want to delete ${staff.name}?\n\nThis action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), 
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true), 
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.deleteStaff(staff.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${staff.name} deleted'),
            backgroundColor: Colors.red,
          ),
        );
      }
      _loadStaff();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Staff Management'),
            if (loggedInDoctor != null)
              Text(
                clinicName,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              ),
          ],
        ),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.teal.shade50,
              Colors.white,
            ],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _staffList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 80, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'No staff members yet',
                          style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tap + to add your first staff member',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _staffList.length,
                    itemBuilder: (context, index) {
                      final staff = _staffList[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 3,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.teal.shade100,
                            child: Text(
                              staff.name.isNotEmpty ? staff.name[0].toUpperCase() : 'S',
                              style: TextStyle(
                                color: Colors.teal.shade700,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            staff.name, 
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('@${staff.username}'),
                              if (staff.email != null)
                                Text(staff.email!, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                              if (staff.mobile != null)
                                Text(staff.mobile!, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _showAddEditDialog(staff),
                              ),
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Staff'),
      ),
    );
  }
}

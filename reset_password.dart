import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'lib/database_helper.dart';
import 'lib/models.dart';

void main() async {
  // Initialize database
  await DatabaseHelper.instance.database;
  
  print('=== Password Reset Tool ===');
  print('Fetching all staff...\n');
  
  final allStaff = await DatabaseHelper.instance.getAllStaff();
  
  for (var staff in allStaff) {
    print('Staff: ${staff.name} (@${staff.username})');
    print('  Role: ${staff.role}');
    print('  Current Salt: ${staff.salt}');
    print('  Current Hash: ${staff.passwordHash}');
    print('');
  }
  
  // Reset admin password to "admin123"
  print('\n=== Resetting admin password to "admin123" ===');
  
  final adminStaff = allStaff.firstWhere(
    (s) => s.username == 'admin',
    orElse: () => throw Exception('Admin user not found!'),
  );
  
  // Generate new salt and hash
  final newSalt = const Uuid().v4();
  final newPassword = 'admin123';
  final bytes = utf8.encode(newPassword + newSalt);
  final newHash = sha256.convert(bytes).toString();
  
  final updatedAdmin = Staff(
    id: adminStaff.id,
    name: adminStaff.name,
    username: adminStaff.username,
    passwordHash: newHash,
    salt: newSalt,
    role: adminStaff.role,
    createdAt: adminStaff.createdAt,
  );
  
  await DatabaseHelper.instance.updateStaff(updatedAdmin);
  
  print('✓ Admin password reset successfully!');
  print('  Username: admin');
  print('  Password: admin123');
  print('  New Salt: $newSalt');
  print('  New Hash: $newHash');
  
  // Verify the update
  print('\n=== Verifying authentication ===');
  final authResult = await DatabaseHelper.instance.authenticate('admin', 'admin123');
  
  if (authResult != null) {
    print('✓ Authentication successful!');
    print('  Logged in as: ${authResult.name} (@${authResult.username})');
  } else {
    print('✗ Authentication failed!');
  }
  
  print('\n=== Done ===');
}

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'firebase_config.dart';

/// License types
enum LicenseType {
  demo,    // 7 days free
  trial,   // 30 days
  lifetime // Forever
}

/// License status
enum LicenseStatus {
  active,
  expired,
  invalid,
  notFound
}

/// License information model
class LicenseInfo {
  final LicenseType type;
  final DateTime activationDate;
  final DateTime? expiryDate;
  final String? key;
  final int daysRemaining;
  final bool isActive;
  final String? customerName;

  LicenseInfo({
    required this.type,
    required this.activationDate,
    this.expiryDate,
    this.key,
    required this.daysRemaining,
    required this.isActive,
    this.customerName,
  });
}

/// Online License Service - Uses Firebase for 24/7 license verification
class OnlineLicenseService {
  static FirebaseFirestore? _firestore;
  static bool _isInitialized = false;
  
  // Local storage keys
  static const String _licenseTypeKey = 'license_type';
  static const String _activationDateKey = 'license_activation_date';
  static const String _expiryDateKey = 'license_expiry_date';
  static const String _licenseKeyKey = 'license_key';
  static const String _isActivatedKey = 'license_is_activated';
  static const String _deviceIdKey = 'device_unique_id';
  
  // Durations
  static const int demoDays = 7;
  static const int trialDays = 30;
  
  // Valid characters for key generation
  static const String _validChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static const String _secretSalt = 'KSMODI2024ONLINE';

  /// Initialize Firebase
  static Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    if (!FirebaseConfig.isConfigured) {
      print('⚠️ Firebase not configured - using offline mode');
      return false;
    }
    
    try {
      await Firebase.initializeApp(
        options: FirebaseConfig.currentPlatform,
      );
      _firestore = FirebaseFirestore.instance;
      _isInitialized = true;
      print('✅ Firebase initialized for online license verification');
      return true;
    } catch (e) {
      print('❌ Firebase init error: $e');
      return false;
    }
  }

  /// Check if online mode is available
  static bool get isOnlineMode => _isInitialized && _firestore != null;

  /// Get unique device ID
  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString(_deviceIdKey);
    
    if (deviceId == null) {
      final random = Random.secure();
      final values = List<int>.generate(16, (i) => random.nextInt(256));
      deviceId = base64Url.encode(values).substring(0, 16);
      await prefs.setString(_deviceIdKey, deviceId);
    }
    
    return deviceId;
  }

  /// Generate checksum for security
  static String _calculateChecksum(String part1, String part2, String part3, String typeChar) {
    final data = '$_secretSalt$part1$part2$part3$typeChar$_secretSalt';
    final bytes = utf8.encode(data);
    final hash = md5.convert(bytes).toString().toUpperCase();
    
    final middleCheck = _validChars[int.parse(hash.substring(5, 7), radix: 16) % _validChars.length];
    final endCheck1 = _validChars[int.parse(hash.substring(10, 12), radix: 16) % _validChars.length];
    final endCheck2 = _validChars[int.parse(hash.substring(15, 17), radix: 16) % _validChars.length];
    
    return '$middleCheck$endCheck1$endCheck2';
  }

  static String _generateRandomString(int length) {
    final random = Random.secure();
    return List.generate(length, (index) => _validChars[random.nextInt(_validChars.length)]).join();
  }

  /// Generate a license key and save to Firebase
  static Future<String?> generateKey(LicenseType type, {String? customerName}) async {
    if (!isOnlineMode) {
      print('❌ Firebase not initialized');
      return null;
    }
    
    // Generate random parts
    String part1 = _generateRandomString(4);
    String part2Base = _generateRandomString(3);
    String part3 = _generateRandomString(4);
    
    // Type suffix
    String typeSuffix;
    switch (type) {
      case LicenseType.demo:
        typeSuffix = 'D';
        break;
      case LicenseType.trial:
        typeSuffix = 'T';
        break;
      case LicenseType.lifetime:
        typeSuffix = 'L';
        break;
    }
    
    // Calculate checksum
    final checksum = _calculateChecksum(part1, part2Base, part3, typeSuffix);
    final middleCheck = checksum[0];
    final endCheck = checksum.substring(1);
    
    // Insert middle checksum
    final part2 = '${part2Base[0]}$middleCheck${part2Base.substring(1)}';
    
    // Final key
    final key = 'MODI-$part1-$part2-$part3-$typeSuffix-$endCheck';
    
    // Calculate expiry
    DateTime? expiry;
    switch (type) {
      case LicenseType.demo:
        expiry = DateTime.now().add(Duration(days: demoDays));
        break;
      case LicenseType.trial:
        expiry = DateTime.now().add(Duration(days: trialDays));
        break;
      case LicenseType.lifetime:
        expiry = null;
        break;
    }
    
    // Save to Firebase
    try {
      await _firestore!.collection('licenses').doc(key).set({
        'key': key,
        'type': typeSuffix,
        'typeName': type.toString().split('.').last,
        'status': 'unused',
        'createdAt': FieldValue.serverTimestamp(),
        'expiryDate': expiry?.toIso8601String(),
        'customerName': customerName ?? '',
        'activatedBy': null,
        'activatedAt': null,
      });
      
      print('✅ Key saved to Firebase: $key');
      return key;
    } catch (e) {
      print('❌ Firebase save error: $e');
      return null;
    }
  }

  /// Validate a key format and checksum
  static bool _validateKeyFormat(String key) {
    key = key.toUpperCase().trim();
    
    final pattern = RegExp(r'^MODI-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[DTL]-[A-Z0-9]{2}$');
    if (!pattern.hasMatch(key)) return false;
    
    // Validate checksum
    final parts = key.split('-');
    if (parts.length != 6) return false;
    
    final part1 = parts[1];
    final part2Full = parts[2];
    final part3 = parts[3];
    final typeChar = parts[4];
    final endCheckProvided = parts[5];
    
    final part2Base = '${part2Full[0]}${part2Full.substring(2)}';
    final expectedChecksum = _calculateChecksum(part1, part2Base, part3, typeChar);
    
    return part2Full[1] == expectedChecksum[0] && endCheckProvided == expectedChecksum.substring(1);
  }

  /// Activate license with online verification
  static Future<Map<String, dynamic>> activateLicense(
    String key, {
    String? customerName,
    String? customerPhone,
  }) async {
    key = key.toUpperCase().trim();
    
    // Validate format first
    if (!_validateKeyFormat(key)) {
      return {'success': false, 'error': 'Invalid license key format'};
    }
    
    // If online mode, verify with Firebase
    if (isOnlineMode) {
      try {
        final doc = await _firestore!.collection('licenses').doc(key).get();
        
        if (!doc.exists) {
          return {'success': false, 'error': 'License key not found'};
        }
        
        final data = doc.data()!;
        
        if (data['status'] == 'used') {
          return {'success': false, 'error': 'This license key has already been used'};
        }
        
        if (data['status'] == 'revoked') {
          return {'success': false, 'error': 'This license key has been revoked'};
        }
        
        // Get device ID
        final deviceId = await getDeviceId();
        
        // Update Firebase with customer info
        await _firestore!.collection('licenses').doc(key).update({
          'status': 'used',
          'activatedAt': FieldValue.serverTimestamp(),
          'activatedBy': deviceId,
          'customerName': customerName ?? data['customerName'] ?? '',
          'customerPhone': customerPhone ?? data['customerPhone'] ?? '',
        });
        
        // Parse type
        final typeChar = data['type'] as String;
        LicenseType type;
        DateTime? expiry;
        
        switch (typeChar) {
          case 'D':
            type = LicenseType.demo;
            expiry = DateTime.now().add(Duration(days: demoDays));
            break;
          case 'T':
            type = LicenseType.trial;
            expiry = DateTime.now().add(Duration(days: trialDays));
            break;
          case 'L':
          default:
            type = LicenseType.lifetime;
            expiry = null;
        }
        
        // Save locally
        await _saveLocalLicense(type, key, expiry);
        
        return {
          'success': true,
          'type': type.toString().split('.').last,
          'expiry': expiry?.toIso8601String(),
          'online': true,
        };
        
      } catch (e) {
        print('❌ Firebase verification error: $e');
        return {'success': false, 'error': 'Network error. Please try again.'};
      }
    } else {
      // Offline fallback - just validate format
      final parts = key.split('-');
      final typeChar = parts[4];
      
      LicenseType type;
      DateTime? expiry;
      
      switch (typeChar) {
        case 'D':
          type = LicenseType.demo;
          expiry = DateTime.now().add(Duration(days: demoDays));
          break;
        case 'T':
          type = LicenseType.trial;
          expiry = DateTime.now().add(Duration(days: trialDays));
          break;
        case 'L':
        default:
          type = LicenseType.lifetime;
          expiry = null;
      }
      
      await _saveLocalLicense(type, key, expiry);
      
      return {
        'success': true,
        'type': type.toString().split('.').last,
        'expiry': expiry?.toIso8601String(),
        'online': false,
      };
    }
  }

  /// Save license locally
  static Future<void> _saveLocalLicense(LicenseType type, String key, DateTime? expiry) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    
    await prefs.setString(_licenseTypeKey, type.toString().split('.').last);
    await prefs.setString(_activationDateKey, now.toIso8601String());
    if (expiry != null) {
      await prefs.setString(_expiryDateKey, expiry.toIso8601String());
    } else {
      await prefs.remove(_expiryDateKey);
    }
    await prefs.setString(_licenseKeyKey, key);
    await prefs.setBool(_isActivatedKey, true);
  }

  /// Initialize demo on first run
  static Future<bool> initializeDemoIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    
    if (prefs.containsKey(_isActivatedKey)) {
      return false;
    }
    
    final now = DateTime.now();
    final expiry = now.add(Duration(days: demoDays));
    
    await prefs.setString(_licenseTypeKey, 'demo');
    await prefs.setString(_activationDateKey, now.toIso8601String());
    await prefs.setString(_expiryDateKey, expiry.toIso8601String());
    await prefs.setBool(_isActivatedKey, true);
    
    print('📦 Demo license activated: expires $expiry');
    return true;
  }

  /// Get current license info
  static Future<LicenseInfo?> getLicenseInfo() async {
    final prefs = await SharedPreferences.getInstance();
    
    if (!prefs.containsKey(_licenseTypeKey)) {
      return null;
    }
    
    final typeStr = prefs.getString(_licenseTypeKey) ?? 'demo';
    final activationStr = prefs.getString(_activationDateKey);
    final expiryStr = prefs.getString(_expiryDateKey);
    final key = prefs.getString(_licenseKeyKey);
    
    LicenseType type;
    switch (typeStr) {
      case 'demo':
        type = LicenseType.demo;
        break;
      case 'trial':
        type = LicenseType.trial;
        break;
      case 'lifetime':
        type = LicenseType.lifetime;
        break;
      default:
        type = LicenseType.demo;
    }
    
    final activationDate = activationStr != null 
        ? DateTime.parse(activationStr) 
        : DateTime.now();
    
    final expiryDate = expiryStr != null ? DateTime.parse(expiryStr) : null;
    
    int daysRemaining = 0;
    bool isActive = true;
    
    if (type == LicenseType.lifetime) {
      daysRemaining = 999999;
      isActive = true;
    } else if (expiryDate != null) {
      final now = DateTime.now();
      daysRemaining = expiryDate.difference(now).inDays;
      if (daysRemaining < 0) daysRemaining = 0;
      isActive = now.isBefore(expiryDate);
    }
    
    return LicenseInfo(
      type: type,
      activationDate: activationDate,
      expiryDate: expiryDate,
      key: key,
      daysRemaining: daysRemaining,
      isActive: isActive,
    );
  }

  /// Get current license info as simple Map (for UI display)
  static Future<Map<String, dynamic>?> getCurrentLicenseInfo() async {
    final info = await getLicenseInfo();
    if (info == null) return null;
    
    String typeStr = '';
    switch (info.type) {
      case LicenseType.demo:
        typeStr = 'DEMO';
        break;
      case LicenseType.trial:
        typeStr = 'TRIAL';
        break;
      case LicenseType.lifetime:
        typeStr = 'LIFETIME';
        break;
    }
    
    return {
      'type': typeStr,
      'daysRemaining': info.daysRemaining,
      'isActive': info.isActive,
      'expiryDate': info.expiryDate?.toString(),
    };
  }

  /// Check license status
  static Future<LicenseStatus> checkLicenseStatus() async {
    final info = await getLicenseInfo();
    
    if (info == null) {
      return LicenseStatus.notFound;
    }
    
    if (info.isActive) {
      return LicenseStatus.active;
    } else {
      return LicenseStatus.expired;
    }
  }

  /// Get all licenses from Firebase (admin only)
  static Future<List<Map<String, dynamic>>> getAllLicenses() async {
    if (!isOnlineMode) return [];
    
    try {
      final snapshot = await _firestore!
          .collection('licenses')
          .orderBy('createdAt', descending: true)
          .limit(100)
          .get();
      
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('❌ Error fetching licenses: $e');
      return [];
    }
  }

  /// Revoke a license (admin only)
  static Future<bool> revokeLicense(String key) async {
    if (!isOnlineMode) return false;
    
    try {
      await _firestore!.collection('licenses').doc(key).update({
        'status': 'revoked',
        'revokedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('❌ Error revoking license: $e');
      return false;
    }
  }

  /// Reset local license (for testing)
  static Future<void> resetLicense() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_licenseTypeKey);
    await prefs.remove(_activationDateKey);
    await prefs.remove(_expiryDateKey);
    await prefs.remove(_licenseKeyKey);
    await prefs.remove(_isActivatedKey);
    print('🔄 License reset');
  }
}

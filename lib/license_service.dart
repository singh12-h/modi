import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

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

  LicenseInfo({
    required this.type,
    required this.activationDate,
    this.expiryDate,
    this.key,
    required this.daysRemaining,
    required this.isActive,
  });
}

/// License Service - Handles all license operations
class LicenseService {
  static const String _keyPrefix = 'MODI';
  static const String _licenseTypeKey = 'license_type';
  static const String _activationDateKey = 'license_activation_date';
  static const String _expiryDateKey = 'license_expiry_date';
  static const String _licenseKeyKey = 'license_key';
  static const String _isActivatedKey = 'license_is_activated';
  static const String _usedKeysKey = 'license_used_keys';
  static const String _deviceIdKey = 'device_unique_id';
  
  // Demo duration: 7 days
  static const int demoDays = 7;
  // Trial duration: 30 days
  static const int trialDays = 30;
  
  // Secret key for checksum (only we know this)
  static const String _secretSalt = 'KS2024MODI';
  
  // Master password for key generation (only you know this)
  static const String masterPassword = 'KRIPASHANKAR_ADMIN_2024';

  // Valid characters for key generation (removed confusing chars like 0,O,1,I)
  static const String _validChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  /// Generate a unique device ID
  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString(_deviceIdKey);
    
    if (deviceId == null) {
      // Generate unique device ID
      final random = Random.secure();
      final values = List<int>.generate(16, (i) => random.nextInt(256));
      deviceId = base64Url.encode(values).substring(0, 12);
      await prefs.setString(_deviceIdKey, deviceId);
    }
    
    return deviceId;
  }

  /// Calculate checksum for a key (returns 3 chars: 1 middle + 2 end)
  static String _calculateChecksum(String part1, String part2, String part3, String typeChar) {
    // Combine all parts with secret salt
    final data = '$_secretSalt$part1$part2$part3$typeChar$_secretSalt';
    
    // Create MD5 hash
    final bytes = utf8.encode(data);
    final hash = md5.convert(bytes).toString().toUpperCase();
    
    // Extract 3 checksum characters from hash
    // Middle checksum (1 char) - from position 5
    final middleCheck = _validChars[int.parse(hash.substring(5, 7), radix: 16) % _validChars.length];
    // End checksum (2 chars) - from positions 10 and 15
    final endCheck1 = _validChars[int.parse(hash.substring(10, 12), radix: 16) % _validChars.length];
    final endCheck2 = _validChars[int.parse(hash.substring(15, 17), radix: 16) % _validChars.length];
    
    return '$middleCheck$endCheck1$endCheck2';
  }

  /// Generate a license key with checksum
  /// Format: MODI-XXXX-[C]XXX-XXXX-TYPE-CC
  /// Where [C] is middle checksum, CC is end checksum
  static String generateKey(LicenseType type, {String? deviceId}) {
    // Generate random parts (3 chars each, checksum added)
    String part1 = _generateRandomString(4);
    String part2Base = _generateRandomString(3); // 3 chars, 1 checksum will be added
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
    
    // Insert middle checksum into part2 (position 1)
    final part2 = '${part2Base[0]}$middleCheck${part2Base.substring(1)}';
    
    // Final key format: MODI-XXXX-X[C]XX-XXXX-T-CC
    return '$_keyPrefix-$part1-$part2-$part3-$typeSuffix-$endCheck';
  }

  static String _generateRandomString(int length) {
    final random = Random.secure();
    return List.generate(length, (index) => _validChars[random.nextInt(_validChars.length)]).join();
  }

  /// Validate checksum of a key
  static bool _validateChecksum(String key) {
    // Key format: MODI-XXXX-XXXX-XXXX-T-CC
    final parts = key.split('-');
    if (parts.length != 6) return false;
    
    final part1 = parts[1]; // XXXX
    final part2Full = parts[2]; // X[C]XX (with middle checksum)
    final part3 = parts[3]; // XXXX
    final typeChar = parts[4]; // D/T/L
    final endCheckProvided = parts[5]; // CC
    
    if (part1.length != 4 || part2Full.length != 4 || part3.length != 4) return false;
    if (endCheckProvided.length != 2) return false;
    
    // Extract part2 without middle checksum (remove char at position 1)
    final part2Base = '${part2Full[0]}${part2Full.substring(2)}'; // Remove middle check
    
    // Recalculate checksum
    final expectedChecksum = _calculateChecksum(part1, part2Base, part3, typeChar);
    final expectedMiddle = expectedChecksum[0];
    final expectedEnd = expectedChecksum.substring(1);
    
    // Verify middle checksum (position 1 in part2)
    if (part2Full[1] != expectedMiddle) {
      print('❌ Middle checksum mismatch: ${part2Full[1]} != $expectedMiddle');
      return false;
    }
    
    // Verify end checksum
    if (endCheckProvided != expectedEnd) {
      print('❌ End checksum mismatch: $endCheckProvided != $expectedEnd');
      return false;
    }
    
    return true;
  }

  /// Validate and parse a license key
  static LicenseType? parseKey(String key) {
    key = key.toUpperCase().trim();
    
    // Check format: MODI-XXXX-XXXX-XXXX-X-XX
    final pattern = RegExp(r'^MODI-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[DTL]-[A-Z0-9]{2}$');
    if (!pattern.hasMatch(key)) {
      print('❌ Invalid key format');
      return null;
    }
    
    // Validate checksum
    if (!_validateChecksum(key)) {
      print('❌ Invalid checksum');
      return null;
    }
    
    // Get type from key
    final parts = key.split('-');
    final typeChar = parts[4];
    
    switch (typeChar) {
      case 'D':
        return LicenseType.demo;
      case 'T':
        return LicenseType.trial;
      case 'L':
        return LicenseType.lifetime;
      default:
        return null;
    }
  }

  /// Check if a key has already been used
  static Future<bool> isKeyUsed(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final usedKeys = prefs.getStringList(_usedKeysKey) ?? [];
    return usedKeys.contains(key.toUpperCase());
  }

  /// Mark a key as used
  static Future<void> markKeyAsUsed(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final usedKeys = prefs.getStringList(_usedKeysKey) ?? [];
    usedKeys.add(key.toUpperCase());
    await prefs.setStringList(_usedKeysKey, usedKeys);
  }

  /// Initialize demo license on first run
  static Future<bool> initializeDemoIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if already initialized
    if (prefs.containsKey(_isActivatedKey)) {
      return false;
    }
    
    // First run - activate demo
    final now = DateTime.now();
    final expiry = now.add(Duration(days: demoDays));
    
    await prefs.setString(_licenseTypeKey, 'demo');
    await prefs.setString(_activationDateKey, now.toIso8601String());
    await prefs.setString(_expiryDateKey, expiry.toIso8601String());
    await prefs.setBool(_isActivatedKey, true);
    
    print('📦 Demo license activated: expires ${expiry.toString()}');
    return true;
  }

  /// Activate a license with a key
  static Future<Map<String, dynamic>> activateLicense(String key) async {
    key = key.toUpperCase().trim();
    
    // Parse key (includes checksum validation)
    final type = parseKey(key);
    if (type == null) {
      return {'success': false, 'error': 'Invalid license key. Please check and try again.'};
    }
    
    // Check if already used
    if (await isKeyUsed(key)) {
      return {'success': false, 'error': 'This license key has already been used'};
    }
    
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    
    // Calculate expiry
    DateTime? expiry;
    switch (type) {
      case LicenseType.demo:
        expiry = now.add(Duration(days: demoDays));
        break;
      case LicenseType.trial:
        expiry = now.add(Duration(days: trialDays));
        break;
      case LicenseType.lifetime:
        expiry = null; // Never expires
        break;
    }
    
    // Save license info
    await prefs.setString(_licenseTypeKey, type.toString().split('.').last);
    await prefs.setString(_activationDateKey, now.toIso8601String());
    if (expiry != null) {
      await prefs.setString(_expiryDateKey, expiry.toIso8601String());
    } else {
      await prefs.remove(_expiryDateKey);
    }
    await prefs.setString(_licenseKeyKey, key);
    await prefs.setBool(_isActivatedKey, true);
    
    // Mark key as used
    await markKeyAsUsed(key);
    
    print('✅ License activated: $type');
    
    return {
      'success': true,
      'type': type.toString().split('.').last,
      'expiry': expiry?.toIso8601String(),
    };
  }

  /// Get current license information
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
    
    // Calculate days remaining
    int daysRemaining = 0;
    bool isActive = true;
    
    if (type == LicenseType.lifetime) {
      daysRemaining = 999999; // Infinite
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

  /// Check if license is active
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

  /// Check if current license is lifetime
  static Future<bool> isLifetime() async {
    final info = await getLicenseInfo();
    return info?.type == LicenseType.lifetime;
  }

  /// Get display string for license status
  static Future<String> getLicenseDisplayString() async {
    final info = await getLicenseInfo();
    
    if (info == null) {
      return 'No License';
    }
    
    switch (info.type) {
      case LicenseType.lifetime:
        return '✅ Lifetime License';
      case LicenseType.trial:
        if (info.isActive) {
          return '⏳ Trial: ${info.daysRemaining} days left';
        } else {
          return '❌ Trial Expired';
        }
      case LicenseType.demo:
        if (info.isActive) {
          return '🆓 Demo: ${info.daysRemaining} days left';
        } else {
          return '❌ Demo Expired';
        }
    }
  }

  /// Verify master password for admin functions
  static bool verifyMasterPassword(String password) {
    return password == masterPassword;
  }

  /// Reset license (for testing only)
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

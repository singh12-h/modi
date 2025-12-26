import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import 'models.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  // In-memory storage for Web (Static to persist across navigation in same session)
  static final List<Patient> _webPatients = [];
  static final List<MedicalHistory> _webMedicalHistory = [];
  static final List<Prescription> _webPrescriptions = [];
  static final List<Consultation> _webConsultations = [];

  static final List<Appointment> _webAppointments = [];
  static final List<Staff> _webStaff = [];

  DatabaseHelper._init() {
    if (kIsWeb) {
      // Load persisted data for Web
      _loadWebData();
    } else if (defaultTargetPlatform == TargetPlatform.windows || 
               defaultTargetPlatform == TargetPlatform.linux || 
               defaultTargetPlatform == TargetPlatform.macOS) {
      // Initialize sqflite for desktop only
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    // On Android/iOS, standard sqflite is used automatically
  }

  // Web Persistence
  Future<void> _loadWebData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load Patients
      final patientsJson = prefs.getString('web_patients');
      if (patientsJson != null) {
        final List<dynamic> decoded = jsonDecode(patientsJson);
        _webPatients.clear();
        _webPatients.addAll(decoded.map((e) => Patient.fromMap(e)).toList());
        print('💾 [WEB] Loaded ${_webPatients.length} patients from storage');
      }

      // Load Appointments
      final appointmentsJson = prefs.getString('web_appointments');
      if (appointmentsJson != null) {
        final List<dynamic> decoded = jsonDecode(appointmentsJson);
        _webAppointments.clear();
        _webAppointments.addAll(decoded.map((e) => Appointment.fromMap(e)).toList());

      }

      // Load Staff
      final staffJson = prefs.getString('web_staff');
      if (staffJson != null) {
        final List<dynamic> decoded = jsonDecode(staffJson);
        _webStaff.clear();
        _webStaff.addAll(decoded.map((e) => Staff.fromMap(e)).toList());
      }
      
      // Seed default admin if no staff exists
      if (_webStaff.isEmpty) {
        await seedDefaultAdmin();
      }
      
      // Load others as needed...
    } catch (e) {
      print('🔴 Error loading web data: $e');
    }
  }

  Future<void> _saveWebData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save Patients
      final patientsJson = jsonEncode(_webPatients.map((p) => p.toMap()).toList());
      await prefs.setString('web_patients', patientsJson);
      
      // Save Appointments
      final appointmentsJson = jsonEncode(_webAppointments.map((a) => a.toMap()).toList());
      await prefs.setString('web_appointments', appointmentsJson);

      // Save Staff
      final staffJson = jsonEncode(_webStaff.map((s) => s.toMap()).toList());
      await prefs.setString('web_staff', staffJson);
      
      // Calculate and print storage size
      final totalBytes = patientsJson.length + appointmentsJson.length + staffJson.length;
      final totalKB = (totalBytes / 1024).toStringAsFixed(2);
      final avgPerPatient = _webPatients.isNotEmpty ? (patientsJson.length / _webPatients.length / 1024).toStringAsFixed(2) : '0';
      
      print('💾 [WEB] Data saved to storage');
      print('📊 Storage: ${totalKB} KB total | ${_webPatients.length} patients | ~${avgPerPatient} KB/patient');
    } catch (e) {
      print('🔴 Error saving web data: $e');
    }
  }

  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError('SQL database not supported on web fallback');
    }
    if (_database != null) return _database!;
    print('Initializing database...'); // Debug
    _database = await _initDB('patients.db');
    print('Database initialized'); // Debug
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    print('Database path: $dbPath'); // Debug
    final path = join(dbPath, filePath);
    print('Opening database at $path'); // Debug
    return await openDatabase(
      path,
      version: 15,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        await _seedDefaultAdmin(db);
      },
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('Upgrading database from version $oldVersion to $newVersion...');
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE patients ADD COLUMN address TEXT');
      await db.execute('ALTER TABLE patients ADD COLUMN medicalHistory TEXT');
      await db.execute('ALTER TABLE patients ADD COLUMN symptoms TEXT');
      await db.execute('ALTER TABLE patients ADD COLUMN emergencyContact TEXT');
    }
    if (oldVersion < 6) {
      await db.execute('ALTER TABLE patients ADD COLUMN is_appointment INTEGER DEFAULT 0');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE patients ADD COLUMN blood_group TEXT');
      await db.execute('ALTER TABLE patients ADD COLUMN allergies TEXT');
      await db.execute('ALTER TABLE patients ADD COLUMN registered_date TEXT');
      await db.execute('ALTER TABLE patients ADD COLUMN last_visit TEXT');
      await db.execute('ALTER TABLE patients ADD COLUMN consultation_count INTEGER DEFAULT 0');
      await db.execute('''
        UPDATE patients 
        SET registered_date = registrationTime 
        WHERE registered_date IS NULL
      ''');
      await db.execute('''
        CREATE TABLE medical_history (
          id TEXT PRIMARY KEY,
          patient_id TEXT NOT NULL,
          previous_conditions TEXT,
          current_diagnosis TEXT,
          notes TEXT,
          allergies TEXT,
          blood_group TEXT,
          created_at TEXT NOT NULL,
          FOREIGN KEY (patient_id) REFERENCES patients (id)
        )
      ''');
      await db.execute('''
        CREATE TABLE prescriptions (
          id TEXT PRIMARY KEY,
          patient_id TEXT NOT NULL,
          medicine_name TEXT NOT NULL,
          dosage TEXT NOT NULL,
          frequency TEXT NOT NULL,
          created_at TEXT NOT NULL,
          is_current INTEGER DEFAULT 1,
          FOREIGN KEY (patient_id) REFERENCES patients (id)
        )
      ''');
      await db.execute('''
        CREATE TABLE consultations (
          id TEXT PRIMARY KEY,
          patient_id TEXT NOT NULL,
          date TEXT NOT NULL,
          reason TEXT,
          doctor_id TEXT NOT NULL,
          doctor_name TEXT,
          diagnosis TEXT,
          medications TEXT,
          notes TEXT,
          prescription TEXT,
          follow_up_date TEXT,
          checkup_details TEXT,
          FOREIGN KEY (patient_id) REFERENCES patients (id)
        )
      ''');
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE appointments (
          id TEXT PRIMARY KEY,
          patient_name TEXT NOT NULL,
          mobile TEXT NOT NULL,
          date TEXT NOT NULL,
          time TEXT NOT NULL,
          type TEXT NOT NULL,
          reason TEXT,
          status TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE appointments ADD COLUMN patient_id TEXT');
      await db.execute('ALTER TABLE appointments ADD COLUMN patient_image TEXT');
      await db.execute('ALTER TABLE appointments ADD COLUMN rejection_reason TEXT');
      await db.execute('ALTER TABLE appointments ADD COLUMN verified_at TEXT');
    }
    if (oldVersion < 7) {
      await db.execute('ALTER TABLE prescriptions ADD COLUMN manufacturer TEXT');
      await db.execute('ALTER TABLE prescriptions ADD COLUMN mr_name TEXT');
      await db.execute('ALTER TABLE prescriptions ADD COLUMN start_date TEXT');
      await db.execute('ALTER TABLE prescriptions ADD COLUMN generic_name TEXT');
      await db.execute('ALTER TABLE prescriptions ADD COLUMN composition TEXT');
      await db.execute('ALTER TABLE prescriptions ADD COLUMN form TEXT');
      await db.execute('ALTER TABLE prescriptions ADD COLUMN instructions TEXT');
      await db.execute('ALTER TABLE prescriptions ADD COLUMN duration INTEGER');
      await db.execute('ALTER TABLE prescriptions ADD COLUMN notes TEXT');
    }
    if (oldVersion < 8) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS payments (
          id TEXT PRIMARY KEY,
          patient_id TEXT NOT NULL,
          patient_name TEXT NOT NULL,
          token TEXT NOT NULL,
          amount REAL NOT NULL,
          status TEXT NOT NULL,
          date TEXT NOT NULL,
          payment_date TEXT,
          payment_method TEXT,
          notes TEXT,
          FOREIGN KEY (patient_id) REFERENCES patients (id)
        )
      ''');
    }
    if (oldVersion < 9) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS staff (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          username TEXT NOT NULL UNIQUE,
          password_hash TEXT NOT NULL,
          salt TEXT NOT NULL,
          role TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 10) {
      // Payment Installments Table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS payment_installments (
          id TEXT PRIMARY KEY,
          patient_id TEXT NOT NULL,
          patient_name TEXT NOT NULL,
          appointment_id TEXT,
          total_amount REAL NOT NULL,
          instrument_charges REAL DEFAULT 0,
          service_charges REAL DEFAULT 0,
          created_at TEXT NOT NULL,
          status TEXT NOT NULL DEFAULT 'PENDING',
          paid_amount REAL DEFAULT 0,
          remaining_amount REAL NOT NULL,
          FOREIGN KEY (patient_id) REFERENCES patients (id)
        )
      ''');
      // Payment Transactions Table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS payment_transactions (
          id TEXT PRIMARY KEY,
          payment_id TEXT NOT NULL,
          amount_paid REAL NOT NULL,
          payment_date TEXT NOT NULL,
          payment_mode TEXT NOT NULL,
          received_by TEXT NOT NULL,
          receipt_number TEXT NOT NULL,
          notes TEXT,
          FOREIGN KEY (payment_id) REFERENCES payment_installments (id)
        )
      ''');
    }
    if (oldVersion < 11) {
      // Add new columns for doctor profile
      try {
        await db.execute('ALTER TABLE staff ADD COLUMN email TEXT');
        await db.execute('ALTER TABLE staff ADD COLUMN mobile TEXT');
        await db.execute('ALTER TABLE staff ADD COLUMN clinic_name TEXT');
        await db.execute('ALTER TABLE staff ADD COLUMN clinic_address TEXT');
        await db.execute('ALTER TABLE staff ADD COLUMN specialty TEXT');
        await db.execute('ALTER TABLE staff ADD COLUMN registration_number TEXT');
      } catch (e) {
        print('Staff columns might already exist: $e');
      }
    }
    if (oldVersion < 12) {
      // Add doctor_id for multi-clinic support
      try {
        await db.execute('ALTER TABLE staff ADD COLUMN doctor_id TEXT');
      } catch (e) {
        print('doctor_id column might already exist: $e');
      }
    }
    if (oldVersion < 13) {
      // Add payment_for column to track what payment is for
      try {
        await db.execute('ALTER TABLE payment_installments ADD COLUMN payment_for TEXT');
        print('Added payment_for column to payment_installments');
      } catch (e) {
        print('payment_for column might already exist: $e');
      }
    }
    if (oldVersion < 14) {
      // Add birth_date column for birthday notifications and auto age calculation
      try {
        await db.execute('ALTER TABLE patients ADD COLUMN birth_date TEXT');
        print('Added birth_date column to patients');
      } catch (e) {
        print('birth_date column might already exist: $e');
      }
    }
    if (oldVersion < 15) {
      // Patient Feedback Table for storing patient reviews and ratings
      await db.execute('''
        CREATE TABLE IF NOT EXISTS patient_feedback (
          id TEXT PRIMARY KEY,
          patient_id TEXT,
          patient_name TEXT NOT NULL,
          overall_rating INTEGER NOT NULL,
          doctor_rating INTEGER NOT NULL,
          staff_rating INTEGER NOT NULL,
          cleanliness_rating INTEGER NOT NULL,
          waiting_time_rating INTEGER NOT NULL,
          comments TEXT,
          sentiment TEXT,
          created_at TEXT NOT NULL,
          FOREIGN KEY (patient_id) REFERENCES patients (id)
        )
      ''');
      print('Created patient_feedback table');
    }
  }

  Future _createDB(Database db, int version) async {
    print('Creating database tables...'); // Debug
    await db.execute('''
      CREATE TABLE patients (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        token TEXT NOT NULL,
        age TEXT NOT NULL,
        gender TEXT NOT NULL,
        mobile TEXT NOT NULL,
        status INTEGER NOT NULL,
        photoPath TEXT,
        address TEXT,
        medicalHistory TEXT,
        symptoms TEXT,
        emergencyContact TEXT,
        registrationTime TEXT NOT NULL,
        blood_group TEXT,
        allergies TEXT,
        registered_date TEXT NOT NULL,
        last_visit TEXT,
        consultation_count INTEGER DEFAULT 0,
        history TEXT,
        is_appointment INTEGER DEFAULT 0,
        birth_date TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE medical_history (
        id TEXT PRIMARY KEY,
        patient_id TEXT NOT NULL,
        previous_conditions TEXT,
        current_diagnosis TEXT,
        notes TEXT,
        allergies TEXT,
        blood_group TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (patient_id) REFERENCES patients (id)
      )
    ''');
    await db.execute('''
      CREATE TABLE prescriptions (
        id TEXT PRIMARY KEY,
        patient_id TEXT NOT NULL,
        medicine_name TEXT NOT NULL,
        dosage TEXT NOT NULL,
        frequency TEXT NOT NULL,
        created_at TEXT NOT NULL,
        is_current INTEGER DEFAULT 1,
        manufacturer TEXT,
        mr_name TEXT,
        start_date TEXT,
        generic_name TEXT,
        composition TEXT,
        form TEXT,
        instructions TEXT,
        duration INTEGER,
        notes TEXT,
        FOREIGN KEY (patient_id) REFERENCES patients (id)
      )
    ''');
    await db.execute('''
      CREATE TABLE consultations (
        id TEXT PRIMARY KEY,
        patient_id TEXT NOT NULL,
        date TEXT NOT NULL,
        reason TEXT,
        doctor_id TEXT NOT NULL,
        doctor_name TEXT,
        diagnosis TEXT,
        medications TEXT,
        notes TEXT,
        prescription TEXT,
        follow_up_date TEXT,
        checkup_details TEXT,
        FOREIGN KEY (patient_id) REFERENCES patients (id)
      )
    ''');
    await db.execute('''
      CREATE TABLE appointments (
        id TEXT PRIMARY KEY,
        patient_name TEXT NOT NULL,
        mobile TEXT NOT NULL,
        date TEXT NOT NULL,
        time TEXT NOT NULL,
        type TEXT NOT NULL,
        reason TEXT,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        patient_id TEXT,
        patient_image TEXT,
        rejection_reason TEXT,
        verified_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE payments (
        id TEXT PRIMARY KEY,
        patient_id TEXT NOT NULL,
        patient_name TEXT NOT NULL,
        token TEXT NOT NULL,
        amount REAL NOT NULL,
        status TEXT NOT NULL,
        date TEXT NOT NULL,
        payment_date TEXT,
        payment_method TEXT,
        notes TEXT,
        FOREIGN KEY (patient_id) REFERENCES patients (id)
      )
    ''');
    await db.execute('''
      CREATE TABLE staff (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        username TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        salt TEXT NOT NULL,
        role TEXT NOT NULL,
        created_at TEXT NOT NULL,
        email TEXT,
        mobile TEXT,
        clinic_name TEXT,
        clinic_address TEXT,
        specialty TEXT,
        registration_number TEXT,
        doctor_id TEXT
      )
    ''');
    // Payment Installments Table - For tracking bills with partial payments
    await db.execute('''
      CREATE TABLE IF NOT EXISTS payment_installments (
        id TEXT PRIMARY KEY,
        patient_id TEXT NOT NULL,
        patient_name TEXT NOT NULL,
        appointment_id TEXT,
        total_amount REAL NOT NULL,
        instrument_charges REAL DEFAULT 0,
        service_charges REAL DEFAULT 0,
        created_at TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'PENDING',
        paid_amount REAL DEFAULT 0,
        remaining_amount REAL NOT NULL,
        payment_for TEXT,
        FOREIGN KEY (patient_id) REFERENCES patients (id)
      )
    ''');
    // Payment Transactions Table - Individual payments for installments
    await db.execute('''
      CREATE TABLE IF NOT EXISTS payment_transactions (
        id TEXT PRIMARY KEY,
        payment_id TEXT NOT NULL,
        amount_paid REAL NOT NULL,
        payment_date TEXT NOT NULL,
        payment_mode TEXT NOT NULL,
        received_by TEXT NOT NULL,
        receipt_number TEXT NOT NULL UNIQUE,
        notes TEXT,
        FOREIGN KEY (payment_id) REFERENCES payment_installments (id)
      )
    ''');
    // Patient Feedback Table - For storing patient reviews
    await db.execute('''
      CREATE TABLE IF NOT EXISTS patient_feedback (
        id TEXT PRIMARY KEY,
        patient_id TEXT,
        patient_name TEXT NOT NULL,
        overall_rating INTEGER NOT NULL,
        doctor_rating INTEGER NOT NULL,
        staff_rating INTEGER NOT NULL,
        cleanliness_rating INTEGER NOT NULL,
        waiting_time_rating INTEGER NOT NULL,
        comments TEXT,
        sentiment TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (patient_id) REFERENCES patients (id)
      )
    ''');
  }

  // Staff Operations & Authentication
  Future<void> _seedDefaultAdmin(Database db) async {
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM staff'));
    if (count == 0) {
      print('🔐 Seeding default admin account...');
      const salt = 'random_salt_value'; // In production, generate random salt
      final bytes = utf8.encode('admin123' + salt);
      final hash = sha256.convert(bytes).toString();
      
      await db.insert('staff', {
        'id': const Uuid().v4(),
        'name': 'Administrator',
        'username': 'admin',
        'password_hash': hash,
        'salt': salt,
        'role': 'doctor',
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> seedDefaultAdmin() async {
    if (kIsWeb) {
      if (_webStaff.isEmpty) {
         print('🔐 [WEB] Seeding default admin account...');
        const salt = 'random_salt_value';
        final bytes = utf8.encode('admin123' + salt);
        final hash = sha256.convert(bytes).toString();
        
        _webStaff.add(Staff(
          id: const Uuid().v4(),
          name: 'Administrator',
          username: 'admin',
          passwordHash: hash,
          salt: salt,
          role: 'doctor',
          createdAt: DateTime.now(),
        ));
        await _saveWebData();
      }
    }
    // For mobile/desktop, it's handled in onOpen
  }

  Future<Staff?> authenticate(String username, String password) async {
    if (kIsWeb) {
      try {
        final staff = _webStaff.firstWhere((s) => s.username == username);
        final bytes = utf8.encode(password + staff.salt);
        final hash = sha256.convert(bytes).toString();
        if (hash == staff.passwordHash) {
          return staff;
        }
      } catch (_) {}
      return null;
    }

    final db = await database;
    final maps = await db.query('staff', where: 'username = ?', whereArgs: [username]);
    if (maps.isNotEmpty) {
      final staff = Staff.fromMap(maps.first);
      final bytes = utf8.encode(password + staff.salt);
      final hash = sha256.convert(bytes).toString();
      if (hash == staff.passwordHash) {
        return staff;
      }
    }
    return null;
  }

  Future<int> insertStaff(Staff staff) async {
    if (kIsWeb) {
      _webStaff.add(staff);
      await _saveWebData();
      return 1;
    }
    final db = await database;
    return await db.insert('staff', staff.toMap());
  }

  Future<int> updateStaff(Staff staff) async {
    if (kIsWeb) {
      final index = _webStaff.indexWhere((s) => s.id == staff.id);
      if (index != -1) {
        _webStaff[index] = staff;
        await _saveWebData();
      }
      return 1;
    }
    final db = await database;
    return await db.update('staff', staff.toMap(), where: 'id = ?', whereArgs: [staff.id]);
  }

  Future<int> deleteStaff(String id) async {
    if (kIsWeb) {
      _webStaff.removeWhere((s) => s.id == id);
      await _saveWebData();
      return 1;
    }
    final db = await database;
    return await db.delete('staff', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Staff>> getAllStaff() async {
    if (kIsWeb) {
      return List.from(_webStaff);
    }
    final db = await database;
    final maps = await db.query('staff');
    return List.generate(maps.length, (i) => Staff.fromMap(maps[i]));
  }

  Future<Staff?> getStaffByUsername(String username) async {
    if (kIsWeb) {
      try {
        return _webStaff.firstWhere((s) => s.username == username);
      } catch (_) {
        return null;
      }
    }
    final db = await database;
    final maps = await db.query('staff', where: 'username = ?', whereArgs: [username]);
    if (maps.isNotEmpty) return Staff.fromMap(maps.first);
    return null;
  }

  // Get staff by ID
  Future<Staff?> getStaffById(String id) async {
    if (kIsWeb) {
      try {
        return _webStaff.firstWhere((s) => s.id == id);
      } catch (_) {
        return null;
      }
    }
    final db = await database;
    final maps = await db.query('staff', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return Staff.fromMap(maps.first);
    return null;
  }

  // Get all staff members for a specific doctor (multi-clinic support)
  Future<List<Staff>> getStaffByDoctorId(String doctorId) async {
    if (kIsWeb) {
      return _webStaff.where((s) => s.doctorId == doctorId).toList();
    }
    final db = await database;
    final maps = await db.query('staff', where: 'doctor_id = ?', whereArgs: [doctorId]);
    return List.generate(maps.length, (i) => Staff.fromMap(maps[i]));
  }

  // Get the parent doctor for a staff member
  Future<Staff?> getParentDoctor(Staff staff) async {
    if (staff.doctorId == null) return null;
    return await getStaffById(staff.doctorId!);
  }

  // Patient Operations
  Future<Patient?> getPatient(String id) async {
    if (kIsWeb) {
      try {
        return _webPatients.firstWhere((p) => p.id == id);
      } catch (_) {
        return null;
      }
    }
    final db = await database;
    final maps = await db.query('patients', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return Patient.fromMap(maps.first);
    return null;
  }

  Future<int> updatePatient(Patient patient) async {
    print('DB: Updating patient ${patient.id} status to ${patient.status}');
    if (kIsWeb) {
      final index = _webPatients.indexWhere((p) => p.id == patient.id);
      if (index != -1) {
        _webPatients[index] = patient;
        print('✏️ [WEB] Updated patient: ${patient.name} - Status: ${patient.status}');
      }
      await _saveWebData();
      return 1;
    }
    final db = await database;
    final result = await db.update('patients', patient.toMap(), where: 'id = ?', whereArgs: [patient.id]);
    print('DB: Update result: $result');
    return result;
  }

  Future<List<Patient>> getAllPatients() async {
    if (kIsWeb) {
      if (_webPatients.isEmpty) {
        print('⏳ [WEB] Waiting for data load...');
        await _loadWebData();
      }
      print('📋 [WEB] getAllPatients: ${_webPatients.length} patients');
      final sorted = List<Patient>.from(_webPatients);
      sorted.sort((a, b) => b.registrationTime.compareTo(a.registrationTime));
      return sorted;
    }
    final db = await database;
    final maps = await db.query('patients', orderBy: 'registrationTime DESC');
    print('DB: Fetched ${maps.length} patients');
    return List.generate(maps.length, (i) => Patient.fromMap(maps[i]));
  }

  Future<int> insertPatient(Patient patient) async {
    print('DB: Inserting patient ${patient.name} with status: ${patient.status} (Index: ${patient.status.index})');
    if (kIsWeb) {
      final index = _webPatients.indexWhere((p) => p.id == patient.id);
      if (index != -1) {
        _webPatients[index] = patient;
      } else {
        _webPatients.add(patient);
      }
      await _saveWebData();
      return 1;
    }
    final db = await database;
    return await db.insert('patients', patient.toMap());
  }

  Future<List<Patient>> getPatientsByDate(DateTime date) async {
    if (kIsWeb) {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
      final filtered = _webPatients.where((patient) {
        final regTime = patient.registeredDate ?? patient.registrationTime;
        return regTime.isAfter(startOfDay) && regTime.isBefore(endOfDay);
      }).toList();
      print('📋 [WEB] getPatientsByDate: Found ${filtered.length} patients');
      return filtered;
    }
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day).toIso8601String();
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();
    final maps = await db.query('patients', where: 'registrationTime BETWEEN ? AND ?', whereArgs: [startOfDay, endOfDay]);
    return List.generate(maps.length, (i) => Patient.fromMap(maps[i]));
  }

  Future<List<Patient>> getPatientsByMobile(String mobile) async {
    if (kIsWeb) {
      final filtered = _webPatients.where((patient) => patient.mobile == mobile).toList();
      filtered.sort((a, b) => b.registrationTime.compareTo(a.registrationTime));
      print('📋 [WEB] getPatientsByMobile: Found ${filtered.length} patients');
      return filtered;
    }
    final db = await database;
    final maps = await db.query('patients', where: 'mobile = ?', whereArgs: [mobile], orderBy: 'registrationTime DESC');
    return List.generate(maps.length, (i) => Patient.fromMap(maps[i]));
  }

  // Search patients by name (for registration autocomplete)
  Future<List<Patient>> searchPatientsByName(String query) async {
    if (query.isEmpty || query.length < 2) return [];
    final lowerQuery = query.toLowerCase();
    
    if (kIsWeb) {
      final filtered = _webPatients.where((p) => p.name.toLowerCase().contains(lowerQuery)).toList();
      filtered.sort((a, b) => b.registrationTime.compareTo(a.registrationTime));
      print('🔍 [WEB] searchPatientsByName: Found ${filtered.length} patients for "$query"');
      return filtered.take(10).toList();
    }
    
    final db = await database;
    final maps = await db.query('patients', where: 'LOWER(name) LIKE ?', whereArgs: ['%$lowerQuery%'], orderBy: 'registrationTime DESC', limit: 10);
    return List.generate(maps.length, (i) => Patient.fromMap(maps[i]));
  }


  Future<int> deletePatient(String patientId) async {
    if (kIsWeb) {
      _webPatients.removeWhere((p) => p.id == patientId);
      await _saveWebData();
      return 1;
    }
    final db = await database;
    return await db.delete('patients', where: 'id = ?', whereArgs: [patientId]);
  }

  // Consultation Operations
  Future<List<Consultation>> getConsultations(String patientId) async {
    if (kIsWeb) {
      final consultations = _webConsultations.where((c) => c.patientId == patientId).toList();
      consultations.sort((a, b) => b.date.compareTo(a.date));
      return consultations;
    }
    final db = await database;
    final maps = await db.query('consultations', where: 'patient_id = ?', whereArgs: [patientId], orderBy: 'date DESC');
    return List.generate(maps.length, (i) => Consultation.fromMap(maps[i]));
  }

  Future<void> updatePatientStats(String patientId) async {
    final patient = await getPatient(patientId);
    if (patient == null) return;
    final consultations = await getConsultations(patientId);
    final updatedPatient = patient.copyWith(lastVisit: DateTime.now(), consultationCount: consultations.length);
    await updatePatient(updatedPatient);
  }

  Future<int> getPendingFollowUpsCount() async {
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    
    if (kIsWeb) {
      return _webConsultations.where((c) => c.followUpDate == todayStr).length;
    }
    
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM consultations WHERE follow_up_date = ?', 
      [todayStr]
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getNotificationCount() async {
    final pendingAppts = await getPendingAppointmentsCount();
    
    // Pending payments
    int pendingPayments = 0;
    if (kIsWeb) {
      pendingPayments = _webPayments.where((p) => p.status == 'pending').length;
    } else {
      final db = await database;
      final result = await db.rawQuery("SELECT COUNT(*) as count FROM payments WHERE status = 'pending'");
      pendingPayments = Sqflite.firstIntValue(result) ?? 0;
    }

    // Today's follow-ups
    final followUps = await getTodayFollowUps();
    
    return pendingAppts + pendingPayments + followUps.length;
  }

  // Medical History Operations
  Future<List<Consultation>> getTodayFollowUps() async {
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    
    if (kIsWeb) {
      return _webConsultations.where((c) => c.followUpDate == todayStr).toList();
    }
    
    final db = await database;
    final maps = await db.query('consultations', where: 'follow_up_date = ?', whereArgs: [todayStr]);
    return List.generate(maps.length, (i) => Consultation.fromMap(maps[i]));
  }

  // Get patients with birthday today
  Future<List<Patient>> getTodayBirthdayPatients() async {
    final now = DateTime.now();
    final todayMonth = now.month.toString().padLeft(2, '0');
    final todayDay = now.day.toString().padLeft(2, '0');
    
    if (kIsWeb) {
      return _webPatients.where((p) {
        if (p.birthDate == null) return false;
        return p.birthDate!.month == now.month && p.birthDate!.day == now.day;
      }).toList();
    }
    
    final db = await database;
    // Match month and day from birth_date (format: YYYY-MM-DD...)
    final maps = await db.rawQuery(
      "SELECT * FROM patients WHERE birth_date IS NOT NULL AND substr(birth_date, 6, 2) = ? AND substr(birth_date, 9, 2) = ?",
      [todayMonth, todayDay]
    );
    return List.generate(maps.length, (i) => Patient.fromMap(maps[i]));
  }

  // Get upcoming birthdays (next 7 days)
  Future<List<Patient>> getUpcomingBirthdayPatients({int days = 7}) async {
    final now = DateTime.now();
    
    if (kIsWeb) {
      return _webPatients.where((p) {
        if (p.birthDate == null) return false;
        // Check if birthday falls within next 'days' days
        for (int i = 0; i <= days; i++) {
          final checkDate = now.add(Duration(days: i));
          if (p.birthDate!.month == checkDate.month && p.birthDate!.day == checkDate.day) {
            return true;
          }
        }
        return false;
      }).toList();
    }
    
    // For SQLite, we need to check each day
    final db = await database;
    List<Patient> result = [];
    for (int i = 0; i <= days; i++) {
      final checkDate = now.add(Duration(days: i));
      final checkMonth = checkDate.month.toString().padLeft(2, '0');
      final checkDay = checkDate.day.toString().padLeft(2, '0');
      
      final maps = await db.rawQuery(
        "SELECT * FROM patients WHERE birth_date IS NOT NULL AND substr(birth_date, 6, 2) = ? AND substr(birth_date, 9, 2) = ?",
        [checkMonth, checkDay]
      );
      result.addAll(List.generate(maps.length, (i) => Patient.fromMap(maps[i])));
    }
    return result;
  }

  // Get birthday count for notifications
  Future<int> getTodayBirthdayCount() async {
    final patients = await getTodayBirthdayPatients();
    return patients.length;
  }

  Future<MedicalHistory?> getMedicalHistory(String patientId) async {
    if (kIsWeb) {
      try {
        return _webMedicalHistory.firstWhere((h) => h.patientId == patientId);
      } catch (_) {
        return null;
      }
    }
    final db = await database;
    final maps = await db.query('medical_history', where: 'patient_id = ?', whereArgs: [patientId]);
    if (maps.isNotEmpty) return MedicalHistory.fromMap(maps.first);
    return null;
  }

  Future<List<Consultation>> getUpcomingFollowUps() async {
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    
    if (kIsWeb) {
      return _webConsultations.where((c) {
        if (c.followUpDate == null) return false;
        final followUp = DateFormat('yyyy-MM-dd').format(c.followUpDate!);
        return followUp.compareTo(todayStr) >= 0;
      }).toList()..sort((a, b) => a.followUpDate!.compareTo(b.followUpDate!));
    }
    
    final db = await database;
    final maps = await db.query(
      'consultations', 
      where: 'follow_up_date >= ?', 
      whereArgs: [todayStr],
      orderBy: 'follow_up_date ASC'
    );
    return List.generate(maps.length, (i) => Consultation.fromMap(maps[i]));
  }

  Future<int> insertMedicalHistory(MedicalHistory history) async {
    if (kIsWeb) {
      final index = _webMedicalHistory.indexWhere((h) => h.patientId == history.patientId);
      if (index != -1) {
        _webMedicalHistory[index] = history;
      } else {
        _webMedicalHistory.add(history);
      }
      return 1;
    }
    final db = await database;
    return await db.insert('medical_history', history.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateMedicalHistory(MedicalHistory history) async {
    if (kIsWeb) {
      final index = _webMedicalHistory.indexWhere((h) => h.id == history.id);
      if (index != -1) {
        _webMedicalHistory[index] = history;
      }
      return 1;
    }
    final db = await database;
    return await db.update('medical_history', history.toMap(), where: 'id = ?', whereArgs: [history.id]);
  }

  // Prescription Operations
  Future<List<Prescription>> getCurrentPrescriptions(String patientId) async {
    if (kIsWeb) {
      final prescriptions = _webPrescriptions.where((p) => p.patientId == patientId && p.isCurrent).toList();
      prescriptions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return prescriptions;
    }
    final db = await database;
    final maps = await db.query('prescriptions', where: 'patient_id = ? AND is_current = 1', whereArgs: [patientId], orderBy: 'created_at DESC');
    return List.generate(maps.length, (i) => Prescription.fromMap(maps[i]));
  }

  Future<int> insertPrescription(Prescription prescription) async {
    if (kIsWeb) {
      _webPrescriptions.add(prescription);
      return 1;
    }
    final db = await database;
    return await db.insert('prescriptions', prescription.toMap());
  }

  Future<int> markPrescriptionsAsOld(String patientId) async {
    if (kIsWeb) {
      for (var i = 0; i < _webPrescriptions.length; i++) {
        if (_webPrescriptions[i].patientId == patientId) {
          _webPrescriptions[i] = Prescription(
            id: _webPrescriptions[i].id,
            patientId: _webPrescriptions[i].patientId,
            medicineName: _webPrescriptions[i].medicineName,
            dosage: _webPrescriptions[i].dosage,
            frequency: _webPrescriptions[i].frequency,
            createdAt: _webPrescriptions[i].createdAt,
            isCurrent: false,
          );
        }
      }
      return 1;
    }
    final db = await database;
    return await db.update('prescriptions', {'is_current': 0}, where: 'patient_id = ?', whereArgs: [patientId]);
  }

  Future<int> insertConsultation(Consultation consultation) async {
    if (kIsWeb) {
      _webConsultations.add(consultation);
      return 1;
    }
    final db = await database;
    return await db.insert('consultations', consultation.toMap());
  }

  // Appointment Operations
  Future<List<Appointment>> getAppointmentsByDate(DateTime date) async {
    if (kIsWeb) {
      final targetDate = DateTime(date.year, date.month, date.day);
      return _webAppointments.where((apt) {
        final aptDate = DateTime(apt.date.year, apt.date.month, apt.date.day);
        return aptDate.isAtSameMomentAs(targetDate) && apt.status != 'cancelled';
      }).toList();
    }
    final db = await database;
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final maps = await db.query('appointments', where: 'date LIKE ? AND status != ?', whereArgs: ['%$dateStr%', 'cancelled'], orderBy: 'time ASC');
    return List.generate(maps.length, (i) => Appointment.fromMap(maps[i]));
  }

  Future<List<Appointment>> getPendingAppointments() async {
    if (kIsWeb) {
      return _webAppointments.where((apt) => apt.status == 'pending').toList()
        ..sort((a, b) {
          final dateCompare = a.date.compareTo(b.date);
          if (dateCompare != 0) return dateCompare;
          return a.time.compareTo(b.time);
        });
    }
    final db = await database;
    final maps = await db.query('appointments', where: 'status = ?', whereArgs: ['pending'], orderBy: 'date ASC, time ASC');
    return List.generate(maps.length, (i) => Appointment.fromMap(maps[i]));
  }

  Future<int> updateAppointmentStatus(String id, String status) async {
    if (kIsWeb) {
      final index = _webAppointments.indexWhere((apt) => apt.id == id);
      if (index != -1) {
        _webAppointments[index] = _webAppointments[index].copyWith(status: status);
      }
      await _saveWebData();
      return 1;
    }
    final db = await database;
    return await db.update('appointments', {'status': status}, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertAppointment(Appointment appointment) async {
    if (kIsWeb) {
      _webAppointments.add(appointment);
      await _saveWebData();
      return 1;
    }
    final db = await database;
    return await db.insert('appointments', appointment.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> confirmAppointment(String appointmentId, String patientId, String? imagePath) async {
    if (kIsWeb) {
      final index = _webAppointments.indexWhere((apt) => apt.id == appointmentId);
      if (index != -1) {
        _webAppointments[index] = Appointment(
          id: _webAppointments[index].id,
          patientName: _webAppointments[index].patientName,
          mobile: _webAppointments[index].mobile,
          date: _webAppointments[index].date,
          time: _webAppointments[index].time,
          type: _webAppointments[index].type,
          reason: _webAppointments[index].reason,
          status: 'confirmed',
          createdAt: _webAppointments[index].createdAt,
          patientId: patientId,
          patientImage: imagePath,
          verifiedAt: DateTime.now(),
        );
      }
      await _saveWebData();
      return 1;
    }
    final db = await database;
    return await db.update('appointments', {'status': 'confirmed', 'patient_id': patientId, 'patient_image': imagePath, 'verified_at': DateTime.now().toIso8601String()}, where: 'id = ?', whereArgs: [appointmentId]);
  }

  Future<int> rejectAppointment(String appointmentId, String reason) async {
    if (kIsWeb) {
      final index = _webAppointments.indexWhere((apt) => apt.id == appointmentId);
      if (index != -1) {
        _webAppointments[index] = _webAppointments[index].copyWith(status: 'rejected', rejectionReason: reason);
      }
      await _saveWebData();
      return 1;
    }
    final db = await database;
    return await db.update('appointments', {'status': 'rejected', 'rejection_reason': reason}, where: 'id = ?', whereArgs: [appointmentId]);
  }

  Future<List<Appointment>> getConfirmedAppointments() async {
    if (kIsWeb) {
      return _webAppointments.where((apt) => apt.status == 'confirmed').toList()
        ..sort((a, b) {
          final dateCompare = a.date.compareTo(b.date);
          if (dateCompare != 0) return dateCompare;
          return a.time.compareTo(b.time);
        });
    }
    final db = await database;
    final maps = await db.query('appointments', where: 'status = ?', whereArgs: ['confirmed'], orderBy: 'date ASC, time ASC');
    return List.generate(maps.length, (i) => Appointment.fromMap(maps[i]));
  }

  Future<int> autoRejectExpiredAppointments() async {
    if (kIsWeb) {
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);
      int count = 0;
      for (int i = 0; i < _webAppointments.length; i++) {
        final apt = _webAppointments[i];
        final aptDate = DateTime(apt.date.year, apt.date.month, apt.date.day);
        if ((apt.status == 'pending' || apt.status == 'confirmed') && aptDate.isBefore(startOfToday)) {
          _webAppointments[i] = apt.copyWith(status: 'rejected', rejectionReason: 'Auto-rejected: Patient did not arrive');
          count++;
        }
      }
      return count;
    }
    final db = await database;
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    return await db.update('appointments', {'status': 'rejected', 'rejection_reason': 'Auto-rejected: Patient did not arrive'}, where: 'status IN (?, ?) AND date < ?', whereArgs: ['pending', 'confirmed', startOfToday.toIso8601String()]);
  }

  Future<int> getPendingAppointmentsCount() async {
    if (kIsWeb) {
      return _webAppointments.where((apt) => apt.status == 'pending').length;
    }
    final db = await database;
    final result = await db.rawQuery("SELECT COUNT(*) as count FROM appointments WHERE status = 'pending'");
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Payment Operations
  static final List<Payment> _webPayments = [];
  
  Future<int> insertPayment(Payment payment) async {
    if (kIsWeb) {
      _webPayments.add(payment);
      await _saveWebData();
      return 1;
    }
    final db = await database;
    return await db.insert('payments', payment.toMap());
  }

  Future<int> updatePayment(Payment payment) async {
    if (kIsWeb) {
      final index = _webPayments.indexWhere((p) => p.id == payment.id);
      if (index != -1) {
        _webPayments[index] = payment;
        await _saveWebData();
      }
      return 1;
    }
    final db = await database;
    return await db.update('payments', payment.toMap(), where: 'id = ?', whereArgs: [payment.id]);
  }

  Future<List<Payment>> getAllPayments() async {
    if (kIsWeb) {
      return List.from(_webPayments)..sort((a, b) => b.date.compareTo(a.date));
    }
    final db = await database;
    final maps = await db.query('payments', orderBy: 'date DESC');
    return List.generate(maps.length, (i) => Payment.fromMap(maps[i]));
  }

  Future<Payment?> getPaymentByPatient(String patientId) async {
    if (kIsWeb) {
      try {
        return _webPayments.firstWhere((p) => p.patientId == patientId);
      } catch (_) {
        return null;
      }
    }
    final db = await database;
    final maps = await db.query('payments', where: 'patient_id = ?', whereArgs: [patientId], orderBy: 'date DESC', limit: 1);
    if (maps.isNotEmpty) return Payment.fromMap(maps.first);
    return null;
  }

  Future<List<Payment>> getPaymentsByPatient(String patientId) async {
    if (kIsWeb) {
      return _webPayments.where((p) => p.patientId == patientId).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    }
    final db = await database;
    final maps = await db.query('payments', where: 'patient_id = ?', whereArgs: [patientId], orderBy: 'date DESC');
    return List.generate(maps.length, (i) => Payment.fromMap(maps[i]));
  }

  Future<List<Payment>> getPaymentsByStatus(String status) async {
    if (kIsWeb) {
      return _webPayments.where((p) => p.status == status).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    }
    final db = await database;
    final maps = await db.query('payments', where: 'status = ?', whereArgs: [status], orderBy: 'date DESC');
    return List.generate(maps.length, (i) => Payment.fromMap(maps[i]));
  }

  Future<bool> isPaymentCompleted(String patientId) async {
    final payment = await getPaymentByPatient(patientId);
    return payment?.status == 'paid';
  }

  Future<int> getPendingPaymentsCount() async {
    if (kIsWeb) {
      return _webPayments.where((p) => p.status == 'pending').length;
    }
    final db = await database;
    final result = await db.rawQuery("SELECT COUNT(*) as count FROM payments WHERE status = 'pending'");
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Payment Settings
  Future<Map<String, dynamic>?> getPaymentSettings() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final doctorFees = prefs.getDouble('doctor_fees');
      final followUpFees = prefs.getDouble('followup_fees');
      final followUpMonths = prefs.getInt('followup_months');
      
      if (doctorFees == null) return null;
      
      return {
        'doctorFees': doctorFees,
        'followUpFees': followUpFees ?? 250.0,
        'followUpMonths': followUpMonths ?? 3,
      };
    }
    
    final prefs = await SharedPreferences.getInstance();
    final doctorFees = prefs.getDouble('doctor_fees');
    final followUpFees = prefs.getDouble('followup_fees');
    final followUpMonths = prefs.getInt('followup_months');
    
    if (doctorFees == null) return null;
    
    return {
      'doctorFees': doctorFees,
      'followUpFees': followUpFees ?? 250.0,
      'followUpMonths': followUpMonths ?? 3,
    };
  }

  Future<void> savePaymentSettings(Map<String, dynamic> settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('doctor_fees', settings['doctorFees']);
    await prefs.setDouble('followup_fees', settings['followUpFees']);
    await prefs.setInt('followup_months', settings['followUpMonths']);
  }

  // ========== Payment Installment Operations ==========
  static final List<PaymentInstallment> _webInstallments = [];
  static final List<PaymentTransaction> _webTransactions = [];

  // Generate unique receipt number
  String generateReceiptNumber() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch;
    return 'RCP${timestamp.toString().substring(timestamp.toString().length - 8)}';
  }

  // Create new payment installment
  Future<int> createPaymentInstallment(PaymentInstallment installment) async {
    if (kIsWeb) {
      _webInstallments.add(installment);
      await _saveWebData();
      return 1;
    }
    final db = await database;
    return await db.insert('payment_installments', installment.toMap());
  }

  // Add payment transaction to installment
  Future<int> addPaymentTransaction(PaymentTransaction transaction) async {
    if (kIsWeb) {
      _webTransactions.add(transaction);
      // Update installment status
      await _updateInstallmentStatus(transaction.paymentId);
      await _saveWebData();
      return 1;
    }
    final db = await database;
    final result = await db.insert('payment_transactions', transaction.toMap());
    // Update installment status
    await _updateInstallmentStatus(transaction.paymentId);
    return result;
  }

  // Update installment status based on transactions
  Future<void> _updateInstallmentStatus(String paymentId) async {
    if (kIsWeb) {
      final transactions = _webTransactions.where((t) => t.paymentId == paymentId).toList();
      final totalPaid = transactions.fold<double>(0, (sum, t) => sum + t.amountPaid);
      
      final index = _webInstallments.indexWhere((i) => i.id == paymentId);
      if (index != -1) {
        final installment = _webInstallments[index];
        final remaining = installment.totalAmount - totalPaid;
        
        String status;
        if (remaining <= 0) {
          status = 'FULL_PAID';
        } else if (totalPaid > 0) {
          status = 'PARTIAL';
        } else {
          status = 'PENDING';
        }
        
        _webInstallments[index] = installment.copyWith(
          paidAmount: totalPaid,
          remainingAmount: remaining > 0 ? remaining : 0,
          status: status,
        );
      }
      return;
    }

    final db = await database;
    
    // Get total paid amount
    final result = await db.rawQuery('''
      SELECT SUM(amount_paid) as total_paid
      FROM payment_transactions
      WHERE payment_id = ?
    ''', [paymentId]);

    final totalPaid = (result.first['total_paid'] as num?)?.toDouble() ?? 0.0;

    // Get payment details
    final payment = await db.query(
      'payment_installments',
      where: 'id = ?',
      whereArgs: [paymentId],
    );

    if (payment.isNotEmpty) {
      final totalAmount = (payment.first['total_amount'] as num).toDouble();
      final remaining = totalAmount - totalPaid;

      String status;
      if (remaining <= 0) {
        status = 'FULL_PAID';
      } else if (totalPaid > 0) {
        status = 'PARTIAL';
      } else {
        status = 'PENDING';
      }

      await db.update(
        'payment_installments',
        {
          'paid_amount': totalPaid,
          'remaining_amount': remaining > 0 ? remaining : 0,
          'status': status,
        },
        where: 'id = ?',
        whereArgs: [paymentId],
      );
    }
  }

  // Get all payment installments
  Future<List<PaymentInstallment>> getAllPaymentInstallments() async {
    if (kIsWeb) {
      return List.from(_webInstallments)..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    final db = await database;
    final maps = await db.query('payment_installments', orderBy: 'created_at DESC');
    return List.generate(maps.length, (i) => PaymentInstallment.fromMap(maps[i]));
  }

  // Get payment installments by patient
  Future<List<PaymentInstallment>> getPaymentInstallmentsByPatient(String patientId) async {
    if (kIsWeb) {
      return _webInstallments.where((i) => i.patientId == patientId).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    final db = await database;
    final maps = await db.query(
      'payment_installments',
      where: 'patient_id = ?',
      whereArgs: [patientId],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => PaymentInstallment.fromMap(maps[i]));
  }

  // Get payment installments by status
  Future<List<PaymentInstallment>> getPaymentInstallmentsByStatus(String status) async {
    if (kIsWeb) {
      return _webInstallments.where((i) => i.status == status).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    final db = await database;
    final maps = await db.query(
      'payment_installments',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => PaymentInstallment.fromMap(maps[i]));
  }

  // Get pending/partial payment installments
  Future<List<PaymentInstallment>> getPendingPaymentInstallments() async {
    if (kIsWeb) {
      return _webInstallments.where((i) => i.status == 'PENDING' || i.status == 'PARTIAL').toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    final db = await database;
    final maps = await db.query(
      'payment_installments',
      where: 'status IN (?, ?)',
      whereArgs: ['PENDING', 'PARTIAL'],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => PaymentInstallment.fromMap(maps[i]));
  }

  // Get payment installment by ID
  Future<PaymentInstallment?> getPaymentInstallment(String id) async {
    if (kIsWeb) {
      try {
        return _webInstallments.firstWhere((i) => i.id == id);
      } catch (_) {
        return null;
      }
    }
    final db = await database;
    final maps = await db.query(
      'payment_installments',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) return PaymentInstallment.fromMap(maps.first);
    return null;
  }

  // Get transactions for a payment
  Future<List<PaymentTransaction>> getPaymentTransactions(String paymentId) async {
    if (kIsWeb) {
      return _webTransactions.where((t) => t.paymentId == paymentId).toList()
        ..sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
    }
    final db = await database;
    final maps = await db.query(
      'payment_transactions',
      where: 'payment_id = ?',
      whereArgs: [paymentId],
      orderBy: 'payment_date DESC',
    );
    return List.generate(maps.length, (i) => PaymentTransaction.fromMap(maps[i]));
  }

  // Get installment summary
  Future<Map<String, dynamic>> getInstallmentSummary() async {
    if (kIsWeb) {
      final totalBills = _webInstallments.length;
      final totalAmount = _webInstallments.fold<double>(0, (sum, i) => sum + i.totalAmount);
      final totalPaid = _webInstallments.fold<double>(0, (sum, i) => sum + i.paidAmount);
      final totalRemaining = _webInstallments.fold<double>(0, (sum, i) => sum + i.remainingAmount);
      
      return {
        'total_bills': totalBills,
        'total_amount': totalAmount,
        'total_paid': totalPaid,
        'total_remaining': totalRemaining,
        'pending_count': _webInstallments.where((i) => i.status == 'PENDING').length,
        'partial_count': _webInstallments.where((i) => i.status == 'PARTIAL').length,
        'full_paid_count': _webInstallments.where((i) => i.status == 'FULL_PAID').length,
      };
    }
    
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_bills,
        COALESCE(SUM(total_amount), 0) as total_amount,
        COALESCE(SUM(paid_amount), 0) as total_paid,
        COALESCE(SUM(remaining_amount), 0) as total_remaining
      FROM payment_installments
    ''');

    final statusResult = await db.rawQuery('''
      SELECT 
        status,
        COUNT(*) as count
      FROM payment_installments
      GROUP BY status
    ''');

    int pendingCount = 0, partialCount = 0, fullPaidCount = 0;
    for (var row in statusResult) {
      if (row['status'] == 'PENDING') pendingCount = row['count'] as int;
      if (row['status'] == 'PARTIAL') partialCount = row['count'] as int;
      if (row['status'] == 'FULL_PAID') fullPaidCount = row['count'] as int;
    }

    return {
      'total_bills': result.first['total_bills'],
      'total_amount': result.first['total_amount'],
      'total_paid': result.first['total_paid'],
      'total_remaining': result.first['total_remaining'],
      'pending_count': pendingCount,
      'partial_count': partialCount,
      'full_paid_count': fullPaidCount,
    };
  }

  // Insert payment installment
  Future<int> insertPaymentInstallment(PaymentInstallment installment) async {
    if (kIsWeb) {
      _webInstallments.add(installment);
      await _saveWebData();
      return 1;
    }
    final db = await database;
    return await db.insert('payment_installments', installment.toMap());
  }

  // Update payment installment
  Future<int> updatePaymentInstallment(PaymentInstallment installment) async {
    if (kIsWeb) {
      final index = _webInstallments.indexWhere((i) => i.id == installment.id);
      if (index != -1) {
        _webInstallments[index] = installment;
        await _saveWebData();
      }
      return 1;
    }
    final db = await database;
    return await db.update(
      'payment_installments',
      installment.toMap(),
      where: 'id = ?',
      whereArgs: [installment.id],
    );
  }

  // Delete payment installment
  Future<int> deletePaymentInstallment(String id) async {
    if (kIsWeb) {
      _webInstallments.removeWhere((i) => i.id == id);
      _webTransactions.removeWhere((t) => t.paymentId == id);
      await _saveWebData();
      return 1;
    }
    final db = await database;
    await db.delete('payment_transactions', where: 'payment_id = ?', whereArgs: [id]);
    return await db.delete('payment_installments', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== PATIENT FEEDBACK OPERATIONS ====================
  
  static final List<PatientFeedback> _webFeedback = [];

  // Insert patient feedback
  Future<int> insertPatientFeedback(PatientFeedback feedback) async {
    if (kIsWeb) {
      _webFeedback.add(feedback);
      return 1;
    }
    final db = await database;
    return await db.insert('patient_feedback', feedback.toMap());
  }

  // Get all feedback
  Future<List<PatientFeedback>> getAllFeedback() async {
    if (kIsWeb) {
      return List.from(_webFeedback)..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    final db = await database;
    final maps = await db.query('patient_feedback', orderBy: 'created_at DESC');
    return List.generate(maps.length, (i) => PatientFeedback.fromMap(maps[i]));
  }

  // Get feedback statistics - for Settings analytics
  Future<Map<String, dynamic>> getFeedbackStatistics() async {
    final allFeedback = await getAllFeedback();
    
    if (allFeedback.isEmpty) {
      return {
        'totalReviews': 0,
        'avgOverall': 0.0,
        'avgDoctor': 0.0,
        'avgStaff': 0.0,
        'avgCleanliness': 0.0,
        'avgWaitingTime': 0.0,
        'positiveCount': 0,
        'neutralCount': 0,
        'negativeCount': 0,
        'staffBehavior': 'No Data',
        'aiSuggestion': 'No feedback data available yet.',
      };
    }

    double avgOverall = allFeedback.map((f) => f.overallRating).reduce((a, b) => a + b) / allFeedback.length;
    double avgDoctor = allFeedback.map((f) => f.doctorRating).reduce((a, b) => a + b) / allFeedback.length;
    double avgStaff = allFeedback.map((f) => f.staffRating).reduce((a, b) => a + b) / allFeedback.length;
    double avgCleanliness = allFeedback.map((f) => f.cleanlinessRating).reduce((a, b) => a + b) / allFeedback.length;
    double avgWaitingTime = allFeedback.map((f) => f.waitingTimeRating).reduce((a, b) => a + b) / allFeedback.length;

    // Sentiment analysis based on ratings
    int positiveCount = allFeedback.where((f) => f.overallRating >= 4).length;
    int neutralCount = allFeedback.where((f) => f.overallRating == 3).length;
    int negativeCount = allFeedback.where((f) => f.overallRating <= 2).length;

    // AI-like staff behavior analysis
    String staffBehavior;
    String aiSuggestion;
    
    if (avgStaff >= 4.5) {
      staffBehavior = '😊 EXCELLENT - Very Polite';
      aiSuggestion = '✨ Excellent work! Staff is receiving outstanding feedback. Patients love the courteous behavior. Keep up the great work!';
    } else if (avgStaff >= 4.0) {
      staffBehavior = '🙂 GOOD - Polite';
      aiSuggestion = '👍 Good performance! Staff behavior is appreciated by patients. Minor improvements in attentiveness could help reach excellence.';
    } else if (avgStaff >= 3.0) {
      staffBehavior = '😐 AVERAGE - Needs Improvement';
      aiSuggestion = '⚠️ Staff behavior is average. Consider training on patient communication, active listening, and empathy to improve patient experience.';
    } else if (avgStaff >= 2.0) {
      staffBehavior = '😕 POOR - Rude Behavior Reported';
      aiSuggestion = '🚨 Warning: Patients are reporting unsatisfactory staff behavior. Immediate attention needed! Conduct staff meeting and implement customer service training.';
    } else {
      staffBehavior = '😡 CRITICAL - Very Rude';
      aiSuggestion = '🔴 CRITICAL ALERT: Multiple complaints about rude staff behavior. This is affecting patient satisfaction severely. Take immediate action - counseling, training, or personnel review required.';
    }

    // Add waiting time suggestion
    if (avgWaitingTime < 3.0) {
      aiSuggestion += '\n\n⏰ Note: Waiting time ratings are low. Consider improving appointment scheduling or adding more staff during peak hours.';
    }

    return {
      'totalReviews': allFeedback.length,
      'avgOverall': avgOverall,
      'avgDoctor': avgDoctor,
      'avgStaff': avgStaff,
      'avgCleanliness': avgCleanliness,
      'avgWaitingTime': avgWaitingTime,
      'positiveCount': positiveCount,
      'neutralCount': neutralCount,
      'negativeCount': negativeCount,
      'staffBehavior': staffBehavior,
      'aiSuggestion': aiSuggestion,
      'recentFeedback': allFeedback.take(5).toList(),
    };
  }
  // ==================== BACKUP & RESTORE ====================
  
  /// Export all database data to a JSON string for backup
  Future<String> exportBackupData() async {
    final backupData = <String, dynamic>{
      'backupVersion': 1,
      'backupDate': DateTime.now().toIso8601String(),
      'appName': 'MODI - Medical OPD',
    };

    if (kIsWeb) {
      backupData['patients'] = _webPatients.map((p) => p.toMap()).toList();
      backupData['appointments'] = _webAppointments.map((a) => a.toMap()).toList();
      backupData['staff'] = _webStaff.map((s) => s.toMap()).toList();
      backupData['medicalHistory'] = _webMedicalHistory.map((m) => m.toMap()).toList();
      backupData['prescriptions'] = _webPrescriptions.map((p) => p.toMap()).toList();
      backupData['consultations'] = _webConsultations.map((c) => c.toMap()).toList();
    } else {
      final db = await database;
      
      // Export all tables
      final patients = await db.query('patients');
      backupData['patients'] = patients;
      
      final appointments = await db.query('appointments');
      backupData['appointments'] = appointments;
      
      final staff = await db.query('staff');
      backupData['staff'] = staff;
      
      final medicalHistory = await db.query('medical_history');
      backupData['medicalHistory'] = medicalHistory;
      
      final prescriptions = await db.query('prescriptions');
      backupData['prescriptions'] = prescriptions;
      
      final consultations = await db.query('consultations');
      backupData['consultations'] = consultations;
      
      final payments = await db.query('payments');
      backupData['payments'] = payments;
      
      final paymentInstallments = await db.query('payment_installments');
      backupData['paymentInstallments'] = paymentInstallments;
      
      final paymentTransactions = await db.query('payment_transactions');
      backupData['paymentTransactions'] = paymentTransactions;
      
      final feedback = await db.query('patient_feedback');
      backupData['patientFeedback'] = feedback;
    }

    final jsonString = jsonEncode(backupData);
    print('📦 Backup created: ${(jsonString.length / 1024).toStringAsFixed(2)} KB');
    return jsonString;
  }

  /// Get backup statistics without creating full backup
  Future<Map<String, int>> getBackupStats() async {
    if (kIsWeb) {
      return {
        'patients': _webPatients.length,
        'appointments': _webAppointments.length,
        'staff': _webStaff.length,
        'prescriptions': _webPrescriptions.length,
        'consultations': _webConsultations.length,
      };
    }
    
    final db = await database;
    return {
      'patients': Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM patients')) ?? 0,
      'appointments': Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM appointments')) ?? 0,
      'staff': Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM staff')) ?? 0,
      'prescriptions': Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM prescriptions')) ?? 0,
      'consultations': Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM consultations')) ?? 0,
      'payments': Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM payments')) ?? 0,
      'paymentInstallments': Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM payment_installments')) ?? 0,
      'feedback': Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM patient_feedback')) ?? 0,
    };
  }

  /// Restore data from a JSON backup string
  Future<Map<String, dynamic>> restoreFromBackup(String jsonString) async {
    try {
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;
      
      // Validate backup
      if (!backupData.containsKey('backupVersion') || !backupData.containsKey('patients')) {
        return {'success': false, 'error': 'Invalid backup file format'};
      }

      int patientsRestored = 0;
      int appointmentsRestored = 0;
      int staffRestored = 0;

      if (kIsWeb) {
        // Clear existing data
        _webPatients.clear();
        _webAppointments.clear();
        // Don't clear staff to preserve login credentials
        
        // Restore patients
        if (backupData['patients'] != null) {
          for (var p in backupData['patients']) {
            _webPatients.add(Patient.fromMap(p));
            patientsRestored++;
          }
        }
        
        // Restore appointments
        if (backupData['appointments'] != null) {
          for (var a in backupData['appointments']) {
            _webAppointments.add(Appointment.fromMap(a));
            appointmentsRestored++;
          }
        }
        
        await _saveWebData();
      } else {
        final db = await database;
        
        // Use transaction for safety
        await db.transaction((txn) async {
          // Restore patients
          if (backupData['patients'] != null) {
            for (var p in backupData['patients']) {
              await txn.insert('patients', Map<String, dynamic>.from(p), 
                conflictAlgorithm: ConflictAlgorithm.replace);
              patientsRestored++;
            }
          }
          
          // Restore appointments
          if (backupData['appointments'] != null) {
            for (var a in backupData['appointments']) {
              await txn.insert('appointments', Map<String, dynamic>.from(a),
                conflictAlgorithm: ConflictAlgorithm.replace);
              appointmentsRestored++;
            }
          }
          
          // Restore prescriptions
          if (backupData['prescriptions'] != null) {
            for (var p in backupData['prescriptions']) {
              await txn.insert('prescriptions', Map<String, dynamic>.from(p),
                conflictAlgorithm: ConflictAlgorithm.replace);
            }
          }
          
          // Restore consultations
          if (backupData['consultations'] != null) {
            for (var c in backupData['consultations']) {
              await txn.insert('consultations', Map<String, dynamic>.from(c),
                conflictAlgorithm: ConflictAlgorithm.replace);
            }
          }
          
          // Restore payments
          if (backupData['payments'] != null) {
            for (var p in backupData['payments']) {
              await txn.insert('payments', Map<String, dynamic>.from(p),
                conflictAlgorithm: ConflictAlgorithm.replace);
            }
          }
          
          // Restore payment installments
          if (backupData['paymentInstallments'] != null) {
            for (var p in backupData['paymentInstallments']) {
              await txn.insert('payment_installments', Map<String, dynamic>.from(p),
                conflictAlgorithm: ConflictAlgorithm.replace);
            }
          }
          
          // Restore feedback
          if (backupData['patientFeedback'] != null) {
            for (var f in backupData['patientFeedback']) {
              await txn.insert('patient_feedback', Map<String, dynamic>.from(f),
                conflictAlgorithm: ConflictAlgorithm.replace);
            }
          }
        });
      }

      print('✅ Restore complete: $patientsRestored patients, $appointmentsRestored appointments');
      
      return {
        'success': true,
        'patientsRestored': patientsRestored,
        'appointmentsRestored': appointmentsRestored,
        'backupDate': backupData['backupDate'],
      };
    } catch (e) {
      print('🔴 Restore error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get database file path (for direct file backup on mobile)
  Future<String?> getDatabasePath() async {
    if (kIsWeb) return null;
    final dbPath = await getDatabasesPath();
    return join(dbPath, 'patients.db');
  }

  Future close() async {
    if (kIsWeb) return;
    final db = await database;
    await db.close();
  }
}


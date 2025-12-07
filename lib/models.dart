import 'dart:convert';

// Patient status enum
enum PatientStatus { waiting, inProgress, completed }

// Staff model
class Staff {
  final String id;
  final String name;
  final String username;
  final String passwordHash;
  final String salt;
  final String role; // 'doctor' or 'staff'
  final DateTime createdAt;
  
  // Extended fields for Doctor profile
  final String? email;
  final String? mobile;
  final String? clinicName;
  final String? clinicAddress;
  final String? specialty;
  final String? registrationNumber;
  
  // For Staff: Link to parent Doctor (multi-clinic support)
  final String? doctorId; // ID of the doctor who created this staff

  Staff({
    required this.id,
    required this.name,
    required this.username,
    required this.passwordHash,
    required this.salt,
    required this.role,
    DateTime? createdAt,
    this.email,
    this.mobile,
    this.clinicName,
    this.clinicAddress,
    this.specialty,
    this.registrationNumber,
    this.doctorId,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'password_hash': passwordHash,
      'salt': salt,
      'role': role,
      'created_at': createdAt.toIso8601String(),
      'email': email,
      'mobile': mobile,
      'clinic_name': clinicName,
      'clinic_address': clinicAddress,
      'specialty': specialty,
      'registration_number': registrationNumber,
      'doctor_id': doctorId,
    };
  }

  factory Staff.fromMap(Map<String, dynamic> map) {
    return Staff(
      id: map['id'],
      name: map['name'],
      username: map['username'],
      passwordHash: map['password_hash'],
      salt: map['salt'],
      role: map['role'],
      createdAt: DateTime.parse(map['created_at']),
      email: map['email'],
      mobile: map['mobile'],
      clinicName: map['clinic_name'],
      clinicAddress: map['clinic_address'],
      specialty: map['specialty'],
      registrationNumber: map['registration_number'],
      doctorId: map['doctor_id'],
    );
  }
  
  // CopyWith method for easy updates
  Staff copyWith({
    String? id,
    String? name,
    String? username,
    String? passwordHash,
    String? salt,
    String? role,
    DateTime? createdAt,
    String? email,
    String? mobile,
    String? clinicName,
    String? clinicAddress,
    String? specialty,
    String? registrationNumber,
    String? doctorId,
  }) {
    return Staff(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      passwordHash: passwordHash ?? this.passwordHash,
      salt: salt ?? this.salt,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      email: email ?? this.email,
      mobile: mobile ?? this.mobile,
      clinicName: clinicName ?? this.clinicName,
      clinicAddress: clinicAddress ?? this.clinicAddress,
      specialty: specialty ?? this.specialty,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      doctorId: doctorId ?? this.doctorId,
    );
  }
  
  // Helper method to check if staff belongs to a doctor
  bool belongsToDoctor(String docId) {
    return doctorId == docId;
  }
  
  // Check if this is a doctor account
  bool get isDoctor => role == 'doctor';
  
  // Check if this is a staff account
  bool get isStaff => role == 'staff';
}


// Medical History model
class MedicalHistory {
  final String id;
  final String patientId;
  final List<String> previousConditions;
  final String currentDiagnosis;
  final String notes;
  final String allergies;
  final String bloodGroup;
  final DateTime createdAt;

  MedicalHistory({
    required this.id,
    required this.patientId,
    required this.previousConditions,
    required this.currentDiagnosis,
    required this.notes,
    required this.allergies,
    required this.bloodGroup,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patient_id': patientId,
      'previous_conditions': jsonEncode(previousConditions),
      'current_diagnosis': currentDiagnosis,
      'notes': notes,
      'allergies': allergies,
      'blood_group': bloodGroup,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory MedicalHistory.fromMap(Map<String, dynamic> map) {
    List<String> conditions = [];
    if (map['previous_conditions'] != null) {
      try {
        conditions = List<String>.from(jsonDecode(map['previous_conditions']));
      } catch (_) {}
    }
    return MedicalHistory(
      id: map['id'],
      patientId: map['patient_id'],
      previousConditions: conditions,
      currentDiagnosis: map['current_diagnosis'] ?? '',
      notes: map['notes'] ?? '',
      allergies: map['allergies'] ?? '',
      bloodGroup: map['blood_group'] ?? '',
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}

// Prescription model
class Prescription {
  final String id;
  final String patientId;
  final String medicineName;
  final String dosage;
  final String frequency;
  final DateTime createdAt;
  final bool isCurrent;
  final String? manufacturer;
  final String? mrName;
  final DateTime? startDate;
  final String? genericName;
  final String? composition;
  final String? form;
  final String? instructions;
  final int? duration;
  final String? notes;

  Prescription({
    required this.id,
    required this.patientId,
    required this.medicineName,
    required this.dosage,
    required this.frequency,
    DateTime? createdAt,
    this.isCurrent = true,
    this.manufacturer,
    this.mrName,
    this.startDate,
    this.genericName,
    this.composition,
    this.form,
    this.instructions,
    this.duration,
    this.notes,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patient_id': patientId,
      'medicine_name': medicineName,
      'dosage': dosage,
      'frequency': frequency,
      'created_at': createdAt.toIso8601String(),
      'is_current': isCurrent ? 1 : 0,
      'manufacturer': manufacturer,
      'mr_name': mrName,
      'start_date': startDate?.toIso8601String(),
      'generic_name': genericName,
      'composition': composition,
      'form': form,
      'instructions': instructions,
      'duration': duration,
      'notes': notes,
    };
  }

  factory Prescription.fromMap(Map<String, dynamic> map) {
    return Prescription(
      id: map['id'],
      patientId: map['patient_id'],
      medicineName: map['medicine_name'],
      dosage: map['dosage'],
      frequency: map['frequency'],
      createdAt: DateTime.parse(map['created_at']),
      isCurrent: map['is_current'] == 1,
      manufacturer: map['manufacturer'],
      mrName: map['mr_name'],
      startDate: map['start_date'] != null ? DateTime.parse(map['start_date']) : null,
      genericName: map['generic_name'],
      composition: map['composition'],
      form: map['form'],
      instructions: map['instructions'],
      duration: map['duration'],
      notes: map['notes'],
    );
  }
}

// Enhanced Consultation model
class Consultation {
  final String id;
  final String patientId;
  final DateTime date;
  final String reason;
  final String doctorId;
  final String doctorName;
  final String diagnosis;
  final List<String> medications;
  final String notes;
  final String prescription;
  final DateTime? followUpDate;
  final String? checkupDetails;

  Consultation({
    required this.id,
    required this.patientId,
    required this.date,
    required this.reason,
    required this.doctorId,
    required this.doctorName,
    required this.diagnosis,
    required this.medications,
    required this.notes,
    required this.prescription,
    this.followUpDate,
    this.checkupDetails,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patient_id': patientId,
      'date': date.toIso8601String(),
      'reason': reason,
      'doctor_id': doctorId,
      'doctor_name': doctorName,
      'diagnosis': diagnosis,
      'medications': jsonEncode(medications),
      'notes': notes,
      'prescription': prescription,
      'follow_up_date': followUpDate?.toIso8601String(),
      'checkup_details': checkupDetails,
    };
  }

  factory Consultation.fromMap(Map<String, dynamic> map) {
    List<String> meds = [];
    if (map['medications'] != null) {
      try {
        meds = List<String>.from(jsonDecode(map['medications']));
      } catch (_) {}
    }
    return Consultation(
      id: map['id'],
      patientId: map['patient_id'],
      date: DateTime.parse(map['date']),
      reason: map['reason'] ?? '',
      doctorId: map['doctor_id'],
      doctorName: map['doctor_name'] ?? '',
      diagnosis: map['diagnosis'] ?? '',
      medications: meds,
      notes: map['notes'] ?? '',
      prescription: map['prescription'] ?? '',
      followUpDate: map['follow_up_date'] != null 
          ? DateTime.parse(map['follow_up_date']) 
          : null,
      checkupDetails: map['checkup_details'],
    );
  }
}

// Enhanced Patient model
class Patient {
  final String id;
  final String name;
  final String token;
  final String age;
  final String gender;
  final String? address;
  final String? medicalHistory;
  final String? symptoms;
  final String? emergencyContact;
  final String mobile;
  final String? photoPath;
  PatientStatus status;
  final DateTime registrationTime;
  final List<Consultation> history;
  final String? bloodGroup;
  final String? allergies;
  final DateTime? registeredDate;
  final DateTime? lastVisit;
  final int consultationCount;
  final bool isAppointment;

  Patient({
    required this.id,
    required this.name,
    required this.token,
    required this.age,
    required this.gender,
    required this.mobile,
    this.photoPath,
    this.address,
    this.medicalHistory,
    this.symptoms,
    this.emergencyContact,
    this.status = PatientStatus.waiting,
    DateTime? registrationTime,
    List<Consultation>? history,
    this.bloodGroup,
    this.allergies,
    this.registeredDate,
    this.lastVisit,
    int? consultationCount,
    this.isAppointment = false,
  })  : registrationTime = registrationTime ?? DateTime.now(),
        consultationCount = consultationCount ?? 0,
        history = history ?? [];

  Patient copyWith({
    String? id,
    String? name,
    String? token,
    String? age,
    String? gender,
    String? mobile,
    String? photoPath,
    String? address,
    String? medicalHistory,
    String? symptoms,
    String? emergencyContact,
    PatientStatus? status,
    DateTime? registrationTime,
    List<Consultation>? history,
    String? bloodGroup,
    String? allergies,
    DateTime? registeredDate,
    DateTime? lastVisit,
    int? consultationCount,
    bool? isAppointment,
  }) {
    return Patient(
      id: id ?? this.id,
      name: name ?? this.name,
      token: token ?? this.token,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      mobile: mobile ?? this.mobile,
      photoPath: photoPath ?? this.photoPath,
      address: address ?? this.address,
      medicalHistory: medicalHistory ?? this.medicalHistory,
      symptoms: symptoms ?? this.symptoms,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      status: status ?? this.status,
      registrationTime: registrationTime ?? this.registrationTime,
      history: history ?? this.history,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      allergies: allergies ?? this.allergies,
      registeredDate: registeredDate ?? this.registeredDate,
      lastVisit: lastVisit ?? this.lastVisit,
      consultationCount: consultationCount ?? this.consultationCount,
      isAppointment: isAppointment ?? this.isAppointment,
    );
  }

  // Convert Patient to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'token': token,
      'age': age,
      'gender': gender,
      'mobile': mobile,
      'photoPath': photoPath,
      'address': address,
      'medicalHistory': medicalHistory,
      'symptoms': symptoms,
      'emergencyContact': emergencyContact,
      'status': status.index,
      'registrationTime': registrationTime.toIso8601String(),
      'history': jsonEncode(history.map((c) => c.toMap()).toList()),
      'blood_group': bloodGroup,
      'allergies': allergies,
      'registered_date': registeredDate?.toIso8601String(),
      'last_visit': lastVisit?.toIso8601String(),
      'consultation_count': consultationCount,
      'is_appointment': isAppointment ? 1 : 0,
    };
  }

  // Create Patient from Map
  factory Patient.fromMap(Map<String, dynamic> map) {
    List<dynamic> historyJson = [];
    if (map['history'] != null) {
      try {
        historyJson = jsonDecode(map['history']);
      } catch (_) {}
    }

    // Robust status parsing
    PatientStatus parsedStatus = PatientStatus.waiting;
    if (map['status'] != null) {
      if (map['status'] is int) {
        int idx = map['status'];
        if (idx >= 0 && idx < PatientStatus.values.length) {
          parsedStatus = PatientStatus.values[idx];
        }
      } else if (map['status'] is String) {
        // Handle potential string storage
        String statusStr = map['status'].toString().toLowerCase();
        if (statusStr == 'waiting') parsedStatus = PatientStatus.waiting;
        else if (statusStr == 'inprogress') parsedStatus = PatientStatus.inProgress;
        else if (statusStr == 'completed') parsedStatus = PatientStatus.completed;
      }
    }

    return Patient(
      id: map['id'],
      name: map['name'],
      token: map['token'],
      age: map['age'],
      gender: map['gender'],
      mobile: map['mobile'],
      photoPath: map['photoPath'],
      address: map['address'],
      medicalHistory: map['medicalHistory'],
      symptoms: map['symptoms'],
      emergencyContact: map['emergencyContact'],
      status: parsedStatus,
      registrationTime: DateTime.parse(map['registrationTime']),
      history: historyJson.map((e) => Consultation.fromMap(e)).toList(),
      bloodGroup: map['blood_group'],
      allergies: map['allergies'],
      registeredDate: map['registered_date'] != null ? DateTime.parse(map['registered_date']) : null,
      lastVisit: map['last_visit'] != null ? DateTime.parse(map['last_visit']) : null,
      consultationCount: map['consultation_count'] ?? 0,
      isAppointment: map['is_appointment'] == 1,
    );
  }
}

// Appointment model
class Appointment {
  final String id;
  final String patientName;
  final String mobile;
  final DateTime date;
  final String time;
  final String type;
  final String reason;
  String status; // 'pending', 'confirmed', 'rejected'
  final DateTime createdAt;
  
  // New fields for verification system
  final String? patientId; // Links to Patient record after registration
  final String? patientImage; // Cached from patient record
  final String? rejectionReason; // Reason if rejected
  final DateTime? verifiedAt; // When registration was completed

  Appointment({
    required this.id,
    required this.patientName,
    required this.mobile,
    required this.date,
    required this.time,
    required this.type,
    required this.reason,
    this.status = 'pending',
    DateTime? createdAt,
    this.patientId,
    this.patientImage,
    this.rejectionReason,
    this.verifiedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patient_name': patientName,
      'mobile': mobile,
      'date': date.toIso8601String(),
      'time': time,
      'type': type,
      'reason': reason,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'patient_id': patientId,
      'patient_image': patientImage,
      'rejection_reason': rejectionReason,
      'verified_at': verifiedAt?.toIso8601String(),
    };
  }

  factory Appointment.fromMap(Map<String, dynamic> map) {
    return Appointment(
      id: map['id'],
      patientName: map['patient_name'],
      mobile: map['mobile'],
      date: DateTime.parse(map['date']),
      time: map['time'],
      type: map['type'],
      reason: map['reason'],
      status: map['status'] ?? 'pending',
      createdAt: DateTime.parse(map['created_at']),
      patientId: map['patient_id'],
      patientImage: map['patient_image'],
      rejectionReason: map['rejection_reason'],
      verifiedAt: map['verified_at'] != null ? DateTime.parse(map['verified_at']) : null,
    );
  }
  
  // Helper method to create a copy with updated fields
  Appointment copyWith({
    String? status,
    String? patientId,
    String? patientImage,
    String? rejectionReason,
    DateTime? verifiedAt,
  }) {
    return Appointment(
      id: id,
      patientName: patientName,
      mobile: mobile,
      date: date,
      time: time,
      type: type,
      reason: reason,
      status: status ?? this.status,
      createdAt: createdAt,
      patientId: patientId ?? this.patientId,
      patientImage: patientImage ?? this.patientImage,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      verifiedAt: verifiedAt ?? this.verifiedAt,
    );
  }
}

// Payment model
class Payment {
  final String id;
  final String patientId;
  final String patientName;
  final String token;
  final double amount;
  final String status; // 'pending', 'paid'
  final DateTime date;
  final DateTime? paymentDate;
  final String? paymentMethod; // 'Cash', 'Card', 'UPI'
  final String? notes;

  Payment({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.token,
    required this.amount,
    this.status = 'pending',
    required this.date,
    this.paymentDate,
    this.paymentMethod,
    this.notes,
  });

  Payment copyWith({
    String? id,
    String? patientId,
    String? patientName,
    String? token,
    double? amount,
    String? status,
    DateTime? date,
    DateTime? paymentDate,
    String? paymentMethod,
    String? notes,
  }) {
    return Payment(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      token: token ?? this.token,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      date: date ?? this.date,
      paymentDate: paymentDate ?? this.paymentDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patient_id': patientId,
      'patient_name': patientName,
      'token': token,
      'amount': amount,
      'status': status,
      'date': date.toIso8601String(),
      'payment_date': paymentDate?.toIso8601String(),
      'payment_method': paymentMethod,
      'notes': notes,
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'],
      patientId: map['patient_id'],
      patientName: map['patient_name'],
      token: map['token'],
      amount: map['amount'].toDouble(),
      status: map['status'] ?? 'pending',
      date: DateTime.parse(map['date']),
      paymentDate: map['payment_date'] != null ? DateTime.parse(map['payment_date']) : null,
      paymentMethod: map['payment_method'],
      notes: map['notes'],
    );
  }
}

// Payment Installment - For tracking bills with partial payments
class PaymentInstallment {
  final String id;
  final String patientId;
  final String patientName;
  final String? appointmentId;
  final double totalAmount;
  final double instrumentCharges;
  final double serviceCharges;
  final DateTime createdAt;
  final String status; // 'PENDING', 'PARTIAL', 'FULL_PAID'
  final double paidAmount;
  final double remainingAmount;
  final String? paymentFor; // What the payment is for (Consultation, Medicine, Procedure, Lab Test, etc.)

  PaymentInstallment({
    required this.id,
    required this.patientId,
    required this.patientName,
    this.appointmentId,
    required this.totalAmount,
    this.instrumentCharges = 0.0,
    this.serviceCharges = 0.0,
    DateTime? createdAt,
    this.status = 'PENDING',
    this.paidAmount = 0.0,
    double? remainingAmount,
    this.paymentFor,
  }) : createdAt = createdAt ?? DateTime.now(),
       remainingAmount = remainingAmount ?? totalAmount;

  PaymentInstallment copyWith({
    String? id,
    String? patientId,
    String? patientName,
    String? appointmentId,
    double? totalAmount,
    double? instrumentCharges,
    double? serviceCharges,
    DateTime? createdAt,
    String? status,
    double? paidAmount,
    double? remainingAmount,
    String? paymentFor,
  }) {
    return PaymentInstallment(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      appointmentId: appointmentId ?? this.appointmentId,
      totalAmount: totalAmount ?? this.totalAmount,
      instrumentCharges: instrumentCharges ?? this.instrumentCharges,
      serviceCharges: serviceCharges ?? this.serviceCharges,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      paidAmount: paidAmount ?? this.paidAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      paymentFor: paymentFor ?? this.paymentFor,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patient_id': patientId,
      'patient_name': patientName,
      'appointment_id': appointmentId,
      'total_amount': totalAmount,
      'instrument_charges': instrumentCharges,
      'service_charges': serviceCharges,
      'created_at': createdAt.toIso8601String(),
      'status': status,
      'paid_amount': paidAmount,
      'remaining_amount': remainingAmount,
      'payment_for': paymentFor,
    };
  }

  factory PaymentInstallment.fromMap(Map<String, dynamic> map) {
    return PaymentInstallment(
      id: map['id'],
      patientId: map['patient_id'],
      patientName: map['patient_name'] ?? '',
      appointmentId: map['appointment_id'],
      totalAmount: (map['total_amount'] ?? 0).toDouble(),
      instrumentCharges: (map['instrument_charges'] ?? 0).toDouble(),
      serviceCharges: (map['service_charges'] ?? 0).toDouble(),
      createdAt: DateTime.parse(map['created_at']),
      status: map['status'] ?? 'PENDING',
      paidAmount: (map['paid_amount'] ?? 0).toDouble(),
      remainingAmount: (map['remaining_amount'] ?? map['total_amount'] ?? 0).toDouble(),
      paymentFor: map['payment_for'],
    );
  }
}

// Payment Transaction - Individual payment record for an installment
class PaymentTransaction {
  final String id;
  final String paymentId; // References PaymentInstallment
  final double amountPaid;
  final DateTime paymentDate;
  final String paymentMode; // 'Cash', 'UPI', 'Card', 'Cheque'
  final String receivedBy; // Staff/Doctor name
  final String receiptNumber;
  final String? notes;

  PaymentTransaction({
    required this.id,
    required this.paymentId,
    required this.amountPaid,
    DateTime? paymentDate,
    required this.paymentMode,
    required this.receivedBy,
    required this.receiptNumber,
    this.notes,
  }) : paymentDate = paymentDate ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'payment_id': paymentId,
      'amount_paid': amountPaid,
      'payment_date': paymentDate.toIso8601String(),
      'payment_mode': paymentMode,
      'received_by': receivedBy,
      'receipt_number': receiptNumber,
      'notes': notes,
    };
  }

  factory PaymentTransaction.fromMap(Map<String, dynamic> map) {
    return PaymentTransaction(
      id: map['id'],
      paymentId: map['payment_id'],
      amountPaid: (map['amount_paid'] ?? 0).toDouble(),
      paymentDate: DateTime.parse(map['payment_date']),
      paymentMode: map['payment_mode'] ?? 'Cash',
      receivedBy: map['received_by'] ?? '',
      receiptNumber: map['receipt_number'] ?? '',
      notes: map['notes'],
    );
  }
}

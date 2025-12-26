<div align="center">

# 🏥 MODI
### Medical OPD Digital Interface

**Enterprise-Grade Healthcare Management Platform**

[![Version](https://img.shields.io/badge/Version-2.0.0-blue.svg)](https://github.com)
[![Flutter](https://img.shields.io/badge/Flutter-3.16.0-02569B.svg?logo=flutter)](https://flutter.dev)
[![License](https://img.shields.io/badge/License-Proprietary-red.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%20|%20iOS%20|%20Web%20|%20Desktop-green.svg)](https://flutter.dev)

---

*Transforming Healthcare Operations with Intelligent Digital Solutions*

**Developed by:** Singh Technologies Pvt. Ltd.  
**Last Updated:** December 15, 2025  
**Document Version:** 3.0

</div>

---

## 📋 Table of Contents

| Section | Description |
|:--------|:------------|
| [1. Executive Summary](#1-executive-summary) | Project overview and business value |
| [2. System Architecture](#2-system-architecture) | Technical architecture and design patterns |
| [3. Core Modules](#3-core-modules) | Detailed feature documentation |
| [4. User Interface](#4-user-interface-design-system) | Design system and UI/UX guidelines |
| [5. Security Framework](#5-security-framework) | Data protection and authentication |
| [6. Integration APIs](#6-integration-apis) | Third-party integrations |
| [7. Deployment Guide](#7-deployment-guide) | Installation and configuration |
| [8. Performance Metrics](#8-performance-metrics) | Benchmarks and optimization |
| [9. Roadmap](#9-product-roadmap) | Future enhancements |
| [10. Support](#10-support--maintenance) | Technical support information |

---

# 1. Executive Summary

## 1.1 Product Vision

**MODI (Medical OPD Digital Interface)** is a comprehensive, enterprise-grade healthcare management platform designed to revolutionize the way medical clinics and hospitals manage their outpatient departments. Built with cutting-edge technology and industry best practices, MODI provides an end-to-end solution for patient management, clinical operations, and business intelligence.

## 1.2 Business Value Proposition

| Benefit | Impact |
|:--------|:-------|
| **Operational Efficiency** | 70% reduction in administrative workload |
| **Patient Experience** | 85% improvement in patient satisfaction scores |
| **Revenue Optimization** | 40% decrease in payment collection delays |
| **Data Accuracy** | 99.9% elimination of manual data entry errors |
| **Time Savings** | Average 2 hours saved per healthcare provider daily |

## 1.3 Target Users

```
┌─────────────────────────────────────────────────────────────┐
│                    MODI USER ECOSYSTEM                       │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   👨‍⚕️ DOCTORS                    👩‍💼 CLINICAL STAFF           │
│   ├─ General Practitioners       ├─ Receptionists            │
│   ├─ Specialists                 ├─ Billing Officers         │
│   ├─ Consultants                 ├─ Patient Coordinators     │
│   └─ Surgeons                    └─ Administrative Staff     │
│                                                              │
│   🏥 HEALTHCARE FACILITIES        👥 PATIENTS                 │
│   ├─ Private Clinics             ├─ Walk-in Patients         │
│   ├─ Polyclinics                 ├─ Registered Patients      │
│   ├─ Small Hospitals             └─ Follow-up Patients       │
│   └─ Multi-specialty Centers                                 │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## 1.4 Key Differentiators

| Feature | MODI | Traditional Systems |
|:--------|:----:|:-------------------:|
| Cross-Platform Support | ✅ | ❌ |
| Offline Functionality | ✅ | ❌ |
| Real-time Analytics | ✅ | ❌ |
| WhatsApp Integration | ✅ | ❌ |
| Smart QR System | ✅ | ❌ |
| Voice Prescriptions | ✅ | ❌ |
| Waiting Room Display | ✅ | ❌ |
| Birthday Automation | ✅ | ❌ |

---

# 2. System Architecture

## 2.1 High-Level Architecture

```
╔══════════════════════════════════════════════════════════════════╗
║                      MODI SYSTEM ARCHITECTURE                      ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                    ║
║  ┌─────────────────────────────────────────────────────────────┐  ║
║  │                    PRESENTATION LAYER                        │  ║
║  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐       │  ║
║  │  │  Mobile  │ │  Tablet  │ │  Desktop │ │   Web    │       │  ║
║  │  │   App    │ │   App    │ │   App    │ │   App    │       │  ║
║  │  └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘       │  ║
║  └───────┼────────────┼────────────┼────────────┼──────────────┘  ║
║          │            │            │            │                  ║
║  ┌───────┴────────────┴────────────┴────────────┴──────────────┐  ║
║  │                    FLUTTER FRAMEWORK                         │  ║
║  │           (Unified Codebase - Dart Programming)              │  ║
║  └─────────────────────────┬───────────────────────────────────┘  ║
║                            │                                       ║
║  ┌─────────────────────────┴───────────────────────────────────┐  ║
║  │                   BUSINESS LOGIC LAYER                       │  ║
║  │  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐         │  ║
║  │  │ Auth Service │ │Patient Mgmt  │ │Payment Engine│         │  ║
║  │  ├──────────────┤ ├──────────────┤ ├──────────────┤         │  ║
║  │  │Consultation  │ │ Appointment  │ │  Analytics   │         │  ║
║  │  │   Engine     │ │   Handler    │ │   Engine     │         │  ║
║  │  └──────────────┘ └──────────────┘ └──────────────┘         │  ║
║  └─────────────────────────┬───────────────────────────────────┘  ║
║                            │                                       ║
║  ┌─────────────────────────┴───────────────────────────────────┐  ║
║  │                    DATA ACCESS LAYER                         │  ║
║  │              (DatabaseHelper - Singleton Pattern)            │  ║
║  └─────────────────────────┬───────────────────────────────────┘  ║
║                            │                                       ║
║  ┌─────────────────────────┴───────────────────────────────────┐  ║
║  │                     STORAGE LAYER                            │  ║
║  │  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐         │  ║
║  │  │   SQLite     │ │SharedPrefs   │ │ File System  │         │  ║
║  │  │  Database    │ │ (Settings)   │ │  (Photos)    │         │  ║
║  │  └──────────────┘ └──────────────┘ └──────────────┘         │  ║
║  └─────────────────────────────────────────────────────────────┘  ║
║                                                                    ║
╚══════════════════════════════════════════════════════════════════╝
```

## 2.2 Technology Stack

### Core Technologies

| Layer | Technology | Version | Purpose |
|:------|:-----------|:--------|:--------|
| **Frontend** | Flutter | 3.16.0 | Cross-platform UI framework |
| **Language** | Dart | 3.2.0 | Programming language |
| **Database** | SQLite | 3.x | Local persistent storage |
| **State** | Provider/setState | - | State management |
| **UI Kit** | Material Design 3 | - | Design system |

### Dependencies Matrix

| Package | Version | Category | Description |
|:--------|:--------|:---------|:------------|
| `sqflite` | ^2.3.0 | Database | SQLite database plugin |
| `pdf` | ^3.10.0 | Document | PDF generation engine |
| `printing` | ^5.11.0 | Document | Print functionality |
| `fl_chart` | ^0.65.0 | Analytics | Charts and graphs |
| `image_picker` | ^1.0.0 | Media | Camera/gallery access |
| `image_cropper` | ^5.0.0 | Media | Image editing tools |
| `url_launcher` | ^6.2.0 | Integration | External app launcher |
| `permission_handler` | ^11.0.0 | System | Runtime permissions |
| `table_calendar` | ^3.0.0 | UI | Calendar widget |
| `intl` | ^0.18.0 | Utility | Internationalization |
| `qr_flutter` | ^4.1.0 | Utility | QR code generation |
| `share_plus` | ^7.2.0 | Integration | Share functionality |
| `path_provider` | ^2.1.0 | System | File system paths |
| `crypto` | ^3.0.0 | Security | Encryption utilities |

## 2.3 Design Patterns Implemented

| Pattern | Implementation | Benefits |
|:--------|:---------------|:---------|
| **Singleton** | DatabaseHelper | Single database instance, memory efficient |
| **Repository** | Data Layer | Separation of concerns, testability |
| **Factory** | Widget Builders | Dynamic widget creation |
| **Observer** | State Management | Reactive UI updates |
| **Strategy** | Payment Methods | Flexible payment processing |
| **Builder** | PDF Generation | Complex document construction |

---

# 3. Core Modules

## 3.1 🔐 Authentication & Security Module

### Overview
Enterprise-grade authentication system with multi-factor security, session management, and role-based access control (RBAC).

### Features

#### 3.1.1 Doctor Authentication Portal
| Feature | Description | Status |
|:--------|:------------|:------:|
| Email/Password Login | Secure credential-based authentication | ✅ |
| Password Encryption | SHA-256 with unique salt per user | ✅ |
| Session Management | Auto-logout on inactivity | ✅ |
| Remember Me | Secure token-based quick login | ✅ |
| Password Strength Meter | Real-time password validation | ✅ |
| Brute Force Protection | Account lockout after failed attempts | ✅ |

#### 3.1.2 Staff Authentication Portal
| Feature | Description | Status |
|:--------|:------------|:------:|
| Role-Based Login | Different permissions per role | ✅ |
| Limited Access Mode | Restricted feature access | ✅ |
| Activity Logging | Track staff actions | ✅ |
| Multi-Staff Support | Multiple staff accounts | ✅ |

#### 3.1.3 Password Recovery System
| Feature | Description | Status |
|:--------|:------------|:------:|
| Email Verification | Secure reset link via email | ✅ |
| Security Questions | Alternative recovery method | ✅ |
| Password Reset Tool | Admin password management | ✅ |
| Expiring Reset Links | Time-limited security tokens | ✅ |

### Security Implementation

```dart
/// Password Security Architecture
/// 
/// ┌─────────────────────────────────────────────────────────┐
/// │              PASSWORD SECURITY FLOW                      │
/// ├─────────────────────────────────────────────────────────┤
/// │                                                          │
/// │  User Password ──► Generate Salt ──► Combine            │
/// │                                          │               │
/// │                                          ▼               │
/// │                                    SHA-256 Hash          │
/// │                                          │               │
/// │                                          ▼               │
/// │                               Store Hash + Salt          │
/// │                                  in Database             │
/// │                                                          │
/// │  Login Attempt ──► Retrieve Salt ──► Hash Input         │
/// │                                          │               │
/// │                                          ▼               │
/// │                               Compare with Stored        │
/// │                                          │               │
/// │                                          ▼               │
/// │                              ✅ Match: Grant Access      │
/// │                              ❌ Mismatch: Deny Access    │
/// │                                                          │
/// └─────────────────────────────────────────────────────────┘
```

---

## 3.2 👥 Patient Management Module

### Overview
Comprehensive patient lifecycle management from registration to discharge, with complete medical history tracking and intelligent data organization.

### Features

#### 3.2.1 Patient Registration System

| Field Category | Fields Captured | Data Type |
|:---------------|:----------------|:----------|
| **Personal Information** | Full Name, Gender, Date of Birth, Age (Auto-calculated) | Text, Enum, Date |
| **Contact Details** | Mobile Number, Email, Address, Emergency Contact | Phone, Email, Text |
| **Medical Profile** | Blood Group, Allergies, Medical History, Current Medications | Enum, Text |
| **Documentation** | Patient Photo, ID Documents | Image/Blob |
| **System Generated** | Patient ID, Registration Date, QR Code | Auto |

#### 3.2.2 Smart Search Engine

```
┌─────────────────────────────────────────────────────────────┐
│                  INTELLIGENT SEARCH SYSTEM                   │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  SEARCH METHODS:                                             │
│  ├─ 🔤 Name Search (Fuzzy matching enabled)                 │
│  ├─ 📱 Phone Number Search (Partial match)                  │
│  ├─ 🔢 Patient ID Lookup (Exact match)                      │
│  ├─ 📷 QR Code Scan (Instant retrieval)                     │
│  └─ 📅 Date-based Search (Registration/Visit date)          │
│                                                              │
│  ADVANCED FILTERS:                                           │
│  ├─ Gender Filter                                            │
│  ├─ Age Range Filter                                         │
│  ├─ Blood Group Filter                                       │
│  ├─ Visit Status (Today/This Week/This Month)               │
│  └─ Payment Status (Paid/Pending)                            │
│                                                              │
│  PERFORMANCE:                                                │
│  ├─ Average Search Time: < 50ms                              │
│  ├─ Results Pagination: 50 records per page                  │
│  └─ Real-time as-you-type suggestions                        │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

#### 3.2.3 Patient Profile Management

| Feature | Description | Capabilities |
|:--------|:------------|:-------------|
| **Photo Management** | High-quality patient photos | Camera capture, Gallery import, Crop & resize |
| **Medical Timeline** | Visual history of all interactions | Consultations, Payments, Reports |
| **Quick Actions** | One-tap communication | Call, SMS, WhatsApp, Email |
| **Document Storage** | Attach medical documents | Lab reports, X-rays, Prescriptions |
| **QR Card Generation** | Unique patient identification | Print-ready QR cards with patient info |

#### 3.2.4 Patient QR Code System

```
┌─────────────────────────────────────────────────────────────┐
│                    QR CODE ARCHITECTURE                      │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  QR CODE STRUCTURE:                                          │
│  ┌───────────────────────────────────────┐                  │
│  │  ╔═══════════╗  ┌─────────────────┐  │                  │
│  │  ║    QR     ║  │ Patient Name    │  │                  │
│  │  ║   CODE    ║  │ ID: MODI-001234 │  │                  │
│  │  ║           ║  │ Ph: 98XXXXX890  │  │                  │
│  │  ╚═══════════╝  │ Blood: O+       │  │                  │
│  │                  └─────────────────┘  │                  │
│  │  [Clinic Logo & Name]                 │                  │
│  └───────────────────────────────────────┘                  │
│                                                              │
│  ENCODED DATA:                                               │
│  ├─ Deep Link URL to Patient Web Report                     │
│  ├─ Patient Unique Identifier                                │
│  ├─ Encrypted Patient Hash                                   │
│  └─ Clinic Identifier                                        │
│                                                              │
│  USE CASES:                                                  │
│  ├─ Quick Patient Check-in                                   │
│  ├─ Instant Medical History Access                           │
│  ├─ Emergency Information Display                            │
│  └─ Share Patient Report via QR Scan                         │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 3.3 🏥 Clinical Consultation Module

### Overview
End-to-end consultation management from patient queue to prescription generation, with intelligent medicine suggestions and digital prescription delivery.

### Features

#### 3.3.1 Consultation Workflow

```
┌─────────────────────────────────────────────────────────────┐
│               CONSULTATION WORKFLOW ENGINE                    │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  STEP 1: PATIENT CHECK-IN                                    │
│  ├─ Token Generation (Auto-sequential)                       │
│  ├─ Queue Assignment                                         │
│  ├─ Vital Signs Recording (Optional)                         │
│  └─ Waiting Room Display Update                              │
│                          │                                   │
│                          ▼                                   │
│  STEP 2: DOCTOR CONSULTATION                                 │
│  ├─ Patient History Review                                   │
│  ├─ Chief Complaints Entry                                   │
│  ├─ Examination Notes                                        │
│  ├─ Diagnosis Entry                                          │
│  └─ Treatment Plan                                           │
│                          │                                   │
│                          ▼                                   │
│  STEP 3: PRESCRIPTION GENERATION                             │
│  ├─ Medicine Selection (with suggestions)                    │
│  ├─ Dosage & Duration                                        │
│  ├─ Special Instructions                                     │
│  ├─ Follow-up Scheduling                                     │
│  └─ PDF Generation                                           │
│                          │                                   │
│                          ▼                                   │
│  STEP 4: DELIVERY & BILLING                                  │
│  ├─ Print Prescription                                       │
│  ├─ WhatsApp/Email Prescription                              │
│  ├─ Payment Processing                                       │
│  └─ Next Appointment Booking                                 │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

#### 3.3.2 Medicine Database

| Feature | Specification |
|:--------|:--------------|
| **Database Size** | 10,000+ medicines |
| **Categories** | 50+ therapeutic categories |
| **Search** | Generic name, Brand name, Salt composition |
| **Auto-complete** | Real-time suggestions as you type |
| **Dosage Forms** | Tablets, Capsules, Syrups, Injections, etc. |
| **Dosage Presets** | Common dosing patterns pre-configured |

#### 3.3.3 Prescription Templates

| Template Type | Use Case | Customizable |
|:--------------|:---------|:------------:|
| General Consultation | Common ailments | ✅ |
| Follow-up Visit | Continuing treatment | ✅ |
| Chronic Disease | Long-term medications | ✅ |
| Pediatric | Child-specific dosing | ✅ |
| Emergency | Quick prescriptions | ✅ |

#### 3.3.4 Voice Prescription (Beta)

| Feature | Status | Description |
|:--------|:------:|:------------|
| Speech-to-Text | 🔄 | Dictate prescriptions hands-free |
| Medicine Recognition | 🔄 | Auto-identify medicine names |
| Dosage Parsing | 🔄 | Extract dosing from speech |
| Language Support | 🔄 | Hindi & English |

---

## 3.4 💰 Financial Management Module

### Overview
Complete revenue cycle management including consultation fees, payment processing, installment management, and comprehensive financial reporting.

### Features

#### 3.4.1 Payment Processing Engine

```
┌─────────────────────────────────────────────────────────────┐
│                  PAYMENT PROCESSING FLOW                     │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  PAYMENT METHODS SUPPORTED:                                  │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐       │
│  │   CASH   │ │   UPI    │ │   CARD   │ │  ONLINE  │       │
│  │    💵    │ │    📱    │ │    💳    │ │    🌐    │       │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘       │
│                                                              │
│  PAYMENT PURPOSES:                                           │
│  ├─ Consultation Fee (Configurable)                          │
│  ├─ Medicine Charges                                         │
│  ├─ Lab Test Fees                                            │
│  ├─ Procedure Charges                                        │
│  ├─ Follow-up Fee (Discounted)                               │
│  └─ Other Services                                           │
│                                                              │
│  PAYMENT STATUS:                                             │
│  ├─ ✅ PAID (Full amount received)                           │
│  ├─ ⏳ PENDING (No payment received)                         │
│  ├─ 🔄 PARTIAL (Partial payment received)                    │
│  └─ 📅 INSTALLMENT (EMI in progress)                         │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

#### 3.4.2 Installment Management (EMI)

| Feature | Description |
|:--------|:------------|
| **EMI Calculator** | Auto-calculate installment amounts |
| **Flexible Tenures** | 2, 3, 6, 12 month options |
| **Due Date Tracking** | Automated due date assignment |
| **Payment Reminders** | SMS/WhatsApp reminders before due date |
| **Transaction Ledger** | Account-style transaction history |
| **Interest-Free EMI** | Optional interest configuration |

#### 3.4.3 Invoice Generation

| Invoice Elements | Included |
|:-----------------|:--------:|
| Clinic Header with Logo | ✅ |
| Patient Information | ✅ |
| Itemized Services | ✅ |
| Tax Breakdown (if applicable) | ✅ |
| Payment Method | ✅ |
| Digital Signature | ✅ |
| QR Code for Verification | ✅ |
| Terms & Conditions | ✅ |

#### 3.4.4 Financial Reports

| Report Type | Frequency | Format |
|:------------|:----------|:-------|
| Daily Collection Summary | Daily | PDF/Screen |
| Weekly Revenue Report | Weekly | PDF/Excel |
| Monthly Financial Statement | Monthly | PDF/Excel |
| Outstanding Dues Report | On-demand | PDF |
| Payment Mode Analysis | On-demand | Charts |
| Patient-wise Ledger | On-demand | PDF |

---

## 3.5 📅 Appointment Management Module

### Overview
Intelligent scheduling system with conflict detection, automated reminders, and seamless integration with consultation workflow.

### Features

#### 3.5.1 Appointment Booking System

```
┌─────────────────────────────────────────────────────────────┐
│                APPOINTMENT BOOKING SYSTEM                    │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  BOOKING CHANNELS:                                           │
│  ├─ In-Clinic Booking (Staff)                                │
│  ├─ Phone Booking (Staff-assisted)                           │
│  └─ Walk-in Registration                                     │
│                                                              │
│  INTELLIGENT FEATURES:                                       │
│  ├─ Slot Availability Check                                  │
│  ├─ Conflict Detection                                       │
│  ├─ Doctor Leave Integration                                 │
│  ├─ Holiday Calendar Sync                                    │
│  ├─ Estimated Wait Time Display                              │
│  └─ Auto-suggest Next Available Slot                         │
│                                                              │
│  APPOINTMENT TYPES:                                          │
│  ├─ 🆕 New Consultation                                      │
│  ├─ 🔄 Follow-up Visit                                       │
│  ├─ 💉 Procedure Appointment                                 │
│  ├─ 🧪 Lab Visit                                             │
│  └─ ⚡ Emergency                                             │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

#### 3.5.2 Token Management System

| Feature | Description |
|:--------|:------------|
| **Auto Token Generation** | Sequential token numbers per day |
| **Token Display** | Large screen waiting room display |
| **Voice Announcement** | Audio call for token numbers |
| **Skip/Defer Token** | Handle patient delays |
| **Priority Tokens** | Emergency & VIP patients |
| **Token History** | Daily token logs |

#### 3.5.3 Waiting Room Display

```
┌─────────────────────────────────────────────────────────────┐
│              WAITING ROOM TV DISPLAY SYSTEM                  │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  DISPLAY MODES:                                              │
│  ┌─────────────────────────────────────────┐                │
│  │  CURRENT TOKEN                          │                │
│  │  ╔════════════════════════════════╗    │                │
│  │  ║         NOW SERVING            ║    │                │
│  │  ║                                ║    │                │
│  │  ║       TOKEN: 0 2 5            ║    │                │
│  │  ║                                ║    │                │
│  │  ║     Patient: Rajesh K.         ║    │                │
│  │  ╚════════════════════════════════╝    │                │
│  │                                         │                │
│  │  NEXT IN QUEUE:                         │                │
│  │  026 → 027 → 028 → 029                  │                │
│  │                                         │                │
│  │  [Advertisement Banner Space]           │                │
│  └─────────────────────────────────────────┘                │
│                                                              │
│  FEATURES:                                                   │
│  ├─ Full-screen optimized for TV                            │
│  ├─ Auto-refresh every 5 seconds                            │
│  ├─ Advertisement rotation                                   │
│  ├─ Clinic branding                                          │
│  ├─ Patient photo display (optional)                         │
│  └─ Estimated wait time                                      │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

#### 3.5.4 Follow-up Management

| Feature | Description |
|:--------|:------------|
| **Auto Follow-up Scheduling** | Schedule at consultation end |
| **Reminder System** | 1 day before reminders |
| **Follow-up Tracking** | Dashboard widget for pending follow-ups |
| **Overdue Alerts** | Highlight missed follow-ups |
| **One-click Booking** | Quick reschedule options |

---

## 3.6 📡 Communication & Integration Module

### Overview
Multi-channel patient communication system with deep integration into WhatsApp, SMS, and email platforms for seamless patient engagement.

### Features

#### 3.6.1 WhatsApp Integration

```
┌─────────────────────────────────────────────────────────────┐
│                 WHATSAPP INTEGRATION                         │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  CAPABILITIES:                                               │
│  ├─ 📤 Send Prescription PDF                                │
│  ├─ 📅 Appointment Reminders                                │
│  ├─ 💰 Payment Reminders                                    │
│  ├─ 🎂 Birthday Wishes                                      │
│  ├─ 📋 Lab Report Sharing                                   │
│  └─ 💬 Custom Messages                                      │
│                                                              │
│  MESSAGE TEMPLATES:                                          │
│  ┌─────────────────────────────────────────┐                │
│  │ 🏥 *Modi Clinic*                        │                │
│  │                                          │                │
│  │ Dear {Patient Name},                     │                │
│  │                                          │                │
│  │ This is a reminder for your             │                │
│  │ appointment tomorrow at 10:30 AM.        │                │
│  │                                          │                │
│  │ Doctor: Dr. {Doctor Name}                │                │
│  │ Token: {Token Number}                    │                │
│  │                                          │                │
│  │ Please arrive 10 minutes early.          │                │
│  │                                          │                │
│  │ Thank you! 🙏                            │                │
│  └─────────────────────────────────────────┘                │
│                                                              │
│  BULK MESSAGING:                                             │
│  ├─ Select multiple patients                                 │
│  ├─ Filter by criteria (Birthday/Pending/etc.)              │
│  ├─ Personalized message merge                               │
│  └─ Sequential sending (WhatsApp compliant)                  │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

#### 3.6.2 SMS Integration

| Feature | Description |
|:--------|:------------|
| **Single SMS** | One-tap SMS from patient profile |
| **Bulk SMS** | Message multiple patients |
| **Templates** | Pre-defined message templates |
| **Personalization** | Auto-fill patient name, date, amount |
| **Character Count** | Real-time SMS length indicator |
| **History** | Track sent messages |

#### 3.6.3 Birthday Notification System

```
┌─────────────────────────────────────────────────────────────┐
│              BIRTHDAY NOTIFICATION SYSTEM                    │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  FEATURES:                                                   │
│  ├─ Automatic birthday detection from DOB                   │
│  ├─ Dashboard widget showing today's birthdays              │
│  ├─ Notification count badge                                 │
│  ├─ Age calculation display                                  │
│  └─ Bulk birthday wishes                                     │
│                                                              │
│  BIRTHDAY MESSAGE:                                           │
│  ┌─────────────────────────────────────────┐                │
│  │ 🎂🎉 *HAPPY BIRTHDAY!* 🎉🎂            │                │
│  │                                          │                │
│  │ Dear {Patient Name},                     │                │
│  │                                          │                │
│  │ Wishing you a very Happy Birthday        │                │
│  │ filled with joy, happiness, and          │                │
│  │ good health!                             │                │
│  │                                          │                │
│  │ May this year bring you lots of          │                │
│  │ wonderful moments! 🌟                    │                │
│  │                                          │                │
│  │ With warm wishes,                        │                │
│  │ *{Clinic Name}*                          │                │
│  │ {Doctor Name}                            │                │
│  └─────────────────────────────────────────┘                │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

#### 3.6.4 Email Service

| Feature | Description |
|:--------|:------------|
| **SMTP Configuration** | Custom email server setup |
| **PDF Attachments** | Send prescriptions, reports |
| **HTML Templates** | Professional email formatting |
| **Delivery Status** | Track sent emails |

---

## 3.7 📊 Analytics & Reporting Module

### Overview
Comprehensive business intelligence platform providing real-time insights into clinic operations, patient demographics, and revenue metrics.

### Features

#### 3.7.1 Dashboard Analytics

```
┌─────────────────────────────────────────────────────────────┐
│                  ANALYTICS DASHBOARD                         │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  KEY METRICS (Real-time):                                    │
│  ┌────────────┐ ┌────────────┐ ┌────────────┐ ┌────────────┐│
│  │Today's     │ │ Today's    │ │ Pending    │ │ Follow-ups ││
│  │Patients    │ │ Revenue    │ │ Payments   │ │ Due        ││
│  │    25      │ │  ₹15,000   │ │  ₹8,500    │ │    12      ││
│  │  ↑ 12%     │ │   ↑ 8%     │ │   ↓ 5%     │ │   ↑ 3%     ││
│  └────────────┘ └────────────┘ └────────────┘ └────────────┘│
│                                                              │
│  CHARTS:                                                     │
│  ├─ 📈 Daily Patient Trend (Line Chart)                     │
│  ├─ 📊 Revenue Analysis (Bar Chart)                         │
│  ├─ 🥧 Payment Mode Distribution (Pie Chart)                │
│  ├─ 📉 Monthly Comparison (Area Chart)                      │
│  └─ 📋 Patient Demographics (Donut Chart)                   │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

#### 3.7.2 Available Reports

| Report Category | Reports Included |
|:----------------|:-----------------|
| **Patient Reports** | Registration Stats, Demographics, Visit Frequency |
| **Financial Reports** | Daily/Weekly/Monthly Revenue, Outstanding Dues |
| **Clinical Reports** | Consultation Count, Disease Patterns, Referrals |
| **Operational Reports** | Peak Hours Analysis, Staff Performance, Wait Times |
| **Custom Reports** | User-defined date ranges and filters |

#### 3.7.3 Export Formats

| Format | Use Case |
|:-------|:---------|
| **PDF** | Print-ready professional reports |
| **Excel** | Data analysis and manipulation |
| **On-Screen** | Quick dashboard viewing |
| **Charts** | Visual data representation |

---

## 3.8 ⚙️ Settings & Configuration Module

### Overview
Comprehensive configuration center for customizing every aspect of the clinic management system.

### Features

#### 3.8.1 Clinic Profile Settings

| Setting | Options |
|:--------|:--------|
| **Clinic Name** | Text input |
| **Clinic Logo** | Image upload |
| **Address** | Multi-line text |
| **Contact Numbers** | Multiple phone numbers |
| **Email** | Clinic email address |
| **Website** | Clinic website URL |
| **Operating Hours** | Day-wise timing |
| **Specializations** | Multiple selection |

#### 3.8.2 Fee Configuration

| Fee Type | Configuration Options |
|:---------|:---------------------|
| **Consultation Fee** | Amount, different for new/follow-up |
| **Follow-up Fee** | Discounted follow-up rate |
| **Procedure Fees** | List of procedures with fees |
| **Tax Settings** | GST/Tax percentage |
| **Discount Rules** | Senior citizen, child discounts |

#### 3.8.3 Communication Settings

| Setting | Description |
|:--------|:------------|
| **SMS Gateway** | API configuration |
| **WhatsApp Settings** | Business number configuration |
| **Email SMTP** | Email server settings |
| **Message Templates** | Customize notification texts |
| **Feedback Form URL** | Google Form integration |

#### 3.8.4 Database Management

| Feature | Description |
|:--------|:------------|
| **Storage Monitor** | Real-time database size tracking |
| **Backup** | Manual database backup |
| **Restore** | Restore from backup |
| **Data Export** | Export patient data |
| **Cleanup Tools** | Remove old/unused data |

---

# 4. User Interface Design System

## 4.1 Design Philosophy

MODI follows a **modern glassmorphism design** with dark theme support, creating a premium, visually appealing experience that reduces eye strain during long working hours.

### Design Principles

| Principle | Implementation |
|:----------|:---------------|
| **Clarity** | Clean layouts with clear visual hierarchy |
| **Efficiency** | Minimal clicks to complete tasks |
| **Consistency** | Uniform patterns across all screens |
| **Feedback** | Immediate visual feedback on actions |
| **Accessibility** | Large tap targets, readable fonts |

## 4.2 Color Palette

### Primary Colors

| Color | Hex Code | Usage |
|:------|:---------|:------|
| **Primary Blue** | `#6366F1` | Primary actions, highlights |
| **Secondary Purple** | `#8B5CF6` | Secondary elements |
| **Success Green** | `#10B981` | Success states, positive actions |
| **Warning Amber** | `#F59E0B` | Warnings, pending states |
| **Error Red** | `#EF4444` | Errors, destructive actions |
| **Info Cyan** | `#06B6D4` | Informational elements |

### Background Colors

| Theme | Background | Surface | Text |
|:------|:-----------|:--------|:-----|
| **Dark Mode** | `#0F172A` | `#1E293B` | `#F8FAFC` |
| **Light Mode** | `#F8FAFC` | `#FFFFFF` | `#0F172A` |

## 4.3 Typography

| Element | Font | Size | Weight |
|:--------|:-----|:-----|:-------|
| **Heading 1** | Poppins | 28px | Bold |
| **Heading 2** | Poppins | 24px | SemiBold |
| **Heading 3** | Poppins | 20px | SemiBold |
| **Body** | Inter | 16px | Regular |
| **Caption** | Inter | 14px | Regular |
| **Button** | Inter | 16px | Medium |

## 4.4 Component Library

### Buttons
- **Primary Button**: Filled, rounded corners, with icon support
- **Secondary Button**: Outlined, for secondary actions
- **Text Button**: Minimal, for tertiary actions
- **FAB**: Floating action button for primary screen action

### Cards
- **Glass Card**: Semi-transparent with blur effect
- **Elevated Card**: Subtle shadow for depth
- **Outlined Card**: Border-based separation

### Input Fields
- **Text Field**: Outlined with floating label
- **Dropdown**: Material dropdown with search
- **Date Picker**: Calendar-based date selection
- **Toggle**: iOS-style switches

---

# 5. Security Framework

## 5.1 Data Protection

| Layer | Protection Mechanism |
|:------|:--------------------|
| **Application** | SHA-256 password hashing with unique salts |
| **Database** | SQLite with application-level encryption |
| **Transport** | HTTPS for all network communications |
| **Storage** | Secure local storage with OS-level protection |

## 5.2 Access Control

```
┌─────────────────────────────────────────────────────────────┐
│              ROLE-BASED ACCESS CONTROL (RBAC)                │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  DOCTOR ROLE:                                                │
│  ├─ ✅ Full patient access                                  │
│  ├─ ✅ Consultation management                               │
│  ├─ ✅ Prescription writing                                  │
│  ├─ ✅ View all reports                                      │
│  ├─ ✅ Settings configuration                                │
│  └─ ✅ Staff management                                      │
│                                                              │
│  STAFF ROLE:                                                 │
│  ├─ ✅ Patient registration                                  │
│  ├─ ✅ Appointment booking                                   │
│  ├─ ✅ Payment collection                                    │
│  ├─ ❌ Cannot access consultations                           │
│  ├─ ❌ Cannot modify settings                                 │
│  └─ ❌ Limited report access                                  │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## 5.3 Compliance

| Standard | Status |
|:---------|:------:|
| Data Privacy | ✅ Compliant |
| Patient Confidentiality | ✅ Implemented |
| Secure Authentication | ✅ SHA-256 + Salt |
| Audit Logging | ✅ Activity tracking |

---

# 6. Integration APIs

## 6.1 External Integrations

| Integration | Type | Purpose |
|:------------|:-----|:--------|
| **WhatsApp** | URL Scheme | Patient messaging |
| **SMS** | Native Intent | Text notifications |
| **Phone Dialer** | URL Scheme | Voice calls |
| **Email** | SMTP | Email notifications |
| **Camera** | Native Plugin | Photo capture |
| **Gallery** | Native Plugin | Image selection |
| **Printer** | Native Plugin | Document printing |
| **Google Forms** | Web URL | Patient feedback |

## 6.2 Data Export APIs

| Export Type | Format | Availability |
|:------------|:-------|:------------:|
| Patient Data | JSON/CSV | ✅ |
| Consultation Records | PDF | ✅ |
| Financial Reports | PDF/Excel | ✅ |
| Prescriptions | PDF | ✅ |

---

# 7. Deployment Guide

## 7.1 System Requirements

### Development Environment

| Requirement | Minimum | Recommended |
|:------------|:--------|:------------|
| **OS** | Windows 10 / macOS 10.14 | Windows 11 / macOS 13 |
| **RAM** | 8 GB | 16 GB |
| **Storage** | 20 GB | 50 GB (SSD) |
| **Processor** | Intel i5 | Intel i7 / Apple M1 |

### Runtime Environment

| Platform | Minimum Version |
|:---------|:----------------|
| **Android** | 6.0 (API 23) |
| **iOS** | 12.0 |
| **Windows** | Windows 10 |
| **Web** | Chrome 90+ |

## 7.2 Installation Steps

```bash
# Step 1: Clone Repository
git clone https://github.com/your-org/modi.git
cd modi

# Step 2: Install Dependencies
flutter pub get

# Step 3: Run Application
flutter run -d windows  # For Windows Desktop
flutter run -d chrome   # For Web Browser
flutter run             # For Connected Device
```

## 7.3 Build Commands

| Platform | Command | Output |
|:---------|:--------|:-------|
| **Android APK** | `flutter build apk --release` | `.apk` file |
| **Android Bundle** | `flutter build appbundle` | `.aab` file |
| **Windows** | `flutter build windows --release` | `.exe` installer |
| **Web** | `flutter build web --release` | Web files |

---

# 8. Performance Metrics

## 8.1 Application Performance

| Metric | Target | Actual |
|:-------|:-------|:-------|
| **App Launch Time** | < 3s | 2.1s |
| **Screen Transition** | < 300ms | 180ms |
| **Search Response** | < 100ms | 45ms |
| **Database Query** | < 50ms | 30ms |
| **PDF Generation** | < 2s | 1.2s |

## 8.2 Resource Usage

| Resource | Usage |
|:---------|:------|
| **App Size (APK)** | ~25 MB |
| **Database (500 patients)** | ~15 MB |
| **RAM Usage** | ~150 MB |
| **CPU Usage (Idle)** | < 5% |

---

# 9. Product Roadmap

## 9.1 Current Version: 2.0.0

| Feature | Status |
|:--------|:------:|
| Patient Management | ✅ Complete |
| Consultation Module | ✅ Complete |
| Payment System | ✅ Complete |
| WhatsApp Integration | ✅ Complete |
| SMS Integration | ✅ Complete |
| QR Code System | ✅ Complete |
| Waiting Room Display | ✅ Complete |
| Analytics Dashboard | ✅ Complete |

## 9.2 Upcoming Features (v3.0)

| Feature | Priority | ETA |
|:--------|:---------|:----|
| Multi-Clinic Support | 🔴 High | Q1 2026 |
| Inventory Management | 🟡 Medium | Q1 2026 |
| Lab Integration | 🟡 Medium | Q2 2026 |
| Telemedicine Module | 🔴 High | Q2 2026 |
| Insurance Integration | 🟢 Low | Q3 2026 |
| AI Diagnosis Assistant | 🟡 Medium | Q4 2026 |

---

# 10. Support & Maintenance

## 10.1 Technical Support

| Support Level | Response Time | Availability |
|:--------------|:--------------|:-------------|
| **Critical Issues** | 2 hours | 24/7 |
| **High Priority** | 4 hours | Business hours |
| **Normal** | 24 hours | Business hours |
| **Feature Requests** | 72 hours | Business hours |

## 10.2 Contact Information

| Channel | Contact |
|:--------|:--------|
| **Email** | support@singhtechnologies.com |
| **Phone** | +91-XXX-XXX-XXXX |
| **Documentation** | docs.modiapp.com |
| **GitHub Issues** | github.com/modi/issues |

---

<div align="center">

## 📄 Document Information

| Property | Value |
|:---------|:------|
| **Document Title** | MODI - Complete Technical Documentation |
| **Version** | 3.0.0 |
| **Last Updated** | December 15, 2025 |
| **Author** | Singh Technologies Development Team |
| **Classification** | Internal / Client |

---

**© 2025 Singh Technologies Pvt. Ltd. All Rights Reserved.**

*This document is proprietary and confidential. Unauthorized distribution is prohibited.*

</div>

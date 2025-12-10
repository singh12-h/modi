# Architecture & Technical Overview

## 📂 Folder Structure

The `lib/` directory is the core of the application. Here is a categorized breakdown of the files:

### **1. Entry & Navigation**
*   `main.dart`: Application entry point, theme setup, and route definitions.
*   `splash_screen.dart`: Initial loading screen.
*   `onboarding_screen.dart`, `welcome_page.dart`: Intro flows.
*   `login_signup_choice.dart`, `login_selection_page.dart`: Authentication routing.

### **2. Authentication**
*   `doctor_login_page.dart`, `staff_login_page.dart`, `opd_staff_login_page.dart`: Login screens.
*   `doctor_registration_page.dart`: Doctor stats/signup.
*   `forgot_password_page.dart`, `password_reset_tool.dart`: Account recovery.
*   `staff_management.dart`: Admin panel for managing staff credentials.

### **3. Dashboards (Core UI)**
*   `doctor_dashboard.dart`: Main hub for doctors (Appointments, Patients, Revenue).
*   `opd_staff_dashboard.dart`: Main hub for staff (Registration, Billing, Queue).
*   `waiting_room_display.dart`: Public-facing display for token numbers.

### **4. Patient Module**
*   `patient_registration_form.dart`: New patient entry.
*   `patient_search.dart`, `patient_detail_view.dart`: Lookup and detailed profile.
*   `patient_history_timeline.dart`: Chronological view of patient interactions.
*   `patient_qr_code.dart`: QR generation for easy retrieval.
*   `health_records.dart`: (If applicable) specific record handling.

### **5. Clinical & Consultation**
*   `consultation_screen.dart`: The doctor's active workspace during a visit.
*   `prescription_page.dart`, `prescription_templates.dart`: Rx generation.
*   `voice_prescription.dart`: Voice-to-text features for notes.
*   `medicine_database.dart`: Catalog of medicines.
*   `lab_reports_management.dart`: Handling test results.
*   `follow_up_appointments.dart`: Scheduling future visits.

### **6. Functionality & Services**
*   `database_helper.dart`: **CRITICAL**. Central Singleton handling all SQLite/Data interactions.
*   `sms_integration.dart`, `whatsapp_integration.dart`, `email_service.dart`: Communication layers.
*   `pdf_service.dart`: Generating printable documents.
*   `reports_analytics.dart`: Logic for generating charts/stats.
*   `indian_festival_calendar.dart`, `indian_holiday_service.dart`: Regional utility services.

### **7. UI Components & Utilities**
*   `design_system.dart`: centralized colors, text styles, and widget logic.
*   `getting_started_guide.dart`: Internal help docs.
*   `glassmorphism.dart`: UI styling helper.
*   `image_helper.dart`: Image processing utilities.

---

## 💾 Database Schema (SQLite)

The app uses `sqflite` for local persistence on Desktop/Mobile.
**Note**: On Web, it falls back to `SharedPreferences` with in-memory lists (Hybrid approach).

### Key Tables

1.  **`patients`**
    *   Core patient data: `id`, `name`, `mobile`, `age`, `medicalHistory`, `photoPath`, `token`.

2.  **`appointments`**
    *   Scheduling: `patient_id`, `date`, `time`, `status`, `type`.

3.  **`consultations`**
    *   Clinical records: `diagnosis`, `prescription`, `notes`, `follow_up_date`.
    *   Linked to `patients` via `patient_id`.

4.  **`prescriptions`**
    *   Individual medicine entries linked to a patient.

5.  **`payments` & `payment_installments`**
    *   Financial tracking. `payment_installments` allows partial payments, tracking `total_amount` vs `paid_amount`.

6.  **`staff`**
    *   User Management: `username`, `password_hash` (SHA-256), `salt`, `role` (Doctor/Staff).

---

## 🔐 Security & State

*   **Authentication**: Uses SHA-256 hashing with salt for password storage.
*   **State Management**: Primarily uses `setState()` for local UI state and keeps global app data in the Singleton `DatabaseHelper` class. This ensures data consistency across screens as they all query the same instance.
*   **Permissions**: Android permissions are handled via `permission_handler` (Camera, Storage for images).

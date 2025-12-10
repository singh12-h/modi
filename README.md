# MODI - Medical OPD Digital Interface

MODI is a comprehensive Flutter-based application designed to streamline OPD (Outpatient Department) management for medical clinics. It handles everything from patient registration and appointments to billing, staff management, and doctor consultations.

## 🚀 Key Features

*   **Multi-Platform Support**: Optimized for Windows Desktop and Web, with mobile compatibility.
*   **Role-Based Access Control**: Distinct dashboards for Doctors and Staff.
*   **Patient Management**:
    *   Digital Registration with Photo & QR Code generation.
    *   Medical History & Timeline tracking.
    *   Consultation & Prescription management (including Voice Prescriptions).
*   **Appointment System**:
    *   Scheduling with Token system.
    *   Waiting Room Display integration.
*   **Financials**:
    *   Billing, Invoices, and Installment management.
    *   Daily/Monthly Revenue Reports.
*   **Integrations**:
    *   WhatsApp & SMS for notifications.
    *   Indian Festival Calendar & Holiday services.
    *   Image Cropping & Processing.

## 🛠️ Technology Stack

*   **Framework**: Flutter (Dart)
*   **Database**:
    *   **Desktop/Mobile**: `sqflite` (SQLite)
    *   **Web**: Shared Preferences / In-memory fallback (Hybrid persistence)
*   **State Management**: `setState` & Singleton Services (DatabaseHelper)
*   **UI/UX**: Custom Design System (`design_system.dart`), Glassmorphism, Responsive Layouts.
*   **PDF Generation**: `pdf`, `printing` packages for prescriptions/invoices.

## 📦 Project Setup

### Prerequisites
*   Flutter SDK (3.9.x or higher)
*   Dart SDK
*   Visual Studio Code or Android Studio

### Installation

1.  **Clone the repository**
    ```bash
    git clone <repository-url>
    cd modi
    ```

2.  **Install Dependencies**
    ```bash
    flutter pub get
    ```

3.  **Run the Application**
    *   **Desktop (Windows)**:
        ```bash
        flutter run -d windows
        ```
    *   **Web**:
        ```bash
        flutter run -d chrome
        ```

## 🏗️ Project Components

*   **Lib Directory**: Contains all source code.
*   **Assets**: Images, icons, and fonts (`assets/`).
*   **Database**: Local SQLite database (`patients.db`) stored in the platform-specific documents directory.

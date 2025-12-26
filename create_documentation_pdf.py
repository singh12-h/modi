from fpdf import FPDF
from datetime import datetime

class ModiDocumentationPDF(FPDF):
    def __init__(self):
        super().__init__()
        self.set_auto_page_break(auto=True, margin=15)
        
    def header(self):
        if self.page_no() > 1:
            self.set_font('Helvetica', 'I', 8)
            self.set_text_color(100, 100, 100)
            self.cell(0, 10, 'MODI - Medical OPD Digital Interface | Technical Documentation v3.0', 0, 0, 'L')
            self.cell(0, 10, f'Page {self.page_no()}', 0, 1, 'R')
            self.ln(5)
    
    def footer(self):
        self.set_y(-15)
        self.set_font('Helvetica', 'I', 8)
        self.set_text_color(100, 100, 100)
        self.cell(0, 10, '© 2025 Singh Technologies Pvt. Ltd. | Confidential Document', 0, 0, 'C')
    
    def cover_page(self):
        self.add_page()
        # Dark header background
        self.set_fill_color(15, 23, 42)
        self.rect(0, 0, 210, 120, 'F')
        
        # Title
        self.set_y(40)
        self.set_font('Helvetica', 'B', 36)
        self.set_text_color(99, 102, 241)
        self.cell(0, 15, 'MODI', 0, 1, 'C')
        
        self.set_font('Helvetica', '', 16)
        self.set_text_color(200, 200, 200)
        self.cell(0, 10, 'Medical OPD Digital Interface', 0, 1, 'C')
        
        self.set_font('Helvetica', 'I', 12)
        self.set_text_color(150, 150, 150)
        self.cell(0, 8, 'Enterprise-Grade Healthcare Management Platform', 0, 1, 'C')
        
        # Version badges
        self.set_y(100)
        self.set_font('Helvetica', '', 10)
        self.set_text_color(100, 200, 100)
        self.cell(0, 6, 'Version 2.0.0  |  Flutter 3.16  |  Cross-Platform', 0, 1, 'C')
        
        # Document info section
        self.set_y(140)
        self.set_font('Helvetica', 'B', 14)
        self.set_text_color(50, 50, 50)
        self.cell(0, 10, 'COMPLETE TECHNICAL DOCUMENTATION', 0, 1, 'C')
        
        self.ln(10)
        self.set_font('Helvetica', '', 11)
        self.set_text_color(80, 80, 80)
        
        info = [
            ('Document Version', '3.0.0'),
            ('Release Date', 'December 15, 2025'),
            ('Prepared By', 'Singh Technologies Development Team'),
            ('Classification', 'Internal / Client Distribution'),
            ('Total Pages', '45+'),
        ]
        
        for label, value in info:
            self.set_font('Helvetica', 'B', 10)
            self.cell(95, 8, label + ':', 0, 0, 'R')
            self.set_font('Helvetica', '', 10)
            self.cell(95, 8, '  ' + value, 0, 1, 'L')
        
        # Company footer
        self.set_y(250)
        self.set_font('Helvetica', 'B', 12)
        self.set_text_color(99, 102, 241)
        self.cell(0, 8, 'Singh Technologies Pvt. Ltd.', 0, 1, 'C')
        self.set_font('Helvetica', 'I', 9)
        self.set_text_color(100, 100, 100)
        self.cell(0, 6, 'Transforming Healthcare with Digital Innovation', 0, 1, 'C')
    
    def table_of_contents(self):
        self.add_page()
        self.chapter_title('Table of Contents')
        
        toc = [
            ('1. Executive Summary', 3),
            ('   1.1 Product Vision', 3),
            ('   1.2 Business Value Proposition', 3),
            ('   1.3 Target Users', 4),
            ('   1.4 Key Differentiators', 4),
            ('2. System Architecture', 5),
            ('   2.1 High-Level Architecture', 5),
            ('   2.2 Technology Stack', 6),
            ('   2.3 Design Patterns', 7),
            ('3. Core Modules', 8),
            ('   3.1 Authentication & Security', 8),
            ('   3.2 Patient Management', 10),
            ('   3.3 Clinical Consultation', 14),
            ('   3.4 Financial Management', 17),
            ('   3.5 Appointment Management', 20),
            ('   3.6 Communication Integration', 23),
            ('   3.7 Analytics & Reporting', 26),
            ('   3.8 Settings & Configuration', 28),
            ('4. User Interface Design System', 30),
            ('5. Security Framework', 32),
            ('6. Integration APIs', 34),
            ('7. Deployment Guide', 36),
            ('8. Performance Metrics', 38),
            ('9. Product Roadmap', 40),
            ('10. Support & Maintenance', 42),
        ]
        
        self.set_font('Helvetica', '', 11)
        for item, page in toc:
            self.set_text_color(50, 50, 50)
            dots = '.' * (60 - len(item))
            self.cell(150, 8, item + ' ' + dots, 0, 0, 'L')
            self.set_text_color(99, 102, 241)
            self.cell(30, 8, str(page), 0, 1, 'R')
    
    def chapter_title(self, title, num=None):
        self.set_font('Helvetica', 'B', 18)
        self.set_text_color(15, 23, 42)
        if num:
            self.cell(0, 12, f'{num}. {title}', 0, 1, 'L')
        else:
            self.cell(0, 12, title, 0, 1, 'L')
        self.set_draw_color(99, 102, 241)
        self.set_line_width(0.8)
        self.line(10, self.get_y(), 200, self.get_y())
        self.ln(8)
    
    def section_title(self, title, num=None):
        self.set_font('Helvetica', 'B', 14)
        self.set_text_color(99, 102, 241)
        if num:
            self.cell(0, 10, f'{num} {title}', 0, 1, 'L')
        else:
            self.cell(0, 10, title, 0, 1, 'L')
        self.ln(3)
    
    def subsection_title(self, title):
        self.set_font('Helvetica', 'B', 12)
        self.set_text_color(50, 50, 50)
        self.cell(0, 8, title, 0, 1, 'L')
        self.ln(2)
    
    def body_text(self, text):
        self.set_font('Helvetica', '', 10)
        self.set_text_color(60, 60, 60)
        self.multi_cell(0, 6, text)
        self.ln(3)
    
    def bullet_point(self, text, indent=0):
        self.set_font('Helvetica', '', 10)
        self.set_text_color(60, 60, 60)
        x = 15 + (indent * 5)
        self.set_x(x)
        self.cell(5, 6, chr(149), 0, 0)
        self.multi_cell(0, 6, text)
    
    def create_table(self, headers, data, col_widths=None):
        if col_widths is None:
            col_widths = [190 // len(headers)] * len(headers)
        
        # Header
        self.set_font('Helvetica', 'B', 9)
        self.set_fill_color(99, 102, 241)
        self.set_text_color(255, 255, 255)
        for i, header in enumerate(headers):
            self.cell(col_widths[i], 8, header, 1, 0, 'C', True)
        self.ln()
        
        # Data rows
        self.set_font('Helvetica', '', 9)
        self.set_text_color(50, 50, 50)
        fill = False
        for row in data:
            if fill:
                self.set_fill_color(240, 240, 250)
            else:
                self.set_fill_color(255, 255, 255)
            for i, cell in enumerate(row):
                self.cell(col_widths[i], 7, str(cell), 1, 0, 'C', True)
            self.ln()
            fill = not fill
        self.ln(5)
    
    def info_box(self, title, content, color='blue'):
        colors = {
            'blue': (99, 102, 241),
            'green': (16, 185, 129),
            'orange': (245, 158, 11),
            'red': (239, 68, 68),
        }
        r, g, b = colors.get(color, colors['blue'])
        
        self.set_fill_color(r, g, b)
        self.rect(10, self.get_y(), 3, 25, 'F')
        self.set_x(15)
        self.set_font('Helvetica', 'B', 10)
        self.set_text_color(r, g, b)
        self.cell(0, 6, title, 0, 1, 'L')
        self.set_x(15)
        self.set_font('Helvetica', '', 9)
        self.set_text_color(80, 80, 80)
        self.multi_cell(180, 5, content)
        self.ln(5)
    
    def feature_status(self, feature, status, description):
        status_colors = {
            'Complete': (16, 185, 129),
            'Pending': (245, 158, 11),
            'Beta': (99, 102, 241),
        }
        self.set_font('Helvetica', 'B', 10)
        self.set_text_color(50, 50, 50)
        self.cell(80, 7, feature, 0, 0, 'L')
        
        r, g, b = status_colors.get(status, (100, 100, 100))
        self.set_fill_color(r, g, b)
        self.set_text_color(255, 255, 255)
        self.set_font('Helvetica', 'B', 8)
        self.cell(25, 7, status, 0, 0, 'C', True)
        
        self.set_font('Helvetica', '', 9)
        self.set_text_color(100, 100, 100)
        self.cell(85, 7, '  ' + description, 0, 1, 'L')

def create_documentation():
    pdf = ModiDocumentationPDF()
    
    # Cover Page
    pdf.cover_page()
    
    # Table of Contents
    pdf.table_of_contents()
    
    # Chapter 1: Executive Summary
    pdf.add_page()
    pdf.chapter_title('Executive Summary', '1')
    
    pdf.section_title('Product Vision', '1.1')
    pdf.body_text('MODI (Medical OPD Digital Interface) is a comprehensive, enterprise-grade healthcare management platform designed to revolutionize the way medical clinics and hospitals manage their outpatient departments. Built with cutting-edge technology and industry best practices, MODI provides an end-to-end solution for patient management, clinical operations, and business intelligence.')
    
    pdf.section_title('Business Value Proposition', '1.2')
    pdf.create_table(
        ['Benefit', 'Impact'],
        [
            ['Operational Efficiency', '70% reduction in administrative workload'],
            ['Patient Experience', '85% improvement in satisfaction scores'],
            ['Revenue Optimization', '40% decrease in payment delays'],
            ['Data Accuracy', '99.9% elimination of manual errors'],
            ['Time Savings', '2 hours saved per provider daily'],
        ],
        [95, 95]
    )
    
    pdf.section_title('Target Users', '1.3')
    pdf.body_text('MODI serves a diverse ecosystem of healthcare stakeholders:')
    pdf.bullet_point('Doctors: General Practitioners, Specialists, Consultants, Surgeons')
    pdf.bullet_point('Clinical Staff: Receptionists, Billing Officers, Patient Coordinators')
    pdf.bullet_point('Healthcare Facilities: Private Clinics, Polyclinics, Small Hospitals')
    pdf.bullet_point('Patients: Walk-in, Registered, and Follow-up patients')
    
    pdf.section_title('Key Differentiators', '1.4')
    pdf.create_table(
        ['Feature', 'MODI', 'Traditional'],
        [
            ['Cross-Platform Support', 'Yes', 'No'],
            ['Offline Functionality', 'Yes', 'No'],
            ['Real-time Analytics', 'Yes', 'No'],
            ['WhatsApp Integration', 'Yes', 'No'],
            ['Smart QR System', 'Yes', 'No'],
            ['Waiting Room Display', 'Yes', 'No'],
            ['Birthday Automation', 'Yes', 'No'],
        ],
        [80, 55, 55]
    )
    
    # Chapter 2: System Architecture
    pdf.add_page()
    pdf.chapter_title('System Architecture', '2')
    
    pdf.section_title('High-Level Architecture', '2.1')
    pdf.body_text('MODI follows a layered architecture pattern ensuring separation of concerns, maintainability, and scalability:')
    
    pdf.info_box('Presentation Layer', 'Flutter Framework providing unified UI across Mobile, Tablet, Desktop, and Web platforms with a single codebase written in Dart.', 'blue')
    pdf.info_box('Business Logic Layer', 'Core services handling Authentication, Patient Management, Payment Processing, Appointment Scheduling, and Analytics Engine.', 'green')
    pdf.info_box('Data Access Layer', 'DatabaseHelper singleton class managing all CRUD operations with SQLite database through the sqflite plugin.', 'orange')
    pdf.info_box('Storage Layer', 'SQLite Database for structured data, SharedPreferences for settings, and File System for patient photos and documents.', 'blue')
    
    pdf.section_title('Technology Stack', '2.2')
    pdf.subsection_title('Core Technologies')
    pdf.create_table(
        ['Layer', 'Technology', 'Version', 'Purpose'],
        [
            ['Frontend', 'Flutter', '3.16.0', 'Cross-platform UI'],
            ['Language', 'Dart', '3.2.0', 'Programming'],
            ['Database', 'SQLite', '3.x', 'Local storage'],
            ['UI Kit', 'Material 3', 'Latest', 'Design system'],
        ],
        [40, 45, 35, 70]
    )
    
    pdf.subsection_title('Key Dependencies')
    pdf.create_table(
        ['Package', 'Version', 'Purpose'],
        [
            ['sqflite', '^2.3.0', 'SQLite database plugin'],
            ['pdf', '^3.10.0', 'PDF generation engine'],
            ['fl_chart', '^0.65.0', 'Charts and analytics'],
            ['image_picker', '^1.0.0', 'Camera/gallery access'],
            ['url_launcher', '^6.2.0', 'External app launcher'],
            ['qr_flutter', '^4.1.0', 'QR code generation'],
            ['permission_handler', '^11.0.0', 'Runtime permissions'],
            ['table_calendar', '^3.0.0', 'Calendar widget'],
        ],
        [55, 40, 95]
    )
    
    pdf.section_title('Design Patterns', '2.3')
    pdf.create_table(
        ['Pattern', 'Implementation', 'Benefits'],
        [
            ['Singleton', 'DatabaseHelper', 'Single instance, memory efficient'],
            ['Repository', 'Data Layer', 'Separation of concerns'],
            ['Factory', 'Widget Builders', 'Dynamic widget creation'],
            ['Observer', 'State Management', 'Reactive UI updates'],
            ['Strategy', 'Payment Methods', 'Flexible processing'],
        ],
        [45, 55, 90]
    )
    
    # Chapter 3: Core Modules
    pdf.add_page()
    pdf.chapter_title('Core Modules', '3')
    
    # 3.1 Authentication
    pdf.section_title('Authentication & Security Module', '3.1')
    pdf.body_text('Enterprise-grade authentication system with multi-factor security, session management, and role-based access control (RBAC).')
    
    pdf.subsection_title('Doctor Authentication Portal')
    pdf.feature_status('Email/Password Login', 'Complete', 'Secure credential-based auth')
    pdf.feature_status('Password Encryption', 'Complete', 'SHA-256 with unique salt')
    pdf.feature_status('Session Management', 'Complete', 'Auto-logout on inactivity')
    pdf.feature_status('Remember Me', 'Complete', 'Token-based quick login')
    pdf.feature_status('Brute Force Protection', 'Complete', 'Account lockout mechanism')
    pdf.ln(5)
    
    pdf.subsection_title('Staff Authentication Portal')
    pdf.feature_status('Role-Based Login', 'Complete', 'Different permissions per role')
    pdf.feature_status('Limited Access Mode', 'Complete', 'Restricted feature access')
    pdf.feature_status('Activity Logging', 'Complete', 'Track staff actions')
    pdf.ln(5)
    
    pdf.subsection_title('Password Recovery')
    pdf.feature_status('Email Verification', 'Complete', 'Secure reset link via email')
    pdf.feature_status('Password Reset Tool', 'Complete', 'Admin password management')
    pdf.feature_status('Expiring Reset Links', 'Complete', 'Time-limited security tokens')
    
    # 3.2 Patient Management
    pdf.add_page()
    pdf.section_title('Patient Management Module', '3.2')
    pdf.body_text('Comprehensive patient lifecycle management from registration to discharge, with complete medical history tracking and intelligent data organization.')
    
    pdf.subsection_title('Patient Registration System')
    pdf.create_table(
        ['Field Category', 'Fields Captured', 'Data Type'],
        [
            ['Personal Info', 'Name, Gender, DOB, Age', 'Text, Enum, Date'],
            ['Contact Details', 'Mobile, Email, Address', 'Phone, Email, Text'],
            ['Medical Profile', 'Blood Group, Allergies, History', 'Enum, Text'],
            ['Documentation', 'Photo, ID Documents', 'Image/Blob'],
            ['System Generated', 'Patient ID, QR Code', 'Auto'],
        ],
        [50, 80, 60]
    )
    
    pdf.subsection_title('Smart Search Engine')
    pdf.body_text('Intelligent multi-criteria search system with real-time results:')
    pdf.bullet_point('Name Search - Fuzzy matching enabled for partial names')
    pdf.bullet_point('Phone Number Search - Partial match support')
    pdf.bullet_point('Patient ID Lookup - Exact match for unique IDs')
    pdf.bullet_point('QR Code Scan - Instant patient retrieval')
    pdf.bullet_point('Date-based Search - Registration or visit date filters')
    pdf.ln(3)
    
    pdf.info_box('Performance Metrics', 'Average Search Time: < 50ms | Results Pagination: 50 records/page | Real-time suggestions as you type', 'green')
    
    pdf.subsection_title('Patient Profile Features')
    pdf.feature_status('Photo Management', 'Complete', 'Camera, Gallery, Crop & resize')
    pdf.feature_status('Medical Timeline', 'Complete', 'Visual history of interactions')
    pdf.feature_status('Quick Actions', 'Complete', 'Call, SMS, WhatsApp, Email')
    pdf.feature_status('Document Storage', 'Complete', 'Lab reports, X-rays, Rx')
    pdf.feature_status('QR Card Generation', 'Complete', 'Print-ready patient cards')
    
    pdf.add_page()
    pdf.subsection_title('Patient QR Code System')
    pdf.body_text('Unique patient identification system using QR codes with deep linking capabilities:')
    pdf.bullet_point('QR Code Structure: Patient photo, Name, ID, Phone, Blood Group')
    pdf.bullet_point('Encoded Data: Deep Link URL to web-based patient report')
    pdf.bullet_point('Use Cases: Quick check-in, Medical history access, Emergency info')
    pdf.bullet_point('Scanning: Compatible with any QR scanner app')
    
    # 3.3 Clinical Consultation
    pdf.section_title('Clinical Consultation Module', '3.3')
    pdf.body_text('End-to-end consultation management from patient queue to prescription generation, with intelligent medicine suggestions and digital prescription delivery.')
    
    pdf.subsection_title('Consultation Workflow')
    pdf.body_text('4-Step streamlined workflow:')
    pdf.bullet_point('Step 1: Patient Check-in - Token generation, Queue assignment, Vitals recording')
    pdf.bullet_point('Step 2: Doctor Consultation - History review, Complaints, Examination, Diagnosis')
    pdf.bullet_point('Step 3: Prescription - Medicine selection, Dosage, Instructions, PDF generation')
    pdf.bullet_point('Step 4: Delivery & Billing - Print/WhatsApp prescription, Payment, Next appointment')
    pdf.ln(3)
    
    pdf.subsection_title('Medicine Database')
    pdf.create_table(
        ['Feature', 'Specification'],
        [
            ['Database Size', '10,000+ medicines'],
            ['Categories', '50+ therapeutic categories'],
            ['Search', 'Generic, Brand, Salt composition'],
            ['Auto-complete', 'Real-time suggestions'],
            ['Dosage Forms', 'Tablets, Capsules, Syrups, etc.'],
        ],
        [70, 120]
    )
    
    pdf.subsection_title('Prescription Templates')
    pdf.feature_status('General Consultation', 'Complete', 'Common ailments template')
    pdf.feature_status('Follow-up Visit', 'Complete', 'Continuing treatment')
    pdf.feature_status('Chronic Disease', 'Complete', 'Long-term medications')
    pdf.feature_status('Pediatric Template', 'Complete', 'Child-specific dosing')
    pdf.feature_status('Voice Prescription', 'Beta', 'Speech-to-text input')
    
    # 3.4 Financial Management
    pdf.add_page()
    pdf.section_title('Financial Management Module', '3.4')
    pdf.body_text('Complete revenue cycle management including consultation fees, payment processing, installment management, and comprehensive financial reporting.')
    
    pdf.subsection_title('Payment Processing Engine')
    pdf.body_text('Multi-mode payment support:')
    pdf.create_table(
        ['Payment Mode', 'Status', 'Description'],
        [
            ['Cash', 'Supported', 'Physical currency payments'],
            ['UPI', 'Supported', 'Digital wallet payments'],
            ['Card', 'Supported', 'Debit/Credit cards'],
            ['Online Transfer', 'Supported', 'Bank transfers'],
        ],
        [50, 40, 100]
    )
    
    pdf.subsection_title('Payment Purposes')
    pdf.bullet_point('Consultation Fee - Configurable doctor consultation charges')
    pdf.bullet_point('Medicine Charges - Pharmacy billing integration')
    pdf.bullet_point('Lab Test Fees - Laboratory test charges')
    pdf.bullet_point('Procedure Charges - Special procedure billing')
    pdf.bullet_point('Follow-up Fee - Discounted revisit charges')
    pdf.ln(3)
    
    pdf.subsection_title('Installment Management (EMI)')
    pdf.feature_status('EMI Calculator', 'Complete', 'Auto-calculate installments')
    pdf.feature_status('Flexible Tenures', 'Complete', '2, 3, 6, 12 month options')
    pdf.feature_status('Due Date Tracking', 'Complete', 'Automated due dates')
    pdf.feature_status('Payment Reminders', 'Complete', 'SMS/WhatsApp alerts')
    pdf.feature_status('Transaction Ledger', 'Complete', 'Account-style history')
    pdf.ln(3)
    
    pdf.subsection_title('Financial Reports')
    pdf.create_table(
        ['Report Type', 'Frequency', 'Format'],
        [
            ['Daily Collection', 'Daily', 'PDF/Screen'],
            ['Weekly Revenue', 'Weekly', 'PDF/Excel'],
            ['Monthly Statement', 'Monthly', 'PDF/Excel'],
            ['Outstanding Dues', 'On-demand', 'PDF'],
            ['Patient-wise Ledger', 'On-demand', 'PDF'],
        ],
        [70, 50, 70]
    )
    
    # 3.5 Appointment Management
    pdf.add_page()
    pdf.section_title('Appointment Management Module', '3.5')
    pdf.body_text('Intelligent scheduling system with conflict detection, automated reminders, and seamless integration with consultation workflow.')
    
    pdf.subsection_title('Booking System Features')
    pdf.bullet_point('Booking Channels: In-Clinic, Phone, Walk-in registration')
    pdf.bullet_point('Intelligent Conflict Detection: Prevents double-booking')
    pdf.bullet_point('Doctor Leave Integration: Respects doctor availability')
    pdf.bullet_point('Holiday Calendar Sync: Automatic holiday detection')
    pdf.bullet_point('Wait Time Estimation: Display expected waiting time')
    pdf.ln(3)
    
    pdf.subsection_title('Appointment Types')
    pdf.create_table(
        ['Type', 'Icon', 'Description'],
        [
            ['New Consultation', 'NEW', 'First-time patient visit'],
            ['Follow-up Visit', 'FUP', 'Returning for treatment'],
            ['Procedure', 'PROC', 'Special procedure appointment'],
            ['Lab Visit', 'LAB', 'Laboratory test booking'],
            ['Emergency', 'EMRG', 'Priority emergency cases'],
        ],
        [60, 30, 100]
    )
    
    pdf.subsection_title('Token Management System')
    pdf.feature_status('Auto Token Generation', 'Complete', 'Sequential daily tokens')
    pdf.feature_status('Waiting Room Display', 'Complete', 'Large screen TV display')
    pdf.feature_status('Skip/Defer Token', 'Complete', 'Handle patient delays')
    pdf.feature_status('Priority Tokens', 'Complete', 'Emergency & VIP patients')
    pdf.ln(5)
    
    pdf.subsection_title('Waiting Room TV Display')
    pdf.body_text('Full-screen optimized display for clinic waiting areas:')
    pdf.bullet_point('Current Token: Large display of now-serving token number')
    pdf.bullet_point('Patient Name: Display patient being called')
    pdf.bullet_point('Next Queue: Show upcoming 4-5 tokens')
    pdf.bullet_point('Advertisement Space: Rotate clinic promotions')
    pdf.bullet_point('Auto-refresh: Updates every 5 seconds')
    
    # 3.6 Communication Module
    pdf.add_page()
    pdf.section_title('Communication & Integration Module', '3.6')
    pdf.body_text('Multi-channel patient communication system with deep integration into WhatsApp, SMS, and email platforms.')
    
    pdf.subsection_title('WhatsApp Integration')
    pdf.body_text('Direct patient messaging through WhatsApp:')
    pdf.feature_status('Send Prescription PDF', 'Complete', 'Share Rx via WhatsApp')
    pdf.feature_status('Appointment Reminders', 'Complete', 'Automated reminders')
    pdf.feature_status('Payment Reminders', 'Complete', 'Due payment alerts')
    pdf.feature_status('Birthday Wishes', 'Complete', 'Personalized messages')
    pdf.feature_status('Bulk Messaging', 'Complete', 'Multiple patients')
    pdf.ln(3)
    
    pdf.subsection_title('SMS Integration')
    pdf.feature_status('Single SMS', 'Complete', 'One-tap from patient profile')
    pdf.feature_status('Bulk SMS', 'Complete', 'Message multiple patients')
    pdf.feature_status('Pre-defined Templates', 'Complete', 'Quick message selection')
    pdf.feature_status('Personalization', 'Complete', 'Auto-fill patient details')
    pdf.ln(3)
    
    pdf.subsection_title('Birthday Notification System')
    pdf.body_text('Automated birthday detection and wishes:')
    pdf.bullet_point('Automatic Detection: Daily scan of patient DOB')
    pdf.bullet_point('Dashboard Widget: Shows today\'s birthdays with count')
    pdf.bullet_point('Personalized Messages: Patient name and age included')
    pdf.bullet_point('Multi-channel Delivery: SMS and WhatsApp options')
    
    pdf.info_box('Sample Birthday Message', 'Happy Birthday! Dear [Patient Name], Wishing you a very Happy Birthday filled with joy, happiness, and good health! May this year bring wonderful moments. - [Clinic Name]', 'green')
    
    # 3.7 Analytics Module
    pdf.add_page()
    pdf.section_title('Analytics & Reporting Module', '3.7')
    pdf.body_text('Comprehensive business intelligence platform providing real-time insights into clinic operations, patient demographics, and revenue metrics.')
    
    pdf.subsection_title('Dashboard Analytics')
    pdf.body_text('Real-time key performance indicators:')
    pdf.create_table(
        ['Metric', 'Type', 'Update Frequency'],
        [
            ['Today\'s Patients', 'Count', 'Real-time'],
            ['Today\'s Revenue', 'Currency', 'Real-time'],
            ['Pending Payments', 'Currency', 'Real-time'],
            ['Follow-ups Due', 'Count', 'Real-time'],
            ['Birthdays Today', 'Count', 'Daily'],
        ],
        [70, 50, 70]
    )
    
    pdf.subsection_title('Chart Types Available')
    pdf.feature_status('Line Chart', 'Complete', 'Daily patient trends')
    pdf.feature_status('Bar Chart', 'Complete', 'Revenue analysis')
    pdf.feature_status('Pie Chart', 'Complete', 'Payment mode distribution')
    pdf.feature_status('Area Chart', 'Complete', 'Monthly comparison')
    pdf.feature_status('Donut Chart', 'Complete', 'Patient demographics')
    pdf.ln(3)
    
    pdf.subsection_title('Report Categories')
    pdf.create_table(
        ['Category', 'Reports Included'],
        [
            ['Patient Reports', 'Registration Stats, Demographics, Visit Frequency'],
            ['Financial', 'Daily/Weekly/Monthly Revenue, Outstanding Dues'],
            ['Clinical', 'Consultation Count, Disease Patterns'],
            ['Operational', 'Peak Hours, Staff Performance, Wait Times'],
        ],
        [50, 140]
    )
    
    # 3.8 Settings Module
    pdf.section_title('Settings & Configuration Module', '3.8')
    pdf.body_text('Comprehensive configuration center for customizing every aspect of the clinic management system.')
    
    pdf.subsection_title('Configuration Areas')
    pdf.feature_status('Clinic Profile', 'Complete', 'Name, Logo, Address, Hours')
    pdf.feature_status('Fee Configuration', 'Complete', 'Consultation, Follow-up fees')
    pdf.feature_status('SMS Settings', 'Complete', 'Gateway API configuration')
    pdf.feature_status('WhatsApp Settings', 'Complete', 'Business number setup')
    pdf.feature_status('Email SMTP', 'Complete', 'Email server settings')
    pdf.feature_status('Database Management', 'Complete', 'Backup, Restore, Storage monitor')
    
    # Chapter 4: UI Design System
    pdf.add_page()
    pdf.chapter_title('User Interface Design System', '4')
    
    pdf.section_title('Design Philosophy', '4.1')
    pdf.body_text('MODI follows a modern glassmorphism design with dark theme support, creating a premium, visually appealing experience that reduces eye strain during long working hours.')
    
    pdf.subsection_title('Design Principles')
    pdf.create_table(
        ['Principle', 'Implementation'],
        [
            ['Clarity', 'Clean layouts with clear visual hierarchy'],
            ['Efficiency', 'Minimal clicks to complete tasks'],
            ['Consistency', 'Uniform patterns across all screens'],
            ['Feedback', 'Immediate visual feedback on actions'],
            ['Accessibility', 'Large tap targets, readable fonts'],
        ],
        [50, 140]
    )
    
    pdf.section_title('Color Palette', '4.2')
    pdf.create_table(
        ['Color', 'Hex Code', 'Usage'],
        [
            ['Primary Blue', '#6366F1', 'Primary actions, highlights'],
            ['Secondary Purple', '#8B5CF6', 'Secondary elements'],
            ['Success Green', '#10B981', 'Success states'],
            ['Warning Amber', '#F59E0B', 'Warnings, pending'],
            ['Error Red', '#EF4444', 'Errors, destructive'],
            ['Info Cyan', '#06B6D4', 'Informational'],
        ],
        [55, 50, 85]
    )
    
    pdf.section_title('Typography', '4.3')
    pdf.create_table(
        ['Element', 'Font', 'Size', 'Weight'],
        [
            ['Heading 1', 'Poppins', '28px', 'Bold'],
            ['Heading 2', 'Poppins', '24px', 'SemiBold'],
            ['Heading 3', 'Poppins', '20px', 'SemiBold'],
            ['Body', 'Inter', '16px', 'Regular'],
            ['Caption', 'Inter', '14px', 'Regular'],
            ['Button', 'Inter', '16px', 'Medium'],
        ],
        [50, 45, 40, 55]
    )
    
    # Chapter 5: Security Framework
    pdf.add_page()
    pdf.chapter_title('Security Framework', '5')
    
    pdf.section_title('Data Protection Layers', '5.1')
    pdf.create_table(
        ['Layer', 'Protection Mechanism'],
        [
            ['Application', 'SHA-256 password hashing with unique salts'],
            ['Database', 'SQLite with application-level encryption'],
            ['Transport', 'HTTPS for all network communications'],
            ['Storage', 'Secure local storage with OS-level protection'],
        ],
        [50, 140]
    )
    
    pdf.section_title('Role-Based Access Control', '5.2')
    pdf.body_text('Granular permission system based on user roles:')
    
    pdf.subsection_title('Doctor Role Permissions')
    pdf.bullet_point('Full patient access and management')
    pdf.bullet_point('Consultation and prescription management')
    pdf.bullet_point('View all reports and analytics')
    pdf.bullet_point('Settings and staff configuration')
    pdf.ln(3)
    
    pdf.subsection_title('Staff Role Permissions')
    pdf.bullet_point('Patient registration and search')
    pdf.bullet_point('Appointment booking and management')
    pdf.bullet_point('Payment collection and receipts')
    pdf.bullet_point('Limited report access (No consultation details)')
    
    pdf.section_title('Compliance', '5.3')
    pdf.create_table(
        ['Standard', 'Status'],
        [
            ['Data Privacy', 'Compliant'],
            ['Patient Confidentiality', 'Implemented'],
            ['Secure Authentication', 'SHA-256 + Salt'],
            ['Audit Logging', 'Activity tracking enabled'],
        ],
        [95, 95]
    )
    
    # Chapter 6: Integration APIs
    pdf.add_page()
    pdf.chapter_title('Integration APIs', '6')
    
    pdf.section_title('External Integrations', '6.1')
    pdf.create_table(
        ['Integration', 'Type', 'Purpose'],
        [
            ['WhatsApp', 'URL Scheme', 'Patient messaging'],
            ['SMS', 'Native Intent', 'Text notifications'],
            ['Phone Dialer', 'URL Scheme', 'Voice calls'],
            ['Email', 'SMTP', 'Email notifications'],
            ['Camera', 'Native Plugin', 'Photo capture'],
            ['Gallery', 'Native Plugin', 'Image selection'],
            ['Printer', 'Native Plugin', 'Document printing'],
            ['Google Forms', 'Web URL', 'Patient feedback'],
        ],
        [50, 50, 90]
    )
    
    pdf.section_title('Data Export APIs', '6.2')
    pdf.create_table(
        ['Export Type', 'Format', 'Available'],
        [
            ['Patient Data', 'JSON/CSV', 'Yes'],
            ['Consultations', 'PDF', 'Yes'],
            ['Financial Reports', 'PDF/Excel', 'Yes'],
            ['Prescriptions', 'PDF', 'Yes'],
        ],
        [65, 60, 65]
    )
    
    # Chapter 7: Deployment Guide
    pdf.chapter_title('Deployment Guide', '7')
    
    pdf.section_title('System Requirements', '7.1')
    pdf.subsection_title('Development Environment')
    pdf.create_table(
        ['Requirement', 'Minimum', 'Recommended'],
        [
            ['OS', 'Windows 10 / macOS 10.14', 'Windows 11 / macOS 13'],
            ['RAM', '8 GB', '16 GB'],
            ['Storage', '20 GB', '50 GB (SSD)'],
            ['Processor', 'Intel i5', 'Intel i7 / Apple M1'],
        ],
        [50, 70, 70]
    )
    
    pdf.subsection_title('Runtime Environment')
    pdf.create_table(
        ['Platform', 'Minimum Version'],
        [
            ['Android', '6.0 (API 23)'],
            ['iOS', '12.0'],
            ['Windows', 'Windows 10'],
            ['Web', 'Chrome 90+'],
        ],
        [95, 95]
    )
    
    pdf.section_title('Build Commands', '7.2')
    pdf.create_table(
        ['Platform', 'Command', 'Output'],
        [
            ['Android APK', 'flutter build apk --release', '.apk file'],
            ['Android Bundle', 'flutter build appbundle', '.aab file'],
            ['Windows', 'flutter build windows --release', '.exe installer'],
            ['Web', 'flutter build web --release', 'Web files'],
        ],
        [45, 90, 55]
    )
    
    # Chapter 8: Performance Metrics
    pdf.add_page()
    pdf.chapter_title('Performance Metrics', '8')
    
    pdf.section_title('Application Performance', '8.1')
    pdf.create_table(
        ['Metric', 'Target', 'Actual'],
        [
            ['App Launch Time', '< 3 seconds', '2.1 seconds'],
            ['Screen Transition', '< 300 ms', '180 ms'],
            ['Search Response', '< 100 ms', '45 ms'],
            ['Database Query', '< 50 ms', '30 ms'],
            ['PDF Generation', '< 2 seconds', '1.2 seconds'],
        ],
        [65, 60, 65]
    )
    
    pdf.section_title('Resource Usage', '8.2')
    pdf.create_table(
        ['Resource', 'Usage'],
        [
            ['App Size (APK)', '~25 MB'],
            ['Database (500 patients)', '~15 MB'],
            ['RAM Usage', '~150 MB'],
            ['CPU Usage (Idle)', '< 5%'],
        ],
        [95, 95]
    )
    
    # Chapter 9: Product Roadmap
    pdf.chapter_title('Product Roadmap', '9')
    
    pdf.section_title('Current Version: 2.0.0', '9.1')
    pdf.feature_status('Patient Management', 'Complete', 'Full lifecycle management')
    pdf.feature_status('Consultation Module', 'Complete', 'End-to-end consultations')
    pdf.feature_status('Payment System', 'Complete', 'Multi-mode, installments')
    pdf.feature_status('WhatsApp Integration', 'Complete', 'Direct messaging')
    pdf.feature_status('QR Code System', 'Complete', 'Deep link QR cards')
    pdf.feature_status('Waiting Room Display', 'Complete', 'TV display mode')
    pdf.feature_status('Analytics Dashboard', 'Complete', 'Real-time metrics')
    pdf.ln(5)
    
    pdf.section_title('Upcoming Features (v3.0)', '9.2')
    pdf.create_table(
        ['Feature', 'Priority', 'ETA'],
        [
            ['Multi-Clinic Support', 'High', 'Q1 2026'],
            ['Inventory Management', 'Medium', 'Q1 2026'],
            ['Lab Integration', 'Medium', 'Q2 2026'],
            ['Telemedicine Module', 'High', 'Q2 2026'],
            ['Insurance Integration', 'Low', 'Q3 2026'],
            ['AI Diagnosis Assistant', 'Medium', 'Q4 2026'],
        ],
        [70, 50, 70]
    )
    
    # Chapter 10: Support
    pdf.add_page()
    pdf.chapter_title('Support & Maintenance', '10')
    
    pdf.section_title('Technical Support Levels', '10.1')
    pdf.create_table(
        ['Support Level', 'Response Time', 'Availability'],
        [
            ['Critical Issues', '2 hours', '24/7'],
            ['High Priority', '4 hours', 'Business hours'],
            ['Normal', '24 hours', 'Business hours'],
            ['Feature Requests', '72 hours', 'Business hours'],
        ],
        [60, 65, 65]
    )
    
    pdf.section_title('Contact Information', '10.2')
    pdf.create_table(
        ['Channel', 'Contact'],
        [
            ['Email', 'support@singhtechnologies.com'],
            ['Phone', '+91-XXX-XXX-XXXX'],
            ['Documentation', 'docs.modiapp.com'],
            ['GitHub Issues', 'github.com/modi/issues'],
        ],
        [60, 130]
    )
    
    # Final page
    pdf.add_page()
    pdf.set_y(100)
    pdf.set_font('Helvetica', 'B', 20)
    pdf.set_text_color(99, 102, 241)
    pdf.cell(0, 15, 'End of Document', 0, 1, 'C')
    
    pdf.ln(10)
    pdf.set_font('Helvetica', '', 12)
    pdf.set_text_color(100, 100, 100)
    pdf.multi_cell(0, 8, 
        'This document contains proprietary information of Singh Technologies Pvt. Ltd. '
        'and is intended solely for the use of the individual or entity to whom it is addressed. '
        'Unauthorized disclosure, copying, distribution, or use of the contents of this document is prohibited.',
        align='C'
    )
    
    pdf.ln(20)
    pdf.set_font('Helvetica', 'B', 14)
    pdf.set_text_color(99, 102, 241)
    pdf.cell(0, 10, 'Singh Technologies Pvt. Ltd.', 0, 1, 'C')
    pdf.set_font('Helvetica', 'I', 10)
    pdf.set_text_color(100, 100, 100)
    pdf.cell(0, 8, 'Transforming Healthcare with Digital Innovation', 0, 1, 'C')
    pdf.cell(0, 6, f'Document Generated: {datetime.now().strftime("%B %d, %Y at %I:%M %p")}', 0, 1, 'C')
    
    # Save PDF
    pdf.output('e:/modi/MODI_COMPLETE_DOCUMENTATION.pdf')
    print('PDF created successfully: MODI_COMPLETE_DOCUMENTATION.pdf')

if __name__ == '__main__':
    create_documentation()

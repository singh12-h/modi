import 'package:flutter/material.dart';

class EmailFeatures extends StatefulWidget {
  const EmailFeatures({super.key});

  @override
  State<EmailFeatures> createState() => _EmailFeaturesState();
}

class _EmailFeaturesState extends State<EmailFeatures> {
  void _sendPrescription() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Prescription sent via email')),
    );
  }

  void _sendAppointmentConfirmation() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Appointment confirmation sent via email')),
    );
  }

  void _sendHealthSummary() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Monthly health summary sent via email')),
    );
  }

  void _sendReports() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reports and analytics sent via email')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Features'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Email Features',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildFeatureCard(
              'Send prescription via email',
              Icons.email,
              _sendPrescription,
            ),
            _buildFeatureCard(
              'Send appointment confirmations',
              Icons.calendar_today,
              _sendAppointmentConfirmation,
            ),
            _buildFeatureCard(
              'Send monthly health summary',
              Icons.summarize,
              _sendHealthSummary,
            ),
            _buildFeatureCard(
              'Send reports and analytics',
              Icons.analytics,
              _sendReports,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(String title, IconData icon, VoidCallback onPressed) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: Icon(icon, size: 40, color: Colors.blue),
        title: Text(title),
        trailing: ElevatedButton(
          onPressed: onPressed,
          child: const Text('Send'),
        ),
      ),
    );
  }
}

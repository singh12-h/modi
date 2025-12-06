import 'package:flutter/material.dart';

class LabReportsManagement extends StatefulWidget {
  const LabReportsManagement({super.key});

  @override
  State<LabReportsManagement> createState() => _LabReportsManagementState();
}

class _LabReportsManagementState extends State<LabReportsManagement> {
  final List<Map<String, String>> _reports = [
    {'name': 'CBC Test', 'date': '10 Nov 2024'},
    {'name': 'Blood Sugar', 'date': '10 Nov 2024'},
    {'name': 'X-Ray Chest', 'date': '05 Nov 2024'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lab Reports Management'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'LAB REPORTS - JOHN DOE',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _reports.length,
              itemBuilder: (context, index) {
                var report = _reports[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    leading: const Icon(Icons.description, size: 40),
                    title: Text(report['name']!),
                    subtitle: Text('Date: ${report['date']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () => _viewReport(report['name']!),
                          child: const Text('View'),
                        ),
                        TextButton(
                          onPressed: () => _downloadReport(report['name']!),
                          child: const Text('Download'),
                        ),
                        TextButton(
                          onPressed: () => _shareReport(report['name']!),
                          child: const Text('Share'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: _uploadReport,
              icon: const Icon(Icons.upload),
              label: const Text('UPLOAD NEW REPORT'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _viewReport(String reportName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Viewing $reportName')),
    );
  }

  void _downloadReport(String reportName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Downloading $reportName')),
    );
  }

  void _shareReport(String reportName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sharing $reportName')),
    );
  }

  void _uploadReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Upload new report')),
    );
  }
}

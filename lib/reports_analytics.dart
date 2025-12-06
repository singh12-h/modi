import 'package:flutter/material.dart';

class ReportsAnalytics extends StatefulWidget {
  const ReportsAnalytics({super.key});

  @override
  State<ReportsAnalytics> createState() => _ReportsAnalyticsState();
}

class _ReportsAnalyticsState extends State<ReportsAnalytics> {
  String _selectedPeriod = 'Today';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 10.1 DASHBOARD
            const Text(
              '📊 ANALYTICS DASHBOARD',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildPeriodButton('Today'),
                _buildPeriodButton('Week'),
                _buildPeriodButton('Month'),
                _buildPeriodButton('Custom Range'),
              ],
            ),
            const SizedBox(height: 20),
            // 10.2 KEY METRICS CARDS
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard('💰', '₹45,000', 'Total Revenue', '+15% vs last'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard('👥', '150', 'Total Patients', '+10% vs last'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard('📋', '135', 'Consultations', 'Avg: 45/day'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // 10.3 CHARTS
            const Text(
              'Charts',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildChartPlaceholder('Patient Trend Chart (Line Graph)'),
            _buildChartPlaceholder('Revenue Chart (Bar Graph)'),
            _buildChartPlaceholder('Appointment Status (Pie Chart)'),
            _buildChartPlaceholder('Peak Hours (Bar Chart)'),
            _buildChartPlaceholder('Top Diagnoses (Horizontal Bar Chart)'),
            const SizedBox(height: 20),
            // 10.4 DETAILED REPORTS
            const Text(
              'Detailed Reports',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildReportCard('Daily Report - 15 Nov 2024', [
              'Total Patients: 32',
              'New Patients: 12',
              'Follow-ups: 20',
              'Consultations Completed: 30',
              'Average Wait Time: 25 mins',
              'Average Consultation: 15 mins',
              'Revenue Collected: ₹16,000',
              'Pending Payments: ₹2,000',
            ]),
            const SizedBox(height: 10),
            _buildReportCard('Monthly Report', [
              'Total patients, new vs returning',
              'Revenue breakdown',
              'Payment mode distribution',
              'Doctor-wise statistics',
              'Top medicines prescribed',
              'Common diagnoses',
              'Age distribution',
              'Gender distribution',
            ]),
            const SizedBox(height: 20),
            // 10.5 EXPORT OPTIONS
            const Text(
              'Export Options',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _export('PDF'),
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('PDF'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _export('Excel'),
                  icon: const Icon(Icons.table_chart),
                  label: const Text('Excel'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _export('CSV'),
                  icon: const Icon(Icons.file_present),
                  label: const Text('CSV'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _export('Email'),
                  icon: const Icon(Icons.email),
                  label: const Text('Email'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _export('Print'),
                  icon: const Icon(Icons.print),
                  label: const Text('Print'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodButton(String period) {
    return Expanded(
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _selectedPeriod = period;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: _selectedPeriod == period ? Colors.blue : Colors.grey,
        ),
        child: Text(period),
      ),
    );
  }

  Widget _buildMetricCard(String icon, String value, String title, String change) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 30)),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(title),
            Text(change, style: const TextStyle(color: Colors.green)),
          ],
        ),
      ),
    );
  }

  Widget _buildChartPlaceholder(String title) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              height: 150,
              color: Colors.grey[200],
              child: const Center(child: Text('Chart Placeholder')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(String title, List<String> details) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...details.map((detail) => Text(detail)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.email),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.print),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _export(String format) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Exporting as $format')),
    );
  }
}

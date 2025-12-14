import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'database_helper.dart';
import 'models.dart';
import 'package:intl/intl.dart';
import 'responsive_helper.dart';

class ReportsAnalytics extends StatefulWidget {
  const ReportsAnalytics({super.key});

  @override
  State<ReportsAnalytics> createState() => _ReportsAnalyticsState();
}

class _ReportsAnalyticsState extends State<ReportsAnalytics> {
  String _selectedPeriod = 'Today';
  bool _isLoading = true;
  
  // Analytics Data
  int _totalPatients = 0;
  int _newPatients = 0;
  int _followUpPatients = 0;
  double _totalRevenue = 0;
  int _completedConsultations = 0;
  List<Patient> _patients = [];
  Map<String, int> _genderDistribution = {};
  Map<int, int> _hourlyDistribution = {};
  List<MapEntry<String, int>> _topSymptoms = [];

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    
    try {
      final now = DateTime.now();
      DateTime startDate;
      DateTime endDate = now;
      
      switch (_selectedPeriod) {
        case 'Today':
          startDate = DateTime(now.year, now.month, now.day);
          break;
        case 'Week':
          startDate = now.subtract(const Duration(days: 7));
          break;
        case 'Month':
          startDate = DateTime(now.year, now.month - 1, now.day);
          break;
        default:
          startDate = DateTime(now.year, now.month, now.day);
      }
      
      // Get patients in date range
      final allPatients = await DatabaseHelper.instance.getAllPatients();
      _patients = allPatients.where((p) {
        return p.registrationTime.isAfter(startDate) && 
               p.registrationTime.isBefore(endDate.add(const Duration(days: 1)));
      }).toList();
      
      _totalPatients = _patients.length;
      _newPatients = _patients.where((p) => p.consultationCount <= 1).length;
      _followUpPatients = _patients.where((p) => p.consultationCount > 1).length;
      _completedConsultations = _patients.where((p) => p.status == PatientStatus.completed).length;
      
      // Gender distribution
      _genderDistribution = {};
      for (var p in _patients) {
        _genderDistribution[p.gender] = (_genderDistribution[p.gender] ?? 0) + 1;
      }
      
      // Hourly distribution
      _hourlyDistribution = {};
      for (var p in _patients) {
        int hour = p.registrationTime.hour;
        _hourlyDistribution[hour] = (_hourlyDistribution[hour] ?? 0) + 1;
      }
      
      // Top symptoms
      Map<String, int> symptomsCount = {};
      for (var p in _patients) {
        if (p.symptoms != null && p.symptoms!.isNotEmpty) {
          symptomsCount[p.symptoms!] = (symptomsCount[p.symptoms!] ?? 0) + 1;
        }
      }
      _topSymptoms = symptomsCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      if (_topSymptoms.length > 5) _topSymptoms = _topSymptoms.sublist(0, 5);
      
      // Calculate revenue (placeholder - you can connect to actual payment data)
      _totalRevenue = _patients.length * 500.0; // Average fee per patient
      
    } catch (e) {
      print('Error loading analytics: $e');
    }
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),
              
              // Content
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Period Selector
                              _buildPeriodSelector(),
                              const SizedBox(height: 20),
                              
                              // Key Metrics Cards
                              _buildMetricsRow(),
                              const SizedBox(height: 24),
                              
                              // Patient Trend Chart
                              _buildSectionTitle('📈 Patient Status Overview'),
                              _buildPatientStatusPieChart(),
                              const SizedBox(height: 24),
                              
                              // Gender Distribution
                              _buildSectionTitle('👥 Gender Distribution'),
                              _buildGenderPieChart(),
                              const SizedBox(height: 24),
                              
                              // Peak Hours Chart
                              _buildSectionTitle('⏰ Peak Hours'),
                              _buildPeakHoursChart(),
                              const SizedBox(height: 24),
                              
                              // Top Symptoms
                              _buildSectionTitle('🩺 Top Symptoms'),
                              _buildTopSymptomsChart(),
                              const SizedBox(height: 24),
                              
                              // Detailed Report Card
                              _buildDetailedReportCard(),
                              const SizedBox(height: 24),
                              
                              // Export Options
                              _buildExportSection(),
                              const SizedBox(height: 30),
                            ],
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 10),
          const Text(
            'Reports & Analytics',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadAnalytics,
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: ['Today', 'Week', 'Month'].map((period) {
          final isSelected = _selectedPeriod == period;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedPeriod = period);
                _loadAnalytics();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  period,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMetricsRow() {
    ResponsiveHelper.init(context);
    final isSmall = ResponsiveHelper.isMobile && ResponsiveHelper.screenWidth < 400;
    
    final cards = [
      _buildMetricCard(
        icon: Icons.people_alt,
        value: '$_totalPatients',
        label: 'Total',
        color: const Color(0xFF667eea),
      ),
      _buildMetricCard(
        icon: Icons.person_add,
        value: '$_newPatients',
        label: 'New',
        color: const Color(0xFF10B981),
      ),
      _buildMetricCard(
        icon: Icons.check_circle,
        value: '$_completedConsultations',
        label: 'Done',
        color: const Color(0xFFEC4899),
      ),
    ];
    
    // On very small screens, use 2-column grid instead of row
    if (isSmall) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: cards.map((card) => SizedBox(
          width: (ResponsiveHelper.screenWidth - 56) / 2, // 2 columns with padding
          child: card,
        )).toList(),
      );
    }
    
    return Row(
      children: [
        Expanded(child: cards[0]),
        const SizedBox(width: 12),
        Expanded(child: cards[1]),
        const SizedBox(width: 12),
        Expanded(child: cards[2]),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1F2937),
        ),
      ),
    );
  }

  Widget _buildPatientStatusPieChart() {
    final waiting = _patients.where((p) => p.status == PatientStatus.waiting).length;
    final inProgress = _patients.where((p) => p.status == PatientStatus.inProgress).length;
    final completed = _patients.where((p) => p.status == PatientStatus.completed).length;
    
    if (_patients.isEmpty) {
      return _buildEmptyChart('No patient data available');
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 50,
                sections: [
                  PieChartSectionData(
                    value: waiting.toDouble(),
                    title: '$waiting',
                    color: const Color(0xFFFBBF24),
                    radius: 50,
                    titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: inProgress.toDouble(),
                    title: '$inProgress',
                    color: const Color(0xFF3B82F6),
                    radius: 50,
                    titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: completed.toDouble(),
                    title: '$completed',
                    color: const Color(0xFF10B981),
                    radius: 50,
                    titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegendItem('Waiting', const Color(0xFFFBBF24)),
              _buildLegendItem('In Progress', const Color(0xFF3B82F6)),
              _buildLegendItem('Completed', const Color(0xFF10B981)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenderPieChart() {
    if (_genderDistribution.isEmpty) {
      return _buildEmptyChart('No gender data available');
    }
    
    final colors = {
      'Male': const Color(0xFF3B82F6),
      'Female': const Color(0xFFEC4899),
      'Other': const Color(0xFF8B5CF6),
    };
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 40,
                sections: _genderDistribution.entries.map((e) {
                  return PieChartSectionData(
                    value: e.value.toDouble(),
                    title: '${e.value}',
                    color: colors[e.key] ?? Colors.grey,
                    radius: 45,
                    titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _genderDistribution.entries.map((e) {
              return _buildLegendItem(e.key, colors[e.key] ?? Colors.grey);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPeakHoursChart() {
    if (_hourlyDistribution.isEmpty) {
      return _buildEmptyChart('No hourly data available');
    }
    
    // Create bar groups for hours 8 AM to 8 PM
    List<BarChartGroupData> barGroups = [];
    for (int hour = 8; hour <= 20; hour++) {
      barGroups.add(
        BarChartGroupData(
          x: hour,
          barRods: [
            BarChartRodData(
              toY: (_hourlyDistribution[hour] ?? 0).toDouble(),
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
              width: 16,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
            ),
          ],
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: (_hourlyDistribution.values.isEmpty ? 10 : 
                   _hourlyDistribution.values.reduce((a, b) => a > b ? a : b) + 2).toDouble(),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    '${group.x}:00\n${rod.toY.toInt()} patients',
                    const TextStyle(color: Colors.white, fontSize: 12),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value % 2 == 0) {
                      return Text(
                        '${value.toInt()}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 10),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      '${value.toInt()}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 10),
                    );
                  },
                ),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.grey[200]!,
                  strokeWidth: 1,
                );
              },
            ),
            barGroups: barGroups,
          ),
        ),
      ),
    );
  }

  Widget _buildTopSymptomsChart() {
    if (_topSymptoms.isEmpty) {
      return _buildEmptyChart('No symptoms data available');
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: _topSymptoms.asMap().entries.map((entry) {
          final index = entry.key;
          final symptom = entry.value;
          final maxCount = _topSymptoms.first.value;
          final percentage = symptom.value / maxCount;
          
          final colors = [
            const Color(0xFF667eea),
            const Color(0xFF10B981),
            const Color(0xFFEC4899),
            const Color(0xFFFBBF24),
            const Color(0xFF8B5CF6),
          ];
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    symptom.key.length > 15 
                        ? '${symptom.key.substring(0, 15)}...' 
                        : symptom.key,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: percentage,
                        child: Container(
                          height: 24,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                colors[index % colors.length],
                                colors[index % colors.length].withOpacity(0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${symptom.value}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDetailedReportCard() {
    final today = DateFormat('dd MMM yyyy').format(DateTime.now());
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assessment, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Text(
                '$_selectedPeriod Report - $today',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildReportRow('Total Patients', '$_totalPatients'),
          _buildReportRow('New Patients', '$_newPatients'),
          _buildReportRow('Follow-ups', '$_followUpPatients'),
          _buildReportRow('Completed Consultations', '$_completedConsultations'),
          _buildReportRow('Estimated Revenue', '₹${_totalRevenue.toStringAsFixed(0)}'),
        ],
      ),
    );
  }

  Widget _buildReportRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportSection() {
    ResponsiveHelper.init(context);
    final isSmall = ResponsiveHelper.screenWidth < 380;
    
    final buttons = [
      _buildExportButton(
        icon: Icons.picture_as_pdf,
        label: 'PDF',
        color: const Color(0xFFEF4444),
        onTap: () => _export('PDF'),
      ),
      _buildExportButton(
        icon: Icons.table_chart,
        label: 'Excel',
        color: const Color(0xFF10B981),
        onTap: () => _export('Excel'),
      ),
      _buildExportButton(
        icon: Icons.print,
        label: 'Print',
        color: const Color(0xFF3B82F6),
        onTap: () => _export('Print'),
      ),
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('📤 Export Options'),
        isSmall
            ? Wrap(
                spacing: 8,
                runSpacing: 8,
                children: buttons.map((btn) => SizedBox(
                  width: (ResponsiveHelper.screenWidth - 56) / 2,
                  child: btn,
                )).toList(),
              )
            : Row(
                children: [
                  Expanded(child: buttons[0]),
                  const SizedBox(width: 12),
                  Expanded(child: buttons[1]),
                  const SizedBox(width: 12),
                  Expanded(child: buttons[2]),
                ],
              ),
      ],
    );
  }

  Widget _buildExportButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyChart(String message) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.bar_chart, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  void _export(String format) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exporting as $format...'),
        backgroundColor: const Color(0xFF667eea),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

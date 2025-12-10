import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Storage Alert Service
class StorageAlertService {
  static const double warningThresholdMB = 300.0;
  static const double maxStorageMB = 1024.0;
  
  static const String developerEmail = 'support@modiapp.com';
  static const String developerPhone = '+91-9876543210';
  static const String developerWhatsApp = '+919876543210';
  
  static Future<double> getDatabaseSizeMB() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final dbPath = path.join(directory.path, 'modi_database.db');
      final file = File(dbPath);
      if (await file.exists()) {
        return await file.length() / (1024 * 1024);
      }
      return 0.0;
    } catch (e) {
      return 0.0;
    }
  }
  
  static Future<double> getTotalStorageMB() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      double totalSize = 0.0;
      await for (final entity in directory.list(recursive: true, followLinks: false)) {
        if (entity is File) totalSize += await entity.length();
      }
      return totalSize / (1024 * 1024);
    } catch (e) {
      return 0.0;
    }
  }
  
  static Future<bool> shouldShowWarning() async {
    final usedMB = await getTotalStorageMB();
    return (maxStorageMB - usedMB) <= warningThresholdMB && usedMB > 0;
  }
  
  static Future<double> getRemainingStorageMB() async {
    return maxStorageMB - await getTotalStorageMB();
  }
  
  static Future<double> getStorageUsagePercent() async {
    return ((await getTotalStorageMB()) / maxStorageMB * 100).clamp(0.0, 100.0);
  }
}

/// Modern Light Medical Themed Storage Alert Widget
class StorageAlertWidget extends StatefulWidget {
  final VoidCallback? onDismiss;
  const StorageAlertWidget({super.key, this.onDismiss});

  @override
  State<StorageAlertWidget> createState() => _StorageAlertWidgetState();
}

class _StorageAlertWidgetState extends State<StorageAlertWidget> {
  double _usedMB = 0.0;
  double _remainingMB = 0.0;
  double _usagePercent = 0.0;
  bool _isLoading = true;
  bool _isDismissed = false;
  int _notificationCount = 1;

  @override
  void initState() {
    super.initState();
    _loadStorageInfo();
  }

  Future<void> _loadStorageInfo() async {
    final used = await StorageAlertService.getTotalStorageMB();
    final remaining = await StorageAlertService.getRemainingStorageMB();
    final percent = await StorageAlertService.getStorageUsagePercent();
    if (mounted) {
      setState(() {
        _usedMB = used;
        _remainingMB = remaining;
        _usagePercent = percent;
        _isLoading = false;
      });
    }
  }

  void _clearNotification() => setState(() => _notificationCount = 0);
  void _dismissAlert() {
    setState(() => _isDismissed = true);
    widget.onDismiss?.call();
  }

  Future<void> _contactViaEmail() async {
    final Uri uri = Uri(scheme: 'mailto', path: StorageAlertService.developerEmail);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _contactViaPhone() async {
    final Uri uri = Uri(scheme: 'tel', path: StorageAlertService.developerPhone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _contactViaWhatsApp() async {
    final msg = Uri.encodeComponent('Hello, I need to upgrade my MODI App storage.\nUsed: ${_usedMB.toStringAsFixed(1)} MB\nRemaining: ${_remainingMB.toStringAsFixed(1)} MB');
    final Uri uri = Uri.parse('https://wa.me/${StorageAlertService.developerWhatsApp}?text=$msg');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    if (_isDismissed) return const SizedBox.shrink();
    
    final w = MediaQuery.of(context).size.width;
    final isSmall = w < 400;
    final bool isWarning = _remainingMB <= StorageAlertService.warningThresholdMB;
    final bool isCritical = _remainingMB <= 100;
    
    // Colors based on status
    final Color primary = isCritical ? const Color(0xFFE53935) : isWarning ? const Color(0xFFFF9800) : const Color(0xFF7C4DFF);
    final Color accent = isCritical ? const Color(0xFFFFEBEE) : isWarning ? const Color(0xFFFFF3E0) : const Color(0xFFEDE7F6);

    return Container(
      margin: EdgeInsets.all(isSmall ? 10 : 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            accent.withOpacity(0.3),
            Colors.white,
          ],
        ),
        boxShadow: [
          BoxShadow(color: primary.withOpacity(0.2), blurRadius: 25, offset: const Offset(0, 8)),
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Medical decorative icons - top area
            Positioned(top: 10, right: 15, child: Icon(Icons.medication_rounded, size: 35, color: const Color(0xFF4CAF50).withOpacity(0.15))),
            Positioned(top: 50, right: 60, child: Icon(Icons.healing_rounded, size: 28, color: const Color(0xFFE91E63).withOpacity(0.12))),
            Positioned(top: 25, right: 110, child: Icon(Icons.medical_services_rounded, size: 30, color: const Color(0xFF2196F3).withOpacity(0.12))),
            
            // Medical decorative icons - bottom area
            Positioned(bottom: 20, left: 15, child: Icon(Icons.vaccines_rounded, size: 32, color: const Color(0xFFFF5722).withOpacity(0.12))),
            Positioned(bottom: 60, left: 55, child: Icon(Icons.biotech_rounded, size: 28, color: const Color(0xFF9C27B0).withOpacity(0.1))),
            Positioned(bottom: 30, left: 100, child: Icon(Icons.health_and_safety_rounded, size: 26, color: const Color(0xFF00BCD4).withOpacity(0.12))),
            
            // Colorful circles decoration
            Positioned(top: -25, left: -25, child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [const Color(0xFF7C4DFF).withOpacity(0.15), Colors.transparent]),
              ),
            )),
            Positioned(bottom: -30, right: -30, child: Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [const Color(0xFF00BCD4).withOpacity(0.12), Colors.transparent]),
              ),
            )),
            Positioned(top: 80, right: -20, child: Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [const Color(0xFFE91E63).withOpacity(0.1), Colors.transparent]),
              ),
            )),
            
            // Pill shapes decoration
            Positioned(top: 100, left: 10, child: _buildPillShape(const Color(0xFF4CAF50), 40, 16)),
            Positioned(bottom: 100, right: 10, child: _buildPillShape(const Color(0xFFFF9800), 35, 14)),
            Positioned(top: 150, right: 50, child: _buildCapsule(const Color(0xFFE91E63), const Color(0xFFFFFFFF), 30, 12)),
            
            // Main Content
            Padding(
              padding: EdgeInsets.all(isSmall ? 18 : 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    children: [
                      // Icon with gradient
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            padding: EdgeInsets.all(isSmall ? 14 : 18),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [primary, primary.withOpacity(0.7)]),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [BoxShadow(color: primary.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 5))],
                            ),
                            child: Icon(
                              isCritical ? Icons.warning_amber_rounded : Icons.storage_rounded,
                              color: Colors.white, 
                              size: isSmall ? 28 : 34,
                            ),
                          ),
                          if (_notificationCount > 0)
                            Positioned(top: -8, right: -8, child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFFFF5252), Color(0xFFFF1744)]),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2.5),
                                boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.4), blurRadius: 8)],
                              ),
                              child: Text('$_notificationCount', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            )),
                        ],
                      ),
                      SizedBox(width: isSmall ? 14 : 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isCritical ? '⚠️ Storage Critical!' : isWarning ? '⚠️ Storage Low' : '💾 Storage Status',
                              style: TextStyle(fontSize: isSmall ? 18 : 22, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A2E)),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [accent, accent.withOpacity(0.5)]),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: primary.withOpacity(0.2)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.local_hospital_rounded, size: 14, color: primary),
                                  const SizedBox(width: 5),
                                  Text('MODI Medical Database', style: TextStyle(fontSize: 11, color: primary, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_notificationCount > 0)
                        IconButton(onPressed: _clearNotification, icon: Icon(Icons.notifications_off_outlined, color: Colors.grey.shade500, size: 22)),
                      IconButton(onPressed: _dismissAlert, icon: Icon(Icons.close_rounded, color: Colors.grey.shade500, size: 22)),
                    ],
                  ),
                  
                  SizedBox(height: isSmall ? 22 : 30),
                  
                  if (_isLoading)
                    Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(primary)))
                  else ...[
                    // Storage meter with medical theme
                    Container(
                      padding: EdgeInsets.all(isSmall ? 16 : 22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Row(
                        children: [
                          // Colorful circular meter
                          Container(
                            width: isSmall ? 80 : 100,
                            height: isSmall ? 80 : 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [accent.withOpacity(0.3), Colors.white],
                                radius: 0.8,
                              ),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox.expand(
                                  child: CircularProgressIndicator(
                                    value: _usagePercent / 100,
                                    strokeWidth: isSmall ? 10 : 12,
                                    backgroundColor: Colors.grey.shade200,
                                    valueColor: AlwaysStoppedAnimation<Color>(primary),
                                  ),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('${_usagePercent.toStringAsFixed(0)}%', style: TextStyle(fontSize: isSmall ? 18 : 22, fontWeight: FontWeight.bold, color: primary)),
                                    Text('Used', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: isSmall ? 16 : 24),
                          Expanded(
                            child: Column(
                              children: [
                                _buildColorfulInfoRow(Icons.cloud_upload_rounded, 'Used', '${_usedMB.toStringAsFixed(1)} MB', const Color(0xFF7C4DFF)),
                                const SizedBox(height: 10),
                                _buildColorfulInfoRow(Icons.cloud_download_rounded, 'Free', '${_remainingMB.toStringAsFixed(1)} MB', 
                                  isWarning ? const Color(0xFFFF9800) : const Color(0xFF4CAF50)),
                                const SizedBox(height: 10),
                                _buildColorfulInfoRow(Icons.cloud_done_rounded, 'Total', '${StorageAlertService.maxStorageMB.toInt()} MB', const Color(0xFF2196F3)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: isSmall ? 18 : 24),
                    
                    // Warning banner
                    if (isWarning)
                      Container(
                        padding: EdgeInsets.all(isSmall ? 14 : 18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [accent, accent.withOpacity(0.3)]),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: primary.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                              child: Icon(Icons.medical_information_rounded, color: primary, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                isCritical ? 'Storage full! Contact us now to continue saving patient data.' 
                                  : 'Storage running low. Upgrade to keep your medical records safe.',
                                style: TextStyle(fontSize: isSmall ? 12 : 14, color: const Color(0xFF374151), height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    SizedBox(height: isSmall ? 18 : 24),
                    
                    // Contact section
                    Row(
                      children: [
                        Container(width: 5, height: 22, decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [primary, primary.withOpacity(0.4)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                          borderRadius: BorderRadius.circular(3),
                        )),
                        const SizedBox(width: 10),
                        const Text('Contact Developer', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
                      ],
                    ),
                    
                    SizedBox(height: isSmall ? 14 : 18),
                    
                    // Colorful contact buttons
                    Row(
                      children: [
                        Expanded(child: _buildColorfulContactBtn(Icons.email_rounded, 'Email', const Color(0xFF5C6BC0), _contactViaEmail, isSmall)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildColorfulContactBtn(Icons.phone_rounded, 'Call', const Color(0xFF26A69A), _contactViaPhone, isSmall)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildColorfulContactBtn(Icons.chat_rounded, 'WhatsApp', const Color(0xFF66BB6A), _contactViaWhatsApp, isSmall)),
                      ],
                    ),
                    
                    SizedBox(height: isSmall ? 18 : 22),
                    
                    // Upgrade button with gradient
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [primary, primary.withOpacity(0.8)]),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: primary.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 6))],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _contactViaWhatsApp,
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: isSmall ? 16 : 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 22),
                                const SizedBox(width: 10),
                                Text('Upgrade Storage Now', style: TextStyle(fontSize: isSmall ? 15 : 17, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.3)),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(10)),
                                  child: const Text('PRO', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPillShape(Color color, double width, double height) {
    return Container(
      width: width, height: height,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(height / 2),
      ),
    );
  }

  Widget _buildCapsule(Color color1, Color color2, double width, double height) {
    return Container(
      width: width, height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(height / 2),
        gradient: LinearGradient(colors: [color1.withOpacity(0.2), color2.withOpacity(0.1)]),
      ),
    );
  }

  Widget _buildColorfulInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600))),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildColorfulContactBtn(IconData icon, String label, Color color, VoidCallback onTap, bool isSmall) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: isSmall ? 14 : 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color.withOpacity(0.1), color.withOpacity(0.05)]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: Icon(icon, color: Colors.white, size: isSmall ? 20 : 24),
              ),
              SizedBox(height: isSmall ? 8 : 10),
              Text(label, style: TextStyle(fontSize: isSmall ? 11 : 13, color: color, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact storage indicator
class CompactStorageIndicator extends StatefulWidget {
  final VoidCallback? onTap;
  const CompactStorageIndicator({super.key, this.onTap});

  @override
  State<CompactStorageIndicator> createState() => _CompactStorageIndicatorState();
}

class _CompactStorageIndicatorState extends State<CompactStorageIndicator> {
  double _usagePercent = 0.0;
  bool _isWarning = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final percent = await StorageAlertService.getStorageUsagePercent();
    final remaining = await StorageAlertService.getRemainingStorageMB();
    if (mounted) setState(() { _usagePercent = percent; _isWarning = remaining <= StorageAlertService.warningThresholdMB; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox.shrink();
    final color = _isWarning ? (_usagePercent > 90 ? const Color(0xFFEF4444) : const Color(0xFFF59E0B)) : const Color(0xFF22D3EE);

    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.4))),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isWarning) Container(width: 8, height: 8, margin: const EdgeInsets.only(right: 6), decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            Icon(Icons.storage, size: 16, color: color),
            const SizedBox(width: 5),
            Text('${_usagePercent.toStringAsFixed(0)}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}

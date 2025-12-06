import 'package:flutter/material.dart';

/// Shared service to manage doctor leaves across the app
/// This allows appointment management and booking to share leave data
class DoctorLeaveService {
  // Singleton pattern
  static final DoctorLeaveService _instance = DoctorLeaveService._internal();
  factory DoctorLeaveService() => _instance;
  DoctorLeaveService._internal();
  
  // List of doctor leaves
  final List<Map<String, dynamic>> _leaves = [];
  
  // Listeners for changes
  final List<VoidCallback> _listeners = [];
  
  /// Add a new leave
  void addLeave(DateTime date, String reason) {
    _leaves.add({
      'date': date,
      'reason': reason,
    });
    _notifyListeners();
  }
  
  /// Remove a leave by index
  void removeLeave(int index) {
    if (index >= 0 && index < _leaves.length) {
      _leaves.removeAt(index);
      _notifyListeners();
    }
  }
  
  /// Get all leaves
  List<Map<String, dynamic>> getAllLeaves() {
    return List.unmodifiable(_leaves);
  }
  
  /// Check if a date is a leave day
  bool isLeaveDay(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    for (var leave in _leaves) {
      final leaveDate = DateTime(
        leave['date'].year,
        leave['date'].month,
        leave['date'].day,
      );
      if (leaveDate == dateOnly) {
        return true;
      }
    }
    return false;
  }
  
  /// Get leave reason for a specific date
  String? getLeaveReason(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    for (var leave in _leaves) {
      final leaveDate = DateTime(
        leave['date'].year,
        leave['date'].month,
        leave['date'].day,
      );
      if (leaveDate == dateOnly) {
        return leave['reason'];
      }
    }
    return null;
  }
  
  /// Add a listener for leave changes
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }
  
  /// Remove a listener
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }
  
  /// Notify all listeners of changes
  void _notifyListeners() {
    for (var listener in _listeners) {
      listener();
    }
  }
  
  /// Clear all leaves
  void clearAllLeaves() {
    _leaves.clear();
    _notifyListeners();
  }
}

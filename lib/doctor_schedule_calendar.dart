import 'package:flutter/material.dart';

class DoctorScheduleCalendar extends StatefulWidget {
  const DoctorScheduleCalendar({super.key});

  @override
  State<DoctorScheduleCalendar> createState() => _DoctorScheduleCalendarState();
}

class _DoctorScheduleCalendarState extends State<DoctorScheduleCalendar> {
  final List<Map<String, dynamic>> _schedule = [
    {'day': 'Monday', 'time': '09:00 AM - 02:00 PM', 'available': true},
    {'day': 'Tuesday', 'time': '09:00 AM - 02:00 PM', 'available': true},
    {'day': 'Wednesday', 'time': '09:00 AM - 02:00 PM', 'available': true},
    {'day': 'Thursday', 'time': '09:00 AM - 02:00 PM', 'available': true},
    {'day': 'Friday', 'time': '09:00 AM - 02:00 PM', 'available': true},
    {'day': 'Saturday', 'time': '09:00 AM - 12:00 PM', 'available': true},
    {'day': 'Sunday', 'time': 'CLOSED', 'available': false},
  ];

  final List<String> _holidays = [
    '25 Dec 2024 - Christmas',
    '01 Jan 2025 - New Year',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor\'s Schedule'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'MY SCHEDULE',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ..._schedule.map((day) => Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                title: Text(day['day']),
                subtitle: Text(day['time']),
                trailing: Icon(
                  day['available'] ? Icons.check_circle : Icons.cancel,
                  color: day['available'] ? Colors.green : Colors.red,
                ),
              ),
            )),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _editSchedule,
              child: const Text('EDIT SCHEDULE'),
            ),
            const SizedBox(height: 20),
            const Text(
              'HOLIDAYS & LEAVES:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ..._holidays.map((holiday) => Text(holiday)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addLeave,
              child: const Text('ADD LEAVE'),
            ),
          ],
        ),
      ),
    );
  }

  void _editSchedule() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit schedule')),
    );
  }

  void _addLeave() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add leave')),
    );
  }
}

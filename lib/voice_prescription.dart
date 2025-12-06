import 'package:flutter/material.dart';

class VoicePrescription extends StatefulWidget {
  const VoicePrescription({super.key});

  @override
  State<VoicePrescription> createState() => _VoicePrescriptionState();
}

class _VoicePrescriptionState extends State<VoicePrescription> {
  bool _isRecording = false;
  String _transcription = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Prescription'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '🎤 VOICE PRESCRIPTION',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: _toggleRecording,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: _isRecording ? Colors.red : Colors.blue,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isRecording ? Icons.stop : Icons.mic,
                  size: 80,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _isRecording ? 'TAP TO STOP' : 'TAP TO SPEAK',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                _transcription.isEmpty ? '"Tab paracetamol 500mg\n1-0-1 after food 5 days"' : _transcription,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('CLEAR'),
                ),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('ADD TO Rx'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _toggleRecording() {
    setState(() {
      _isRecording = !_isRecording;
      if (!_isRecording && _transcription.isEmpty) {
        _transcription = 'Tab paracetamol 500mg\n1-0-1 after food 5 days';
      }
    });
  }
}

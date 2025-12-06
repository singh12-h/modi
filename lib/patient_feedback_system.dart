import 'package:flutter/material.dart';

class PatientFeedbackSystem extends StatefulWidget {
  const PatientFeedbackSystem({super.key});

  @override
  State<PatientFeedbackSystem> createState() => _PatientFeedbackSystemState();
}

class _PatientFeedbackSystemState extends State<PatientFeedbackSystem> {
  int _overallRating = 0;
  int _doctorRating = 0;
  int _staffRating = 0;
  int _cleanlinessRating = 0;
  int _waitingTimeRating = 0;
  final TextEditingController _commentsController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Feedback'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'FEEDBACK FORM',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              'How was your experience?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  onPressed: () => setState(() => _overallRating = index + 1),
                  icon: Icon(
                    index < _overallRating ? Icons.star : Icons.star_border,
                    size: 40,
                    color: Colors.amber,
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            _buildRatingRow('Doctor Rating:', _doctorRating, (rating) => setState(() => _doctorRating = rating)),
            _buildRatingRow('Staff Rating:', _staffRating, (rating) => setState(() => _staffRating = rating)),
            _buildRatingRow('Cleanliness:', _cleanlinessRating, (rating) => setState(() => _cleanlinessRating = rating)),
            _buildRatingRow('Waiting Time:', _waitingTimeRating, (rating) => setState(() => _waitingTimeRating = rating)),
            const SizedBox(height: 20),
            const Text(
              'Comments:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _commentsController,
              maxLines: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Please share your feedback...',
              ),
            ),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: _submitFeedback,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: const Text('SUBMIT FEEDBACK'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingRow(String label, int rating, Function(int) onRatingChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Row(
            children: List.generate(5, (index) {
              return IconButton(
                onPressed: () => onRatingChanged(index + 1),
                icon: Icon(
                  index < rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  void _submitFeedback() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Thank you for your feedback!')),
    );
  }

  @override
  void dispose() {
    _commentsController.dispose();
    super.dispose();
  }
}

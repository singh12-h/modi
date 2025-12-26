import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'database_helper.dart';
import 'models.dart';

class PatientFeedbackSystem extends StatefulWidget {
  final String? patientId;
  final String? patientName;
  
  const PatientFeedbackSystem({super.key, this.patientId, this.patientName});

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
  final TextEditingController _nameController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.patientName != null) {
      _nameController.text = widget.patientName!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        '📝 Patient Feedback',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        const Center(
                          child: Column(
                            children: [
                              Icon(Icons.rate_review, size: 50, color: Color(0xFF667eea)),
                              SizedBox(height: 10),
                              Text(
                                'Share Your Experience',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              Text(
                                'Your feedback helps us improve our services',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                        
                        // Patient Name
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Your Name (Optional)',
                            prefixIcon: const Icon(Icons.person, color: Color(0xFF667eea)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF667eea), width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Overall Experience
                        _buildRatingSection(
                          '⭐ Overall Experience',
                          'How was your overall visit?',
                          _overallRating,
                          (rating) => setState(() => _overallRating = rating),
                          Colors.amber,
                        ),
                        
                        // Doctor Rating
                        _buildRatingSection(
                          '👨‍⚕️ Doctor',
                          "How was the doctor's consultation?",
                          _doctorRating,
                          (rating) => setState(() => _doctorRating = rating),
                          Colors.blue,
                        ),
                        
                        // Staff Rating
                        _buildRatingSection(
                          '👥 Staff Behavior',
                          "How was the staff's behavior?",
                          _staffRating,
                          (rating) => setState(() => _staffRating = rating),
                          Colors.purple,
                        ),
                        
                        // Cleanliness
                        _buildRatingSection(
                          '🧹 Cleanliness',
                          'How clean was the clinic?',
                          _cleanlinessRating,
                          (rating) => setState(() => _cleanlinessRating = rating),
                          Colors.green,
                        ),
                        
                        // Waiting Time
                        _buildRatingSection(
                          '⏰ Waiting Time',
                          'How was the waiting time?',
                          _waitingTimeRating,
                          (rating) => setState(() => _waitingTimeRating = rating),
                          Colors.orange,
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Comments
                        const Text(
                          '💬 Additional Comments',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _commentsController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Tell us more about your experience...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF667eea), width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        
                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitFeedback,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF667eea),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                            ),
                            child: _isSubmitting
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text(
                                    'SUBMIT FEEDBACK',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),
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

  Widget _buildRatingSection(String title, String subtitle, int rating, Function(int) onRatingChanged, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return Expanded(
                child: IconButton(
                  onPressed: () => onRatingChanged(index + 1),
                  icon: Icon(
                    index < rating ? Icons.star : Icons.star_border,
                    size: 36,
                    color: color,
                  ),
                ),
              );
            }),
          ),
          if (rating > 0)
            Center(
              child: Text(
                _getRatingText(rating),
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1: return '😡 Very Poor';
      case 2: return '😕 Poor';
      case 3: return '😐 Average';
      case 4: return '🙂 Good';
      case 5: return '😊 Excellent';
      default: return '';
    }
  }

  Future<void> _submitFeedback() async {
    // Validate
    if (_overallRating == 0 || _doctorRating == 0 || _staffRating == 0 || 
        _cleanlinessRating == 0 || _waitingTimeRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 10),
              Text('Please provide all ratings'),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Determine sentiment based on overall rating
      String sentiment;
      if (_overallRating >= 4) {
        sentiment = 'positive';
      } else if (_overallRating == 3) {
        sentiment = 'neutral';
      } else {
        sentiment = 'negative';
      }

      final feedback = PatientFeedback(
        id: const Uuid().v4(),
        patientId: widget.patientId,
        patientName: _nameController.text.trim().isEmpty ? 'Anonymous' : _nameController.text.trim(),
        overallRating: _overallRating,
        doctorRating: _doctorRating,
        staffRating: _staffRating,
        cleanlinessRating: _cleanlinessRating,
        waitingTimeRating: _waitingTimeRating,
        comments: _commentsController.text.trim(),
        sentiment: sentiment,
      );

      await DatabaseHelper.instance.insertPatientFeedback(feedback);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Expanded(child: Text('Thank you for your valuable feedback! 🙏')),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _commentsController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}

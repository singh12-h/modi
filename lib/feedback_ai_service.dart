import 'models.dart';

/// AI-powered service for analyzing patient feedback and generating actionable insights
class FeedbackAIService {
  /// Analyzes feedback data and generates comprehensive insights
  static Map<String, dynamic> analyzeFeedback(List<PatientFeedback> feedbackList) {
    if (feedbackList.isEmpty) {
      return {
        'totalReviews': 0,
        'avgOverall': 0.0,
        'avgDoctor': 0.0,
        'avgStaff': 0.0,
        'avgCleanliness': 0.0,
        'avgWaitingTime': 0.0,
        'positiveCount': 0,
        'neutralCount': 0,
        'negativeCount': 0,
        'staffBehavior': 'No data available',
        'aiSuggestion': 'Collect feedback to get AI-powered insights',
        'criticalIssues': <String>[],
        'strengths': <String>[],
        'actionItems': <String>[],
      };
    }

    // Calculate averages
    double avgOverall = _calculateAverage(feedbackList.map((f) => f.overallRating).toList());
    double avgDoctor = _calculateAverage(feedbackList.map((f) => f.doctorRating).toList());
    double avgStaff = _calculateAverage(feedbackList.map((f) => f.staffRating).toList());
    double avgCleanliness = _calculateAverage(feedbackList.map((f) => f.cleanlinessRating).toList());
    double avgWaitingTime = _calculateAverage(feedbackList.map((f) => f.waitingTimeRating).toList());

    // Count sentiments
    int positiveCount = feedbackList.where((f) => f.sentiment == 'positive').length;
    int neutralCount = feedbackList.where((f) => f.sentiment == 'neutral').length;
    int negativeCount = feedbackList.where((f) => f.sentiment == 'negative').length;

    // Analyze staff behavior
    String staffBehavior = _analyzeStaffBehavior(avgStaff, feedbackList);

    // Generate AI suggestions
    String aiSuggestion = _generateAISuggestion(
      avgOverall: avgOverall,
      avgDoctor: avgDoctor,
      avgStaff: avgStaff,
      avgCleanliness: avgCleanliness,
      avgWaitingTime: avgWaitingTime,
      feedbackList: feedbackList,
    );

    // Identify critical issues
    List<String> criticalIssues = _identifyCriticalIssues(
      avgStaff: avgStaff,
      avgCleanliness: avgCleanliness,
      avgWaitingTime: avgWaitingTime,
      feedbackList: feedbackList,
    );

    // Identify strengths
    List<String> strengths = _identifyStrengths(
      avgDoctor: avgDoctor,
      avgStaff: avgStaff,
      avgCleanliness: avgCleanliness,
      avgWaitingTime: avgWaitingTime,
    );

    // Generate action items
    List<String> actionItems = _generateActionItems(
      avgStaff: avgStaff,
      avgCleanliness: avgCleanliness,
      avgWaitingTime: avgWaitingTime,
      criticalIssues: criticalIssues,
    );

    return {
      'totalReviews': feedbackList.length,
      'avgOverall': avgOverall,
      'avgDoctor': avgDoctor,
      'avgStaff': avgStaff,
      'avgCleanliness': avgCleanliness,
      'avgWaitingTime': avgWaitingTime,
      'positiveCount': positiveCount,
      'neutralCount': neutralCount,
      'negativeCount': negativeCount,
      'staffBehavior': staffBehavior,
      'aiSuggestion': aiSuggestion,
      'criticalIssues': criticalIssues,
      'strengths': strengths,
      'actionItems': actionItems,
    };
  }

  static double _calculateAverage(List<int> ratings) {
    if (ratings.isEmpty) return 0.0;
    return ratings.reduce((a, b) => a + b) / ratings.length;
  }

  static String _analyzeStaffBehavior(double avgStaff, List<PatientFeedback> feedbackList) {
    int lowRatings = feedbackList.where((f) => f.staffRating < 3).length;
    double lowRatingPercentage = (lowRatings / feedbackList.length) * 100;

    if (avgStaff >= 4.5) {
      return '🌟 Excellent - Staff behavior is outstanding!';
    } else if (avgStaff >= 4.0) {
      return '✅ Very Good - Staff is performing well';
    } else if (avgStaff >= 3.5) {
      return '👍 Good - Staff behavior is satisfactory';
    } else if (avgStaff >= 3.0) {
      return '⚡ Average - Staff needs improvement';
    } else if (avgStaff >= 2.0) {
      return '⚠️ Below Average - Immediate attention required';
    } else {
      return '🚨 Critical - Urgent staff training needed';
    }
  }

  static String _generateAISuggestion({
    required double avgOverall,
    required double avgDoctor,
    required double avgStaff,
    required double avgCleanliness,
    required double avgWaitingTime,
    required List<PatientFeedback> feedbackList,
  }) {
    List<String> suggestions = [];

    // Analyze staff behavior
    int lowStaffRatings = feedbackList.where((f) => f.staffRating < 3).length;
    double lowStaffPercentage = (lowStaffRatings / feedbackList.length) * 100;

    if (avgStaff < 3.0) {
      suggestions.add('🚨 CRITICAL: ${lowStaffPercentage.toStringAsFixed(0)}% patients rated staff below 3 stars.');
      suggestions.add('Staff behavior is a major concern. Immediate intervention required.');
    } else if (avgStaff < 4.0) {
      suggestions.add('⚠️ ${lowStaffPercentage.toStringAsFixed(0)}% patients reported staff behavior issues.');
      suggestions.add('Consider staff training on patient interaction and communication skills.');
    }

    // Analyze waiting time
    if (avgWaitingTime < 3.0) {
      suggestions.add('⏰ Long waiting times are frustrating patients. Optimize appointment scheduling.');
    }

    // Analyze cleanliness
    if (avgCleanliness < 3.5) {
      suggestions.add('🧹 Cleanliness standards need improvement. Implement regular cleaning protocols.');
    }

    // Analyze comments for patterns
    List<String> commonIssues = _extractCommonIssues(feedbackList);
    if (commonIssues.isNotEmpty) {
      suggestions.add('\n📝 Common patient complaints:');
      suggestions.addAll(commonIssues.map((issue) => '  • $issue'));
    }

    // Positive feedback
    if (avgDoctor >= 4.5) {
      suggestions.add('\n✨ Patients highly appreciate doctor\'s consultation quality!');
    }

    if (suggestions.isEmpty) {
      return '✅ Overall performance is good! Continue maintaining high standards of patient care.';
    }

    return suggestions.join('\n');
  }

  static List<String> _identifyCriticalIssues({
    required double avgStaff,
    required double avgCleanliness,
    required double avgWaitingTime,
    required List<PatientFeedback> feedbackList,
  }) {
    List<String> issues = [];

    if (avgStaff < 3.0) {
      issues.add('Staff behavior rated poor by patients');
    }
    if (avgCleanliness < 3.0) {
      issues.add('Cleanliness standards below acceptable level');
    }
    if (avgWaitingTime < 2.5) {
      issues.add('Excessive waiting time causing patient dissatisfaction');
    }

    // Check for negative sentiment spike
    int recentNegative = feedbackList.take(10).where((f) => f.sentiment == 'negative').length;
    if (recentNegative >= 5) {
      issues.add('Recent spike in negative feedback - investigate immediately');
    }

    return issues;
  }

  static List<String> _identifyStrengths({
    required double avgDoctor,
    required double avgStaff,
    required double avgCleanliness,
    required double avgWaitingTime,
  }) {
    List<String> strengths = [];

    if (avgDoctor >= 4.5) strengths.add('Excellent doctor consultation quality');
    if (avgStaff >= 4.5) strengths.add('Outstanding staff behavior');
    if (avgCleanliness >= 4.5) strengths.add('Exceptional cleanliness standards');
    if (avgWaitingTime >= 4.0) strengths.add('Efficient appointment management');

    return strengths;
  }

  static List<String> _generateActionItems({
    required double avgStaff,
    required double avgCleanliness,
    required double avgWaitingTime,
    required List<String> criticalIssues,
  }) {
    List<String> actions = [];

    if (avgStaff < 3.5) {
      actions.add('Conduct staff training on patient communication and empathy');
      actions.add('Monitor staff-patient interactions during peak hours');
      actions.add('Implement feedback mechanism for staff performance');
    }

    if (avgCleanliness < 4.0) {
      actions.add('Review and enhance cleaning protocols');
      actions.add('Conduct surprise cleanliness inspections');
    }

    if (avgWaitingTime < 3.5) {
      actions.add('Optimize appointment scheduling to reduce wait times');
      actions.add('Implement queue management system');
      actions.add('Communicate expected wait times to patients');
    }

    if (criticalIssues.isNotEmpty) {
      actions.add('Address critical issues on priority basis');
      actions.add('Follow up with dissatisfied patients');
    }

    if (actions.isEmpty) {
      actions.add('Maintain current standards and continue monitoring feedback');
    }

    return actions;
  }

  static List<String> _extractCommonIssues(List<PatientFeedback> feedbackList) {
    List<String> issues = [];
    Map<String, int> keywordCount = {};

    // Common complaint keywords
    List<String> keywords = [
      'rude', 'wait', 'waiting', 'long', 'delay', 'dirty', 'clean',
      'unhelpful', 'slow', 'crowded', 'noise', 'noisy'
    ];

    for (var feedback in feedbackList) {
      if (feedback.comments != null && feedback.comments!.isNotEmpty) {
        String comment = feedback.comments!.toLowerCase();
        for (var keyword in keywords) {
          if (comment.contains(keyword)) {
            keywordCount[keyword] = (keywordCount[keyword] ?? 0) + 1;
          }
        }
      }
    }

    // Sort by frequency and get top issues
    var sortedIssues = keywordCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (var entry in sortedIssues.take(3)) {
      if (entry.value >= 2) {
        String issue = _formatIssue(entry.key, entry.value);
        issues.add(issue);
      }
    }

    return issues;
  }

  static String _formatIssue(String keyword, int count) {
    Map<String, String> issueMap = {
      'rude': 'Staff rudeness',
      'wait': 'Long waiting time',
      'waiting': 'Long waiting time',
      'long': 'Extended wait periods',
      'delay': 'Appointment delays',
      'dirty': 'Cleanliness issues',
      'clean': 'Cleanliness concerns',
      'unhelpful': 'Unhelpful staff',
      'slow': 'Slow service',
      'crowded': 'Overcrowding',
      'noise': 'Noise disturbance',
      'noisy': 'Noise disturbance',
    };

    String issue = issueMap[keyword] ?? keyword;
    return '$issue (mentioned by $count patients)';
  }

  /// Get trend analysis for the last 30 days
  static Map<String, dynamic> getTrendAnalysis(List<PatientFeedback> allFeedback) {
    DateTime now = DateTime.now();
    DateTime thirtyDaysAgo = now.subtract(const Duration(days: 30));

    List<PatientFeedback> recentFeedback = allFeedback
        .where((f) => f.createdAt.isAfter(thirtyDaysAgo))
        .toList();

    if (recentFeedback.isEmpty) {
      return {
        'trend': 'No recent data',
        'improvement': 0.0,
        'message': 'Need more feedback data to analyze trends',
      };
    }

    // Split into two halves to compare
    int midPoint = recentFeedback.length ~/ 2;
    List<PatientFeedback> firstHalf = recentFeedback.take(midPoint).toList();
    List<PatientFeedback> secondHalf = recentFeedback.skip(midPoint).toList();

    double firstAvg = _calculateAverage(firstHalf.map((f) => f.staffRating).toList());
    double secondAvg = _calculateAverage(secondHalf.map((f) => f.staffRating).toList());

    double improvement = secondAvg - firstAvg;

    String trend;
    String message;

    if (improvement > 0.5) {
      trend = '📈 Improving';
      message = 'Staff behavior is improving! Keep up the good work.';
    } else if (improvement < -0.5) {
      trend = '📉 Declining';
      message = 'Staff behavior is declining. Immediate action needed.';
    } else {
      trend = '➡️ Stable';
      message = 'Staff behavior is stable. Monitor for consistency.';
    }

    return {
      'trend': trend,
      'improvement': improvement,
      'message': message,
      'firstHalfAvg': firstAvg,
      'secondHalfAvg': secondAvg,
    };
  }
}

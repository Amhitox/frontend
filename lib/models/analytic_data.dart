class AnalyticData {
  final int emailsSent;
  final int emailsReceived;
  final int tasksCompleted;
  final int meetingsAttended;
  final int productivityScore;
  final String responseTime;
  final List<String> topCategories;
  final List<num> categoryData; // Using num to handle int or double
  final List<num> weeklyData;

  AnalyticData({
    required this.emailsSent,
    required this.emailsReceived,
    required this.tasksCompleted,
    required this.meetingsAttended,
    required this.productivityScore,
    required this.responseTime,
    required this.topCategories,
    required this.categoryData,
    required this.weeklyData,
  });

  factory AnalyticData.fromJson(Map<String, dynamic> json) {
    return AnalyticData(
      emailsSent: json['emailsSent'] ?? 0,
      emailsReceived: json['emailsReceived'] ?? 0,
      tasksCompleted: json['tasksCompleted'] ?? 0,
      meetingsAttended: json['meetingsAttended'] ?? 0,
      productivityScore: json['productivityScore'] ?? 0,
      responseTime: json['responseTime'] ?? '',
      topCategories: List<String>.from(json['topCategories'] ?? []),
      categoryData: List<num>.from(json['categoryData'] ?? []),
      weeklyData: List<num>.from(json['weeklyData'] ?? []),
    );
  }
}

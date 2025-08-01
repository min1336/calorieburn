// lib/calorie_activity.dart

enum ActivityType { consumed, burned }

class CalorieActivity {
  final String name;
  final double amount;
  final ActivityType type;
  final DateTime timestamp;

  CalorieActivity({
    required this.name,
    required this.amount,
    required this.type,
    required this.timestamp,
  });
}
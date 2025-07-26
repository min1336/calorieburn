// lib/log_entry.dart

enum LogType { food, exercise }

class LogEntry {
  final String name;
  final double calories;
  final LogType type;
  final DateTime timestamp;

  LogEntry({
    required this.name,
    required this.calories,
    required this.type,
    required this.timestamp,
  });

  // 데이터를 저장하기 위해 Map 형태로 변환 (JSON 인코딩용)
  Map<String, dynamic> toJson() => {
    'name': name,
    'calories': calories,
    'type': type.toString(), // Enum을 문자열로 변환
    'timestamp': timestamp.toIso8601String(), // DateTime을 문자열로 변환
  };

  // 저장된 Map 데이터로부터 객체를 생성 (JSON 디코딩용)
  factory LogEntry.fromJson(Map<String, dynamic> json) => LogEntry(
    name: json['name'],
    calories: json['calories'],
    type: LogType.values.firstWhere((e) => e.toString() == json['type']), // 문자열을 Enum으로 변환
    timestamp: DateTime.parse(json['timestamp']), // 문자열을 DateTime으로 변환
  );
}
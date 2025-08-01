// lib/favorite_food.dart

class FavoriteFood {
  final String name;
  final double calories;

  FavoriteFood({required this.name, required this.calories});

  // Firestore 저장을 위한 Map 변환
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'calories': calories,
    };
  }

  // Firestore 데이터를 객체로 변환
  factory FavoriteFood.fromMap(Map<String, dynamic> map) {
    return FavoriteFood(
      name: map['name'] as String,
      calories: (map['calories'] as num).toDouble(),
    );
  }

  // 객체 비교를 위한 override
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is FavoriteFood &&
              runtimeType == other.runtimeType &&
              name == other.name;

  @override
  int get hashCode => name.hashCode;
}
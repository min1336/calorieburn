// lib/favorite_food.dart

class FavoriteFood {
  final String name;
  final double calories;

  FavoriteFood({required this.name, required this.calories});

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'calories': calories,
    };
  }

  factory FavoriteFood.fromMap(Map<String, dynamic> map) {
    return FavoriteFood(
      name: map['name'] as String,
      calories: (map['calories'] as num).toDouble(),
    );
  }

  // ✅ 수정: 정확한 객체 비교를 위해 이름과 칼로리를 모두 비교
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is FavoriteFood &&
              runtimeType == other.runtimeType &&
              name == other.name &&
              calories == other.calories;

  @override
  int get hashCode => name.hashCode ^ calories.hashCode;
}
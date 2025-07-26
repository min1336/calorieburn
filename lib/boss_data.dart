// lib/boss_data.dart

class Boss {
  final int stage;
  final String name;
  final String imagePath;
  final double baseHp;
  final bool hasToxin; // 독소 특성 여부 추가

  const Boss({
    required this.stage,
    required this.name,
    required this.imagePath,
    required this.baseHp,
    this.hasToxin = false, // 기본값은 false
  });
}

// --- 전체 보스 목록 ---
const List<Boss> allBosses = [
  Boss(stage: 1, name: '폭식의 햄스터', imagePath: 'assets/images/boss_image.png', baseHp: 7700),
  // --- 나태의 슬라임에게 독소 특성 부여 ---
  Boss(stage: 2, name: '나태의 슬라임', imagePath: 'assets/images/boss_image_2.png', baseHp: 9000, hasToxin: true),
  Boss(stage: 3, name: '분노의 골렘', imagePath: 'assets/images/boss_image_3.png', baseHp: 12000),
];
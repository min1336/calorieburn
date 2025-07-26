// lib/quest_data.dart

enum QuestType {
  steps,       // 걸음 수
  burnCalories,// 칼로리 소모
  addWater,    // 물 섭취
  logFood,     // 음식 기록 횟수
}

class Quest {
  final String id;
  final String title;
  final String description;
  final QuestType type;
  final double goal;
  final int rewardGems;

  const Quest({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.goal,
    required this.rewardGems,
  });
}

// --- 전체 퀘스트 목록 ---
const List<Quest> allQuests = [
  Quest(id: 'steps_3000', title: '가벼운 산책', description: '하루 3,000 걸음 달성하기', type: QuestType.steps, goal: 3000, rewardGems: 5),
  Quest(id: 'steps_7000', title: '꾸준한 걷기', description: '하루 7,000 걸음 달성하기', type: QuestType.steps, goal: 7000, rewardGems: 10),
  Quest(id: 'burn_200', title: '활기찬 시작', description: '운동으로 200 kcal 소모하기', type: QuestType.burnCalories, goal: 200, rewardGems: 5),
  Quest(id: 'burn_500', title: '불타는 의지', description: '운동으로 500 kcal 소모하기', type: QuestType.burnCalories, goal: 500, rewardGems: 15),
  Quest(id: 'water_1000', title: '수분 보충', description: '물 1,000ml 마시기', type: QuestType.addWater, goal: 1000, rewardGems: 5),
  Quest(id: 'water_2000', title: '건강한 습관', description: '물 2,000ml 마시기', type: QuestType.addWater, goal: 2000, rewardGems: 10),
  Quest(id: 'log_3', title: '식단 기록', description: '음식 3번 기록하기', type: QuestType.logFood, goal: 3, rewardGems: 5),
];
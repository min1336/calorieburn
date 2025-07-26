// lib/exercise_data.dart

class Exercise {
  final String name;
  final double mets; // Metabolic Equivalent of Task (운동 대사 당량)

  Exercise({required this.name, required this.mets});
}

// 운동 데이터 목록 (METs 값은 일반적인 수치)
final List<Exercise> exerciseList = [
  Exercise(name: '가벼운 걷기', mets: 2.5),
  Exercise(name: '빠르게 걷기', mets: 4.5),
  Exercise(name: '달리기', mets: 7.0),
  Exercise(name: '자전거 타기', mets: 6.0),
  Exercise(name: '수영', mets: 7.0),
  Exercise(name: '근력 운동 (웨이트)', mets: 4.0),
  Exercise(name: '스트레칭', mets: 2.0),
  Exercise(name: '계단 오르기', mets: 8.0),
];
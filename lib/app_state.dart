// lib/app_state.dart

import 'dart:async';
import 'dart:math';
import 'package:calorie_burn/calorie_activity.dart'; // CalorieActivity 모델 임포트
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:health/health.dart';

enum Gender { male, female }
enum ActivityLevel { sedentary, light, moderate, active, veryActive }

class AppState extends ChangeNotifier {
  final Health health = Health();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int selectedIndex = 0;
  double currentCalories = 0;
  double maxCalories = 2200;
  int userAge = 30;
  double userHeightCm = 175.0;
  double userWeightKg = 75.0;
  Gender gender = Gender.male;
  ActivityLevel activityLevel = ActivityLevel.moderate;
  String? _uid;
  String nickname = '';
  List<Map<String, dynamic>> rankings = [];
  bool isRankingLoading = true;
  double todayOverconsumedCaloriesBurned = 0;
  bool isHealthAuthorized = false;
  double todaySyncedCalories = 0;
  String? primaryDataSource;
  List<String> availableDataSources = [];

  // ✅ 추가: 오늘의 활동 기록을 저장할 리스트
  List<CalorieActivity> todayActivities = [];


  Future<void> loadData(String uid) async {
    _uid = uid;
    final userDoc = await _firestore.collection('users').doc(_uid).get();
    if (!userDoc.exists) return;

    final data = userDoc.data()!;

    nickname = data['nickname'] ?? '';
    userAge = data['userAge'] ?? 30;
    userHeightCm = (data['userHeightCm'] as num?)?.toDouble() ?? 175.0;
    userWeightKg = (data['userWeightKg'] as num?)?.toDouble() ?? 75.0;
    gender = Gender.values[data['gender'] ?? Gender.male.index];
    activityLevel = ActivityLevel.values[data['activityLevel'] ?? ActivityLevel.moderate.index];
    recalculateRecommendedCalories();
    primaryDataSource = data['primaryDataSource'];

    final todayString = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final lastActiveDate = data['lastActiveDate'];

    if (lastActiveDate == null || lastActiveDate != todayString) {
      currentCalories = 0;
      todayOverconsumedCaloriesBurned = 0;
      todaySyncedCalories = 0;
      todayActivities = []; // 날짜가 바뀌면 활동 기록 초기화
      await _firestore.collection('users').doc(_uid).set({
        'syncedCaloriesToday': 0.0,
      }, SetOptions(merge: true));
      await _saveData();
    } else {
      currentCalories = (data['currentCalories'] as num?)?.toDouble() ?? 0;
      todayOverconsumedCaloriesBurned = (data['todayOverconsumedCaloriesBurned'] as num?)?.toDouble() ?? 0;
      todaySyncedCalories = (data['syncedCaloriesToday'] as num?)?.toDouble() ?? 0;
      // ✅ 추가: Firestore에서 활동 기록 불러오기
      await _loadActivities();
    }

    notifyListeners();
    try {
      await initHealth();
    } catch (e) {
      debugPrint("초기 건강 데이터 로딩 실패: $e");
    }
    await fetchRankings();
  }

  // ✅ 추가: 활동 기록을 저장하는 메서드
  Future<void> _saveActivities() async {
    if (_uid == null) return;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final activitiesCollection = _firestore
        .collection('users')
        .doc(_uid)
        .collection('activities')
        .doc(today)
        .collection('records');

    // Firestore 트랜잭션을 사용하여 모든 활동을 한 번에 씁니다.
    WriteBatch batch = _firestore.batch();
    for (var activity in todayActivities) {
      // 각 활동을 고유한 타임스탬프 기반 ID로 저장합니다.
      var docRef = activitiesCollection.doc(activity.timestamp.toIso8601String());
      batch.set(docRef, {
        'name': activity.name,
        'amount': activity.amount,
        'type': activity.type.index,
        'timestamp': activity.timestamp,
      });
    }
    await batch.commit();
  }

  // ✅ 추가: 활동 기록을 불러오는 메서드
  Future<void> _loadActivities() async {
    if (_uid == null) return;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final snapshot = await _firestore
        .collection('users')
        .doc(_uid)
        .collection('activities')
        .doc(today)
        .collection('records')
        .orderBy('timestamp')
        .get();

    todayActivities = snapshot.docs.map((doc) {
      final data = doc.data();
      return CalorieActivity(
        name: data['name'],
        amount: (data['amount'] as num).toDouble(),
        type: ActivityType.values[data['type']],
        timestamp: (data['timestamp'] as Timestamp).toDate(),
      );
    }).toList();
  }

  Future<void> _saveData() async {
    if (_uid == null) return;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final userDocRef = _firestore.collection('users').doc(_uid);

    await userDocRef.set({
      'nickname': nickname,
      'lastActiveDate': today,
      'userAge': userAge,
      'userHeightCm': userHeightCm,
      'userWeightKg': userWeightKg,
      'gender': gender.index,
      'activityLevel': activityLevel.index,
      'currentCalories': currentCalories,
      'todayOverconsumedCaloriesBurned': todayOverconsumedCaloriesBurned,
      'primaryDataSource': primaryDataSource,
    }, SetOptions(merge: true));

    // ✅ 추가: 데이터 저장 시 활동 기록도 함께 저장
    await _saveActivities();
  }


  // ✅ 수정: 칼로리 추가 시 활동 기록 생성
  void addCalories(String name, double amount) {
    currentCalories += amount;

    todayActivities.add(CalorieActivity(
      name: name,
      amount: amount,
      type: ActivityType.consumed,
      timestamp: DateTime.now(),
    ));

    _saveData();
    notifyListeners();
  }

  // ✅ 수정: 칼로리 감소 시 활동 기록 생성
  void decreaseCalories(String name, double amount) {
    double caloriesOverBefore = max(0, currentCalories - maxCalories);
    currentCalories -= amount;
    if (currentCalories < 0) {
      currentCalories = 0;
    }
    double caloriesOverAfter = max(0, currentCalories - maxCalories);
    double burnedOverCalories = caloriesOverBefore - caloriesOverAfter;
    if (burnedOverCalories > 0) {
      todayOverconsumedCaloriesBurned += burnedOverCalories;
    }

    todayActivities.add(CalorieActivity(
      name: name,
      amount: amount,
      type: ActivityType.burned,
      timestamp: DateTime.now(),
    ));

    _saveData();
    notifyListeners();
  }


  // ... (나머지 AppState 코드는 기존과 동일)
  Future<String> syncFromSmartwatch() async {
    final types = [HealthDataType.ACTIVE_ENERGY_BURNED];
    final permissions = [HealthDataAccess.READ];

    try {
      isHealthAuthorized = await health.requestAuthorization(types, permissions: permissions);
      notifyListeners();

      if (!isHealthAuthorized) {
        return "권한이 거부되었습니다. 스마트워치 데이터에 접근하려면 건강 데이터 권한을 허용해주세요.";
      }

      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);

      List<HealthDataPoint> healthData = await health.getHealthDataFromTypes(
        startTime: midnight,
        endTime: now,
        types: types,
      );

      healthData = health.removeDuplicates(healthData);

      final sources = healthData.map((p) => p.sourceName).toSet().toList();
      availableDataSources = sources;

      if (primaryDataSource != null) {
        healthData = healthData.where((p) => p.sourceName == primaryDataSource).toList();
      } else if (availableDataSources.isNotEmpty) {
        primaryDataSource = availableDataSources.first;
        healthData = healthData.where((p) => p.sourceName == primaryDataSource).toList();
      }

      final userDoc = await _firestore.collection('users').doc(_uid).get();
      final alreadySyncedCalories = (userDoc.data()?['syncedCaloriesToday'] as num?)?.toDouble() ?? 0.0;

      double totalCaloriesBurnedFromWatch = 0;
      for (var dataPoint in healthData) {
        if (dataPoint.type == HealthDataType.ACTIVE_ENERGY_BURNED) {
          totalCaloriesBurnedFromWatch += (dataPoint.value as NumericHealthValue).numericValue.toDouble();
        }
      }

      todaySyncedCalories = totalCaloriesBurnedFromWatch;
      double newlyBurnedCalories = totalCaloriesBurnedFromWatch - alreadySyncedCalories;

      if (newlyBurnedCalories > 0) {
        double caloriesOverBefore = max(0, currentCalories - maxCalories);
        currentCalories -= newlyBurnedCalories;
        if (currentCalories < 0) currentCalories = 0;
        double caloriesOverAfter = max(0, currentCalories - maxCalories);
        double burnedOverCalories = caloriesOverBefore - caloriesOverAfter;
        if (burnedOverCalories > 0) {
          todayOverconsumedCaloriesBurned += burnedOverCalories;
        }

        await _firestore.collection('users').doc(_uid).set({
          'syncedCaloriesToday': totalCaloriesBurnedFromWatch,
        }, SetOptions(merge: true));

        await _saveData();
        notifyListeners();
        return "성공! ${primaryDataSource ?? '스마트워치'}에서 ${newlyBurnedCalories.toInt()} kcal를 가져왔습니다.";
      } else {
        notifyListeners();
        return "이미 최신 데이터입니다. 새로운 활동량이 없습니다.";
      }
    } on HealthException catch (e) {
      // HealthException의 상세 메시지를 직접 사용하도록 수정
      debugPrint("HealthException in syncFromSmartwatch: $e");
      return "데이터 동기화 오류: ${e.toString()}";
    } catch (e) {
      debugPrint("Exception in syncFromSmartwatch: $e");
      return "데이터를 가져오는 중 오류가 발생했습니다: $e";
    }
  }

  Future<void> setPrimaryDataSource(String sourceName) async {
    primaryDataSource = sourceName;
    await _saveData();
    notifyListeners();
  }

  Future<void> initHealth() async {
    final types = [HealthDataType.ACTIVE_ENERGY_BURNED];
    final permissions = [HealthDataAccess.READ];

    try {
      isHealthAuthorized = await health.requestAuthorization(types, permissions: permissions);
    } on HealthException catch (e) {
      isHealthAuthorized = false;
      debugPrint("권한 요청 중 오류 발생: ${e.toString()}");
      rethrow;
    }

    notifyListeners();
    if (isHealthAuthorized) {
      await fetchTodayHealthData();
    }
  }

  Future<void> fetchTodayHealthData() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);

    try {
      List<HealthDataPoint> healthData = await health.getHealthDataFromTypes(
          startTime: midnight,
          endTime: now,
          types: [HealthDataType.ACTIVE_ENERGY_BURNED]
      );
      healthData = health.removeDuplicates(healthData);

      final sources = healthData.map((p) => p.sourceName).toSet().toList();
      if(sources.isNotEmpty && !listEquals(sources, availableDataSources)) {
        availableDataSources = sources;
      }
      if (primaryDataSource != null) {
        healthData = healthData.where((p) => p.sourceName == primaryDataSource).toList();
      }

      double totalCalories = 0;
      for (var dataPoint in healthData) {
        totalCalories += (dataPoint.value as NumericHealthValue).numericValue.toDouble();
      }
      todaySyncedCalories = totalCalories;
    } on HealthException catch (e) {
      debugPrint("오늘의 건강 데이터 가져오기 실패: ${e.toString()}");
      todaySyncedCalories = 0;
    }
    notifyListeners();
  }

  void onTabTapped(int index) {
    selectedIndex = index;
    notifyListeners();
  }

  void recalculateRecommendedCalories() {
    double bmr;
    if (gender == Gender.male) {
      bmr = 88.362 + (13.397 * userWeightKg) + (4.799 * userHeightCm) - (5.677 * userAge);
    } else {
      bmr = 447.593 + (9.247 * userWeightKg) + (3.098 * userHeightCm) - (4.330 * userAge);
    }
    double activityMultiplier;
    switch (activityLevel) {
      case ActivityLevel.sedentary:
        activityMultiplier = 1.2;
        break;
      case ActivityLevel.light:
        activityMultiplier = 1.375;
        break;
      case ActivityLevel.moderate:
        activityMultiplier = 1.55;
        break;
      case ActivityLevel.active:
        activityMultiplier = 1.725;
        break;
      case ActivityLevel.veryActive:
        activityMultiplier = 1.9;
        break;
    }
    maxCalories = bmr * activityMultiplier;
  }

  void updateProfile({
    required String newNickname,
    required int newAge,
    required double newHeight,
    required double newWeight,
    required Gender newGender,
    required ActivityLevel newActivityLevel,
  }) {
    nickname = newNickname;
    userAge = newAge;
    userHeightCm = newHeight;
    userWeightKg = newWeight;
    gender = newGender;
    activityLevel = newActivityLevel;
    recalculateRecommendedCalories();
    _saveData();
    notifyListeners();
  }

  Future<void> fetchRankings() async {
    isRankingLoading = true;
    notifyListeners();
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .orderBy('todayOverconsumedCaloriesBurned', descending: true)
          .limit(50)
          .get();

      rankings = querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint("랭킹을 불러오는 중 오류 발생: $e");
      }
      rankings = [];
    } finally {
      isRankingLoading = false;
      notifyListeners();
    }
  }

  Map<String, double> get exerciseMETs => {
    '가볍게 걷기': 3.5,
    '보통 속도로 달리기': 7.0,
    '자전거 타기': 8.0,
    '수영 (보통)': 7.0,
  };

  int calculateExerciseMinutes(double calories, String exerciseName) {
    if (!exerciseMETs.containsKey(exerciseName) || userWeightKg <= 0) {
      return 0;
    }
    final met = exerciseMETs[exerciseName]!;
    final caloriesPerMinute = (met * 3.5 * userWeightKg) / 200;
    if (caloriesPerMinute <= 0) {
      return 0;
    }
    final minutes = calories / caloriesPerMinute;
    return minutes.ceil();
  }
}
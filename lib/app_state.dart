// lib/app_state.dart

import 'dart:async';
import 'dart:math';
import 'package:calorie_burn/calorie_activity.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:health/health.dart';

enum Gender { male, female }
enum ActivityLevel { sedentary, light, moderate, active, veryActive }

class AppState extends ChangeNotifier {
  final Health health = Health();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int selectedIndex = 0;
  double todayCalories = 0;
  List<CalorieActivity> todayActivities = [];

  // 날짜 선택 기능 관련 상태
  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;
  final Map<DateTime, List<CalorieActivity>> _activitiesCache = {};
  final Map<DateTime, double> _caloriesCache = {};
  bool isLoadingDate = false;

  // 캐시된 데이터를 가져오는 getter
  List<CalorieActivity>? getCachedActivitiesForDate(DateTime date) => _activitiesCache[DateUtils.dateOnly(date)];
  double? getCachedCaloriesForDate(DateTime date) => _caloriesCache[DateUtils.dateOnly(date)];

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

    // 앱 시작 시 오늘 데이터를 먼저 로드
    await _loadTodayData();
    await selectDate(DateTime.now());

    notifyListeners();
    try {
      await initHealth();
    } catch (e) {
      debugPrint("초기 건강 데이터 로딩 실패: $e");
    }
    await fetchRankings();
  }

  // 날짜를 선택하고 데이터를 불러오는 함수
  Future<void> selectDate(DateTime newDate, {bool forceRefetch = false}) async {
    final dateOnly = DateUtils.dateOnly(newDate);
    _selectedDate = dateOnly;

    if (!_activitiesCache.containsKey(dateOnly) || forceRefetch) {
      isLoadingDate = true;
      notifyListeners();

      final activities = await _loadActivitiesForDate(dateOnly);
      final calories = await _loadCaloriesForDate(dateOnly);

      _activitiesCache[dateOnly] = activities;
      _caloriesCache[dateOnly] = calories;

      isLoadingDate = false;
    }
    notifyListeners();
  }

  // 오늘의 데이터만 불러오는 별도 함수
  Future<void> _loadTodayData() async {
    final todayString = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final userDoc = await _firestore.collection('users').doc(_uid).get();
    if (!userDoc.exists) return;

    final data = userDoc.data()!;
    final lastActiveDate = data['lastActiveDate'];

    if (lastActiveDate == null || lastActiveDate != todayString) {
      todayCalories = 0;
      todayActivities = [];
      todayOverconsumedCaloriesBurned = 0;
      todaySyncedCalories = 0;
      await _saveData();
    } else {
      todayCalories = (data['currentCalories'] as num?)?.toDouble() ?? 0;
      todayOverconsumedCaloriesBurned = (data['todayOverconsumedCaloriesBurned'] as num?)?.toDouble() ?? 0;
      todaySyncedCalories = (data['syncedCaloriesToday'] as num?)?.toDouble() ?? 0;
      todayActivities = await _loadActivitiesForDate(DateTime.now());
    }
  }

  // Firestore에 오늘의 주요 데이터 저장 (날짜별 기록은 별도 저장)
  Future<void> _saveData() async {
    if (_uid == null) return;
    final todayString = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final userDocRef = _firestore.collection('users').doc(_uid);

    await userDocRef.set({
      'nickname': nickname,
      'lastActiveDate': todayString,
      'userAge': userAge,
      'userHeightCm': userHeightCm,
      'userWeightKg': userWeightKg,
      'gender': gender.index,
      'activityLevel': activityLevel.index,
      'currentCalories': todayCalories,
      'todayOverconsumedCaloriesBurned': todayOverconsumedCaloriesBurned,
      'primaryDataSource': primaryDataSource,
    }, SetOptions(merge: true));

    // 오늘 날짜의 활동 기록만 별도로 저장
    await _saveActivities(todayActivities, DateTime.now());
  }

  // 특정 날짜의 활동 기록을 저장
  Future<void> _saveActivities(List<CalorieActivity> activities, DateTime date) async {
    if (_uid == null) return;
    final dateString = DateFormat('yyyy-MM-dd').format(date);
    final docRef = _firestore.collection('users').doc(_uid).collection('activities').doc(dateString);

    final activitiesData = activities.map((activity) => {
      'name': activity.name,
      'amount': activity.amount,
      'type': activity.type.index,
      'timestamp': activity.timestamp,
    }).toList();

    // records 필드에 활동 목록 전체를 덮어쓰기
    await docRef.set({'records': activitiesData});
  }

  // 특정 날짜의 활동 기록을 불러오기
  Future<List<CalorieActivity>> _loadActivitiesForDate(DateTime date) async {
    if (_uid == null) return [];
    final dateString = DateFormat('yyyy-MM-dd').format(date);
    final doc = await _firestore.collection('users').doc(_uid).collection('activities').doc(dateString).get();

    if (!doc.exists || doc.data() == null || doc.data()!['records'] == null) {
      return [];
    }

    final records = doc.data()!['records'] as List;
    return records.map((data) {
      return CalorieActivity(
        name: data['name'],
        amount: (data['amount'] as num).toDouble(),
        type: ActivityType.values[data['type']],
        timestamp: (data['timestamp'] as Timestamp).toDate(),
      );
    }).toList();
  }

  // 특정 날짜의 최종 칼로리를 불러오기
  Future<double> _loadCaloriesForDate(DateTime date) async {
    if (_uid == null) return 0.0;
    final dateOnly = DateUtils.dateOnly(date);
    final todayOnly = DateUtils.dateOnly(DateTime.now());

    // 오늘 날짜라면 메인 문서에서 바로 가져오기
    if (dateOnly == todayOnly) {
      final doc = await _firestore.collection('users').doc(_uid).get();
      if (doc.exists && doc.data()?['lastActiveDate'] == DateFormat('yyyy-MM-dd').format(date)) {
        return (doc.data()?['currentCalories'] as num?)?.toDouble() ?? 0.0;
      }
    }

    // 과거 날짜는 활동 기록을 기반으로 계산
    final activities = await _loadActivitiesForDate(date);
    double totalCalories = 0;
    for (var activity in activities) {
      if (activity.type == ActivityType.consumed) {
        totalCalories += activity.amount;
      } else {
        totalCalories -= activity.amount;
      }
    }
    return max(0, totalCalories);
  }

  // 오늘 날짜에 칼로리 추가
  void addCalories(String name, double amount) {
    todayCalories += amount;
    todayActivities.add(CalorieActivity(
      name: name,
      amount: amount,
      type: ActivityType.consumed,
      timestamp: DateTime.now(),
    ));
    _updateCacheForToday();
    _saveData();
    notifyListeners();
  }

  // 오늘 날짜에 칼로리 감소
  void decreaseCalories(String name, double amount) {
    double caloriesOverBefore = max(0, todayCalories - maxCalories);
    todayCalories -= amount;
    if (todayCalories < 0) todayCalories = 0;
    double caloriesOverAfter = max(0, todayCalories - maxCalories);
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
    _updateCacheForToday();
    _saveData();
    notifyListeners();
  }

  void _updateCacheForToday() {
    final today = DateUtils.dateOnly(DateTime.now());
    _caloriesCache[today] = todayCalories;
    _activitiesCache[today] = todayActivities;
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
          types: [HealthDataType.ACTIVE_ENERGY_BURNED]);
      healthData = health.removeDuplicates(healthData);
      final sources = healthData.map((p) => p.sourceName).toSet().toList();
      if (sources.isNotEmpty && !listEquals(sources, availableDataSources)) {
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
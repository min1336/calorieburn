// lib/app_state.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:health/health.dart';

enum Gender { male, female }
enum ActivityLevel { sedentary, light, moderate, active, veryActive }

class AppState extends ChangeNotifier {
  final HealthFactory health = HealthFactory(useHealthConnectIfAvailable: true);
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

  Future<String> syncFromSmartwatch() async {
    final types = [
      HealthDataType.ACTIVE_ENERGY_BURNED,
    ];
    final permissions = types.map((e) => HealthDataAccess.READ).toList();

    isHealthAuthorized = await health.requestAuthorization(types, permissions: permissions);
    notifyListeners();

    if (isHealthAuthorized) {
      try {
        final now = DateTime.now();
        final midnight = DateTime(now.year, now.month, now.day);

        List<HealthDataPoint> healthData = await health.getHealthDataFromTypes(midnight, now, types);

        final sources = healthData.map((p) => p.sourceName).toSet().toList();
        availableDataSources = sources;

        if (primaryDataSource != null) {
          healthData = healthData.where((p) => p.sourceName == primaryDataSource).toList();
        } else if (availableDataSources.isNotEmpty) {
          primaryDataSource = availableDataSources.first;
          healthData = healthData.where((p) => p.sourceName == primaryDataSource).toList();
        }

        final userDoc = await _firestore.collection('users').doc(_uid).get();
        final alreadySyncedCalories = userDoc.data()?['syncedCaloriesToday']?.toDouble() ?? 0.0;

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
      } catch (e) {
        return "데이터를 가져오는 중 오류가 발생했습니다: $e";
      }
    }
    return "권한이 거부되어 데이터를 가져올 수 없습니다.";
  }

  Future<void> loadData(String uid) async {
    _uid = uid;
    final userDoc = await _firestore.collection('users').doc(_uid).get();
    if (!userDoc.exists) return;

    final data = userDoc.data()!;

    nickname = data['nickname'] ?? '';
    userAge = data['userAge'] ?? 30;
    userHeightCm = data['userHeightCm']?.toDouble() ?? 175.0;
    userWeightKg = data['userWeightKg']?.toDouble() ?? 75.0;
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
      await _firestore.collection('users').doc(_uid).set({
        'syncedCaloriesToday': 0.0,
      }, SetOptions(merge: true));
      await _saveData();
    } else {
      currentCalories = data['currentCalories']?.toDouble() ?? 0;
      todayOverconsumedCaloriesBurned = data['todayOverconsumedCaloriesBurned']?.toDouble() ?? 0;
      todaySyncedCalories = data['syncedCaloriesToday']?.toDouble() ?? 0;
    }

    notifyListeners();
    await initHealth();
    await fetchRankings();
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
  }

  Future<void> setPrimaryDataSource(String sourceName) async {
    primaryDataSource = sourceName;
    await _saveData();
    notifyListeners();
  }

  void addCalories(String name, double amount) {
    currentCalories += amount;
    _saveData();
    notifyListeners();
  }

  Future<void> initHealth() async {
    final types = [HealthDataType.ACTIVE_ENERGY_BURNED];
    final permissions = types.map((e) => HealthDataAccess.READ).toList();
    isHealthAuthorized = await health.requestAuthorization(types, permissions: permissions);
    notifyListeners();
    if (isHealthAuthorized) {
      await fetchTodayHealthData();
    }
  }

  Future<void> fetchTodayHealthData() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);

    List<HealthDataPoint> healthData = await health.getHealthDataFromTypes(midnight, now, [HealthDataType.ACTIVE_ENERGY_BURNED]);
    if (primaryDataSource != null) {
      healthData = healthData.where((p) => p.sourceName == primaryDataSource).toList();
    }
    double totalCalories = 0;
    for (var dataPoint in healthData) {
      totalCalories += (dataPoint.value as NumericHealthValue).numericValue.toDouble();
    }
    todaySyncedCalories = totalCalories;

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
      print("랭킹을 불러오는 중 오류 발생: $e");
      rankings = [];
    } finally {
      isRankingLoading = false;
      notifyListeners();
    }
  }
}
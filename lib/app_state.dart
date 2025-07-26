// lib/app_state.dart

import 'dart:convert';
import 'dart:math';
import 'package.flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:health/health.dart';
import 'log_entry.dart';

enum Gender { male, female }
enum ActivityLevel { sedentary, light, moderate, active, veryActive }

class AppState extends ChangeNotifier {
  final HealthFactory health = HealthFactory(useHealthConnectIfAvailable: true);
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int todaySteps = 0;
  String? autoHuntResult;

  int selectedIndex = 0;
  double currentCalories = 0;
  double maxCalories = 2200;
  double toxinLevel = 0;
  double bossHp = 7700;
  double maxBossHp = 7700;
  int bossStage = 1;
  List<LogEntry> logEntries = [];
  int userLevel = 1;
  double currentXp = 0;
  double xpForNextLevel = 100;
  bool isToxified = false;
  int userAge = 30;
  double userHeightCm = 175.0;
  double userWeightKg = 75.0;
  Gender gender = Gender.male;
  ActivityLevel activityLevel = ActivityLevel.moderate;
  int waterIntakeMl = 0;
  final int waterGoalMl = 2000;

  String? _uid;

  Future<void> loadData(String uid) async {
    _uid = uid;

    final userDoc = await _firestore.collection('users').doc(_uid).get();

    if (!userDoc.exists) {
      await _createInitialUserData();
      await loadData(uid);
      return;
    }

    final data = userDoc.data()!;

    userAge = data['userAge'] ?? 30;
    userHeightCm = data['userHeightCm']?.toDouble() ?? 175.0;
    userWeightKg = data['userWeightKg']?.toDouble() ?? 75.0;
    gender = Gender.values[data['gender'] ?? Gender.male.index];
    activityLevel = ActivityLevel.values[data['activityLevel'] ?? ActivityLevel.moderate.index];
    recalculateRecommendedCalories();

    userLevel = data['userLevel'] ?? 1;
    currentXp = data['currentXp']?.toDouble() ?? 0;
    bossStage = data['bossStage'] ?? 1;
    maxBossHp = data['maxBossHp']?.toDouble() ?? 7700.0;
    bossHp = data['bossHp']?.toDouble() ?? maxBossHp;
    xpForNextLevel = _calculateXpForNextLevel(userLevel);
    isToxified = data['isToxified'] ?? false;

    final todayString = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final lastActiveDate = data['lastActiveDate'];

    if (lastActiveDate == null || lastActiveDate != todayString) {
      currentCalories = 0;
      toxinLevel = 0;
      logEntries = [];
      waterIntakeMl = 0;
      await _saveData();
    } else {
      currentCalories = data['currentCalories']?.toDouble() ?? 0;
      toxinLevel = data['toxinLevel']?.toDouble() ?? 0;
      waterIntakeMl = data['waterIntakeMl'] ?? 0;
      if (data['logEntries'] != null) {
        logEntries = (data['logEntries'] as List).map((entry) => LogEntry.fromJson(Map<String, dynamic>.from(entry))).toList();
      } else {
        logEntries = [];
      }
    }

    notifyListeners();
    await initHealth();
  }

  Future<void> _saveData() async {
    if (_uid == null) return;

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final userDocRef = _firestore.collection('users').doc(_uid);

    final logEntriesJson = logEntries.map((entry) => entry.toJson()).toList();

    await userDocRef.set({
      'lastActiveDate': today,
      'userAge': userAge,
      'userHeightCm': userHeightCm,
      'userWeightKg': userWeightKg,
      'gender': gender.index,
      'activityLevel': activityLevel.index,
      'currentCalories': currentCalories,
      'toxinLevel': toxinLevel,
      'bossHp': bossHp,
      'maxBossHp': maxBossHp,
      'bossStage': bossStage,
      'userLevel': userLevel,
      'currentXp': currentXp,
      'isToxified': isToxified,
      'waterIntakeMl': waterIntakeMl,
      'logEntries': logEntriesJson,
    }, SetOptions(merge: true));
  }

  Future<void> _createInitialUserData() async {
    if (_uid == null) return;
    await _firestore.collection('users').doc(_uid).set({
      'userAge': 30,
      'userHeightCm': 175.0,
      'userWeightKg': 75.0,
      'gender': Gender.male.index,
      'activityLevel': ActivityLevel.moderate.index,
      'userLevel': 1,
      'currentXp': 0.0,
      'bossStage': 1,
      'maxBossHp': 7700.0,
      'bossHp': 7700.0,
      'isToxified': false,
      'waterIntakeMl': 0,
      'logEntries': [],
      'lastActiveDate': '',
    });
  }

  Future<void> initHealth() async {
    final types = [HealthDataType.STEPS];
    final permissions = [HealthDataAccess.READ];
    final requested = await health.requestAuthorization(types, permissions: permissions);

    if (requested) {
      await processAutoHunt();
      await fetchTodaySteps();
    }
  }

  Future<void> processAutoHunt() async {
    if (_uid == null) return;
    final userDoc = await _firestore.collection('users').doc(_uid).get();
    if (!userDoc.exists) return;

    final data = userDoc.data()!;
    final lastCheckTimeString = data['lastStepCheckTime'];
    final now = DateTime.now();

    DateTime lastCheckTime;
    if (lastCheckTimeString == null) {
      await _firestore.collection('users').doc(_uid).set({'lastStepCheckTime': now.toIso8601String()}, SetOptions(merge: true));
      return;
    } else {
      lastCheckTime = DateTime.parse(lastCheckTimeString);
    }

    int? steps = await health.getTotalStepsInInterval(lastCheckTime, now);

    if (steps != null && steps > 0) {
      final damage = (steps / 100).floor();
      final xp = (steps / 200).floor();

      if (damage > 0) {
        bossHp -= damage;
        _addXp(xp.toDouble());
        logEntries.add(LogEntry(name: '자동 사냥 ($steps 걸음)', calories: damage.toDouble(), type: LogType.exercise, timestamp: now));
        autoHuntResult = '자동 사냥 결과!\n$steps 걸음으로 보스에게 $damage의 데미지를 입혔습니다! (+${xp}XP)';

        if (bossHp <= 0) {
          bossDefeated();
        } else {
          _saveData();
        }
      }
    }

    await _firestore.collection('users').doc(_uid).set({'lastStepCheckTime': now.toIso8601String()}, SetOptions(merge: true));
    notifyListeners();
  }

  Future<void> fetchTodaySteps() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    int? steps = await health.getTotalStepsInInterval(midnight, now);
    if (steps != null) {
      todaySteps = steps;
      notifyListeners();
    }
  }

  void onTabTapped(int index) {
    selectedIndex = index;
    notifyListeners();
  }

  double _calculateXpForNextLevel(int level) {
    return (100 * pow(level, 1.5)).floorToDouble();
  }

  void _levelUp() {
    userLevel++;
    currentXp -= xpForNextLevel;
    xpForNextLevel = _calculateXpForNextLevel(userLevel);
  }

  void _addXp(double amount) {
    currentXp += amount;
    if (currentXp >= xpForNextLevel) {
      _levelUp();
    }
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
      case ActivityLevel.sedentary: activityMultiplier = 1.2; break;
      case ActivityLevel.light: activityMultiplier = 1.375; break;
      case ActivityLevel.moderate: activityMultiplier = 1.55; break;
      case ActivityLevel.active: activityMultiplier = 1.725; break;
      case ActivityLevel.veryActive: activityMultiplier = 1.9; break;
    }
    maxCalories = bmr * activityMultiplier;
  }

  void updateProfile({ required int newAge, required double newHeight, required double newWeight, required Gender newGender, required ActivityLevel newActivityLevel }) {
    userAge = newAge;
    userHeightCm = newHeight;
    userWeightKg = newWeight;
    gender = newGender;
    activityLevel = newActivityLevel;
    recalculateRecommendedCalories();
    _saveData();
    notifyListeners();
  }

  void addWater(int amount) {
    waterIntakeMl += amount;
    _addXp(2);
    _saveData();
    notifyListeners();
  }

  void addCalories(String name, double amount, {bool isToxinFood = false}) {
    currentCalories += amount;
    if (isToxinFood && !isToxified) {
      toxinLevel += 0.2;
      if (toxinLevel >= 1.0) {
        toxinLevel = 1.0;
        isToxified = true;
      }
    }
    logEntries.add(LogEntry(name: name, calories: amount, type: LogType.food, timestamp: DateTime.now()));
    _addXp(10);
    _saveData();
    notifyListeners();
  }

  void burnCalories(String name, double amount) {
    if (isToxified) {
      isToxified = false;
      toxinLevel = 0;
      logEntries.add(LogEntry(name: "독소 정화", calories: amount, type: LogType.exercise, timestamp: DateTime.now()));
      _saveData();
      notifyListeners();
      return;
    }
    currentCalories -= amount;
    if (currentCalories < 0) currentCalories = 0;
    if (toxinLevel > 0) {
      toxinLevel -= (amount / 1000.0);
      if (toxinLevel < 0) toxinLevel = 0;
    }
    bossHp -= amount;
    logEntries.add(LogEntry(name: name, calories: amount, type: LogType.exercise, timestamp: DateTime.now()));
    _addXp(20);
    if (bossHp <= 0) {
      bossDefeated();
    } else {
      _saveData();
    }
    notifyListeners();
  }

  void bossDefeated() {
    _addXp(100 * bossStage.toDouble());
    bossStage++;
    maxBossHp *= 1.1;
    bossHp = maxBossHp;
    _saveData();
  }
}
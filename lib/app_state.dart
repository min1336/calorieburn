// lib/app_state.dart

import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'log_entry.dart';

enum Gender { male, female }
enum ActivityLevel { sedentary, light, moderate, active, veryActive }

class AppState extends ChangeNotifier {
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

  // --- 여기를 추가했습니다: 수분 섭취 변수 ---
  int waterIntakeMl = 0;
  final int waterGoalMl = 2000; // 목표량 2000ml

  AppState() {
    loadData();
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
    currentXp = currentXp - xpForNextLevel;
    xpForNextLevel = _calculateXpForNextLevel(userLevel);
  }

  void _addXp(double amount) {
    currentXp += amount;
    if (currentXp >= xpForNextLevel) {
      _levelUp();
    }
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final todayString = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final lastActiveDate = prefs.getString('lastActiveDate');

    userAge = prefs.getInt('userAge') ?? 30;
    userHeightCm = prefs.getDouble('userHeightCm') ?? 175.0;
    userWeightKg = prefs.getDouble('userWeightKg') ?? 75.0;
    gender = Gender.values[prefs.getInt('gender') ?? Gender.male.index];
    activityLevel = ActivityLevel.values[prefs.getInt('activityLevel') ?? ActivityLevel.moderate.index];
    recalculateRecommendedCalories();

    userLevel = prefs.getInt('userLevel') ?? 1;
    currentXp = prefs.getDouble('currentXp') ?? 0;
    bossStage = prefs.getInt('bossStage') ?? 1;
    maxBossHp = prefs.getDouble('maxBossHp') ?? 7700.0;
    bossHp = prefs.getDouble('bossHp') ?? maxBossHp;
    xpForNextLevel = _calculateXpForNextLevel(userLevel);

    if (lastActiveDate == null || lastActiveDate != todayString) {
      currentCalories = 0;
      toxinLevel = 0;
      logEntries = [];
      isToxified = false;
      waterIntakeMl = 0; // 날짜 바뀌면 물 섭취량 초기화
    } else {
      currentCalories = prefs.getDouble('currentCalories') ?? 0;
      toxinLevel = prefs.getDouble('toxinLevel') ?? 0;
      isToxified = prefs.getBool('isToxified') ?? false;
      waterIntakeMl = prefs.getInt('waterIntakeMl') ?? 0; // 물 섭취량 불러오기
      List<String> logEntriesJson = prefs.getStringList('logEntries') ?? [];
      logEntries = logEntriesJson.map((jsonString) => LogEntry.fromJson(jsonDecode(jsonString))).toList();
    }
    notifyListeners();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    prefs.setString('lastActiveDate', today);

    prefs.setInt('userAge', userAge);
    prefs.setDouble('userHeightCm', userHeightCm);
    prefs.setDouble('userWeightKg', userWeightKg);
    prefs.setInt('gender', gender.index);
    prefs.setInt('activityLevel', activityLevel.index);

    prefs.setDouble('currentCalories', currentCalories);
    prefs.setDouble('toxinLevel', toxinLevel);
    prefs.setDouble('bossHp', bossHp);
    prefs.setDouble('maxBossHp', maxBossHp);
    prefs.setInt('bossStage', bossStage);
    prefs.setInt('userLevel', userLevel);
    prefs.setDouble('currentXp', currentXp);
    prefs.setBool('isToxified', isToxified);
    prefs.setInt('waterIntakeMl', waterIntakeMl); // 물 섭취량 저장
    List<String> logEntriesJson = logEntries.map((entry) => jsonEncode(entry.toJson())).toList();
    prefs.setStringList('logEntries', logEntriesJson);
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
    notifyListeners();
  }

  void updateProfile({
    required int newAge,
    required double newHeight,
    required double newWeight,
    required Gender newGender,
    required ActivityLevel newActivityLevel,
  }) {
    userAge = newAge;
    userHeightCm = newHeight;
    userWeightKg = newWeight;
    gender = newGender;
    activityLevel = newActivityLevel;
    recalculateRecommendedCalories();
    _saveData();
  }

  // --- 여기를 추가했습니다: 수분 섭취 함수 ---
  void addWater(int amount) {
    waterIntakeMl += amount;
    _addXp(2); // 물 마실 때마다 2 XP 획득
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
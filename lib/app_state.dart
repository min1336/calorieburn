// lib/app_state.dart

import 'dart:async';
import 'dart:math';
import 'package:calorie_burn/boss_data.dart';
import 'package:calorie_burn/item_data.dart';
import 'package:calorie_burn/quest_data.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:health/health.dart';
import 'log_entry.dart';

enum Gender { male, female }
enum ActivityLevel { sedentary, light, moderate, active, veryActive }

class AppState extends ChangeNotifier {
  final HealthFactory health = HealthFactory(useHealthConnectIfAvailable: true);
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- 기존 변수 ---
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
  String nickname = '';
  List<Map<String, dynamic>> rankings = [];
  bool isRankingLoading = true;
  List<String> friends = [];

  // --- RPG 강화 변수 ---
  int gems = 0;
  Map<String, double> questProgress = {};
  List<String> completedDailyQuests = [];
  Map<String, int> inventory = {};

  // --- 보스 상태이상 변수 ---
  bool isBossToxified = false;

  Boss get currentBoss {
    return allBosses.firstWhere((boss) => boss.stage == bossStage, orElse: () => allBosses.last);
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
    userLevel = data['userLevel'] ?? 1;
    currentXp = data['currentXp']?.toDouble() ?? 0;
    bossStage = data['bossStage'] ?? 1;
    isBossToxified = data['isBossToxified'] ?? false;

    _updateBossStats();
    bossHp = data['bossHp']?.toDouble() ?? maxBossHp;

    if (currentBoss.hasToxin && !isBossToxified) {
      isBossToxified = true;
    }

    isToxified = data['isToxified'] ?? false;
    if (data['friends'] != null) friends = List<String>.from(data['friends']);
    gems = data['gems'] ?? 0;
    if (data['inventory'] != null) {
      inventory = Map<String, int>.from(data['inventory']);
    }

    final todayString = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final lastActiveDate = data['lastActiveDate'];

    if (lastActiveDate == null || lastActiveDate != todayString) {
      currentCalories = 0;
      toxinLevel = 0;
      logEntries = [];
      waterIntakeMl = 0;
      questProgress = {};
      completedDailyQuests = [];
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
      if (data['questProgress'] != null) {
        questProgress = Map<String, double>.from(data['questProgress']);
      }
      if (data['completedDailyQuests'] != null) {
        completedDailyQuests = List<String>.from(data['completedDailyQuests']);
      }
    }

    notifyListeners();
    await initHealth();
    await fetchRankings();
  }

  Future<void> _saveData() async {
    if (_uid == null) return;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final userDocRef = _firestore.collection('users').doc(_uid);
    final logEntriesJson = logEntries.map((entry) => entry.toJson()).toList();

    await userDocRef.set({
      'nickname': nickname,
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
      'isBossToxified': isBossToxified,
      'waterIntakeMl': waterIntakeMl,
      'logEntries': logEntriesJson,
      'friends': friends,
      'gems': gems,
      'questProgress': questProgress,
      'completedDailyQuests': completedDailyQuests,
      'inventory': inventory,
    }, SetOptions(merge: true));
  }

  void _updateBossStats() {
    Boss bossInfo = currentBoss;
    if (bossStage > allBosses.length) {
      int extraStages = bossStage - allBosses.length;
      maxBossHp = bossInfo.baseHp * pow(1.2, extraStages);
    } else {
      maxBossHp = bossInfo.baseHp;
    }
    notifyListeners();
  }

  void bossDefeated() {
    _addXp(100 * bossStage.toDouble());
    bossStage++;
    _updateBossStats();
    bossHp = maxBossHp;
    isBossToxified = currentBoss.hasToxin;
    _saveData();
    notifyListeners();
  }

  String buyItem(ShopItem item) {
    if (gems >= item.priceGems) {
      gems -= item.priceGems;
      final currentQuantity = inventory[item.id] ?? 0;
      inventory[item.id] = currentQuantity + 1;
      _saveData();
      notifyListeners();
      return "구매 완료!";
    } else {
      return "젬이 부족합니다.";
    }
  }

  String useItem(ShopItem item) {
    final currentQuantity = inventory[item.id] ?? 0;
    if (currentQuantity > 0) {
      inventory[item.id] = currentQuantity - 1;
      if (inventory[item.id] == 0) inventory.remove(item.id);

      switch (item.effect) {
        case ItemEffect.bossDamage:
          bossHp -= item.effectValue;
          logEntries.add(LogEntry(
              name: '${item.name} 사용',
              calories: item.effectValue,
              type: LogType.exercise,
              timestamp: DateTime.now()));
          if (bossHp <= 0) {
            bossDefeated();
          }
          break;
        case ItemEffect.cureBoss:
          if (isBossToxified) {
            isBossToxified = false;
            notifyListeners();
          }
          break;
        case ItemEffect.xpBoost:
          break;
      }

      _saveData();
      notifyListeners();
      return "${item.name}을(를) 사용했습니다!";
    } else {
      return "아이템이 없습니다.";
    }
  }

  void _updateQuestProgress(QuestType type, double value) {
    for (var quest in allQuests) {
      if (quest.type == type) {
        final currentVal = questProgress[quest.id] ?? 0;
        questProgress[quest.id] = currentVal + value;
        notifyListeners();
      }
    }
    _saveData();
  }

  void _updateQuestProgressAbsolute(QuestType type, double value) {
    for (var quest in allQuests) {
      if (quest.type == type) {
        questProgress[quest.id] = value;
        notifyListeners();
      }
    }
    _saveData();
  }

  void claimQuestReward(Quest quest) {
    if (completedDailyQuests.contains(quest.id)) return;
    final progress = questProgress[quest.id] ?? 0;
    if (progress >= quest.goal) {
      gems += quest.rewardGems;
      completedDailyQuests.add(quest.id);
      _saveData();
      notifyListeners();
    }
  }

  Future<void> fetchTodaySteps() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    int? steps = await health.getTotalStepsInInterval(midnight, now);
    if (steps != null) {
      todaySteps = steps;
      _updateQuestProgressAbsolute(QuestType.steps, todaySteps.toDouble());
      notifyListeners();
    }
  }

  void addWater(int amount) {
    waterIntakeMl += amount;
    _addXp(2);
    _updateQuestProgress(QuestType.addWater, amount.toDouble());
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
    _updateQuestProgress(QuestType.logFood, 1);
    _saveData();
    notifyListeners();
  }

  // --- 여기 로직이 수정되었습니다 ---
  void burnCalories(String name, double amount) {
    // 1. 유저가 중독 상태일 때의 로직
    if (isToxified) {
      toxinLevel -= (amount / 100.0); // 운동량만큼 독소 레벨 감소
      logEntries.add(LogEntry(name: "독소 정화", calories: amount, type: LogType.exercise, timestamp: DateTime.now()));

      // 만약 독소 레벨이 0 이하로 떨어지면 중독 상태 해제
      if (toxinLevel <= 0) {
        toxinLevel = 0;
        isToxified = false;
      }

      _saveData();
      notifyListeners();
      return; // 중독 상태일 때는 보스에게 데미지를 주지 않고 여기서 종료
    }

    // 2. 일반 상태일 때의 로직 (기존과 동일)
    currentCalories -= amount;
    if (currentCalories < 0) currentCalories = 0;

    double finalDamage = amount;
    if (isBossToxified) {
      finalDamage *= 0.1;
    }

    bossHp -= finalDamage;
    logEntries.add(LogEntry(name: name, calories: finalDamage, type: LogType.exercise, timestamp: DateTime.now()));
    _addXp(20);
    _updateQuestProgress(QuestType.burnCalories, amount);

    if (bossHp <= 0) {
      bossDefeated();
    } else {
      _saveData();
    }
    notifyListeners();
  }
  // --- 수정 끝 ---


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
    DocumentSnapshot<Map<String, dynamic>> userDoc;
    try {
      userDoc = await _firestore.collection('users').doc(_uid).get();
      if (!userDoc.exists) return;
    } catch (e) {
      return;
    }
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
    if (_uid == null) return;
    isRankingLoading = true;
    notifyListeners();
    try {
      final uidsToFetch = List<String>.from(friends);
      if (!uidsToFetch.contains(_uid)) {
        uidsToFetch.add(_uid!);
      }
      if (uidsToFetch.isEmpty) {
        rankings = [];
        isRankingLoading = false;
        notifyListeners();
        return;
      }
      final querySnapshot = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: uidsToFetch)
          .get();
      var friendData = querySnapshot.docs.map((doc) => doc.data()).toList();
      friendData.sort((a, b) {
        int levelCompare = (b['userLevel'] ?? 0).compareTo(a['userLevel'] ?? 0);
        if (levelCompare != 0) return levelCompare;
        return (b['currentXp'] ?? 0.0).compareTo(a['currentXp'] ?? 0.0);
      });
      rankings = friendData;
    } catch (e) {
      print("랭킹을 불러오는 중 오류 발생: $e");
      rankings = [];
    } finally {
      isRankingLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, String>?> findUserByNickname(String nickname) async {
    final querySnapshot = await _firestore
        .collection('users')
        .where('nickname', isEqualTo: nickname)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      final userDoc = querySnapshot.docs.first;
      return {'uid': userDoc.id, 'nickname': userDoc.data()['nickname']};
    }
    return null;
  }

  Future<void> addFriend(String friendUid) async {
    if (!friends.contains(friendUid) && friendUid != _uid) {
      friends.add(friendUid);
      await _saveData();
      await fetchRankings();
      notifyListeners();
    }
  }

  Future<void> removeFriend(String friendUid) async {
    friends.remove(friendUid);
    await _saveData();
    await fetchRankings();
    notifyListeners();
  }
}
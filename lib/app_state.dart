// lib/app_state.dart

import 'dart:async';
import 'dart:math';
import 'package:calorie_burn/calorie_activity.dart';
import 'package:calorie_burn/favorite_food.dart';
import 'package:calorie_burn/models/user_profile.dart';
import 'package:calorie_burn/services/firestore_service.dart';
import 'package:calorie_burn/services/health_service.dart';
import 'package:calorie_burn/models/enums.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class AppState extends ChangeNotifier {
  final FirestoreService _firestoreService;
  final HealthService _healthService;

  AppState(this._firestoreService, this._healthService);

  // --- UI 상태 ---
  int selectedIndex = 0;
  DateTime selectedDate = DateTime.now();
  bool isRankingLoading = true;
  bool get isHealthAuthorized => _healthService.isAuthorized;

  // --- 사용자 데이터 ---
  String? _uid;
  UserProfile _userProfile = UserProfile.initial();
  double currentCalories = 0;
  double maxCalories = 2200;
  double todayOverconsumedCaloriesBurned = 0;
  double todaySyncedCalories = 0;
  List<CalorieActivity> todayActivities = [];
  List<FavoriteFood> favoriteFoods = [];
  List<Map<String, dynamic>> rankings = [];
  List<String> get availableDataSources => _healthService.availableDataSources;
  String? get primaryDataSource => _healthService.primaryDataSource;

  // ✅ 추가: 칼로리 기록 데이터
  List<Map<String, dynamic>> calorieHistory = [];
  bool isHistoryLoading = true;

  // --- Getter ---
  String get nickname => _userProfile.nickname;
  int get userAge => _userProfile.userAge;
  double get userHeightCm => _userProfile.userHeightCm;
  double get userWeightKg => _userProfile.userWeightKg;
  Gender get gender => _userProfile.gender;
  ActivityLevel get activityLevel => _userProfile.activityLevel;


  Future<void> loadData(String uid) async {
    _uid = uid;
    final profileData = await _firestoreService.getUserProfile(uid);
    if (profileData != null) {
      _userProfile = profileData;
      _healthService.setPrimaryDataSource(profileData.primaryDataSource, shouldSave: false);
    }
    recalculateRecommendedCalories();

    final dailyData = await _firestoreService.getDailyData(uid, selectedDate);
    currentCalories = dailyData['currentCalories'] ?? 0;
    todayOverconsumedCaloriesBurned = dailyData['todayOverconsumedCaloriesBurned'] ?? 0;
    todaySyncedCalories = dailyData['syncedCaloriesToday'] ?? 0;

    favoriteFoods = await _firestoreService.getFavoriteFoods(uid);
    todayActivities = await _firestoreService.getActivities(uid, selectedDate);

    notifyListeners();

    try {
      await initHealth();
    } catch (e) {
      debugPrint("초기 건강 데이터 로딩 실패: $e");
    }
    await fetchRankings();
  }

  // ✅ 추가: 칼로리 기록 조회 함수
  Future<void> fetchCalorieHistory() async {
    if (_uid == null) return;
    isHistoryLoading = true;
    notifyListeners();

    calorieHistory = await _firestoreService.getCalorieHistory(_uid!);

    isHistoryLoading = false;
    notifyListeners();
  }

  Future<void> changeDate(DateTime newDate) async {
    selectedDate = newDate;
    if (_uid != null) {
      await loadData(_uid!);
    }
  }

  Future<void> _saveData() async {
    if (_uid == null) return;
    await _firestoreService.saveUserProfile(_uid!, _userProfile);
    await _firestoreService.saveDailyData(_uid!, selectedDate, {
      'currentCalories': currentCalories,
      'todayOverconsumedCaloriesBurned': todayOverconsumedCaloriesBurned,
      'syncedCaloriesToday': todaySyncedCalories,
    });
    await _firestoreService.saveActivities(_uid!, selectedDate, todayActivities);
  }

  void addCalories(String name, double amount) {
    currentCalories += amount;
    todayActivities.add(CalorieActivity(
      name: name, amount: amount, type: ActivityType.consumed, timestamp: DateTime.now(),
    ));
    _saveData();
    notifyListeners();
  }

  void decreaseCalories(String name, double amount) {
    double caloriesOverBefore = max(0, currentCalories - maxCalories);
    currentCalories -= amount;
    if (currentCalories < 0) currentCalories = 0;
    double caloriesOverAfter = max(0, currentCalories - maxCalories);
    double burnedOverCalories = caloriesOverBefore - caloriesOverAfter;
    if (burnedOverCalories > 0) {
      todayOverconsumedCaloriesBurned += burnedOverCalories;
    }
    todayActivities.add(CalorieActivity(
      name: name, amount: amount, type: ActivityType.burned, timestamp: DateTime.now(),
    ));
    _saveData();
    notifyListeners();
  }

  Future<void> addFoodFavorite(FavoriteFood food) async {
    if (_uid == null || favoriteFoods.contains(food)) return;
    favoriteFoods.add(food);
    await _firestoreService.saveFavoriteFoods(_uid!, favoriteFoods);
    notifyListeners();
  }

  Future<void> removeFoodFavorite(FavoriteFood food) async {
    if (_uid == null) return;
    favoriteFoods.remove(food);
    await _firestoreService.saveFavoriteFoods(_uid!, favoriteFoods);
    notifyListeners();
  }


  Future<void> initHealth() async {
    await _healthService.authorize();
    if (isHealthAuthorized) {
      await fetchTodayHealthData();
    }
    notifyListeners();
  }

  Future<void> fetchTodayHealthData() async {
    todaySyncedCalories = await _healthService.fetchTodayHealthData(selectedDate);
    notifyListeners();
  }

  Future<String> syncFromSmartwatch() async {
    if (_uid == null) return "사용자 정보가 없어 동기화할 수 없습니다.";

    final result = await _healthService.syncFromSmartwatch(
        selectedDate,
        todaySyncedCalories
    );

    if (result['newlyBurnedCalories'] != null && result['newlyBurnedCalories']! > 0) {
      double newlyBurnedCalories = result['newlyBurnedCalories']!;
      todaySyncedCalories += newlyBurnedCalories;

      double caloriesOverBefore = max(0, currentCalories - maxCalories);
      currentCalories -= newlyBurnedCalories;
      if (currentCalories < 0) currentCalories = 0;
      double caloriesOverAfter = max(0, currentCalories - maxCalories);
      double burnedOverCalories = caloriesOverBefore - caloriesOverAfter;
      if (burnedOverCalories > 0) {
        todayOverconsumedCaloriesBurned += burnedOverCalories;
      }

      await _saveData();
      notifyListeners();
    }
    return result['message'];
  }

  Future<void> setPrimaryDataSource(String sourceName) async {
    if (_uid == null) return;
    _healthService.setPrimaryDataSource(sourceName);
    _userProfile.primaryDataSource = sourceName;
    await _firestoreService.updateUserProfileField(_uid!, {'primaryDataSource': sourceName});
    notifyListeners();
  }

  void onTabTapped(int index) {
    selectedIndex = index;
    notifyListeners();
  }

  void recalculateRecommendedCalories() {
    maxCalories = _userProfile.recommendedCalories;
  }

  void updateProfile({
    required String newNickname,
    required int newAge,
    required double newHeight,
    required double newWeight,
    required Gender newGender,
    required ActivityLevel newActivityLevel,
  }) {
    _userProfile = _userProfile.copyWith(
      nickname: newNickname,
      userAge: newAge,
      userHeightCm: newHeight,
      userWeightKg: newWeight,
      gender: newGender,
      activityLevel: newActivityLevel,
    );
    recalculateRecommendedCalories();
    _saveData();
    notifyListeners();
  }

  Future<void> fetchRankings() async {
    isRankingLoading = true;
    notifyListeners();
    rankings = await _firestoreService.fetchRankings();
    isRankingLoading = false;
    notifyListeners();
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
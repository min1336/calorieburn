// lib/services/health_service.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

class HealthService {
  final Health health = Health();
  bool isAuthorized = false;
  String? primaryDataSource;
  List<String> availableDataSources = [];

  // ✅ 수정: 칼로리 데이터 타입만 남김
  final _types = [
    HealthDataType.ACTIVE_ENERGY_BURNED,
  ];
  // ✅ 수정: 권한도 하나만 요청
  final _permissions = [
    HealthDataAccess.READ,
  ];

  Future<void> authorize() async {
    try {
      isAuthorized = await health.requestAuthorization(_types, permissions: _permissions);
    } catch (e) {
      isAuthorized = false;
      debugPrint("건강 데이터 권한 요청 중 오류 발생: $e");
    }
  }

  // ✅ 삭제: getLatestHeartRate 함수 제거

  Future<double> fetchTodayHealthData(DateTime date) async {
    if (!isAuthorized) return 0;

    final now = date.year == DateTime.now().year &&
        date.month == DateTime.now().month &&
        date.day == DateTime.now().day
        ? DateTime.now()
        : DateTime(date.year, date.month, date.day, 23, 59, 59);
    final midnight = DateTime(date.year, date.month, date.day);

    try {
      List<HealthDataPoint> healthData = await health.getHealthDataFromTypes(
          startTime: midnight, endTime: now, types: [HealthDataType.ACTIVE_ENERGY_BURNED]);
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
      return totalCalories;
    } catch (e) {
      debugPrint("오늘의 건강 데이터 가져오기 실패: $e");
      return 0;
    }
  }

  Future<Map<String, dynamic>> syncFromSmartwatch(DateTime date, double alreadySyncedCalories) async {
    if (!isAuthorized) {
      await authorize();
      if (!isAuthorized) {
        return {'message': "권한이 거부되었습니다. 데이터에 접근하려면 건강 데이터 권한을 허용해주세요."};
      }
    }

    try {
      final totalCaloriesFromWatch = await fetchTodayHealthData(date);
      final newlyBurnedCalories = totalCaloriesFromWatch - alreadySyncedCalories;

      if (newlyBurnedCalories > 0.1) {
        return {
          'message': "성공! ${primaryDataSource ?? '스마트워치'}에서 ${newlyBurnedCalories.toInt()} kcal를 새로 가져왔습니다.",
          'newlyBurnedCalories': newlyBurnedCalories,
        };
      } else {
        return {'message': "이미 최신 데이터입니다. 새로운 활동량이 없습니다."};
      }
    } catch (e) {
      debugPrint("스마트워치 동기화 오류: $e");
      return {'message': "데이터를 가져오는 중 오류가 발생했습니다: $e"};
    }
  }

  void setPrimaryDataSource(String? sourceName, {bool shouldSave = true}) {
    primaryDataSource = sourceName;
  }
}
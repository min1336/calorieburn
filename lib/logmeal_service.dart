// lib/logmeal_service.dart

import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

// LogMeal API 응답을 담을 데이터 모델
class LogMealResult {
  final String foodName;
  final double calories;
  final double protein;
  final double fat;
  final double carbs;

  LogMealResult({
    required this.foodName,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
  });
}

class LogMealService {
  final String _apiToken = dotenv.env['LOGMEAL_API_TOKEN'] ?? 'default_token';
  final String _recognitionUrl = 'https://api.logmeal.es/v2/recognition/dish';
  final String _getNutritionUrl = 'https://api.logmeal.es/v2/nutrition/recipe/ingredients';

  Future<LogMealResult> analyzeImage(XFile imageFile) async {
    try {
      // --- 1단계: 이미지로 음식 이름과 ID 알아내기 ---
      debugPrint("[LogMealService] 1단계: 음식 인식 API 요청을 시작합니다.");
      final imageBytes = await imageFile.readAsBytes();
      final recognitionUri = Uri.parse(_recognitionUrl);
      final recognitionRequest = http.MultipartRequest('POST', recognitionUri)
        ..headers['Authorization'] = 'Bearer $_apiToken'
        ..files.add(http.MultipartFile.fromBytes('image', imageBytes, filename: imageFile.name));

      final streamedResponse = await recognitionRequest.send();
      final recognitionResponse = await http.Response.fromStream(streamedResponse);

      debugPrint("[LogMealService] 1단계 응답 상태 코드: ${recognitionResponse.statusCode}");
      if (kDebugMode) debugPrint("[LogMealService] 1단계 응답 바디: ${recognitionResponse.body}");

      if (recognitionResponse.statusCode != 200) {
        throw Exception('LogMeal API 오류 (1단계 - 음식 인식 실패)');
      }

      final recognitionData = json.decode(recognitionResponse.body);
      if (recognitionData['recognition_results'] == null ||
          (recognitionData['recognition_results'] as List).isEmpty) {
        throw Exception('사진에서 음식을 인식할 수 없습니다.');
      }
      final topResult = recognitionData['recognition_results'][0];
      final imageId = recognitionData['imageId'] as int;
      final foodName = topResult['name'] as String;
      debugPrint("[LogMealService] 1단계 성공: Image ID '$imageId', 이름 '$foodName' 확인");

      // --- 2단계: 알아낸 ID로 영양 정보 직접 조회 시도 ---
      debugPrint("[LogMealService] 2단계: 영양 정보 API 요청을 시작합니다.");
      final nutritionUri = Uri.parse(_getNutritionUrl);
      final nutritionResponse = await http.post(
        nutritionUri,
        headers: {
          'Authorization': 'Bearer $_apiToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({'imageId': imageId}),
      );

      debugPrint("[LogMealService] 2단계 응답 상태 코드: ${nutritionResponse.statusCode}");
      if (kDebugMode) debugPrint("[LogMealService] 2단계 응답 바디: ${nutritionResponse.body}");

      if (nutritionResponse.statusCode != 200) {
        throw Exception('LogMeal API 오류 (2단계 - 영양 정보 조회 실패)');
      }

      final nutritionData = json.decode(nutritionResponse.body);

      // ✅ 수정: API 응답에 영양 정보가 있는지 직접 확인
      final nutritionalInfo = nutritionData['nutritional_info'];

      if (nutritionalInfo == null) {
        debugPrint("[LogMealService] 오류: API 응답에 'nutritional_info' 필드가 없습니다.");
        // 사용자가 이해할 수 있는 명확한 오류 메시지 전달
        throw Exception('API 플랜의 한계로 영양 정보를 가져올 수 없습니다. LogMeal 웹사이트에서 플랜을 확인해주세요.');
      }

      debugPrint("[LogMealService] 2단계 성공: 영양 정보를 찾았습니다.");

      return LogMealResult(
        foodName: foodName,
        calories: (nutritionalInfo['calories'] as num?)?.toDouble() ?? 0.0,
        protein: (nutritionalInfo['protein'] as num?)?.toDouble() ?? 0.0,
        fat: (nutritionalInfo['total_fat'] as num?)?.toDouble() ?? 0.0,
        carbs: (nutritionalInfo['total_carbohydrate'] as num?)?.toDouble() ?? 0.0,
      );
    } catch (e) {
      debugPrint("[LogMealService] 최종 분석 파이프라인 중 오류 발생! 오류: $e");
      // 모든 오류를 포괄하는 일반적인 메시지로 변환
      if (e is Exception) {
        throw e; // 이미 Exception 객체이면 그대로 던짐
      }
      throw Exception('음식 정보를 분석하는 중 알 수 없는 오류가 발생했습니다.');
    }
  }
}
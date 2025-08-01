// lib/services/logmeal_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:calorie_burn/utils/custom_exceptions.dart'; // ✅ 커스텀 예외 임포트
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

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
  final String _apiToken = dotenv.env['LOGMEAL_API_TOKEN'] ?? '';
  final String _recognitionUrl = 'https://api.logmeal.es/v2/recognition/dish';
  final String _getNutritionUrl = 'https://api.logmeal.es/v2/nutrition/recipe/ingredients';

  Future<LogMealResult> analyzeImage(XFile imageFile) async {
    if (_apiToken.isEmpty) {
      // ✅ API 토큰 누락 에러 처리
      throw LogMealException.apiTokenMissing();
    }

    try {
      // --- 1단계: 이미지로 음식 이름과 ID 알아내기 ---
      debugPrint("[LogMealService] 1단계: 음식 인식 API 요청 시작");
      final imageBytes = await imageFile.readAsBytes();
      final recognitionUri = Uri.parse(_recognitionUrl);
      final recognitionRequest = http.MultipartRequest('POST', recognitionUri)
        ..headers['Authorization'] = 'Bearer $_apiToken'
        ..files.add(http.MultipartFile.fromBytes('image', imageBytes, filename: imageFile.name));

      final streamedResponse = await recognitionRequest.send();
      final recognitionResponse = await http.Response.fromStream(streamedResponse);

      debugPrint("[LogMealService] 1단계 응답 코드: ${recognitionResponse.statusCode}");
      if (kDebugMode) debugPrint("[LogMealService] 1단계 응답 바디: ${recognitionResponse.body}");

      if (recognitionResponse.statusCode != 200) {
        // ✅ API 호출 실패 에러 처리
        throw LogMealException.fromStatusCode(recognitionResponse.statusCode, "음식 인식 실패");
      }

      final recognitionData = json.decode(recognitionResponse.body);
      if (recognitionData['recognition_results'] == null ||
          (recognitionData['recognition_results'] as List).isEmpty) {
        // ✅ 음식 인식 불가 에러 처리
        throw LogMealException.foodNotRecognized();
      }
      final topResult = recognitionData['recognition_results'][0];
      final imageId = recognitionData['imageId'] as int;
      final foodName = topResult['name'] as String;
      debugPrint("[LogMealService] 1단계 성공: Image ID '$imageId', 이름 '$foodName'");


      // --- 2단계: 알아낸 ID로 영양 정보 조회 ---
      debugPrint("[LogMealService] 2단계: 영양 정보 API 요청 시작");
      final nutritionUri = Uri.parse(_getNutritionUrl);
      final nutritionResponse = await http.post(
        nutritionUri,
        headers: {
          'Authorization': 'Bearer $_apiToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({'imageId': imageId}),
      );

      debugPrint("[LogMealService] 2단계 응답 코드: ${nutritionResponse.statusCode}");
      if (kDebugMode) debugPrint("[LogMealService] 2단계 응답 바디: ${nutritionResponse.body}");

      if (nutritionResponse.statusCode != 200) {
        // ✅ API 호출 실패 에러 처리
        throw LogMealException.fromStatusCode(nutritionResponse.statusCode, "영양 정보 조회 실패");
      }

      final nutritionData = json.decode(nutritionResponse.body);
      final nutritionalInfo = nutritionData['nutritional_info'];

      if (nutritionalInfo == null || nutritionalInfo['calories'] == null) {
        // ✅ 영양 정보 누락 에러 처리 (API 플랜 문제 등)
        throw LogMealException.nutritionInfoMissing();
      }
      debugPrint("[LogMealService] 2단계 성공: 영양 정보를 찾았습니다.");

      return LogMealResult(
        foodName: foodName,
        calories: (nutritionalInfo['calories'] as num?)?.toDouble() ?? 0.0,
        protein: (nutritionalInfo['protein'] as num?)?.toDouble() ?? 0.0,
        fat: (nutritionalInfo['total_fat'] as num?)?.toDouble() ?? 0.0,
        carbs: (nutritionalInfo['total_carbohydrate'] as num?)?.toDouble() ?? 0.0,
      );
    } on SocketException {
      // ✅ 네트워크 연결 오류 처리
      throw LogMealException.networkError();
    } on LogMealException {
      // ✅ 이미 처리된 LogMealException은 그대로 다시 던짐
      rethrow;
    } catch (e) {
      // ✅ 그 외 알 수 없는 오류 처리
      debugPrint("[LogMealService] 알 수 없는 오류 발생: $e");
      throw LogMealException.unknownError(e.toString());
    }
  }
}
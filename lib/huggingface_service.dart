// lib/huggingface_service.dart

import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'analysis_result.dart';
import 'food_data_service.dart';

class HuggingFaceService {
  final String _hfApiToken = dotenv.env['HF_API_TOKEN'] ?? 'default_token';
  final String _hfModelUrl =
      'https://api-inference.huggingface.co/models/google/vit-base-patch16-224';
  final FoodDataService _foodDataService = FoodDataService();

  Future<List<String>> _getFoodLabelsFromImage(XFile imageFile) async {
    debugPrint("[HuggingFaceService] getFoodLabelsFromImage: Hugging Face API 요청을 시작합니다.");
    debugPrint("[HuggingFaceService] getFoodLabelsFromImage: 요청 URL: $_hfModelUrl");

    final imageBytes = await imageFile.readAsBytes();
    final headers = {
      'Authorization': 'Bearer $_hfApiToken',
      'Content-Type': 'image/jpeg',
    };

    debugPrint("[HuggingFaceService] getFoodLabelsFromImage: 이미지 데이터를 직접 전송합니다...");
    final response = await http.post(
      Uri.parse(_hfModelUrl),
      headers: headers,
      body: imageBytes,
    );

    final responseBody = response.body;
    final statusCode = response.statusCode;

    debugPrint("[HuggingFaceService] getFoodLabelsFromImage: 응답 상태 코드: $statusCode");
    if (kDebugMode) {
      debugPrint("[HuggingFaceService] getFoodLabelsFromImage: 응답 바디: $responseBody");
    }

    if (statusCode == 200) {
      final List<dynamic> predictions = json.decode(responseBody);
      if (predictions.isNotEmpty) {
        final labels = predictions.map<String>((p) => p['label'] as String).toList();
        debugPrint("[HuggingFaceService] getFoodLabelsFromImage: 인식된 라벨: $labels");
        return labels;
      }
      debugPrint("[HuggingFaceService] getFoodLabelsFromImage: 오류: 응답은 성공(200)했으나, 내용물이 비어있습니다.");
      throw Exception('Hugging Face: 음식을 인식할 수 없습니다.');
    } else {
      debugPrint("[HuggingFaceService] getFoodLabelsFromImage: API 요청 실패!");
      if (statusCode == 401 || statusCode == 403) {
        throw Exception('Hugging Face API 인증 오류: API 토큰이 유효한지 확인해주세요. (상태 코드: $statusCode)');
      }
      final errorData = json.decode(responseBody);
      throw Exception('Hugging Face API 오류: ${errorData['error']} (상태 코드: $statusCode)');
    }
  }

  Future<AnalysisResult> analyzeImage(XFile imageFile) async {
    try {
      debugPrint("[HuggingFaceService] analyzeImage: 이미지 분석 파이프라인 시작.");
      final foodLabels = await _getFoodLabelsFromImage(imageFile);

      debugPrint("[HuggingFaceService] analyzeImage: 인식된 라벨($foodLabels)로 공공데이터 API 조회를 시작합니다.");
      for (var label in foodLabels) {
        final subLabels = label.split(',').map((e) => e.trim());
        for (var subLabel in subLabels) {
          final formattedLabel = subLabel.replaceAll('_', ' ');
          debugPrint("[HuggingFaceService] analyzeImage: '$formattedLabel'(으)로 칼로리 정보 검색 시도...");
          final result = await _foodDataService.searchFood(formattedLabel);
          if (result != null) {
            debugPrint("[HuggingFaceService] analyzeImage: 칼로리 정보 찾음! 결과: ${result.foodName}, ${result.calories} kcal");
            return result;
          }
          debugPrint("[HuggingFaceService] analyzeImage: '$formattedLabel'에 대한 칼로리 정보 없음. 다음 라벨로 계속합니다.");
        }
      }
      debugPrint("[HuggingFaceService] analyzeImage: 오류: 모든 라벨에 대한 영양 정보를 찾지 못했습니다.");
      throw Exception('인식된 음식의 영양 정보를 데이터베이스에서 찾을 수 없습니다.');
    } catch (e) {
      debugPrint("[HuggingFaceService] analyzeImage: 분석 파이프라인 중 오류 발생! 오류: $e");
      rethrow;
    }
  }
}
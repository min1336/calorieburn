// lib/food_data_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'analysis_result.dart';

class FoodDataService {
  final String _apiKey = dotenv.env['PUBLIC_DATA_API_KEY'] ?? 'default_key';
  final String _baseUrl = 'http://apis.data.go.kr/1471000/FoodNtrCpntDbInfo02/getFoodNtrCpntDbInq02';

  Future<AnalysisResult?> searchFood(String foodName) async {

    final uri = Uri.parse('$_baseUrl?serviceKey=$_apiKey&desc_kor=$foodName&pageNo=1&numOfRows=1&type=json');

    debugPrint("[FoodDataService] '식품영양성분DB' API 요청을 시작합니다.");
    debugPrint("[FoodDataService] 요청 URL: $uri");

    try {
      final response = await http.get(uri);
      debugPrint("[FoodDataService] 응답 상태 코드: ${response.statusCode}");
      if (kDebugMode) {
        debugPrint("[FoodDataService] 응답 바디: ${response.body}");
      }

      if (response.statusCode == 200) {

        final data = json.decode(response.body);

        // API의 totalCount가 0이면 데이터가 없는 것이므로, 더 정확하게 확인합니다.
        if (data['body'] == null || data['body']['totalCount'] == 0 || (data['body']['items'] as List).isEmpty) {
          debugPrint("[FoodDataService] 응답 성공했으나, '$foodName'에 대한 검색 결과가 없습니다.");
          return null;
        }

        final items = data['body']['items'] as List;
        if (items.isNotEmpty) {
          final foodItem = items[0];
          final calories = double.tryParse(foodItem['NUTR_CONT1']?.toString() ?? '0.0') ?? 0.0;

          if (calories > 0) {
            final foodNameResult = foodItem['DESC_KOR'];
            debugPrint("[FoodDataService] '$foodName' 검색 성공! -> 결과: '$foodNameResult', $calories kcal");
            return AnalysisResult(
              foodName: foodNameResult,
              calories: calories,
            );
          }
        }
        debugPrint("[FoodDataService] '$foodName'에 대한 유효한 칼로리 정보를 찾지 못했습니다.");
        return null;
      } else {
        debugPrint("[FoodDataService] API 요청 실패! 응답: ${response.body}");
        throw Exception('공공데이터 API 서버에서 오류가 발생했습니다. (상태 코드: ${response.statusCode})');
      }
    } catch (e) {
      debugPrint("[FoodDataService] API 요청 또는 데이터 처리 중 오류 발생! 오류: $e");
      if (e is FormatException) {
        throw Exception('서버로부터 받은 데이터 형식이 올바르지 않습니다.');
      }
      rethrow;
    }
  }
}
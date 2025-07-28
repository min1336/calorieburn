// lib/food_data_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'analysis_result.dart';

class FoodDataService {
  final String _apiKey = dotenv.env['PUBLIC_DATA_API_KEY'] ?? 'default_key';

  // ‼️‼️ API 요청 주소 및 파라미터 전달 방식을 공식적인 방법으로 전면 수정했습니다. ‼️‼️
  final String _baseUrl = 'https://openapi.foodsafetykorea.go.kr/api/I2790/json';

  Future<AnalysisResult?> searchFood(String foodName) async {

    // 1. 요청할 파라미터들을 Map 형태로 구성합니다.
    final Map<String, String> queryParams = {
      'keyId': _apiKey, // API key 파라미터의 이름은 'keyId' 입니다.
      'serviceId': 'I2790',
      'dataType': 'json',
      'startIdx': '1',
      'endIdx': '5',
      'DESC_KOR': foodName
    };

    // 2. Uri.https를 사용하여 안전하게 URL과 파라미터를 조합합니다.
    final uri = Uri.https('openapi.foodsafetykorea.go.kr', '/api/I2790/json', queryParams);

    debugPrint("[FoodDataService] searchFood: 공공데이터 API 요청을 시작합니다.");
    debugPrint("[FoodDataService] searchFood: 요청 URL: $uri");

    try {
      final response = await http.get(uri);
      debugPrint("[FoodDataService] searchFood: 응답 상태 코드: ${response.statusCode}");
      if (kDebugMode) {
        debugPrint("[FoodDataService] searchFood: 응답 바디: ${response.body}");
      }

      if (response.statusCode == 200) {

        // 서버가 HTML 형식으로 에러를 보낼 경우를 대비합니다.
        if (response.body.trim().startsWith('<')) {
          debugPrint("[FoodDataService] searchFood: 오류! 서버에서 HTML 형식의 응답을 받았습니다. 인증키를 확인해주세요.");
          throw Exception('공공데이터 API 인증키가 유효하지 않거나, 서버가 점검 중일 수 있습니다.');
        }

        final data = json.decode(response.body);

        // API 응답 구조에 맞게 성공/실패 확인 로직을 수정합니다.
        if (data['I2790'] == null || data['I2790']['RESULT']['CODE'] == 'INFO-200' || (data['I2790']['row'] as List).isEmpty) {
          debugPrint("[FoodDataService] searchFood: 응답 성공(200)했으나, '$foodName'에 대한 데이터가 없습니다.");
          return null;
        }

        final items = data['I2790']['row'] as List;
        if (items.isNotEmpty) {
          final foodItem = items[0];
          final calories = double.tryParse(foodItem['NUTR_CONT1']?.toString() ?? '0.0') ?? 0.0;

          if (calories > 0) {
            final foodNameResult = foodItem['DESC_KOR'];
            debugPrint("[FoodDataService] searchFood: '$foodName' 검색 성공! -> 결과: '$foodNameResult', $calories kcal");
            return AnalysisResult(
              foodName: foodNameResult,
              calories: calories,
            );
          }
        }
        debugPrint("[FoodDataService] searchFood: '$foodName'에 대한 유효한 칼로리 정보를 찾지 못했습니다.");
        return null;
      } else {
        debugPrint("[FoodDataService] searchFood: API 요청 실패! 응답코드가 200이 아닙니다.");
        return null;
      }
    } catch (e) {
      debugPrint("[FoodDataService] searchFood: API 요청 또는 데이터 처리 중 오류 발생! 오류: $e");
      if (e is FormatException) {
        throw Exception('서버로부터 받은 데이터 형식이 올바르지 않습니다.');
      }
      rethrow;
    }
  }
}
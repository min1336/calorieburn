// lib/food_data_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // dotenv import
import 'package:http/http.dart' as http;
import 'analysis_result.dart';

class FoodDataService {
  // .env 파일에서 키를 안전하게 불러옵니다.
  final String _apiKey = dotenv.env['PUBLIC_DATA_API_KEY'] ?? 'default_key';
  final String _baseUrl = 'https://apis.data.go.kr/1471000/I2790/service/I2790/getFoodNtrItmList1';

  Future<AnalysisResult?> searchFood(String foodName) async {
    final url = '$_baseUrl?ServiceKey=$_apiKey&desc_kor=$foodName&pageNo=1&numOfRows=1&type=json';
    final uri = Uri.parse(url);

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['body'] == null || data['body']['items'] == null) {
          return null;
        }

        final items = data['body']['items'];
        if (items is List && items.isNotEmpty) {
          final foodItem = items[0];
          final calories = double.tryParse(foodItem['NUTR_CONT1']?.toString() ?? '0.0') ?? 0.0;

          if (calories > 0) {
            return AnalysisResult(
              foodName: foodItem['DESC_KOR'],
              calories: calories,
            );
          }
        }
        return null;
      } else {
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FoodDataService Error: $e');
      }
      return null;
    }
  }
}
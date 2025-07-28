// lib/huggingface_service.dart

import 'package:camera/camera.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // dotenv import
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'analysis_result.dart';
import 'food_data_service.dart';

class HuggingFaceService {
  // .env 파일에서 키를 안전하게 불러옵니다.
  final String _hfApiToken = dotenv.env['HF_API_TOKEN'] ?? 'default_token';
  final String _hfModelUrl = 'https://api-inference.huggingface.co/models/nateraw/food-101';

  final FoodDataService _foodDataService = FoodDataService();

  Future<List<String>> _getFoodLabelsFromImage(XFile imageFile) async {
    final headers = {'Authorization': 'Bearer $_hfApiToken'};
    final request = http.MultipartRequest('POST', Uri.parse(_hfModelUrl))
      ..files.add(await http.MultipartFile.fromPath('image', imageFile.path));
    request.headers.addAll(headers);

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final List<dynamic> predictions = json.decode(responseBody);
      if (predictions.isNotEmpty) {
        return predictions.map<String>((p) => p['label'] as String).toList();
      }
      throw Exception('Hugging Face: 음식을 인식할 수 없습니다.');
    } else {
      throw Exception('Hugging Face API 오류: ${response.reasonPhrase}');
    }
  }

  Future<AnalysisResult> analyzeImage(XFile imageFile) async {
    try {
      final foodLabels = await _getFoodLabelsFromImage(imageFile);

      for (var label in foodLabels) {
        final formattedLabel = label.replaceAll('_', ' ');
        final result = await _foodDataService.searchFood(formattedLabel);
        if (result != null) {
          return result;
        }
      }
      throw Exception('인식된 음식의 영양 정보를 데이터베이스에서 찾을 수 없습니다.');
    } catch (e) {
      rethrow;
    }
  }
}
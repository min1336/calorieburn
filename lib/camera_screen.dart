// lib/camera_screen.dart

import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'main.dart'; // main.dart에서 정의한 cameras 변수를 사용하기 위해 import
// http 패키지는 실제 API 호출 시 필요합니다.
// import 'package:http/http.dart' as http;
// import 'dart:convert';

// AI 분석 결과를 담을 클래스
class AnalysisResult {
  final String foodName;
  final double calories;
  AnalysisResult({required this.foodName, required this.calories});
}

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  XFile? _imageFile;
  Future<AnalysisResult?>? _analysisFuture;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      cameras.first,
      ResolutionPreset.high, // 더 좋은 화질로 변경
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;
      final image = await _controller.takePicture();
      setState(() {
        _imageFile = image;
        _analysisFuture = _analyzeImage(image); // 사진을 찍으면 바로 분석 시작
      });
    } catch (e) {
      print(e);
    }
  }

  // AI 서버에 이미지를 보내고 결과를 받는 가상 함수
  Future<AnalysisResult> _analyzeImage(XFile image) async {
    // --- AI 분석 시뮬레이션 ---
    // 실제 API를 연동하기 전까지, 2초간 로딩 후 가짜 데이터를 반환합니다.
    await Future.delayed(const Duration(seconds: 2));
    return AnalysisResult(foodName: 'AI 분석 결과: 닭가슴살', calories: 250);
    // --- 시뮬레이션 끝 ---

    /*
    // --- 실제 API 연동 시 사용할 코드 예시 ---
    final uri = Uri.parse('YOUR_AI_API_ENDPOINT_HERE');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('image', image.path));

    // API Key가 필요하다면 헤더에 추가
    // request.headers.addAll({'Authorization': 'Bearer YOUR_API_KEY'});

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final data = json.decode(responseBody);
        // API 응답 형식에 맞게 파싱
        return AnalysisResult(
          foodName: data['foodName'],
          calories: data['calories'].toDouble(),
        );
      } else {
        throw Exception('Failed to analyze image');
      }
    } catch (e) {
      print(e);
      throw Exception('Failed to connect to the server');
    }
    */
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('음식 사진 촬영')),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (_imageFile == null) {
              return CameraPreview(_controller);
            } else {
              // AI 분석 결과를 보여주는 화면으로 변경
              return _buildResultScreen();
            }
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _imageFile == null
          ? FloatingActionButton(
        onPressed: _takePicture,
        child: const Icon(Icons.camera_alt),
      )
          : null,
    );
  }

  Widget _buildResultScreen() {
    return Column(
      children: [
        Expanded(
          flex: 3,
          child: Image.file(File(_imageFile!.path), fit: BoxFit.cover),
        ),
        Expanded(
          flex: 2,
          child: FutureBuilder<AnalysisResult?>(
            future: _analysisFuture,
            builder: (context, snapshot) {
              // 로딩 중일 때
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('AI가 사진을 분석하고 있습니다...'),
                    ],
                  ),
                );
              }
              // 에러 발생 시
              if (snapshot.hasError) {
                return Center(
                  child: Text('오류 발생: ${snapshot.error}'),
                );
              }
              // 분석 완료 시
              final result = snapshot.data;
              if (result != null) {
                return Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${result.foodName} (${result.calories.toInt()} kcal)',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.replay),
                            label: const Text('다시 찍기'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                            onPressed: () {
                              setState(() {
                                _imageFile = null;
                              });
                            },
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.check),
                            label: const Text('이걸로 섭취'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            onPressed: () {
                              context.read<AppState>().addCalories(result.foodName, result.calories);
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('사진으로 칼로리를 기록했습니다!')),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }
              return const Center(child: Text('분석 결과가 없습니다.'));
            },
          ),
        ),
      ],
    );
  }
}
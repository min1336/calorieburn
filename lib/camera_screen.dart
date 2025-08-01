// lib/camera_screen.dart

import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'main.dart';
import 'services/logmeal_service.dart'; // ✅ 수정: 서비스 경로
import 'utils/custom_exceptions.dart'; // ✅ 수정: 커스텀 예외 임포트

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  XFile? _imageFile;
  Future<LogMealResult?>? _analysisFuture;

  // ✅ 수정: Provider를 통해 LogMealService 인스턴스 가져오기
  late final LogMealService _logMealService;

  @override
  void initState() {
    super.initState();
    _logMealService = context.read<LogMealService>(); // Provider에서 가져오기

    debugPrint("[CameraScreen] initState: 카메라 초기화 시작");
    _controller = CameraController(
      cameras.first,
      ResolutionPreset.high,
    );
    _initializeControllerFuture = _controller.initialize().then((_) {
      debugPrint("[CameraScreen] initState: 카메라 초기화 완료");
    }).catchError((e) {
      debugPrint("[CameraScreen] initState: 카메라 초기화 중 오류: $e");
    });
  }

  @override
  void dispose() {
    debugPrint("[CameraScreen] dispose: 카메라 컨트롤러 해제");
    _controller.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;
      debugPrint("[CameraScreen] takePicture: 사진 촬영 시도");
      final image = await _controller.takePicture();
      debugPrint("[CameraScreen] takePicture: 사진 촬영 성공! 경로: ${image.path}");
      setState(() {
        _imageFile = image;
        debugPrint("[CameraScreen] takePicture: 이미지 분석 시작");
        _analysisFuture = _logMealService.analyzeImage(image);
      });
    } catch (e) {
      debugPrint("[CameraScreen] takePicture: 사진 촬영 중 오류: $e");
      setState(() {
        _analysisFuture = Future.error(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('음식 사진 촬영')),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return _imageFile == null
                ? CameraPreview(_controller)
                : _buildResultScreen();
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
          child: FutureBuilder<LogMealResult?>(
            future: _analysisFuture,
            builder: (context, snapshot) {
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
              // ✅ 수정: 구체적인 에러 처리
              if (snapshot.hasError) {
                String errorMessage = "알 수 없는 오류가 발생했습니다.";
                if (snapshot.error is LogMealException) {
                  errorMessage = (snapshot.error as LogMealException).message;
                }
                debugPrint("[CameraScreen] Result: 분석 중 오류: $errorMessage");
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text('오류 발생: $errorMessage', textAlign: TextAlign.center),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () => setState(() => _imageFile = null),
                          child: const Text('다시 시도하기'),
                        )
                      ],
                    ),
                  ),
                );
              }

              final result = snapshot.data;
              if (result != null) {
                debugPrint("[CameraScreen] Result: 분석 성공! 음식: ${result.foodName}, 칼로리: ${result.calories}");
                return Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            '분석 결과: ${result.foodName.replaceAll('_', ' ')}',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${result.calories.toInt()} kcal',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '탄수화물: ${result.carbs.toStringAsFixed(1)}g, 단백질: ${result.protein.toStringAsFixed(1)}g, 지방: ${result.fat.toStringAsFixed(1)}g',
                            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.replay),
                            label: const Text('다시 찍기'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                            onPressed: () => setState(() => _imageFile = null),
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
              return const Center(child: Text('분석 결과가 없습니다. 다시 시도해 주세요.'));
            },
          ),
        ),
      ],
    );
  }
}
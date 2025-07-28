// lib/camera_screen.dart

import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'main.dart';
import 'huggingface_service.dart';
import 'analysis_result.dart';

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

  final HuggingFaceService _huggingFaceService = HuggingFaceService();

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      cameras.first,
      ResolutionPreset.high,
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
        _analysisFuture = _huggingFaceService.analyzeImage(image);
      });
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
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
            if (_imageFile == null) {
              return CameraPreview(_controller);
            } else {
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
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text('오류 발생: ${snapshot.error}', textAlign: TextAlign.center),
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
                return Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '분석 결과: ${result.foodName.replaceAll('_', ' ')}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${result.calories.toInt()} kcal',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
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
              return const Center(child: Text('분석 결과가 없습니다. 다시 시도해 주세요.'));
            },
          ),
        ),
      ],
    );
  }
}
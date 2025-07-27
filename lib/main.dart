// lib/main.dart

import 'package:camera/camera.dart'; // camera 패키지 import
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_state.dart';
import 'authentication_service.dart';
import 'auth_wrapper.dart';

// 사용 가능한 카메라 목록을 저장할 변수
List<CameraDescription> cameras = [];

Future<void> main() async {
  // main 함수를 비동기로 변경
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();
    // 앱 실행 전에 카메라 목록을 가져옴
    cameras = await availableCameras();
  } catch (e) {
    print('카메라를 초기화하는 데 실패했습니다: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthenticationService>(
          create: (_) => AuthenticationService(FirebaseAuth.instance),
        ),
        StreamProvider(
          create: (context) => context.read<AuthenticationService>().authStateChanges,
          initialData: null,
        ),
        ChangeNotifierProvider(
          create: (context) => AppState(),
        ),
      ],
      child: const CalorieBurnApp(),
    ),
  );
}

class CalorieBurnApp extends StatelessWidget {
  const CalorieBurnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calorie Burn',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Colors.deepPurpleAccent,
          secondary: Colors.amber,
          onPrimary: Colors.white,
          onSecondary: Colors.black,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 16.0),
          bodyMedium: TextStyle(fontSize: 14.0, color: Colors.white70),
          headlineSmall: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: Colors.white),
          titleLarge: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1E1E1E),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        progressIndicatorTheme: ProgressIndicatorThemeData(
          color: Colors.deepPurpleAccent,
          linearTrackColor: Colors.grey[800],
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}
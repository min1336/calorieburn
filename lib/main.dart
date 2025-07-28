// lib/main.dart

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app_state.dart';
import 'authentication_service.dart';
import 'auth_wrapper.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    await dotenv.load(fileName: ".env");

    await Firebase.initializeApp();
    cameras = await availableCameras();

    // 모든 초기화가 성공했을 때만 앱을 실행합니다.
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
  } catch (e) {
    // 초기화 중 오류가 발생하면 앱을 실행하는 대신 오류를 출력합니다.
    debugPrint('앱 초기화 실패: $e');
    // 여기에 사용자에게 오류를 보여주는 위젯을 실행할 수도 있습니다.
    // runApp(ErrorScreen(error: e.toString()));
  }
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
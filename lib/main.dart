// lib/main.dart

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:background_fetch/background_fetch.dart';
import 'package:health/health.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app_state.dart';
import 'authentication_service.dart';
import 'auth_wrapper.dart';


@pragma('vm:entry-point')
void backgroundFetchHeadlessTask(HeadlessTask task) async {
  String taskId = task.taskId;
  bool isTimeout = task.timeout;
  if (isTimeout) {
    debugPrint("[BackgroundFetch] Headless task TIMEOUT: $taskId");
    BackgroundFetch.finish(taskId);
    return;
  }
  debugPrint('[BackgroundFetch] Headless event received: $taskId');

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  try {
    final health = Health();
    final types = [HealthDataType.ACTIVE_ENERGY_BURNED];
    bool? isAuthorized = await health.hasPermissions(types, permissions: [HealthDataAccess.READ]);
    if (isAuthorized == true) {
      debugPrint("[BackgroundFetch] 백그라운드에서 데이터 동기화를 시도합니다.");
    }
  } catch(e) {
    debugPrint("[BackgroundFetch] 백그라운드 작업 중 오류 발생: $e");
  }

  BackgroundFetch.finish(taskId);
}


List<CameraDescription> cameras = [];

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('ko_KR', null);
    await dotenv.load(fileName: ".env");
    await Firebase.initializeApp();
    cameras = await availableCameras();
    initBackgroundFetch();

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
    debugPrint('앱 초기화 실패: $e');
  }
}

Future<void> initBackgroundFetch() async {
  try {
    int status = await BackgroundFetch.configure(
        BackgroundFetchConfig(
          minimumFetchInterval: 15,
          stopOnTerminate: false,
          enableHeadless: true,
          startOnBoot: true,
          requiredNetworkType: NetworkType.ANY,
        ),
        _onBackgroundFetch,
        _onBackgroundFetchTimeout
    );
    debugPrint('[BackgroundFetch] configure success: $status');
  } catch(e) {
    debugPrint("[BackgroundFetch] configure FAILED: $e");
  }
}

void _onBackgroundFetch(String taskId) async {
  debugPrint('[BackgroundFetch] Event received: $taskId');
  BackgroundFetch.finish(taskId);
}

void _onBackgroundFetchTimeout(String taskId) {
  debugPrint("[BackgroundFetch] TIMEOUT: $taskId");
  BackgroundFetch.finish(taskId);
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
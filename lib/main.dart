// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'home_screen.dart';
import 'boss_raid_screen.dart';
import 'profile_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => AppState(),
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
        // ... (테마 설정은 변경 없음)
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  void initState() {
    super.initState();
    // initState에서 리스너를 추가하여 자동 사냥 결과를 감지
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = context.read<AppState>();
      appState.addListener(_showAutoHuntDialog);
    });
  }

  @override
  void dispose() {
    // 위젯이 사라질 때 리스너를 제거하여 메모리 누수 방지
    context.read<AppState>().removeListener(_showAutoHuntDialog);
    super.dispose();
  }

  void _showAutoHuntDialog() {
    final appState = context.read<AppState>();
    // autoHuntResult에 메시지가 있고, 아직 화면에 팝업이 떠있지 않을 때만 실행
    if (appState.autoHuntResult != null && ModalRoute.of(context)?.isCurrent != false) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('⚔️ 자동 사냥 결과 ⚔️'),
          content: Text(appState.autoHuntResult!),
          actions: [
            TextButton(
              onPressed: () {
                // 팝업을 닫고, 결과 메시지를 null로 초기화하여 중복 표시 방지
                appState.autoHuntResult = null;
                Navigator.of(context).pop();
              },
              child: const Text('확인'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final List<Widget> screens = [
      const HomeScreen(),
      const BossRaidScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: screens[appState.selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.shield), label: '보스 레이드'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '내 정보'),
        ],
        currentIndex: appState.selectedIndex,
        onTap: (index) => context.read<AppState>().onTabTapped(index),
      ),
    );
  }
}
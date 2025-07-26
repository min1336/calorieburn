// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_state.dart'; // AppState import
import 'home_screen.dart';
import 'boss_raid_screen.dart';
import 'profile_screen.dart';

void main() {
  runApp(
    // 1. AppState를 앱 전체에 제공
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
        // ... 기존 테마 설정 (변경 없음) ...
      ),
      home: const MainScreen(),
    );
  }
}

// 2. MainScreen을 StatelessWidget으로 변경하고 매우 단순화
class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // AppState의 변화를 감지
    final appState = context.watch<AppState>();

    // 현재 선택된 탭에 따라 보여줄 화면 리스트
    final List<Widget> screens = [
      const HomeScreen(),
      const BossRaidScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: screens[appState.selectedIndex], // 선택된 화면 보여주기
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.shield), label: '보스 레이드'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '내 정보'),
        ],
        currentIndex: appState.selectedIndex,
        // 탭을 누르면 AppState의 함수를 호출하여 상태 변경
        onTap: (index) => context.read<AppState>().onTabTapped(index),
      ),
    );
  }
}
// lib/main_app_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_state.dart';
import 'home_screen.dart';
import 'boss_raid_screen.dart';
import 'profile_screen.dart';
import 'ranking_screen.dart'; // 랭킹 화면 import

class MainAppScreen extends StatefulWidget {
  const MainAppScreen({super.key});

  @override
  State<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {

  @override
  void initState() {
    super.initState();
    final user = context.read<User?>();
    if (user != null) {
      context.read<AppState>().loadData(user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    // --- 랭킹 화면 추가 ---
    final List<Widget> screens = [
      const HomeScreen(),
      const BossRaidScreen(),
      const RankingScreen(), // 여기에 추가
      const ProfileScreen(),
    ];

    return Scaffold(
      // --- body 수정 ---
      // IndexedStack을 사용하면 탭을 전환해도 각 화면의 상태가 유지됨
      body: IndexedStack(
        index: appState.selectedIndex,
        children: screens,
      ),
      // --- 내비게이션 아이템 추가 ---
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // 4개 이상의 아이템을 위해 추가
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.shield), label: '보스 레이드'),
          BottomNavigationBarItem(icon: Icon(Icons.leaderboard), label: '랭킹'), // 여기에 추가
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '내 정보'),
        ],
        currentIndex: appState.selectedIndex,
        onTap: (index) => context.read<AppState>().onTabTapped(index),
      ),
    );
  }
}
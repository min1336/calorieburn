// lib/main_app_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_state.dart';
import 'home_screen.dart';
import 'boss_raid_screen.dart';
import 'profile_screen.dart';

class MainAppScreen extends StatefulWidget {
  const MainAppScreen({super.key});

  @override
  State<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {

  @override
  void initState() {
    super.initState();
    // 로그인 후에 AppState가 사용자 데이터를 로드하도록 트리거
    final user = context.read<User?>();
    if (user != null) {
      context.read<AppState>().loadData(user.uid);
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
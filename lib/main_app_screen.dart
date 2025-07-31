// lib/main_app_screen.dart

import 'package:calorie_burn/camera_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_state.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'ranking_screen.dart';

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

    final List<Widget> screens = [
      const HomeScreen(),
      const RankingScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      // ✅ 수정: Scaffold의 body를 Stack으로 변경하여 위젯을 겹치도록 함
      body: Stack(
        children: [
          // 1. 화면 콘텐츠
          IndexedStack(
            index: appState.selectedIndex,
            children: screens,
          ),
          // 2. 하단 탭 바 (화면 맨 아래에 위치)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BottomAppBar(
              shape: const CircularNotchedRectangle(),
              notchMargin: 8.0,
              child: BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.transparent,
                elevation: 0,
                items: const <BottomNavigationBarItem>[
                  BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
                  BottomNavigationBarItem(icon: Icon(Icons.leaderboard), label: '랭킹'),
                  BottomNavigationBarItem(icon: Icon(Icons.person), label: '내 정보'),
                ],
                currentIndex: appState.selectedIndex,
                onTap: (index) => context.read<AppState>().onTabTapped(index),
              ),
            ),
          ),
        ],
      ),
      // ✅ 수정: FloatingActionButton을 Scaffold에 직접 두어 Stack과 분리
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CameraScreen()),
          );
        },
        backgroundColor: Theme.of(context).colorScheme.secondary,
        shape: const CircleBorder(),
        child: Icon(
          Icons.camera_alt,
          color: Theme.of(context).colorScheme.onSecondary,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
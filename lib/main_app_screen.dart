// lib/main_app_screen.dart

import 'package:calorie_burn/camera_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isHomeScreen = appState.selectedIndex == 0;

    // ✅ 수정: 화면 목록을 3개로 복원
    final List<Widget> screens = [
      const HomeScreen(),
      const RankingScreen(),
      const ProfileScreen(),
    ];

    // ✅ 수정: 네비게이션 아이템을 3개로 복원
    final List<Widget> navItems = [
      _buildNavItem(context, Icons.home, '홈', 0, appState),
      _buildNavItem(context, Icons.leaderboard, '랭킹', 1, appState),
      _buildNavItem(context, Icons.person, '내 정보', 2, appState),
    ];

    return Scaffold(
      body: IndexedStack(
        index: appState.selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomAppBar(
        shape: isHomeScreen ? const CircularNotchedRectangle() : null,
        notchMargin: 8.0,
        child: SizedBox(
          height: 60.0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: navItems,
          ),
        ),
      ),
      floatingActionButton: isHomeScreen
          ? FloatingActionButton(
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
      )
          : null,
      // ✅ 수정: FAB 위치를 원래대로 복원
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildNavItem(
      BuildContext context, IconData icon, String label, int index, AppState appState) {
    final isSelected = appState.selectedIndex == index;
    final color = isSelected ? Theme.of(context).colorScheme.primary : Colors.grey;

    return Expanded(
      child: InkWell(
        onTap: () => appState.onTabTapped(index),
        borderRadius: BorderRadius.circular(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
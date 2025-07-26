// lib/main_app_screen.dart

import 'package:calorie_burn/item_shop_screen.dart';
import 'package:calorie_burn/quest_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_state.dart';
import 'home_screen.dart';
import 'boss_raid_screen.dart';
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
      const BossRaidScreen(),
      const QuestScreen(),
      const ItemShopScreen(), // '랭킹' 대신 '상점' 추가
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: appState.selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.shield), label: '보스 레이드'),
          BottomNavigationBarItem(icon: Icon(Icons.task_alt), label: '퀘스트'),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: '상점'), // 아이콘과 라벨 변경
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '내 정보'),
        ],
        currentIndex: appState.selectedIndex,
        onTap: (index) => context.read<AppState>().onTabTapped(index),
        unselectedItemColor: Colors.grey,
        selectedItemColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
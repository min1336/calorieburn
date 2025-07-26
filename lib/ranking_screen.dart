// lib/ranking_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  @override
  void initState() {
    super.initState();
    // 화면이 처음 로드될 때 랭킹 데이터를 가져옴
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().fetchRankings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('랭킹'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // 새로고침 버튼
              appState.fetchRankings();
            },
          ),
        ],
      ),
      body: appState.isRankingLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: appState.rankings.length,
        itemBuilder: (context, index) {
          final userRank = appState.rankings[index];
          final rank = index + 1;

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: ListTile(
              leading: Text(
                '$rank',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              title: Text(
                userRank['nickname'] ?? '이름 없음',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('Stage ${userRank['bossStage'] ?? 1}'),
              trailing: Text(
                'Lv. ${userRank['userLevel'] ?? 1}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
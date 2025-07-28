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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().fetchRankings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('오버 칼로리 챌린지 랭킹'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              appState.fetchRankings();
            },
          ),
        ],
      ),
      body: appState.isRankingLoading
          ? const Center(child: CircularProgressIndicator())
          : appState.rankings.isEmpty
          ? const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            '랭킹 정보가 없습니다.\n친구를 추가하고 함께 챌린지에 참여해보세요!',
            textAlign: TextAlign.center,
          ),
        ),
      )
          : ListView.builder(
        itemCount: appState.rankings.length,
        itemBuilder: (context, index) {
          final userRank = appState.rankings[index];
          final rank = index + 1;
          final score = userRank['todayOverconsumedCaloriesBurned'] ?? 0.0;

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
              trailing: Text(
                '${score.toInt()} kcal',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
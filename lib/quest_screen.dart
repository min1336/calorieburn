// lib/quest_screen.dart

import 'package:calorie_burn/quest_data.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';

class QuestScreen extends StatelessWidget {
  const QuestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('오늘의 퀘스트'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                Icon(Icons.diamond_outlined, color: Colors.cyanAccent),
                const SizedBox(width: 4),
                Text(
                  '${appState.gems}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          )
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: allQuests.length,
        itemBuilder: (context, index) {
          final quest = allQuests[index];
          final progress = appState.questProgress[quest.id] ?? 0.0;
          final isCompleted = appState.completedDailyQuests.contains(quest.id);
          final canClaim = progress >= quest.goal && !isCompleted;

          return Card(
            color: isCompleted ? Colors.grey[800] : theme.cardTheme.color,
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(quest.title, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(quest.description, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: (progress / quest.goal).clamp(0.0, 1.0),
                    minHeight: 10,
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${progress.toInt()} / ${quest.goal.toInt()}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('+${quest.rewardGems} 💎', style: TextStyle(color: Colors.cyanAccent, fontSize: 16)),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: canClaim
                            ? () {
                          appState.claimQuestReward(quest);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("'${quest.title}' 퀘스트 완료! ${quest.rewardGems}젬을 획득했습니다."),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canClaim ? Colors.green : (isCompleted ? Colors.grey : theme.primaryColor),
                        ),
                        child: Text(isCompleted ? '완료됨' : (canClaim ? '보상 받기' : '진행 중')),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
// lib/home_screen.dart

import 'package:calorie_burn/exercise_screen.dart';
import 'package:calorie_burn/food_input_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'app_state.dart';
import 'calorie_activity.dart'; // CalorieActivity 모델 임포트

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final theme = Theme.of(context);

    final isOver = appState.currentCalories > appState.maxCalories;
    final calorieRatio = (appState.maxCalories > 0)
        ? (appState.currentCalories / appState.maxCalories).clamp(0.0, 1.0)
        : 0.0;
    final overCalories = isOver ? appState.currentCalories - appState.maxCalories : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('오늘의 챌린지'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final user = context.read<User?>();
          if (user != null) {
            await context.read<AppState>().loadData(user.uid);
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // '나의 현황' 카드
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('나의 현황', style: theme.textTheme.titleLarge),
                          GestureDetector(
                            onTap: () {
                              if (!appState.isHealthAuthorized) {
                                context.read<AppState>().onTabTapped(2);
                                ScaffoldMessenger.of(context)
                                  ..removeCurrentSnackBar()
                                  ..showSnackBar(const SnackBar(
                                    content: Text('\'내 정보\'에서 데이터 연동 설정을 확인해주세요.'),
                                    duration: Duration(seconds: 3),
                                  ));
                              }
                            },
                            child: Row(
                              children: [
                                Icon(
                                  appState.isHealthAuthorized ? Icons.check_circle : Icons.warning_amber,
                                  color: appState.isHealthAuthorized ? Colors.greenAccent : Colors.amber,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  appState.isHealthAuthorized ? '데이터 연동됨' : '연동 필요',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: appState.isHealthAuthorized ? Colors.greenAccent : Colors.amber,
                                    decoration: appState.isHealthAuthorized ? TextDecoration.none : TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text('오늘의 칼로리', style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 8),
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: calorieRatio, end: calorieRatio),
                        duration: const Duration(milliseconds: 500),
                        builder: (context, value, child) {
                          return LinearProgressIndicator(
                            value: value,
                            minHeight: 20,
                            backgroundColor: isOver ? Colors.red[900] : Colors.grey[800],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isOver ? Colors.redAccent : Color.lerp(Colors.lightGreenAccent, Colors.orangeAccent, value)!,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${appState.currentCalories.toStringAsFixed(0)} / ${appState.maxCalories.toStringAsFixed(0)} kcal',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: isOver ? Colors.redAccent : Colors.white,
                          ),
                        ),
                      ),
                      const Divider(height: 32, color: Colors.white24),
                      Center(
                        child: Column(
                          children: [
                            Text('오늘 소모한 활동 칼로리', style: theme.textTheme.bodyMedium),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                const Icon(Icons.local_fire_department, color: Colors.orange, size: 32),
                                const SizedBox(width: 8),
                                Text(
                                  '${appState.todaySyncedCalories.toInt()}',
                                  style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.orange),
                                ),
                                const SizedBox(width: 4),
                                const Text('kcal'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // '오버 칼로리 태우기 챌린지' 카드 (조건부 표시)
              if (isOver)
                Padding(
                  padding: const EdgeInsets.only(top: 24.0),
                  child: Card(
                    color: const Color(0xFF2a2a2a),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.whatshot, color: Colors.redAccent),
                              const SizedBox(width: 8),
                              Text(
                                '오버 칼로리 태우기 챌린지!',
                                style: theme.textTheme.titleLarge?.copyWith(color: Colors.redAccent),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '초과된 ${overCalories.toInt()} kcal를 소모하려면 아래 운동이 필요해요.',
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 16),
                          ...appState.exerciseMETs.keys.map((exercise) {
                            final minutes = appState.calculateExerciseMinutes(overCalories, exercise);
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(exercise, style: theme.textTheme.bodyLarge),
                                  Text(
                                    '약 $minutes분',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: theme.colorScheme.secondary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ),

              // '직접 기록', '운동 기록' 버튼
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.edit_note),
                      label: const Text('식사 기록'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16), textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const FoodInputScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.fitness_center),
                      label: const Text('운동 기록'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.lightGreenAccent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16), textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ExerciseScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),

              // ✅ 수정: '오늘의 활동' 리스트 섹션을 화면 아래로 이동
              const SizedBox(height: 24),
              Text('오늘의 활동', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              _buildActivityList(context, appState),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // 활동 기록 리스트를 만드는 위젯 (변경 없음)
  Widget _buildActivityList(BuildContext context, AppState appState) {
    if (appState.todayActivities.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Center(
            child: Text('오늘의 활동 기록이 없습니다.'),
          ),
        ),
      );
    }

    final reversedActivities = appState.todayActivities.reversed.toList();

    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: reversedActivities.length,
        itemBuilder: (context, index) {
          final activity = reversedActivities[index];
          final isConsumed = activity.type == ActivityType.consumed;
          final icon = isConsumed ? Icons.add_circle : Icons.remove_circle;
          final color = isConsumed ? Colors.blueAccent : Colors.greenAccent;
          final sign = isConsumed ? '+' : '-';

          return ListTile(
            leading: Icon(icon, color: color),
            title: Text(activity.name),
            subtitle: Text(DateFormat('HH:mm').format(activity.timestamp)),
            trailing: Text(
              '$sign${activity.amount.toInt()} kcal',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          );
        },
        separatorBuilder: (context, index) => const Divider(height: 1),
      ),
    );
  }
}
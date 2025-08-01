// lib/home_screen.dart

import 'package:calorie_burn/exercise_screen.dart';
import 'package:calorie_burn/food_input_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'app_state.dart';
import 'calorie_activity.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 달력 스크롤 컨트롤러
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    // 오늘 날짜가 보이도록 초기 스크롤 위치를 설정합니다. (가장 오른쪽 끝)
    _scrollController = ScrollController(initialScrollOffset: 0.0);
    // 첫 빌드 후에 스크롤을 맨 오른쪽으로 이동시킵니다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final theme = Theme.of(context);

    // 선택된 날짜의 데이터를 가져옴
    final selectedDate = appState.selectedDate;
    final currentActivities = appState.getCachedActivitiesForDate(selectedDate) ?? [];
    final currentCalories = appState.getCachedCaloriesForDate(selectedDate) ?? 0.0;

    final isOver = currentCalories > appState.maxCalories;
    final calorieRatio = (appState.maxCalories > 0)
        ? (currentCalories / appState.maxCalories).clamp(0.0, 1.0)
        : 0.0;
    final overCalories = isOver ? currentCalories - appState.maxCalories : 0.0;
    final isToday = DateUtils.isSameDay(selectedDate, DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat('yyyy년 MM월 dd일').format(selectedDate)),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final user = context.read<User?>();
          if (user != null) {
            await context.read<AppState>().selectDate(selectedDate, forceRefetch: true);
          }
        },
        child: Column(
          children: [
            // 가로 스크롤 달력
            _buildHorizontalCalendar(context, appState),
            Expanded(
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
                            Text('칼로리 현황', style: theme.textTheme.titleLarge),
                            const SizedBox(height: 20),
                            Text('섭취 칼로리', style: theme.textTheme.bodyMedium),
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
                                '${currentCalories.toStringAsFixed(0)} / ${appState.maxCalories.toStringAsFixed(0)} kcal',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: isOver ? Colors.redAccent : Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    Text('활동 기록', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 8),
                    _buildActivityList(context, currentActivities),
                    const SizedBox(height: 24),

                    // 오늘 날짜일 때만 기록 버튼들이 보이도록 설정
                    if (isToday)
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.edit_note),
                              label: const Text('음식 기록'),
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 가로 스크롤 달력을 만드는 위젯
  Widget _buildHorizontalCalendar(BuildContext context, AppState appState) {
    final today = DateTime.now();

    return Container(
      height: 70,
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        reverse: true, // 오른쪽부터 날짜가 시작되도록 (과거 -> 현재 순서)
        itemCount: 31,
        itemBuilder: (context, index) {
          final date = today.subtract(Duration(days: index));
          final isSelected = DateUtils.isSameDay(date, appState.selectedDate);
          final isToday = DateUtils.isSameDay(date, today);

          return GestureDetector(
            onTap: () => appState.selectDate(date),
            child: Container(
              width: 56,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(12),
                border: isToday && !isSelected ? Border.all(color: Colors.amber, width: 2) : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat.E('ko_KR').format(date),
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white : Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    DateFormat.d().format(date),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActivityList(BuildContext context, List<CalorieActivity> activities) {
    if (appState.isLoadingDate) {
      return const Card(child: Center(child: Padding(
        padding: EdgeInsets.all(20.0),
        child: CircularProgressIndicator(),
      )));
    }

    if (activities.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Center(
            child: Text('해당 날짜의 활동 기록이 없습니다.'),
          ),
        ),
      );
    }

    final reversedActivities = activities.reversed.toList();

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
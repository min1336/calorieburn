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
  final GlobalKey<_CalendarStripState> _calendarKey = GlobalKey<_CalendarStripState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<User?>();
      if (user != null) {
        context.read<AppState>().loadData(user.uid);
      }
    });
  }

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
        title: Text(DateFormat('yyyy년 MM월 dd일').format(appState.selectedDate)),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _calendarKey.currentState?.scrollToToday();
          await context.read<AppState>().changeDate(DateTime.now());
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CalendarStrip(key: _calendarKey),
              const SizedBox(height: 16),

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

              const SizedBox(height: 24),
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


class _CalendarStrip extends StatefulWidget {
  // ✅ 수정: use_super_parameters 경고 해결
  const _CalendarStrip({super.key});

  @override
  State<_CalendarStrip> createState() => _CalendarStripState();
}

class _CalendarStripState extends State<_CalendarStrip> {
  late final ScrollController _scrollController;
  final List<DateTime> _dates = [];
  final double _itemWidth = 60.0;
  final double _itemMargin = 4.0;
  int _todayIndex = 0;

  @override
  void initState() {
    super.initState();

    final today = DateTime.now();
    _dates.addAll(List.generate(30, (index) => today.subtract(Duration(days: 30 - index))));
    _dates.add(today);
    _dates.addAll(List.generate(30, (index) => today.add(Duration(days: index + 1))));

    _todayIndex = _dates.indexWhere((date) =>
    date.year == today.year && date.month == today.month && date.day == today.day);

    _scrollController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollToToday(animated: false);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void scrollToToday({bool animated = true}) {
    if (_scrollController.hasClients && _todayIndex != -1) {
      final screenWidth = MediaQuery.of(context).size.width;
      final totalItemWidth = _itemWidth + (_itemMargin * 2);
      final targetOffset = (_todayIndex * totalItemWidth) - (screenWidth / 2) + (totalItemWidth / 2);

      if (animated) {
        _scrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      } else {
        _scrollController.jumpTo(targetOffset);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final selectedDate = appState.selectedDate;
    final theme = Theme.of(context);

    return SizedBox(
      height: 70,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: _dates.length,
        itemBuilder: (context, index) {
          final date = _dates[index];
          final isSelected = date.year == selectedDate.year &&
              date.month == selectedDate.month &&
              date.day == selectedDate.day;

          return GestureDetector(
            onTap: () {
              context.read<AppState>().changeDate(date);
            },
            child: Container(
              width: _itemWidth,
              margin: EdgeInsets.symmetric(horizontal: _itemMargin),
              decoration: BoxDecoration(
                color: isSelected ? theme.colorScheme.primary : theme.cardTheme.color,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E', 'ko_KR').format(date),
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected ? Colors.white : Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    DateFormat('d').format(date),
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
}
// lib/home_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'log_entry.dart';
import 'exercise_data.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final theme = Theme.of(context);

    final isOver = appState.currentCalories > appState.maxCalories;
    final calorieRatio = (appState.maxCalories > 0) ? (appState.currentCalories / appState.maxCalories).clamp(0.0, 1.0) : 0.0;
    final waterRatio = (appState.waterGoalMl > 0) ? (appState.waterIntakeMl / appState.waterGoalMl).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('오늘의 칼로리'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: appState.isToxified ? const Color(0xff522a5b) : const Color(0xFF1E1E1E),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('나의 아바타 (Lv. ${appState.userLevel})', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: appState.xpForNextLevel > 0 ? appState.currentXp / appState.xpForNextLevel : 0,
                      minHeight: 8,
                      backgroundColor: Colors.grey[800],
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.amberAccent),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text('XP: ${appState.currentXp.toInt()} / ${appState.xpForNextLevel.toInt()}', style: theme.textTheme.bodySmall),
                    ),
                    const SizedBox(height: 12),
                    if (appState.isToxified)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Colors.purpleAccent),
                            const SizedBox(width: 8),
                            Text(
                              '중독 상태: 운동으로 정화 필요!',
                              style: theme.textTheme.bodyLarge?.copyWith(color: Colors.purpleAccent, fontWeight: FontWeight.bold),
                            )
                          ],
                        ),
                      ),
                    Text('일일 칼로리 (HP)', style: theme.textTheme.bodyMedium),
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
                    const SizedBox(height: 20),
                    Text('독소 게이지', style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: appState.toxinLevel, end: appState.toxinLevel),
                        duration: const Duration(milliseconds: 500),
                        builder: (context, value, child) {
                          return LinearProgressIndicator(
                            value: value,
                            minHeight: 12,
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.purpleAccent),
                          );
                        }
                    ),
                    const SizedBox(height: 20),
                    Text('수분 섭취량', style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: waterRatio, end: waterRatio),
                        duration: const Duration(milliseconds: 500),
                        builder: (context, value, child) {
                          return LinearProgressIndicator(
                            value: value,
                            minHeight: 12,
                            backgroundColor: Colors.grey[800],
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.lightBlue),
                          );
                        }
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${appState.waterIntakeMl} / ${appState.waterGoalMl} ml',
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                    const Divider(height: 24, color: Colors.white24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.directions_walk, color: Colors.white70),
                        const SizedBox(width: 8),
                        Text(
                          '오늘의 걸음: ${appState.todaySteps} 걸음',
                          style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: ElevatedButton.icon(icon: const Icon(Icons.add_box_rounded), label: const Text('음식 기록'), style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16), textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), onPressed: () => _showAddCaloriesDialog(context))),
                const SizedBox(width: 16),
                Expanded(child: ElevatedButton.icon(icon: const Icon(Icons.fitness_center), label: const Text('운동 기록'), style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), onPressed: () => _showBurnCaloriesDialog(context))),
              ],
            ),
            const SizedBox(height: 24),
            Text('자주 먹는 음식', style: theme.textTheme.titleLarge?.copyWith(color: Colors.white70)),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                _buildQuickAddButton(context, '피자', '🍕', 550, true),
                _buildQuickAddButton(context, '치킨', '🍗', 650, true),
                _buildQuickAddButton(context, '샐러드', '🥗', 250, false),
                _buildQuickAddButton(context, '라면', '🍜', 500, true),
              ],
            ),
            const SizedBox(height: 24),
            Text('자주 하는 운동', style: theme.textTheme.titleLarge?.copyWith(color: Colors.white70)),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                _buildQuickExerciseButton(context, '걷기', '🚶', exerciseList.firstWhere((e) => e.name == '빠르게 걷기'), 30),
                _buildQuickExerciseButton(context, '달리기', '🏃', exerciseList.firstWhere((e) => e.name == '달리기'), 20),
                _buildQuickExerciseButton(context, '근력', '🏋️', exerciseList.firstWhere((e) => e.name == '근력 운동 (웨이트)'), 45),
                _buildQuickExerciseButton(context, '자전거', '🚴', exerciseList.firstWhere((e) => e.name == '자전거 타기'), 30),
              ],
            ),
            const SizedBox(height: 24),
            Text('수분 섭취 기록', style: theme.textTheme.titleLarge?.copyWith(color: Colors.white70)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildWaterButton(context, '1컵', '💧', 250),
                _buildWaterButton(context, '1병', '🍾', 500),
              ],
            ),
            const SizedBox(height: 24),
            Text('오늘의 기록', style: theme.textTheme.titleLarge?.copyWith(color: Colors.white70)),
            const SizedBox(height: 12),
            appState.logEntries.isEmpty
                ? const Center(child: Text('아직 기록이 없습니다.'))
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: appState.logEntries.length,
              itemBuilder: (context, index) {
                final entry = appState.logEntries[appState.logEntries.length - 1 - index];
                final isFood = entry.type == LogType.food;
                return Card(
                  child: ListTile(
                    leading: Icon(isFood ? Icons.fastfood_rounded : Icons.directions_run_rounded, color: isFood ? Colors.orangeAccent : Colors.lightBlueAccent),
                    title: Text(entry.name),
                    subtitle: Text(DateFormat('HH:mm').format(entry.timestamp)),
                    trailing: Text('${isFood ? '+' : '-'}${entry.calories.toInt()} kcal', style: TextStyle(color: isFood ? Colors.redAccent : Colors.greenAccent, fontWeight: FontWeight.bold)),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddCaloriesDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final calorieController = TextEditingController();
    bool isToxinFood = false;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('음식 기록'),
              backgroundColor: const Color(0xFF2a2a2a),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    TextField(controller: nameController, autofocus: true, decoration: const InputDecoration(labelText: '음식 이름')),
                    TextField(controller: calorieController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '칼로리 (kcal)')),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Checkbox(
                          value: isToxinFood,
                          onChanged: (bool? value) => setState(() => isToxinFood = value ?? false),
                        ),
                        const Text('독소 음식인가요?'),
                      ],
                    )
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(child: const Text('취소'), onPressed: () => Navigator.of(dialogContext).pop()),
                ElevatedButton(
                  child: const Text('저장'),
                  onPressed: () {
                    final name = nameController.text;
                    final calorieText = calorieController.text;
                    if (name.isNotEmpty && calorieText.isNotEmpty) {
                      final calories = double.tryParse(calorieText);
                      if (calories != null && calories > 0) {
                        context.read<AppState>().addCalories(name, calories, isToxinFood: isToxinFood);
                        Navigator.of(dialogContext).pop();
                      }
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showBurnCaloriesDialog(BuildContext context) async {
    final durationController = TextEditingController();
    Exercise? selectedExercise;
    final appState = context.read<AppState>();

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('운동 기록'),
          backgroundColor: const Color(0xFF2a2a2a),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                DropdownButtonFormField<Exercise>(
                  decoration: const InputDecoration(labelText: '운동 종류'),
                  items: exerciseList.map((Exercise exercise) {
                    return DropdownMenuItem<Exercise>(value: exercise, child: Text(exercise.name));
                  }).toList(),
                  onChanged: (Exercise? newValue) => selectedExercise = newValue,
                  validator: (value) => value == null ? '운동을 선택하세요' : null,
                ),
                TextField(controller: durationController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '운동 시간 (분)')),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(child: const Text('취소'), onPressed: () => Navigator.of(dialogContext).pop()),
            ElevatedButton(
              child: const Text('저장'),
              onPressed: () {
                final durationText = durationController.text;
                if (selectedExercise != null && durationText.isNotEmpty) {
                  final durationInMinutes = int.tryParse(durationText);
                  if (durationInMinutes != null && durationInMinutes > 0) {
                    final caloriesBurned = selectedExercise!.mets * appState.userWeightKg * (durationInMinutes / 60.0);
                    appState.burnCalories(selectedExercise!.name, caloriesBurned);
                    Navigator.of(dialogContext).pop();
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickAddButton(BuildContext context, String label, String emoji, double calories, bool isToxin) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF333333),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      onPressed: () {
        context.read<AppState>().addCalories(label, calories, isToxinFood: isToxin);
        // --- 여기를 수정! ---
        ScaffoldMessenger.of(context)
          ..removeCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('$label ${calories.toInt()}kcal가 추가되었습니다.'),
              duration: const Duration(seconds: 1),
              backgroundColor: Colors.deepPurpleAccent,
            ),
          );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [Text(emoji, style: const TextStyle(fontSize: 24)), const SizedBox(height: 4), Text(label)],
      ),
    );
  }

  Widget _buildQuickExerciseButton(BuildContext context, String label, String emoji, Exercise exercise, int durationInMinutes) {
    final appState = context.read<AppState>();
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF333333),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      onPressed: () {
        final caloriesBurned = exercise.mets * appState.userWeightKg * (durationInMinutes / 60.0);
        appState.burnCalories(exercise.name, caloriesBurned);
        // --- 여기를 수정! ---
        ScaffoldMessenger.of(context)
          ..removeCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('${exercise.name} ${durationInMinutes}분 (${caloriesBurned.toInt()}kcal)이 기록되었습니다.'),
              duration: const Duration(seconds: 1),
              backgroundColor: Colors.blueAccent,
            ),
          );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [Text(emoji, style: const TextStyle(fontSize: 24)), const SizedBox(height: 4), Text(label)],
      ),
    );
  }

  Widget _buildWaterButton(BuildContext context, String label, String emoji, int amount) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF333333),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: () {
            context.read<AppState>().addWater(amount);
            // --- 여기를 수정! ---
            ScaffoldMessenger.of(context)
              ..removeCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text('$label ($amount ml)를 마셨습니다.'),
                  duration: const Duration(seconds: 1),
                  backgroundColor: Colors.lightBlue,
                ),
              );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}
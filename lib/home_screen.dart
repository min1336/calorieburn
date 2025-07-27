// lib/home_screen.dart

import 'package:calorie_burn/camera_screen.dart'; // 카메라 화면 import
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final theme = Theme.of(context);

    final isOver = appState.currentCalories > appState.maxCalories;
    final calorieRatio = (appState.maxCalories > 0) ? (appState.currentCalories / appState.maxCalories).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('오늘의 챌린지'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                        Row(
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
                              ),
                            ),
                          ],
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
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.edit_note),
                    label: const Text('직접 기록'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16), textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    onPressed: () => _showAddCaloriesDialog(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('사진 기록'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CameraScreen()),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddCaloriesDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final calorieController = TextEditingController();

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('음식 기록'),
          backgroundColor: const Color(0xFF2a2a2a),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(controller: nameController, autofocus: true, decoration: const InputDecoration(labelText: '음식 이름')),
                TextField(controller: calorieController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '칼로리 (kcal)')),
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
                    context.read<AppState>().addCalories(name, calories);
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
}
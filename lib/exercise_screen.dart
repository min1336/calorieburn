// lib/exercise_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';

class ExerciseScreen extends StatefulWidget {
  const ExerciseScreen({super.key});

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  String? _selectedExercise;
  final _minutesController = TextEditingController();
  double _burnedCalories = 0.0;

  void _calculateCalories() {
    final minutes = int.tryParse(_minutesController.text) ?? 0;
    if (_selectedExercise != null && minutes > 0) {
      final appState = context.read<AppState>();
      final met = appState.exerciseMETs[_selectedExercise!]!;
      final weight = appState.userWeightKg;
      // 칼로리 계산 공식: (MET * 3.5 * 체중(kg)) / 200 * 시간(분)
      final caloriesPerMinute = (met * 3.5 * weight) / 200;
      setState(() {
        _burnedCalories = caloriesPerMinute * minutes;
      });
    } else {
      setState(() {
        _burnedCalories = 0.0;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _minutesController.addListener(_calculateCalories);
  }

  @override
  void dispose() {
    _minutesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('운동 기록'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedExercise,
              decoration: const InputDecoration(
                labelText: '운동 선택',
                border: OutlineInputBorder(),
              ),
              items: appState.exerciseMETs.keys.map((String exercise) {
                return DropdownMenuItem<String>(
                  value: exercise,
                  child: Text(exercise),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedExercise = newValue;
                });
                _calculateCalories();
              },
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _minutesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '운동 시간 (분)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            if (_burnedCalories > 0)
              Center(
                child: Column(
                  children: [
                    Text(
                      '예상 소모 칼로리',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_burnedCalories.toStringAsFixed(1)} kcal',
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              onPressed: (_burnedCalories > 0)
                  ? () {
                context.read<AppState>().decreaseCalories(_burnedCalories);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${_selectedExercise!}으로 ${_burnedCalories.toInt()}kcal를 소모했습니다!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
                  : null,
              child: const Text('기록 완료'),
            ),
          ],
        ),
      ),
    );
  }
}
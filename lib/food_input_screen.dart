// lib/food_input_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';

class FoodInputScreen extends StatefulWidget {
  const FoodInputScreen({super.key});

  @override
  State<FoodInputScreen> createState() => _FoodInputScreenState();
}

class _FoodInputScreenState extends State<FoodInputScreen> {
  final _nameController = TextEditingController();
  final _calorieController = TextEditingController();
  bool _isButtonEnabled = false;

  void _validateInput() {
    final name = _nameController.text;
    final calories = double.tryParse(_calorieController.text) ?? 0;
    setState(() {
      _isButtonEnabled = name.isNotEmpty && calories > 0;
    });
  }

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_validateInput);
    _calorieController.addListener(_validateInput);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _calorieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('음식 직접 기록'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: '음식 이름',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _calorieController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '칼로리 (kcal)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              onPressed: _isButtonEnabled
                  ? () {
                final name = _nameController.text;
                final calories = double.parse(_calorieController.text);
                context.read<AppState>().addCalories(name, calories);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('\'$name\' ${calories.toInt()}kcal를 기록했습니다!'),
                    backgroundColor: Colors.blue,
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
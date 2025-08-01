// lib/food_input_screen.dart

import 'package:calorie_burn/favorite_food.dart';
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
  // ✅ 수정: 즐겨찾기 여부를 추적하는 상태 변수 추가
  bool _isAlreadyFavorite = false;

  void _validateInput() {
    final name = _nameController.text;
    final calories = double.tryParse(_calorieController.text) ?? 0;
    final appState = context.read<AppState>();

    setState(() {
      _isButtonEnabled = name.isNotEmpty && calories > 0;

      // ✅ 수정: 현재 입력된 정보가 즐겨찾기에 있는지 확인
      if (_isButtonEnabled) {
        final currentFood = FavoriteFood(name: name, calories: calories);
        _isAlreadyFavorite = appState.favoriteFoods.contains(currentFood);
      } else {
        _isAlreadyFavorite = false;
      }
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
    final appState = context.watch<AppState>();

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
            _buildFavoritesSection(appState),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: '음식 이름',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                // ✅ 수정: 즐겨찾기 추가/삭제 토글 로직 구현
                IconButton(
                  icon: Icon(
                    _isAlreadyFavorite ? Icons.star : Icons.star_border,
                    color: _isAlreadyFavorite ? Colors.amber : Colors.grey,
                  ),
                  tooltip: _isAlreadyFavorite ? '즐겨찾기에서 해제' : '즐겨찾기에 추가',
                  // 버튼 활성화 조건 단순화
                  onPressed: _isButtonEnabled
                      ? () {
                    final name = _nameController.text;
                    final calories = double.parse(_calorieController.text);
                    final food = FavoriteFood(name: name, calories: calories);

                    if (_isAlreadyFavorite) {
                      // 즐겨찾기 해제
                      context.read<AppState>().removeFoodFavorite(food);
                      ScaffoldMessenger.of(context)
                        ..removeCurrentSnackBar()
                        ..showSnackBar(SnackBar(content: Text('\'$name\'을(를) 즐겨찾기에서 해제했습니다.')));
                    } else {
                      // 즐겨찾기 추가
                      context.read<AppState>().addFoodFavorite(food);
                      ScaffoldMessenger.of(context)
                        ..removeCurrentSnackBar()
                        ..showSnackBar(SnackBar(content: Text('\'$name\'을(를) 즐겨찾기에 추가했습니다.')));
                    }
                    // 상태 변경 후 UI 즉시 갱신
                    _validateInput();
                  }
                      : null,
                ),
              ],
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
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade800,
                disabledForegroundColor: Colors.grey.shade400,
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

  Widget _buildFavoritesSection(AppState appState) {
    if (appState.favoriteFoods.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('즐겨찾기', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: appState.favoriteFoods.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final food = appState.favoriteFoods[index];
              return GestureDetector(
                onLongPress: () {
                  showDialog(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('즐겨찾기 삭제'),
                      content: Text('\'${food.name}\'(을)를 즐겨찾기에서 삭제하시겠습니까?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('취소'),
                        ),
                        TextButton(
                          onPressed: () {
                            context.read<AppState>().removeFoodFavorite(food);
                            Navigator.pop(dialogContext);
                            ScaffoldMessenger.of(context)
                              ..removeCurrentSnackBar()
                              ..showSnackBar(SnackBar(content: Text('\'${food.name}\'(이)가 삭제되었습니다.')));
                            // 삭제 후 입력 필드 검증 로직 다시 호출
                            _validateInput();
                          },
                          child: const Text('삭제', style: TextStyle(color: Colors.redAccent)),
                        ),
                      ],
                    ),
                  );
                },
                child: ChoiceChip(
                  label: Text('${food.name} (${food.calories.toInt()}kcal)'),
                  selected: false,
                  onSelected: (_) {
                    _nameController.text = food.name;
                    _calorieController.text = food.calories.toStringAsFixed(0);
                    _validateInput();
                  },
                ),
              );
            },
          ),
        ),
        const Divider(height: 30),
      ],
    );
  }
}
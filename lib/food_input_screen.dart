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
  bool _isFavoriteCandidate = false;

  void _validateInput() {
    final name = _nameController.text;
    final calories = double.tryParse(_calorieController.text) ?? 0;
    final appState = context.read<AppState>();
    setState(() {
      _isButtonEnabled = name.isNotEmpty && calories > 0;
      // 즐겨찾기 후보인지 확인 (이미 즐겨찾기에 없는 경우)
      _isFavoriteCandidate = name.isNotEmpty &&
          calories > 0 &&
          !appState.favoriteFoods.contains(FavoriteFood(name: name, calories: calories));
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
            // ✅ 추가: 즐겨찾기 섹션
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
                // ✅ 추가: 즐겨찾기 추가 버튼
                IconButton(
                  icon: Icon(
                    _isFavoriteCandidate ? Icons.star_border : Icons.star,
                    color: _isFavoriteCandidate ? Colors.grey : Colors.amber,
                  ),
                  tooltip: '즐겨찾기에 추가',
                  onPressed: _isFavoriteCandidate ? () {
                    final name = _nameController.text;
                    final calories = double.parse(_calorieController.text);
                    final food = FavoriteFood(name: name, calories: calories);
                    context.read<AppState>().addFoodFavorite(food);
                    ScaffoldMessenger.of(context)
                      ..removeCurrentSnackBar()
                      ..showSnackBar(SnackBar(content: Text('\'$name\'(을)를 즐겨찾기에 추가했습니다.')));
                  } : null,
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

  // ✅ 추가: 즐겨찾기 섹션 위젯 빌드 함수
  Widget _buildFavoritesSection(AppState appState) {
    if (appState.favoriteFoods.isEmpty) {
      return const SizedBox.shrink(); // 즐겨찾기 없으면 아무것도 표시 안 함
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
                          },
                          child: const Text('삭제', style: TextStyle(color: Colors.redAccent)),
                        ),
                      ],
                    ),
                  );
                },
                child: ChoiceChip(
                  label: Text('${food.name} (${food.calories.toInt()}kcal)'),
                  selected: false, // 선택 상태는 사용하지 않음
                  onSelected: (_) {
                    _nameController.text = food.name;
                    _calorieController.text = food.calories.toStringAsFixed(0);
                    _validateInput(); // 값 변경 후 유효성 검사 다시 실행
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
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final theme = Theme.of(context);

    // 활동 수준을 한글로 변환하는 함수
    String getActivityLevelText(ActivityLevel level) {
      switch (level) {
        case ActivityLevel.sedentary: return '좌식 생활';
        case ActivityLevel.light: return '가벼운 활동';
        case ActivityLevel.moderate: return '보통 활동';
        case ActivityLevel.active: return '높은 활동';
        case ActivityLevel.veryActive: return '매우 높은 활동';
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 정보'),
        centerTitle: true,
        // --- 여기를 추가했습니다: 편집 버튼 ---
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditProfileDialog(context, appState),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Center(
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.deepPurple,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text('용사', style: theme.textTheme.headlineSmall),
          ),
          const SizedBox(height: 30),

          Text('게임 정보', style: theme.textTheme.titleLarge?.copyWith(color: Colors.white70)),
          const SizedBox(height: 8),
          _buildInfoCard(context, '현재 레벨', 'Lv. ${appState.userLevel}', isHighlight: true),
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('경험치', style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: appState.currentXp / appState.xpForNextLevel,
                    minHeight: 8,
                    backgroundColor: Colors.grey[800],
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.amberAccent),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${appState.currentXp.toInt()} / ${appState.xpForNextLevel.toInt()} XP',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildInfoCard(context, '보스 진행', 'Stage ${appState.bossStage}'),
          const Divider(height: 40),

          Text('신체 정보', style: theme.textTheme.titleLarge?.copyWith(color: Colors.white70)),
          const SizedBox(height: 8),
          _buildInfoCard(context, '성별', appState.gender == Gender.male ? '남성' : '여성'),
          _buildInfoCard(context, '나이', '${appState.userAge}세'),
          _buildInfoCard(context, '키', '${appState.userHeightCm}cm'),
          _buildInfoCard(context, '현재 체중', '${appState.userWeightKg}kg'),
          _buildInfoCard(context, '활동 수준', getActivityLevelText(appState.activityLevel)),
          _buildInfoCard(
              context,
              '일일 권장 칼로리',
              '${appState.maxCalories.toStringAsFixed(0)} kcal',
              isHighlight: true
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, String title, String value, {bool isHighlight = false}) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        title: Text(title, style: theme.textTheme.bodyMedium),
        trailing: Text(
          value,
          style: isHighlight
              ? theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold)
              : theme.textTheme.titleLarge,
        ),
      ),
    );
  }

  // --- 여기를 추가했습니다: 프로필 편집 팝업 함수 ---
  Future<void> _showEditProfileDialog(BuildContext context, AppState appState) async {
    final ageController = TextEditingController(text: appState.userAge.toString());
    final heightController = TextEditingController(text: appState.userHeightCm.toString());
    final weightController = TextEditingController(text: appState.userWeightKg.toString());
    Gender selectedGender = appState.gender;
    ActivityLevel selectedActivityLevel = appState.activityLevel;

    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('내 정보 편집'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: ageController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '나이')),
                    TextField(controller: heightController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '키 (cm)')),
                    TextField(controller: weightController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '체중 (kg)')),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<Gender>(
                      value: selectedGender,
                      decoration: const InputDecoration(labelText: '성별'),
                      items: const [
                        DropdownMenuItem(value: Gender.male, child: Text('남성')),
                        DropdownMenuItem(value: Gender.female, child: Text('여성')),
                      ],
                      onChanged: (value) => setState(() => selectedGender = value!),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<ActivityLevel>(
                      value: selectedActivityLevel,
                      decoration: const InputDecoration(labelText: '활동 수준'),
                      items: const [
                        DropdownMenuItem(value: ActivityLevel.sedentary, child: Text('좌식 생활')),
                        DropdownMenuItem(value: ActivityLevel.light, child: Text('가벼운 활동')),
                        DropdownMenuItem(value: ActivityLevel.moderate, child: Text('보통 활동')),
                        DropdownMenuItem(value: ActivityLevel.active, child: Text('높은 활동')),
                        DropdownMenuItem(value: ActivityLevel.veryActive, child: Text('매우 높은 활동')),
                      ],
                      onChanged: (value) => setState(() => selectedActivityLevel = value!),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('취소')),
                ElevatedButton(
                  onPressed: () {
                    final newAge = int.tryParse(ageController.text);
                    final newHeight = double.tryParse(heightController.text);
                    final newWeight = double.tryParse(weightController.text);

                    if (newAge != null && newHeight != null && newWeight != null) {
                      appState.updateProfile(
                        newAge: newAge,
                        newHeight: newHeight,
                        newWeight: newWeight,
                        newGender: selectedGender,
                        newActivityLevel: selectedActivityLevel,
                      );
                      Navigator.of(dialogContext).pop();
                    }
                  },
                  child: const Text('저장'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
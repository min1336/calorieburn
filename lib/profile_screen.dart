// lib/profile_screen.dart

import 'package:calorie_burn/data_sources_screen.dart';
import 'package:calorie_burn/models/enums.dart';
import 'package:calorie_burn/services/authentication_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart'; // ✅ 추가: 차트 라이브러리 임포트
import 'package:intl/intl.dart';      // ✅ 추가: 날짜 포맷을 위해 임포트
import 'app_state.dart';


// ✅ 수정: StatelessWidget -> StatefulWidget으로 변경
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  @override
  void initState() {
    super.initState();
    // ✅ 추가: 화면이 처음 로드될 때 칼로리 기록 데이터 가져오기
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().fetchCalorieHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final theme = Theme.of(context);

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
            child: Text(
              appState.nickname,
              style: theme.textTheme.headlineSmall,
            ),
          ),
          const SizedBox(height: 30),

          // ✅ 추가: 주간 칼로리 기록 섹션
          Text('주간 칼로리 기록', style: theme.textTheme.titleLarge?.copyWith(color: Colors.white70)),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: appState.isHistoryLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(height: 150, child: _CalorieHistoryChart(history: appState.calorieHistory)),
            ),
          ),
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
          const Divider(height: 40),

          Text('데이터 연동', style: theme.textTheme.titleLarge?.copyWith(color: Colors.white70)),
          const SizedBox(height: 8),
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: ListTile(
              leading: Icon(
                appState.isHealthAuthorized ? Icons.check_circle_outline : Icons.help_outline,
                color: appState.isHealthAuthorized ? Colors.greenAccent : Colors.grey,
              ),
              title: const Text('건강 데이터 권한'),
              subtitle: Text(appState.isHealthAuthorized ? '권한이 허용되었습니다.' : '동기화 시 권한을 허용해주세요.'),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: ListTile(
              leading: const Icon(Icons.watch, color: Colors.deepPurpleAccent),
              title: const Text('주 데이터 소스'),
              subtitle: Text(appState.primaryDataSource ?? '선택되지 않음'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DataSourcesScreen()),
                );
              },
            ),
          ),

          const Divider(height: 40),
          ElevatedButton.icon(
            icon: const Icon(Icons.logout),
            label: const Text('로그아웃'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: () {
              context.read<AuthenticationService>().signOut();
            },
          )
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

  Future<void> _showEditProfileDialog(BuildContext context, AppState appState) async {
    final nicknameController = TextEditingController(text: appState.nickname);
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
                    TextField(controller: nicknameController, decoration: const InputDecoration(labelText: '닉네임')),
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
                    final newNickname = nicknameController.text;
                    final newAge = int.tryParse(ageController.text);
                    final newHeight = double.tryParse(heightController.text);
                    final newWeight = double.tryParse(weightController.text);

                    if (newNickname.isNotEmpty && newAge != null && newHeight != null && newWeight != null) {
                      appState.updateProfile(
                        newNickname: newNickname,
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

// ✅ 추가: 라인 차트를 그리는 별도 위젯
class _CalorieHistoryChart extends StatelessWidget {
  final List<Map<String, dynamic>> history;

  const _CalorieHistoryChart({required this.history});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spots = history.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final calories = entry.value['calories'] as double;
      return FlSpot(index, calories);
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          getDrawingHorizontalLine: (value) {
            return const FlLine(color: Colors.white10, strokeWidth: 1);
          },
          getDrawingVerticalLine: (value) {
            return const FlLine(color: Colors.white10, strokeWidth: 1);
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final date = history[value.toInt()]['date'] as DateTime;
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    DateFormat('d').format(date),
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 42),
          ),
        ),
        borderData: FlBorderData(show: true, border: Border.all(color: Colors.white24)),
        minX: 0,
        maxX: 6,
        minY: 0,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            gradient: LinearGradient(
              colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
            ),
            barWidth: 5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withOpacity(0.3),
                  theme.colorScheme.secondary.withOpacity(0.3),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
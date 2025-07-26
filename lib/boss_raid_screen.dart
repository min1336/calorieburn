import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';

class BossRaidScreen extends StatelessWidget {
  const BossRaidScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final theme = Theme.of(context);
    final bossHpPercentage = (appState.bossHp / appState.maxBossHp).clamp(0.0, 1.0);

    // 보스 처치 후 승리 팝업 로직 (UI에서 상태 변화 감지)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (appState.bossHp <= 0) {
        // 이미 팝업이 떠있는지 확인하는 로직이 필요할 수 있으나, 여기선 생략
        _showVictoryDialog(context, appState.bossStage -1);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('보스 레이드 - Stage ${appState.bossStage}'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '폭식의 군주 Lv.${appState.bossStage}',
              style: theme.textTheme.headlineSmall?.copyWith(color: Colors.redAccent),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 200,
              height: 200,
              child: Image.asset('assets/images/boss_image.png', fit: BoxFit.contain),
            ),
            const SizedBox(height: 20),
            Text('남은 HP: ${appState.bossHp.toStringAsFixed(0)} / ${appState.maxBossHp.toStringAsFixed(0)}', style: theme.textTheme.titleLarge),
            const SizedBox(height: 10),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: bossHpPercentage),
              duration: const Duration(milliseconds: 500),
              builder: (context, value, child) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 25,
                  backgroundColor: Colors.grey[800],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.red.shade700),
                );
              },
            ),
            const SizedBox(height: 40),
            Text('운동으로 보스를 공격하세요!', style: theme.textTheme.bodyLarge?.copyWith(color: Colors.amber)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.fitness_center),
              label: const Text('운동 공격! (-150 kcal)'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.secondary,
                  foregroundColor: theme.colorScheme.onSecondary,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  textStyle: theme.textTheme.titleLarge
              ),
              onPressed: () {
                context.read<AppState>().burnCalories("운동 공격", 150);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('보스에게 150의 데미지를 입혔습니다!'),
                    backgroundColor: Colors.deepPurpleAccent,
                  ),
                );
              },
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  // 승리 팝업 함수
  Future<void> _showVictoryDialog(BuildContext context, int defeatedStage) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('🎉 승리! 🎉'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('축하합니다! Stage $defeatedStage 보스를 물리쳤습니다.'),
                Text('경험치를 ${100 * defeatedStage} 만큼 획득했습니다!'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('다음 스테이지로'),
              onPressed: () {
                // AppState의 로직은 이미 호출되었으므로, 여기서는 팝업만 닫음
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
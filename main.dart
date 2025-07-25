import 'package:flutter/material.dart'; // <<-- 이 부분을 수정했습니다! (마침표 -> 콜론)
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// 1. Firebase 연동을 위한 main 함수 수정
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Firebase 초기화
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '둔둔햄 프로토타입',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const DundunhamHomePage(),
    );
  }
}

// 2. 앱의 핵심 로직을 담을 StatefulWidget
class DundunhamHomePage extends StatefulWidget {
  const DundunhamHomePage({super.key});

  @override
  State<DundunhamHomePage> createState() => _DundunhamHomePageState();
}

class _DundunhamHomePageState extends State<DundunhamHomePage> {
  // --- 상태 변수: 화면에 표시될 모든 데이터 ---
  final String _nickname = "강한둔둔햄";
  final int _dailyKcalGoal = 2200; // 일일 권장 칼로리

  // Firestore에서 실시간으로 가져올 데이터
  int _totalKcalIn = 0;
  int _totalKcalOut = 0;
  int _toxinGauge = 0;
  bool _isLoading = true; // 로딩 상태 표시

  // 오늘의 로그 문서 ID (고정된 테스트 값)
  final String _todayDocId = "TEST_USER_${DateFormat('yyyy-MM-dd').format(DateTime.now())}";

  @override
  void initState() {
    super.initState();
    _listenToDailyLog(); // 앱 시작 시 데이터 스트림 구독
  }

  // --- 데이터 로직: Firestore와 통신 ---

  // 실시간으로 오늘의 로그를 감시(listen)하는 함수
  void _listenToDailyLog() {
    FirebaseFirestore.instance
        .collection('daily_logs')
        .doc(_todayDocId)
        .snapshots() // snapshots()를 사용하면 데이터 변경 시 자동으로 UI가 업데이트됨
        .listen((docSnapshot) {
      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        // setState를 통해 화면을 다시 그림
        setState(() {
          _totalKcalIn = data['totalKcalIn'] ?? 0;
          _totalKcalOut = data['totalKcalOut'] ?? 0;
          _toxinGauge = data['toxinGauge'] ?? 0;
          _isLoading = false;
        });
      } else {
        // 문서가 없는 경우 (하루가 시작되어 데이터가 아직 없을 때)
        setState(() {
          _isLoading = false;
        });
      }
    }, onError: (error) {
      // 에러 처리
      setState(() {
        _isLoading = false;
      });
      print("데이터 수신 에러: $error");
    });
  }

  // 음식 추가 함수
  Future<void> _addFood(int kcal, int toxin) async {
    final docRef = FirebaseFirestore.instance.collection('daily_logs').doc(_todayDocId);
    // FieldValue.increment를 사용하면 기존 값에 안전하게 더할 수 있음
    await docRef.update({
      'totalKcalIn': FieldValue.increment(kcal),
      'toxinGauge': FieldValue.increment(toxin),
    });
  }

  // 운동 추가 함수
  Future<void> _addExercise(int kcalBurned) async {
    final docRef = FirebaseFirestore.instance.collection('daily_logs').doc(_todayDocId);
    await docRef.update({
      'totalKcalOut': FieldValue.increment(kcalBurned),
    });
  }

  // --- 계산 로직: 데이터를 기반으로 파생 값 계산 ---

  // 남은 보호막 계산
  int get _remainingShield {
    final remaining = _dailyKcalGoal - _totalKcalIn;
    return remaining > 0 ? remaining : 0;
  }

  // 몬스터 HP 계산
  int get _monsterHp {
    if (_totalKcalIn > _dailyKcalGoal) {
      final monsterHealth = _totalKcalIn - _dailyKcalGoal - _totalKcalOut;
      return monsterHealth > 0 ? monsterHealth : 0;
    }
    return 0;
  }

  // 상태 메시지 계산
  String get _statusMessage {
    if (_monsterHp > 0) {
      return "[경고] 권장 칼로리 초과!\n칼로리 몬스터($_monsterHp HP)가 나타났습니다!";
    } else if (_totalKcalIn > _dailyKcalGoal && _monsterHp <= 0) {
      final netKcal = _totalKcalIn - _totalKcalOut;
      return "[성공] 몬스터를 물리쳤습니다!\n오늘의 최종 결과: $netKcal kcal";
    } else {
      return "좋습니다! 아직 보호막이 튼튼해요.";
    }
  }


  // --- UI 로직: 화면 그리기 ---
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('둔둔햄 v0.2 - Live Prototype'),
        backgroundColor: Colors.purple.shade100,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('$_nickname 님 / ${DateFormat('yyyy-MM-dd (E) a hh:mm', 'ko_KR').format(DateTime.now())}', style: textTheme.titleMedium),
            const Divider(height: 30),

            Text('[현재 상태]', style: textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('- 총 섭취 칼로리  : $_totalKcalIn kcal', style: textTheme.bodyLarge),
            Text('- 총 소모 칼로리  : $_totalKcalOut kcal', style: textTheme.bodyLarge),
            Text('- 독소 게이지     : $_toxinGauge / 100', style: textTheme.bodyLarge),
            const Divider(height: 30),

            Text('[보호막 현황]', style: textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('- 오늘의 보호막   : $_remainingShield / $_dailyKcalGoal kcal', style: textTheme.bodyLarge),
            const Divider(height: 30),

            Text('[칼로리 몬스터]', style: textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('- 몬스터 HP       : $_monsterHp HP', style: textTheme.bodyLarge?.copyWith(color: Colors.red, fontWeight: FontWeight.bold)),
            const Divider(height: 30),

            // 상태 메시지
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  _statusMessage,
                  style: textTheme.titleMedium?.copyWith(color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            const SizedBox(height: 30),
            // 테스트용 버튼
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => _addFood(500, 20),
                  child: const Text('음식 추가\n(+500kcal)'),
                ),
                ElevatedButton(
                  onPressed: () => _addExercise(300),
                  child: const Text('운동 추가\n(-300kcal)'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
// lib/data_sources_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';

class DataSourcesScreen extends StatelessWidget {
  const DataSourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('주 데이터 소스 선택'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: '목록 새로고침',
            onPressed: () async {
              final result = await appState.fetchTodayHealthData();
              if (context.mounted) {
                ScaffoldMessenger.of(context)
                  ..removeCurrentSnackBar()
                  ..showSnackBar(SnackBar(content: Text("데이터를 새로고쳤습니다.")));
              }
            },
          )
        ],
      ),
      body: appState.availableDataSources.isEmpty
          ? const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            '사용 가능한 데이터 소스가 없습니다.\n먼저 스마트워치에서 활동을 기록한 후, 우측 상단의 새로고침 버튼을 눌러주세요.',
            textAlign: TextAlign.center,
          ),
        ),
      )
          : ListView.builder(
        itemCount: appState.availableDataSources.length,
        itemBuilder: (context, index) {
          final sourceName = appState.availableDataSources[index];
          final isSelected = sourceName == appState.primaryDataSource;

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: ListTile(
              title: Text(sourceName),
              trailing: isSelected
                  ? const Icon(Icons.check_circle, color: Colors.greenAccent)
                  : const Icon(Icons.radio_button_unchecked),
              onTap: () {
                context.read<AppState>().setPrimaryDataSource(sourceName);
                ScaffoldMessenger.of(context)
                  ..removeCurrentSnackBar()
                  ..showSnackBar(SnackBar(content: Text('\'$sourceName\'(이)가 주 데이터 소스로 설정되었습니다.')));
              },
            ),
          );
        },
      ),
    );
  }
}
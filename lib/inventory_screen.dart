// lib/inventory_screen.dart

import 'package:calorie_burn/item_data.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    // 보유 중인 아이템 목록만 필터링
    final ownedItems = allItems.where((item) => (appState.inventory[item.id] ?? 0) > 0).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 가방'),
      ),
      body: ownedItems.isEmpty
          ? const Center(child: Text('보유 중인 아이템이 없습니다.\n상점에서 아이템을 구매해보세요!'))
          : ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: ownedItems.length,
        itemBuilder: (context, index) {
          final item = ownedItems[index];
          final count = appState.inventory[item.id] ?? 0;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Text(item.emoji, style: const TextStyle(fontSize: 32)),
              title: Text(item.name),
              subtitle: Text(item.description),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('x$count', style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      final result = appState.useItem(item);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(result)),
                      );
                    },
                    child: const Text('사용'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
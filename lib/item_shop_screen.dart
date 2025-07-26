// lib/item_shop_screen.dart

import 'package:calorie_burn/item_data.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';

class ItemShopScreen extends StatelessWidget {
  const ItemShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('아이템 상점'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                const Icon(Icons.diamond_outlined, color: Colors.cyanAccent),
                const SizedBox(width: 4),
                Text(
                  '${appState.gems}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          )
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        itemCount: allItems.length,
        itemBuilder: (context, index) {
          final item = allItems[index];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text(item.emoji, style: const TextStyle(fontSize: 48)),
                  Text(item.name, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
                  Text(item.description, style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
                  ElevatedButton(
                    onPressed: () {
                      final result = appState.buyItem(item);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(result)),
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${item.priceGems}'),
                        const SizedBox(width: 4),
                        const Icon(Icons.diamond_outlined, size: 16),
                      ],
                    ),
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
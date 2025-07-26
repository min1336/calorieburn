// lib/item_data.dart

enum ItemEffect {
  bossDamage,
  xpBoost,
  cureBoss, // 보스 상태이상 치료
}

class ShopItem {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final int priceGems;
  final ItemEffect effect;
  final double effectValue;

  const ShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.priceGems,
    required this.effect,
    required this.effectValue,
  });
}

// --- 전체 아이템 목록 ---
const List<ShopItem> allItems = [
  // --- 신규 아이템 '해독제' 추가 ---
  ShopItem(
    id: 'potion_antidote',
    name: '해독제',
    description: '보스의 독소 중독을 정화하여 방어력을 낮춥니다.',
    emoji: '🌿',
    priceGems: 50,
    effect: ItemEffect.cureBoss,
    effectValue: 0, // 특정 값을 사용하지 않으므로 0
  ),
  ShopItem(
    id: 'potion_damage_small',
    name: '공격 물약 (소)',
    description: '보스에게 50의 추가 데미지를 입힙니다.',
    emoji: '🧪',
    priceGems: 15,
    effect: ItemEffect.bossDamage,
    effectValue: 50.0,
  ),
  ShopItem(
    id: 'potion_damage_medium',
    name: '공격 물약 (중)',
    description: '보스에게 150의 추가 데미지를 입힙니다.',
    emoji: '🧪',
    priceGems: 40,
    effect: ItemEffect.bossDamage,
    effectValue: 150.0,
  ),
  ShopItem(
    id: 'potion_damage_large',
    name: '공격 물약 (대)',
    description: '보스에게 500의 추가 데미지를 입힙니다.',
    emoji: '🧪',
    priceGems: 120,
    effect: ItemEffect.bossDamage,
    effectValue: 500.0,
  ),
];
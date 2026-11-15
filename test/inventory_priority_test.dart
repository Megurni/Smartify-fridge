import 'package:flutter_test/flutter_test.dart';
import 'package:smartify_refrigerator_demo/models/food_item.dart';
import 'package:smartify_refrigerator_demo/models/inventory_priority.dart';

void main() {
  final now = DateTime(2026, 10, 11);
  FoodItem food(
    String id,
    int daysStored, {
    DateTime? removedAt,
    double price = 0,
  }) => FoodItem(
    id: id,
    name: id,
    storedAt: now.subtract(Duration(days: daysStored)),
    removedAt: removedAt,
    price: price,
    category: 'Produce',
  );

  test('inventory ranks active food by estimated urgency', () {
    final fresh = food('fresh', 0);
    final soon = food('soon', 3);
    final first = food('first', 4);
    final overdue = food('overdue', 5);
    expect(
      InventoryPriority.sorted([
        fresh,
        soon,
        first,
        overdue,
      ], now).map((f) => f.id),
      ['overdue', 'first', 'soon', 'fresh'],
    );
    expect(InventoryPriority.priority(first, now), FoodPriority.first);
    expect(InventoryPriority.score(overdue, now), 100);
  });

  test('removed food stays out of inventory and ties use date then id', () {
    final removed = food('removed', 5, removedAt: now);
    final a = food('a', 0);
    final b = food('b', 0);
    expect(InventoryPriority.sorted([removed, b, a], now).map((f) => f.id), [
      'a',
      'b',
    ]);
    expect(InventoryPriority.score(removed, now), 100);
  });
}

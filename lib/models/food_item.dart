import 'inventory_priority.dart';

/// Accounting lifecycle. Only inStock items appear in inventory.
enum FoodStatus { inStock, consumed, discarded }

enum FoodPriority { first, soon, later }

class FoodItem {
  const FoodItem({
    required this.id,
    required this.name,
    required this.storedAt,
    required this.status,
    required this.quantity,
    required this.price,
    required this.category,
    this.savedAmount = 0,
  });

  final String id;
  final String name;
  final DateTime storedAt;
  final FoodStatus status;
  final String quantity;
  final double price;
  final String category;
  // Snapshot at consumption time; expiry estimates changing later cannot alter it.
  final double savedAmount;

  FoodItem copyWith({FoodStatus? status, double? savedAmount}) => FoodItem(
    id: id,
    name: name,
    storedAt: storedAt,
    status: status ?? this.status,
    quantity: quantity,
    price: price,
    category: category,
    savedAmount: savedAmount ?? this.savedAmount,
  );

  int get daysLeft => InventoryPriority.daysLeft(this, DateTime.now());
  FoodPriority get priority => InventoryPriority.priority(this, DateTime.now());

  String get emoji => switch (category.toLowerCase()) {
    'meat' => '🍗',
    'produce' => '🥬',
    'dairy' => '🥛',
    _ => '🥑',
  };
}

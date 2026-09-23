enum FoodPriority { first, soon, later }

class FoodItem {
  const FoodItem({
    required this.id,
    required this.name,
    required this.emoji,
    required this.quantity,
    required this.daysLeft,
    required this.price,
    required this.priority,
    required this.category,
  });

  final String id;
  final String name;
  final String emoji;
  final String quantity;
  final int daysLeft;
  final double price;
  final FoodPriority priority;
  final String category;
}

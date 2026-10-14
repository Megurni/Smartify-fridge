import 'food_item.dart';

/// Estimates urgency from storage age when no expiry date is available.
class InventoryPriority {
  static int shelfLifeDays(String category) => switch (category.toLowerCase()) {
    'meat' => 3,
    'produce' => 5,
    'dairy' => 7,
    _ => 14,
  };

  static int daysLeft(FoodItem food, DateTime now) {
    final age = now.difference(food.storedAt).inDays;
    return shelfLifeDays(food.category) - (age < 0 ? 0 : age);
  }

  /// Higher scores appear first. This is independent of accounting status.
  static int score(FoodItem food, DateTime now) {
    final remaining = daysLeft(food, now);
    if (remaining <= 0) return 100;

    final life = shelfLifeDays(food.category);
    final priceScore = food.price.clamp(0, 10).round();
    if (remaining == 1) return (85 + priceScore).clamp(0, 99);
    if (remaining <= 3) {
      return (55 + (3 - remaining) * 10 + priceScore).clamp(0, 79);
    }
    final ageScore = ((life - remaining) * 40 / life).round();
    return (ageScore + priceScore).clamp(0, 54);
  }

  static FoodPriority priority(FoodItem food, DateTime now) {
    final value = score(food, now);
    if (value >= 75) return FoodPriority.first;
    if (value >= 40) return FoodPriority.soon;
    return FoodPriority.later;
  }

  static List<FoodItem> sorted(Iterable<FoodItem> foods, DateTime now) {
    final result = foods
        .where((food) => food.status == FoodStatus.inStock)
        .toList();
    result.sort((a, b) {
      final byScore = score(b, now).compareTo(score(a, now));
      if (byScore != 0) return byScore;
      final byDate = a.storedAt.compareTo(b.storedAt);
      return byDate != 0 ? byDate : a.id.compareTo(b.id);
    });
    return result;
  }
}

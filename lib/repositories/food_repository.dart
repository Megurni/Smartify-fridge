import '../models/food_item.dart';

/// Implement this interface with HTTP calls when the backend is ready.
abstract class FoodRepository {
  Future<List<FoodItem>> getFoods();
  Future<FoodItem?> getFood(String id);
  Future<void> addFood(FoodItem food);
  Future<void> updateFood(FoodItem food);
  Future<void> deleteFood(String id);
}

/// Temporary data source. Changes last only for this app session.
class InMemoryFoodRepository implements FoodRepository {
  InMemoryFoodRepository({Iterable<FoodItem>? initialFoods})
    : _foods = {for (final food in initialFoods ?? _sampleFoods) food.id: food};

  final Map<String, FoodItem> _foods;

  @override
  Future<List<FoodItem>> getFoods() async => List.unmodifiable(_foods.values);

  @override
  Future<FoodItem?> getFood(String id) async => _foods[id];

  @override
  Future<void> addFood(FoodItem food) async {
    if (_foods.containsKey(food.id)) {
      throw StateError('Food already exists: ${food.id}');
    }
    _foods[food.id] = food;
  }

  @override
  Future<void> updateFood(FoodItem food) async {
    if (!_foods.containsKey(food.id)) {
      throw StateError('Food not found: ${food.id}');
    }
    _foods[food.id] = food;
  }

  @override
  Future<void> deleteFood(String id) async {
    _foods.remove(id);
  }
}

const _sampleFoods = [
  FoodItem(
    id: 'chicken',
    name: 'Chicken breast',
    emoji: '🍗',
    quantity: '2 pieces',
    daysLeft: 1,
    price: 8.50,
    priority: FoodPriority.first,
    category: 'Meat',
  ),
  FoodItem(
    id: 'spinach',
    name: 'Baby spinach',
    emoji: '🥬',
    quantity: '1 bag',
    daysLeft: 2,
    price: 4.20,
    priority: FoodPriority.first,
    category: 'Produce',
  ),
  FoodItem(
    id: 'mushrooms',
    name: 'Mushrooms',
    emoji: '🍄',
    quantity: '250 g',
    daysLeft: 3,
    price: 3.80,
    priority: FoodPriority.soon,
    category: 'Produce',
  ),
  FoodItem(
    id: 'yogurt',
    name: 'Greek yogurt',
    emoji: '🥛',
    quantity: '3 cups',
    daysLeft: 5,
    price: 5.40,
    priority: FoodPriority.soon,
    category: 'Dairy',
  ),
  FoodItem(
    id: 'carrots',
    name: 'Carrots',
    emoji: '🥕',
    quantity: '6 pieces',
    daysLeft: 9,
    price: 2.60,
    priority: FoodPriority.later,
    category: 'Produce',
  ),
  FoodItem(
    id: 'eggs',
    name: 'Eggs',
    emoji: '🥚',
    quantity: '8 eggs',
    daysLeft: 12,
    price: 4.90,
    priority: FoodPriority.later,
    category: 'Dairy',
  ),
];

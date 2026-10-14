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
    : _foods = {
        for (final food in initialFoods ?? _sampleFoods()) food.id: food,
      };

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

List<FoodItem> _sampleFoods() {
  final now = DateTime.now();
  FoodItem sample(
    String id,
    String name,
    String quantity,
    int daysStored,
    double price,
    String category, {
    FoodStatus status = FoodStatus.inStock,
  }) => FoodItem(
    id: id,
    name: name,
    storedAt: now.subtract(Duration(days: daysStored)),
    status: status,
    quantity: quantity,
    price: price,
    category: category,
  );
  return [
    sample(
      'chicken',
      'Chicken breast',
      '2 pieces',
      2,
      8.50,
      'Meat',
      status: FoodStatus.inStock,
    ),
    sample(
      'spinach',
      'Baby spinach',
      '1 bag',
      4,
      4.20,
      'Produce',
      status: FoodStatus.inStock,
    ),
    sample('mushrooms', 'Mushrooms', '250 g', 2, 3.80, 'Produce'),
    sample('yogurt', 'Greek yogurt', '3 cups', 2, 5.40, 'Dairy'),
    sample('carrots', 'Carrots', '6 pieces', 0, 2.60, 'Produce'),
    sample('eggs', 'Eggs', '8 eggs', 0, 4.90, 'Dairy'),
  ];
}

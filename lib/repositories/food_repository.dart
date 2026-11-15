import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/food_item.dart';

abstract class FoodRepository {
  Future<List<FoodItem>> getFoods();
  Future<FoodItem?> getFood(String id);
  Future<void> addFood(FoodItem food);
  Future<void> updateFood(FoodItem food);
  Future<void> updateFoodDetails(
    String id, {
    required String name,
    required double price,
    required String category,
  });
  Future<void> deleteFood(String id);
}

/// Reads and updates inventory through the Flask backend.
class HttpFoodRepository implements FoodRepository {
  HttpFoodRepository({
    required String baseUrl,
    http.Client? client,
    this.shelfId,
  }) : _baseUrl = Uri.parse(baseUrl.endsWith('/') ? baseUrl : '$baseUrl/'),
       _client = client ?? http.Client();

  final Uri _baseUrl;
  final http.Client _client;
  final int? shelfId;

  Uri _url(String path) => _baseUrl.resolve(path);

  Map<String, dynamic> _decode(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Backend request failed (${response.statusCode}): ${response.body}',
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async => _decode(
    await _client.post(
      _url(path),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    ),
  );

  @override
  Future<List<FoodItem>> getFoods() async {
    final data = _decode(await _client.get(_url('items')));
    final accounting = _decode(await _client.get(_url('accounting/events')));
    final active = (data['items'] as List<dynamic>)
        .map((item) => FoodItem.fromJson(item as Map<String, dynamic>))
        .toList();
    final outcomes = (accounting['events'] as List<dynamic>)
        .map(
          (event) =>
              FoodItem.fromAccountingEvent(event as Map<String, dynamic>),
        )
        .toList();
    return [...active, ...outcomes];
  }

  @override
  Future<FoodItem?> getFood(String id) async {
    final response = await _client.get(_url('item/$id'));
    if (response.statusCode == 404) return null;
    return FoodItem.fromJson(_decode(response));
  }

  Future<int> _shelfForNewFood() async {
    if (shelfId != null) return shelfId!;
    final data = _decode(await _client.get(_url('shelves')));
    final shelves = data['shelves'] as List<dynamic>;
    if (shelves.isNotEmpty) {
      return (shelves.first as Map<String, dynamic>).values.first as int;
    }
    final created = await _post('shelf', {'name': 'Fridge'});
    return created['shelf_id'] as int;
  }

  @override
  Future<void> addFood(FoodItem food) async {
    await _post('item', {
      'name': food.name,
      'price': food.price,
      'category': food.category,
      'shelf_id': food.shelfId ?? await _shelfForNewFood(),
    });
  }

  @override
  Future<void> updateFood(FoodItem food) async {
    if (food.status == FoodStatus.inStock) {
      await _post('item/${food.id}/restore', {});
    } else {
      await _post('item/${food.id}/remove', {
        'outcome': food.status.name,
        'use_first':
            food.status == FoodStatus.consumed &&
            (food.wasUseFirst || food.savedAmount > 0),
      });
    }
  }

  @override
  Future<void> updateFoodDetails(
    String id, {
    required String name,
    required double price,
    required String category,
  }) async {
    await _post('item/$id', {
      'name': name,
      'price': price,
      'category': category,
    });
  }

  @override
  Future<void> deleteFood(String id) async {
    _decode(await _client.delete(_url('item/$id')));
  }
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
  Future<void> updateFoodDetails(
    String id, {
    required String name,
    required double price,
    required String category,
  }) async {
    final food = _foods[id];
    if (food == null) throw StateError('Food not found: $id');
    _foods[id] = food.copyWith(name: name, price: price, category: category);
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
    int daysStored,
    double price,
    String category,
  ) => FoodItem(
    id: id,
    name: name,
    storedAt: now.subtract(Duration(days: daysStored)),
    price: price,
    category: category,
  );
  return [
    sample('chicken', 'Chicken breast', 2, 8.50, 'Meat'),
    sample('spinach', 'Baby spinach', 4, 4.20, 'Produce'),
    sample('mushrooms', 'Mushrooms', 2, 3.80, 'Produce'),
    sample('yogurt', 'Greek yogurt', 2, 5.40, 'Dairy'),
    sample('carrots', 'Carrots', 0, 2.60, 'Produce'),
    sample('eggs', 'Eggs', 0, 4.90, 'Dairy'),
  ];
}

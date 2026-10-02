import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/food_item.dart';
import '../models/recipe.dart';

/// Uses only TheMealDB's free V1 endpoints.
/// Caches successful responses.
class RecipeRepository {
  RecipeRepository({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final Map<String, List<Map<String, dynamic>>> _cache = {};
  bool _closed = false;

  void close() {
    _closed = true;
    _client.close();
  }

  Future<List<Map<String, dynamic>>> _get(
    String endpoint,
    String parameter,
    String value,
  ) async {
    if (_closed) {
      throw StateError('Recipe repository closed');
    }

    final uri = Uri.https('www.themealdb.com', '/api/json/v1/1/$endpoint.php', {
      parameter: value,
    });

    final cached = _cache[uri.toString()];

    if (cached != null) {
      return cached;
    }

    final response = await _client
        .get(uri)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw StateError('Recipe request failed: ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;

    final meals = (json['meals'] as List<dynamic>? ?? [])
        .map((meal) => Map<String, dynamic>.from(meal as Map))
        .toList();

    _cache[uri.toString()] = meals;
    return meals;
  }

  Future<List<RecipeMatch>> recommend(
    List<FoodItem> foods, {
    String? ingredient,
  }) async {
    if (foods.isEmpty) {
      return [];
    }

    final sorted = List<FoodItem>.of(foods)
      ..sort((a, b) {
        final priority = a.priority.index.compareTo(b.priority.index);

        return priority != 0 ? priority : a.daysLeft.compareTo(b.daysLeft);
      });

    // Bound requests for a small demo. Prefer existing urgent tags.
    // If none exist, use other foods without changing their tags.
    final urgent = sorted.where((food) => food.priority != FoodPriority.later);

    // A selected chip searches that ingredient, including Use Later foods.
    // All keeps the existing priority-based recommendations.
    final Iterable<String> targets = ingredient != null
        ? [ingredientKey(ingredient)]
        : (urgent.isEmpty ? sorted : urgent)
              .map((food) => ingredientKey(food.name))
              .toSet()
              .take(3);

    final ingredients = await _get('list', 'i', 'list');

    final names = <String, String>{
      for (final item in ingredients)
        ingredientKey(item['strIngredient'] as String):
            item['strIngredient'] as String,
    };

    final groups = await Future.wait(
      targets.map(
        (name) =>
            _get('filter', 'i', (names[name] ?? name).replaceAll(' ', '_')),
      ),
    );

    // Round-robin candidates so one ingredient cannot occupy every slot.
    final ids = <String>{};

    for (var index = 0; index < 8; index++) {
      for (final group in groups) {
        if (index < group.length) {
          ids.add(group[index]['idMeal'] as String);
        }
      }
    }

    final recipes = <Recipe>[];
    final values = ids.toList();

    // Load details in batches of four.
    for (var offset = 0; offset < values.length; offset += 4) {
      final batch = values.skip(offset).take(4);

      final details = await Future.wait(
        batch.map((id) => _get('lookup', 'i', id)),
      );

      for (final meals in details) {
        if (meals.isNotEmpty) {
          recipes.add(Recipe.fromJson(meals.first));
        }
      }
    }

    return rankRecipes(recipes, foods);
  }
}

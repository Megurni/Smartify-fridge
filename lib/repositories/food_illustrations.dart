import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const categoryIllustrations = {
  'Meat': 'cut-of-meat',
  'Seafood': 'fish',
  'Dairy': 'glass-of-milk',
  'Eggs': 'egg',
  'Fruit': 'red-apple',
  'Vegetable': 'broccoli',
  'Bakery': 'bread',
  'Leftovers': 'shallow-pan-of-food',
  'Beverage': 'beverage-box',
  'Condiment': 'salt',
  'Other': 'fork-and-knife-with-plate',
};

String categoryIllustration(String category) {
  final key = category.toLowerCase();
  if (key == 'produce' || key == 'vege') return 'broccoli';
  return categoryIllustrations.entries
          .where((e) => e.key.toLowerCase() == key)
          .map((e) => e.value)
          .firstOrNull ??
      'fork-and-knife-with-plate';
}

String illustrationName(String name) {
  final key = name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  return const {
        'baby spinach': 'leafy green',
        'spinach': 'leafy green',
        'chicken breast': 'poultry leg',
        'chicken breasts': 'poultry leg',
        'mushrooms': 'brown mushroom',
        'mushroom': 'brown mushroom',
        'carrots': 'carrot',
        'eggs': 'egg',
        'milk': 'glass of milk',
        'apple': 'red apple',
        'apples': 'red apple',
      }[key] ??
      key;
}

/// Only exact canonical names are accepted: "egg" must never select "eggplant".
String? selectIllustration(String query, List<dynamic> results) {
  final expected = 'fluent-emoji-flat:${query.replaceAll(' ', '-')}';
  return results.contains(expected) ? expected : null;
}

class FoodIllustrations {
  FoodIllustrations({http.Client? client}) : _client = client ?? http.Client();
  static final instance = FoodIllustrations();
  final http.Client _client;
  final _pending = <String, Future<String?>>{};

  Future<String?> find(String name) {
    final query = illustrationName(name);
    return _pending.putIfAbsent(query, () => _find(query));
  }

  Future<String?> _find(String query) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'food-svg-v1:$query';
      final cached = prefs.getString(key);
      if (cached != null) return cached;
      final response = await _client
          .get(
            Uri.https('api.iconify.design', '/search', {
              'query': query,
              'prefix': 'fluent-emoji-flat',
            }),
          )
          .timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final icon = selectIllustration(query, data['icons'] as List<dynamic>);
      if (icon == null) return null;
      final svgResponse = await _client
          .get(
            Uri.https(
              'api.iconify.design',
              '/fluent-emoji-flat/${icon.split(':').last}.svg',
            ),
          )
          .timeout(const Duration(seconds: 5));
      if (svgResponse.statusCode != 200 || !svgResponse.body.contains('<svg')) {
        return null;
      }
      await prefs.setString(key, svgResponse.body);
      return svgResponse.body;
    } catch (_) {
      return null;
    }
  }
}

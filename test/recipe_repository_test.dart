import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smartify_refrigerator_demo/models/food_item.dart';
import 'package:smartify_refrigerator_demo/models/recipe.dart';
import 'package:smartify_refrigerator_demo/repositories/recipe_repository.dart';

FoodItem food(String name, FoodPriority priority) => FoodItem(
  id: name,
  name: name,
  emoji: '',
  quantity: '1',
  daysLeft: 2,
  price: 0,
  priority: priority,
  category: 'Other',
);

void main() {
  test(
    'uses canonical API names, deduplicates meals and loads full details',
    () async {
      var lookups = 0;

      final repository = RecipeRepository(
        client: MockClient((request) async {
          if (request.url.path.endsWith('list.php')) {
            return http.Response(
              jsonEncode({
                'meals': [
                  {'strIngredient': 'Spinach'},
                  {'strIngredient': 'Mushrooms'},
                ],
              }),
              200,
            );
          }

          if (request.url.path.endsWith('filter.php')) {
            expect(
              request.url.queryParameters['i'],
              isIn(['Spinach', 'Mushrooms']),
            );

            return http.Response('{"meals":[{"idMeal":"1"}]}', 200);
          }

          lookups++;

          return http.Response(
            jsonEncode({
              'meals': [
                {
                  'idMeal': '1',
                  'strMeal': 'Spinach mushrooms',
                  'strIngredient1': 'Spinach',
                  'strMeasure1': '1 cup',
                  'strIngredient2': 'Mushrooms',
                  'strMeasure2': '100 g',
                  'strIngredient3': 'Salt',
                  'strMeasure3': '1 pinch',
                  'strIngredient4': ' ',
                  'strIngredient5': null,
                },
              ],
            }),
            200,
          );
        }),
      );

      final result = await repository.recommend([
        food('Baby spinach', FoodPriority.first),
        food('Mushrooms', FoodPriority.soon),
      ]);

      expect(lookups, 1);
      expect(result.single.available.length, 2);
      expect(result.single.missing.single.name, 'Salt');
      expect(result.single.useFirst, 1);
      expect(result.single.useSoon, 1);

      repository.close();
    },
  );

  test('ranks existing Use First tags ahead of fewer missing ingredients', () {
    final recipes = [
      Recipe(
        id: 'later',
        name: 'Carrots',
        image: '',
        instructions: '',
        ingredients: [RecipeIngredient('Carrot', '1')],
      ),
      Recipe(
        id: 'first',
        name: 'Spinach soup',
        image: '',
        instructions: '',
        ingredients: [
          RecipeIngredient('Spinach', '1'),
          RecipeIngredient('Salt', '1'),
        ],
      ),
    ];

    final foods = [
      food('Baby spinach', FoodPriority.first),
      food('Carrots', FoodPriority.later),
    ];

    expect(rankRecipes(recipes, foods).first.recipe.id, 'first');
    expect(foods.last.priority, FoodPriority.later);
  });

  test('handles no matches and reports HTTP failures', () async {
    final empty = RecipeRepository(
      client: MockClient((_) async => http.Response('{"meals":null}', 200)),
    );

    expect(
      await empty.recommend([food('Unknown', FoodPriority.first)]),
      isEmpty,
    );

    empty.close();

    final failed = RecipeRepository(
      client: MockClient((_) async => http.Response('Unavailable', 503)),
    );

    await expectLater(
      failed.recommend([food('Eggs', FoodPriority.first)]),
      throwsStateError,
    );

    failed.close();
  });
}

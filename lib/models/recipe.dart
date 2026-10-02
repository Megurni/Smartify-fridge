import 'food_item.dart';

String ingredientKey(String value) {
  final key = value.toLowerCase().trim().replaceAll(RegExp(r'[_\s]+'), ' ');

  return const {
        'baby spinach': 'spinach',
        'chicken breasts': 'chicken breast',
        'mushrooms': 'mushroom',
        'carrots': 'carrot',
        'eggs': 'egg',
        'greek yogurt': 'greek yoghurt',
        'yogurt': 'yoghurt',
      }[key] ??
      key;
}

class RecipeIngredient {
  const RecipeIngredient(this.name, this.measure);

  final String name;
  final String measure;
}

class Recipe {
  const Recipe({
    required this.id,
    required this.name,
    required this.image,
    required this.instructions,
    required this.ingredients,
  });

  final String id;
  final String name;
  final String image;
  final String instructions;
  final List<RecipeIngredient> ingredients;

  factory Recipe.fromJson(Map<String, dynamic> json) {
    final ingredients = <RecipeIngredient>[];

    for (var i = 1; i <= 20; i++) {
      final name = (json['strIngredient$i'] as String? ?? '').trim();

      if (name.isNotEmpty) {
        ingredients.add(
          RecipeIngredient(
            name,
            (json['strMeasure$i'] as String? ?? '').trim(),
          ),
        );
      }
    }

    return Recipe(
      id: json['idMeal'] as String,
      name: json['strMeal'] as String,
      image: json['strMealThumb'] as String? ?? '',
      instructions: json['strInstructions'] as String? ?? '',
      ingredients: ingredients,
    );
  }
}

class RecipeMatch {
  RecipeMatch(this.recipe, List<FoodItem> foods)
    : available = recipe.ingredients.where((ingredient) {
        return foods.any(
          (food) => ingredientKey(food.name) == ingredientKey(ingredient.name),
        );
      }).toList(),
      missing = recipe.ingredients.where((ingredient) {
        return !foods.any(
          (food) => ingredientKey(food.name) == ingredientKey(ingredient.name),
        );
      }).toList(),
      useFirst = foods
          .where(
            (food) =>
                food.priority == FoodPriority.first &&
                recipe.ingredients.any(
                  (ingredient) =>
                      ingredientKey(food.name) ==
                      ingredientKey(ingredient.name),
                ),
          )
          .map((food) => ingredientKey(food.name))
          .toSet()
          .length,
      useSoon = foods
          .where(
            (food) =>
                food.priority == FoodPriority.soon &&
                recipe.ingredients.any(
                  (ingredient) =>
                      ingredientKey(food.name) ==
                      ingredientKey(ingredient.name),
                ),
          )
          .map((food) => ingredientKey(food.name))
          .toSet()
          .length;

  final Recipe recipe;
  final List<RecipeIngredient> available;
  final List<RecipeIngredient> missing;
  final int useFirst;
  final int useSoon;
}

List<RecipeMatch> rankRecipes(List<Recipe> recipes, List<FoodItem> foods) {
  final matches = recipes.map((recipe) => RecipeMatch(recipe, foods)).toList();

  matches.sort((a, b) {
    var order = b.useFirst.compareTo(a.useFirst);

    if (order == 0) {
      order = b.useSoon.compareTo(a.useSoon);
    }

    if (order == 0) {
      order = a.missing.length.compareTo(b.missing.length);
    }

    if (order == 0) {
      order = a.recipe.name.compareTo(b.recipe.name);
    }

    return order;
  });

  return matches;
}

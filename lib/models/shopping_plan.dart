import 'food_item.dart';
import 'recipe.dart';

class ShoppingItem {
  ShoppingItem({
    required this.name,
    this.quantity = '',
    this.recipeName,
    this.recipeId,
    this.ingredientName,
  });

  String name;
  String quantity;
  final String? recipeName;
  final String? recipeId;
  final String? ingredientName;
  bool purchased = false;
}

/// Shopping state, serialized by ShoppingPlanStore.
class ShoppingPlan {
  ShoppingPlan();

  Map<String, dynamic> toJson() => {
    'version': 1,
    'recipes': [
      for (final recipe in recipes)
        {
          'id': recipe.id,
          'name': recipe.name,
          'image': recipe.image,
          'instructions': recipe.instructions,
          'ingredients': [
            for (final ingredient in recipe.ingredients)
              {'name': ingredient.name, 'measure': ingredient.measure},
          ],
        },
    ],
    'items': [
      for (final item in items)
        {
          'name': item.name,
          'quantity': item.quantity,
          'recipeName': item.recipeName,
          'recipeId': item.recipeId,
          'ingredientName': item.ingredientName,
          'purchased': item.purchased,
        },
    ],
    'owned': _owned.map((key, value) => MapEntry(key, value.toList())),
  };

  factory ShoppingPlan.fromJson(Map<String, dynamic> data) {
    if (data['version'] != 1) {
      throw const FormatException('Unsupported shopping data');
    }
    final plan = ShoppingPlan();
    for (final recipe in data['recipes'] as List) {
      plan.recipes.add(
        Recipe(
          id: recipe['id'] as String,
          name: recipe['name'] as String,
          image: recipe['image'] as String,
          instructions: recipe['instructions'] as String,
          ingredients: [
            for (final ingredient in recipe['ingredients'] as List)
              RecipeIngredient(
                ingredient['name'] as String,
                ingredient['measure'] as String,
              ),
          ],
        ),
      );
    }
    for (final item in data['items'] as List) {
      plan.items.add(
        ShoppingItem(
          name: item['name'] as String,
          quantity: item['quantity'] as String,
          recipeName: item['recipeName'] as String?,
          recipeId: item['recipeId'] as String?,
          ingredientName: item['ingredientName'] as String?,
        )..purchased = item['purchased'] as bool,
      );
    }
    for (final entry in (data['owned'] as Map<String, dynamic>).entries) {
      plan._owned[entry.key] = (entry.value as List).cast<String>().toSet();
    }
    return plan;
  }

  final List<Recipe> recipes = [];
  final List<ShoppingItem> items = [];

  final Map<String, Set<String>> _owned = {};

  List<ShoppingItem> get pendingItems =>
      items.where((item) => !item.purchased).toList();

  bool hasIngredient(
    Recipe recipe,
    RecipeIngredient ingredient,
    List<FoodItem> foods,
  ) {
    final key = ingredientKey(ingredient.name);
    final owned = _owned[recipe.id];
    final available = owned != null
        ? owned.contains(key)
        : foods.any(
            (food) =>
                food.status == FoodStatus.inStock &&
                ingredientKey(food.name) == key,
          );
    return available ||
        items.any(
          (item) =>
              item.recipeId == recipe.id &&
              item.purchased &&
              item.ingredientName == key &&
              ingredientKey(item.name) == key,
        );
  }

  void removeRecipe(Recipe recipe) {
    recipes.removeWhere((planned) => planned.id == recipe.id);
    _owned.remove(recipe.id);
  }

  void addRecipe(
    Recipe recipe,
    List<FoodItem> foods, {
    Set<String>? ownedIngredients,
  }) {
    if (recipes.any((planned) => planned.id == recipe.id)) return;
    recipes.add(recipe);
    final stock = foods
        .where((food) => food.status == FoodStatus.inStock)
        .toList();
    final owned =
        ownedIngredients?.map(ingredientKey).toSet() ??
        RecipeMatch(
          recipe,
          stock,
        ).available.map((item) => ingredientKey(item.name)).toSet();
    _owned[recipe.id] = Set.of(owned);
    for (final ingredient in recipe.ingredients.where(
      (item) => !owned.contains(ingredientKey(item.name)),
    )) {
      // Keep separate quantities for separate recipes: arbitrary units cannot
      // safely be combined. Re-adding the same planned recipe is a no-op.
      items.add(
        ShoppingItem(
          name: ingredient.name,
          quantity: ingredient.measure,
          recipeName: recipe.name,
          recipeId: recipe.id,
          ingredientName: ingredientKey(ingredient.name),
        ),
      );
    }
  }
}

import 'food_item.dart';
import 'recipe.dart';

class ShoppingItem {
  ShoppingItem({required this.name, this.quantity = '', this.recipeName});

  String name;
  String quantity;
  final String? recipeName;
  bool purchased = false;
}

/// Session-only, matching the current inventory repository.
class ShoppingPlan {
  final List<Recipe> recipes = [];
  final List<ShoppingItem> items = [];

  void addRecipe(Recipe recipe, List<FoodItem> foods) {
    if (recipes.any((planned) => planned.id == recipe.id)) return;
    recipes.add(recipe);
    final stock = foods.where((food) => food.status == FoodStatus.inStock).toList();
    for (final ingredient in RecipeMatch(recipe, stock).missing) {
      // Keep separate quantities for separate recipes: arbitrary units cannot
      // safely be combined. Re-adding the same planned recipe is a no-op.
      items.add(ShoppingItem(
        name: ingredient.name,
        quantity: ingredient.measure,
        recipeName: recipe.name,
      ));
    }
  }

  double savings(Iterable<FoodItem> foods) {
    final used = <String>{};
    var cents = 0;
    for (final food in foods) {
      if (food.status == FoodStatus.consumed && used.add(food.id)) {
        cents += (food.savedAmount * 100).round();
      }
    }
    return cents / 100;
  }
}

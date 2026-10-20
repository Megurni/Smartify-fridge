import 'package:flutter_test/flutter_test.dart';
import 'package:smartify_refrigerator_demo/models/food_item.dart';
import 'package:smartify_refrigerator_demo/models/recipe.dart';
import 'package:smartify_refrigerator_demo/models/shopping_plan.dart';

void main() {
  FoodItem chicken({FoodStatus status = FoodStatus.inStock, double saved = 0}) =>
      FoodItem(id: 'chicken', name: 'Chicken breast', storedAt: DateTime.now(),
        status: status, quantity: '2 pieces', price: 8.50, category: 'Meat',
        savedAmount: saved);
  const recipe = Recipe(id: '1', name: 'Chicken dish', image: '', instructions: '',
    ingredients: [RecipeIngredient('Chicken breasts', '2'),
      RecipeIngredient('Tomatoes', '3')]);

  test('planning adds only missing ingredients and prevents duplicate plans', () {
    final plan = ShoppingPlan();
    plan.addRecipe(recipe, [chicken()]);
    plan.addRecipe(recipe, [chicken()]);
    expect(plan.recipes.length, 1);
    expect(plan.items.single.name, 'Tomatoes');
    expect(plan.items.single.quantity, '3');
    plan.items.clear();
    plan.addRecipe(recipe, [chicken()]);
    expect(plan.items, isEmpty); // Do not undo a user's shopping-list edits.
  });

  test('consumed food does not satisfy a new recipe', () {
    final plan = ShoppingPlan();
    plan.addRecipe(recipe, [chicken(status: FoodStatus.consumed)]);
    expect(plan.items.length, 2);
  });

  test('purchases never count as savings; used inventory counts once', () {
    final plan = ShoppingPlan();
    plan.addRecipe(recipe, [chicken()]);
    plan.items.single.purchased = true;
    expect(plan.savings([chicken()]), 0);
    final used = chicken(status: FoodStatus.consumed, saved: 8.50);
    expect(plan.savings([used, used]), 8.50);
    expect(plan.savings([used.copyWith(status: FoodStatus.inStock, savedAmount: 0)]), 0);
    expect(plan.savings([chicken(status: FoodStatus.discarded)]), 0);
    expect(plan.savings([chicken(status: FoodStatus.consumed)]), 0);
  });
}

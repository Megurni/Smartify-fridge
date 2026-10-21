import 'package:flutter_test/flutter_test.dart';
import 'package:smartify_refrigerator_demo/models/food_item.dart';
import 'package:smartify_refrigerator_demo/models/recipe.dart';
import 'package:smartify_refrigerator_demo/models/shopping_plan.dart';

void main() {
  FoodItem chicken({FoodStatus status = FoodStatus.inStock}) =>
      FoodItem(id: 'chicken', name: 'Chicken breast', storedAt: DateTime.now(),
        status: status, quantity: '2 pieces', price: 8.50, category: 'Meat');
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

  test('shopping edits and purchases do not change inventory', () {
    final food = chicken();
    final plan = ShoppingPlan();
    plan.addRecipe(recipe, [food]);
    final item = plan.items.single;
    item.name = 'Peppers';
    item.quantity = '2';
    item.purchased = true;
    expect(plan.items.single.name, 'Peppers');
    expect(food.status, FoodStatus.inStock);
    expect(food.price, 8.50);
    item.purchased = false;
    expect(item.purchased, isFalse);
    plan.items.remove(item);
    expect(plan.items, isEmpty);
  });
}

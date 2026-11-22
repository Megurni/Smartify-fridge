import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:smartify_refrigerator_demo/main.dart';
import 'package:smartify_refrigerator_demo/models/recipe.dart';
import 'package:smartify_refrigerator_demo/models/shopping_plan.dart';
import 'package:smartify_refrigerator_demo/repositories/shopping_plan_store.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });
  testWidgets(
    'shopping state survives app recreation and purchases stay hidden',
    (tester) async {
      const recipe = Recipe(
        id: '1',
        name: 'Soup',
        image: '',
        instructions: 'Simmer',
        ingredients: [
          RecipeIngredient('Carrots', '2'),
          RecipeIngredient('Salt', '1 tsp'),
        ],
      );
      final plan = ShoppingPlan()
        ..addRecipe(recipe, [], ownedIngredients: {'carrot'});
      plan.items.single.purchased = true;
      plan.items.add(ShoppingItem(name: 'Bread', quantity: '1 loaf'));
      final store = ShoppingPlanStore(namespace: 'test');
      await store.save(plan);
      await tester.pumpWidget(
        SmartifyApp(
          foodRepository: InMemoryFoodRepository(initialFoods: []),
          shoppingPlanStore: store,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Shopping').last);
      await tester.pumpAndSettle();
      expect(find.text('Soup'), findsOneWidget);
      expect(find.text('Bread'), findsOneWidget);
      expect(find.text('Salt'), findsNothing);
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      final reopened = ShoppingPlanStore(namespace: 'test');
      await tester.pumpWidget(
        SmartifyApp(
          foodRepository: InMemoryFoodRepository(initialFoods: []),
          shoppingPlanStore: reopened,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Shopping').last);
      await tester.pumpAndSettle();
      expect(find.text('Your shopping list is empty.'), findsOneWidget);
      final loaded = await reopened.load();
      expect(
        loaded.hasIngredient(
          loaded.recipes.single,
          loaded.recipes.single.ingredients.first,
          [],
        ),
        isTrue,
      );
      expect(
        loaded.hasIngredient(
          loaded.recipes.single,
          loaded.recipes.single.ingredients.last,
          [],
        ),
        isTrue,
      );
      expect(
        (await ShoppingPlanStore(namespace: 'other').load()).items,
        isEmpty,
      );
    },
  );
  test('rapid save then undo retains latest snapshot', () async {
    final store = ShoppingPlanStore(namespace: 'rapid');
    final plan = ShoppingPlan()..items.add(ShoppingItem(name: 'Milk'));
    plan.items.single.purchased = true;
    final first = store.save(plan);
    plan.items.single.purchased = false;
    final second = store.save(plan);
    await Future.wait([first, second]);
    expect((await store.load()).pendingItems.single.name, 'Milk');
  });
}

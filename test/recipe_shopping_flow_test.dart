import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartify_refrigerator_demo/main.dart';
import 'package:smartify_refrigerator_demo/models/recipe.dart';
import 'package:smartify_refrigerator_demo/models/shopping_plan.dart';

const recipe = Recipe(
  id: 'test',
  name: 'Test soup',
  image: '',
  instructions: 'Mix and simmer.',
  ingredients: [
    RecipeIngredient('Carrots', '2'),
    RecipeIngredient('Salt', '1 tsp'),
  ],
);

void main() {
  test(
    'explicit selection overrides stock and purchase updates recipe status',
    () {
      final plan = ShoppingPlan();
      plan.addRecipe(recipe, [], ownedIngredients: {'carrot'});
      expect(plan.pendingItems.single.name, 'Salt');
      expect(plan.hasIngredient(recipe, recipe.ingredients.first, []), isTrue);
      final salt = plan.pendingItems.single;
      salt.purchased = true;
      expect(plan.pendingItems, isEmpty);
      expect(plan.hasIngredient(recipe, recipe.ingredients.last, []), isTrue);
      salt.purchased = false;
      expect(plan.hasIngredient(recipe, recipe.ingredients.last, []), isFalse);
      salt.name = 'Pepper';
      salt.purchased = true;
      expect(plan.hasIngredient(recipe, recipe.ingredients.last, []), isFalse);
    },
  );

  testWidgets(
    'selection dialog returns only checked ingredients; cancel is inert',
    (tester) async {
      Set<String>? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await showDialog<Set<String>>(
                    context: context,
                    builder: (_) =>
                        RecipeIngredientsDialog(match: RecipeMatch(recipe, [])),
                  );
                },
                child: const Text('Plan'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Plan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salt'));
      await tester.tap(find.text('Add to shopping list'));
      await tester.pumpAndSettle();
      expect(result, {'salt'});
      await tester.tap(find.text('Plan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(result, isNull);
    },
  );

  testWidgets(
    'purchase disappears, undo restores, and recipe has split checklist',
    (tester) async {
      final plan = ShoppingPlan()
        ..addRecipe(recipe, [], ownedIngredients: {'carrot'});
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) => Scaffold(
              body: ShoppingListPage(
                foods: const [],
                plan: plan,
                onChanged: () => setState(() {}),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      expect(find.byType(Checkbox), findsNothing);
      expect(find.text('Your shopping list is empty.'), findsOneWidget);
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(find.byType(Checkbox), findsOneWidget);
      await tester.tap(find.text('Test soup').first);
      await tester.pumpAndSettle();
      expect(find.text('Already have (1)'), findsOneWidget);
      expect(find.text('Need to buy (1)'), findsOneWidget);
      expect(find.text('Mix and simmer.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

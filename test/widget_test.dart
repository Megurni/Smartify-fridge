import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartify_refrigerator_demo/main.dart';

void main() {
  testWidgets('shows inventory-focused home screen', (tester) async {
    await tester.pumpWidget(const SmartifyApp());
    await tester.pumpAndSettle();

    expect(find.text('Good morning 👋'), findsOneWidget);
    expect(find.text('SAVE IT BEFORE\nYOU WASTE IT'), findsOneWidget);
    expect(find.text('Chicken breast'), findsOneWidget);
    expect(find.text('Inventory'), findsNWidgets(2));
  });
  testWidgets('home inventory follows additions and removals', (tester) async {
    final repository = InMemoryFoodRepository(initialFoods: []);
    await tester.pumpWidget(SmartifyApp(foodRepository: repository));
    await tester.pumpAndSettle();

    expect(find.text('No food in your refrigerator yet'), findsOneWidget);
    await tester.tap(find.text('Inventory').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add food'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Apples');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect((await repository.getFoods()).single.name, 'Apples');
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('Apples'), findsOneWidget);
    expect(find.text('1 item in your refrigerator'), findsOneWidget);

    await tester.tap(find.text('See inventory'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apples'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Consumed'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('No food in your refrigerator yet'), findsOneWidget);
    expect(find.text('0 items in your refrigerator'), findsOneWidget);
  });
  testWidgets('inventory and home order foods by days remaining', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const foods = [
      FoodItem(
        id: 'later',
        name: 'Carrots',
        emoji: '🥕',
        quantity: '1 bag',
        daysLeft: 9,
        price: 1,
        priority: FoodPriority.later,
        category: 'Produce',
      ),
      FoodItem(
        id: 'soon',
        name: 'Yogurt',
        emoji: '🥛',
        quantity: '1 cup',
        daysLeft: 4,
        price: 1,
        priority: FoodPriority.soon,
        category: 'Dairy',
      ),
      FoodItem(
        id: 'first',
        name: 'Milk',
        emoji: '🥛',
        quantity: '1 carton',
        daysLeft: 1,
        price: 1,
        priority: FoodPriority.first,
        category: 'Dairy',
      ),
    ];
    await tester.pumpWidget(
      SmartifyApp(foodRepository: InMemoryFoodRepository(initialFoods: foods)),
    );
    await tester.pumpAndSettle();

    List<String> visibleFoodNames() => tester
        .widgetList<FoodTile>(find.byType(FoodTile))
        .map((tile) => tile.food.name)
        .toList();

    expect(visibleFoodNames(), ['Milk', 'Yogurt', 'Carrots']);
    await tester.tap(find.text('Inventory').last);
    await tester.pumpAndSettle();
    expect(visibleFoodNames(), ['Milk', 'Yogurt', 'Carrots']);

    await tester.tap(find.text('Add food'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Tomatoes');
    await tester.enterText(find.byType(TextFormField).last, '0');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(visibleFoodNames(), ['Tomatoes', 'Milk', 'Yogurt', 'Carrots']);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(visibleFoodNames(), ['Tomatoes', 'Milk', 'Yogurt', 'Carrots']);
  });
}

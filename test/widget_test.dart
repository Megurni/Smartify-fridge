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
    expect((await repository.getFoods()).single.status, FoodStatus.consumed);
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('No food in your refrigerator yet'), findsOneWidget);
    expect(find.text('0 items in your refrigerator'), findsOneWidget);
  });
  testWidgets('inventory and home order foods by priority score', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final now = DateTime.now();
    final foods = [
      FoodItem(
        id: 'later',
        name: 'Carrots',
        storedAt: now,
        status: FoodStatus.inStock,
        quantity: '1 bag',
        price: 1,
        category: 'Produce',
      ),
      FoodItem(
        id: 'soon',
        name: 'Yogurt',
        storedAt: now.subtract(const Duration(days: 3)),
        status: FoodStatus.inStock,
        quantity: '1 cup',
        price: 1,
        category: 'Dairy',
      ),
      FoodItem(
        id: 'first',
        name: 'Milk',
        storedAt: now.subtract(const Duration(days: 6)),
        status: FoodStatus.inStock,
        quantity: '1 carton',
        price: 1,
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
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(visibleFoodNames(), ['Milk', 'Yogurt', 'Carrots', 'Tomatoes']);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(visibleFoodNames(), ['Milk', 'Yogurt', 'Carrots', 'Tomatoes']);
  });

  testWidgets('accounting totals consumed as saved and discarded as wasted', (
    tester,
  ) async {
    final now = DateTime.now();
    FoodItem item(String id, FoodStatus status, double price) => FoodItem(
      id: id,
      name: id,
      storedAt: now,
      status: status,
      quantity: '1',
      price: price,
      category: 'Other',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InsightsPage(
            foods: [
              item('used', FoodStatus.consumed, 5),
              item('waste', FoodStatus.discarded, 2.40),
              item('stock', FoodStatus.inStock, 3),
            ],
          ),
        ),
      ),
    );
    expect(find.text('\$5.00'), findsOneWidget);
    expect(find.text('Wasted: \$2.40'), findsOneWidget);
    expect(find.text('Items consumed'), findsOneWidget);
    expect(find.text('Items discarded'), findsOneWidget);
  });
}

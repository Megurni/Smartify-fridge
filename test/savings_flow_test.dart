import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartify_refrigerator_demo/main.dart';

void main() {
  testWidgets('using food credits savings once and undo reverses it', (tester) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = InMemoryFoodRepository(initialFoods: [
      FoodItem(id: 'chicken', name: 'Chicken breast', storedAt: DateTime.now(),
        status: FoodStatus.inStock, quantity: '2 pieces', price: 8.50,
        category: 'Meat'),
    ]);
    await tester.pumpWidget(SmartifyApp(foodRepository: repository));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Savings'));
    await tester.pumpAndSettle();
    expect(find.text('\$0.00'), findsOneWidget);
    await tester.tap(find.text('Mark used'));
    await tester.pumpAndSettle();
    expect(find.text('\$8.50'), findsOneWidget);
    expect(find.text('Mark used'), findsNothing);
    expect((await repository.getFood('chicken'))!.savedAmount, 8.50);
    await tester.tap(find.text('UNDO'));
    await tester.pumpAndSettle();
    expect(find.text('\$0.00'), findsOneWidget);
    expect(find.text('Mark used'), findsOneWidget);
    await tester.tap(find.text('Mark used'));
    await tester.pumpAndSettle();
    expect(find.text('\$8.50'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('past estimated shelf life earns no savings', (tester) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = InMemoryFoodRepository(initialFoods: [
      FoodItem(id: 'old', name: 'Chicken',
        storedAt: DateTime.now().subtract(const Duration(days: 4)),
        status: FoodStatus.inStock, quantity: '1', price: 8.50, category: 'Meat'),
    ]);
    await tester.pumpWidget(SmartifyApp(foodRepository: repository));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Savings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark used'));
    await tester.pumpAndSettle();
    expect(find.text('\$0.00'), findsOneWidget);
    expect((await repository.getFood('old'))!.status, FoodStatus.consumed);
    expect((await repository.getFood('old'))!.savedAmount, 0);
  });
}

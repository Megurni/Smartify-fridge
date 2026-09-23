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
    expect(find.text('Inventory'), findsOneWidget);
  });
  testWidgets('adding a named food writes through the repository', (
    tester,
  ) async {
    final repository = InMemoryFoodRepository(initialFoods: []);
    await tester.pumpWidget(SmartifyApp(foodRepository: repository));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Inventory'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add food'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Apples');
    await tester.enterText(find.byType(TextFormField).last, '3 pieces');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    final foods = await repository.getFoods();
    expect(foods.single.name, 'Apples');
    expect(foods.single.quantity, '3 pieces');
    expect(find.text('Apples'), findsOneWidget);
  });
}

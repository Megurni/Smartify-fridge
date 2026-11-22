import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartify_refrigerator_demo/main.dart';

void main() {
  testWidgets(
    'manual review works without persistence, can defer, reopen and save',
    (tester) async {
      final repository = InMemoryFoodRepository(
        initialFoods: [
          FoodItem(
            id: 'milk',
            name: 'Milk',
            storedAt: DateTime(2026, 11, 22),
            price: 2,
            category: 'Dairy',
          ),
        ],
      );
      await tester.pumpWidget(SmartifyApp(foodRepository: repository));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Inventory').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('1 item to review'));
      await tester.pumpAndSettle();
      expect(find.text('Review new food'), findsOneWidget);
      await tester.tap(find.text('Review later'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('1 item to review'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'Whole milk');
      await tester.tap(find.text('Save inventory'));
      await tester.pumpAndSettle();
      expect(find.text('Review new food'), findsNothing);
      expect(find.text('1 item to review'), findsNothing);
      expect((await repository.getFood('milk'))!.name, 'Whole milk');
      expect(tester.takeException(), isNull);
    },
  );
}

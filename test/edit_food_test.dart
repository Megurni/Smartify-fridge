import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartify_refrigerator_demo/main.dart';

FoodItem _milk() => FoodItem(
  id: 'milk',
  name: 'Milk',
  storedAt: DateTime(2026, 11, 4),
  price: 2,
  category: 'Dairy',
);

Future<void> _openEditor(WidgetTester tester, FoodRepository repository) async {
  tester.view.physicalSize = const Size(1200, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(SmartifyApp(foodRepository: repository));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Inventory').last);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Milk'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Edit'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'saved food can be edited, validated, and reopened with new values',
    (tester) async {
      final original = _milk();
      final repository = InMemoryFoodRepository(initialFoods: [original]);
      await _openEditor(tester, repository);
      expect(find.text('Edit food'), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).first)
            .controller!
            .text,
        'Milk',
      );
      await tester.enterText(find.byType(TextFormField).first, 'Whole milk');
      await tester.enterText(find.byType(TextFormField).last, '-1');
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a valid price'), findsOneWidget);
      expect((await repository.getFood('milk'))!.name, 'Milk');
      await tester.enterText(find.byType(TextFormField).last, '4.25');
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Beverage').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();
      final updated = (await repository.getFood('milk'))!;
      expect(updated.name, 'Whole milk');
      expect(updated.price, 4.25);
      expect(updated.category, 'Beverage');
      expect(updated.storedAt, original.storedAt);
      expect(updated.status, FoodStatus.inStock);
      expect(find.text('Whole milk'), findsOneWidget);
      await tester.tap(find.text('Whole milk'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).first)
            .controller!
            .text,
        'Whole milk',
      );
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).last)
            .controller!
            .text,
        '4.25',
      );
    },
  );

  testWidgets('cancel leaves saved food unchanged', (tester) async {
    final repository = InMemoryFoodRepository(initialFoods: [_milk()]);
    await _openEditor(tester, repository);
    await tester.enterText(find.byType(TextFormField).first, 'Wrong name');
    await tester.enterText(find.byType(TextFormField).last, '99');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    final food = (await repository.getFood('milk'))!;
    expect(food.name, 'Milk');
    expect(food.price, 2);
    expect(find.text('Edit food'), findsNothing);
  });

  testWidgets('failed save keeps the editor and draft available for retry', (
    tester,
  ) async {
    final repository = _FailingRepository();
    await _openEditor(tester, repository);
    await tester.enterText(find.byType(TextFormField).last, '5.50');
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(
      find.text('Could not save inventory. Please retry.'),
      findsOneWidget,
    );
    expect(find.text('Edit food'), findsOneWidget);
    expect((await repository.getFood('milk'))!.price, 2);
    repository.fail = false;
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect((await repository.getFood('milk'))!.price, 5.50);
    expect(find.text('Edit food'), findsNothing);
  });
}

class _FailingRepository extends InMemoryFoodRepository {
  _FailingRepository() : super(initialFoods: [_milk()]);
  bool fail = true;

  @override
  Future<void> updateFoodDetails(
    String id, {
    required String name,
    required double price,
    required String category,
  }) async {
    if (fail) throw StateError('Offline');
    await super.updateFoodDetails(
      id,
      name: name,
      price: price,
      category: category,
    );
  }
}

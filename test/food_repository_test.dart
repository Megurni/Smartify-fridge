import 'package:flutter_test/flutter_test.dart';
import 'package:smartify_refrigerator_demo/models/food_item.dart';
import 'package:smartify_refrigerator_demo/repositories/food_repository.dart';

FoodItem food(String id, String name) => FoodItem(
  id: id,
  name: name,
  storedAt: DateTime(2026, 10, 11),
  status: FoodStatus.inStock,
  quantity: '1',
  price: 2,
  category: 'Dairy',
);

void main() {
  test(
    'CRUD uses ids, allows matching names, and returns detached snapshots',
    () async {
      final repository = InMemoryFoodRepository(initialFoods: []);
      final first = food('1', 'Eggs');
      await repository.addFood(first);
      final snapshot = await repository.getFoods();
      await repository.addFood(food('2', 'Eggs'));
      expect(snapshot.length, 1);
      expect((await repository.getFoods()).length, 2);
      await repository.updateFood(food('1', 'Milk'));
      expect((await repository.getFood('1'))!.name, 'Milk');
      await repository.deleteFood('1');
      expect(await repository.getFood('1'), isNull);
      expect((await repository.getFood('2'))!.name, 'Eggs');
      await repository.addFood(first); // undo restores the same identity
      expect((await repository.getFoods()).length, 2);
    },
  );

  test(
    'duplicate adds and missing updates do not silently overwrite data',
    () async {
      final repository = InMemoryFoodRepository(
        initialFoods: [food('1', 'Eggs')],
      );
      await expectLater(
        repository.addFood(food('1', 'Milk')),
        throwsStateError,
      );
      await expectLater(
        repository.updateFood(food('missing', 'Milk')),
        throwsStateError,
      );
      expect((await repository.getFood('1'))!.name, 'Eggs');
    },
  );
}

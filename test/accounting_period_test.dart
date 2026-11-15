import 'package:flutter_test/flutter_test.dart';
import 'package:smartify_refrigerator_demo/models/accounting_period.dart';
import 'package:smartify_refrigerator_demo/models/food_item.dart';

void main() {
  test('week starts Monday and month uses calendar boundaries', () {
    final now = DateTime(2026, 10, 21, 12);
    FoodItem outcome(DateTime at) => FoodItem(
      id: at.toIso8601String(),
      name: 'Milk',
      storedAt: at,
      status: FoodStatus.discarded,
      price: 3,
      category: 'Dairy',
      outcomeAt: at,
    );

    expect(
      AccountingPeriod.thisWeek.contains(outcome(DateTime(2026, 10, 19)), now),
      isTrue,
    );
    expect(
      AccountingPeriod.previousWeek.contains(
        outcome(DateTime(2026, 10, 18, 23, 59)),
        now,
      ),
      isTrue,
    );
    expect(
      AccountingPeriod.thisWeek.contains(
        outcome(DateTime(2026, 10, 18, 23, 59)),
        now,
      ),
      isFalse,
    );
    expect(
      AccountingPeriod.previousMonth.contains(
        outcome(DateTime(2026, 9, 30)),
        now,
      ),
      isTrue,
    );
    expect(
      AccountingPeriod.thisMonth.contains(outcome(DateTime(2026, 10, 1)), now),
      isTrue,
    );
  });
}

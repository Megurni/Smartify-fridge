import 'food_item.dart';

enum AccountingPeriod { thisWeek, previousWeek, thisMonth, previousMonth }

extension AccountingPeriodRange on AccountingPeriod {
  String get label => switch (this) {
    AccountingPeriod.thisWeek => 'This week',
    AccountingPeriod.previousWeek => 'Previous week',
    AccountingPeriod.thisMonth => 'This month',
    AccountingPeriod.previousMonth => 'Previous month',
  };

  bool contains(FoodItem food, DateTime now) {
    if (food.status == FoodStatus.inStock) return false;
    final time = (food.outcomeAt ?? now).toLocal();
    final weekStart = DateTime(now.year, now.month, now.day - now.weekday + 1);
    final monthStart = DateTime(now.year, now.month);
    final (start, end) = switch (this) {
      AccountingPeriod.thisWeek => (
        weekStart,
        DateTime(weekStart.year, weekStart.month, weekStart.day + 7),
      ),
      AccountingPeriod.previousWeek => (
        DateTime(weekStart.year, weekStart.month, weekStart.day - 7),
        weekStart,
      ),
      AccountingPeriod.thisMonth => (
        monthStart,
        DateTime(now.year, now.month + 1),
      ),
      AccountingPeriod.previousMonth => (
        DateTime(now.year, now.month - 1),
        monthStart,
      ),
    };
    return !time.isBefore(start) && time.isBefore(end);
  }
}

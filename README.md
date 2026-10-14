# smartify_refrigerator_demo

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Food data access

The inventory uses `FoodRepository` (`lib/repositories/food_repository.dart`):
`getFoods`, `getFood(id)`, `addFood`, `updateFood`, and `deleteFood(id)`.
All return Futures so a future HTTP implementation can use the same interface.
Pass a repository to `SmartifyApp(foodRepository: repository)` to replace the
source without changing the screens. Food ids identify records independently
of their names.

The default `InMemoryFoodRepository` contains sample foods and does not persist
changes across restarts. No database or API connection is configured. The UI
loads foods through the repository and routes add, remove, and undo through it.
Food records contain `id`, `name`, `storedAt` (stored_at), `status`,
`quantity`, `price`, and `category`. The Add food dialog defaults `storedAt`
to the current date and lets you choose an earlier date, price, and
category. The id is generated when the food is added.

`status` is an accounting lifecycle: `inStock`, `consumed`, or `discarded`.
Consumed and discarded items leave inventory but remain in the repository.
Accounting sums consumed prices as saved from waste and discarded prices as
wasted; the in-memory demo resets these totals on restart.

Inventory uses `InventoryPriority` to sort by a 0–100 score (highest first).
Estimated shelf life is 3 days for Meat, 5 for Produce, 7 for Dairy, and 14
for Other. Elapsed shelf life scores 100, one day remaining scores at least
85, and older items score more than newer ones. Price adds up to 10 points.
Equal scores sort by older storage date, then id. These are rough estimates
until a real expiry date is available; quantity is displayed but is not parsed
into the score because it is free text.
Recipe suggestions use the active inventory; accounting totals use recorded outcomes.

Run checks with `flutter test` and `flutter analyze`.

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
The Add food dialog accepts name and quantity; other fields currently default
to 7 days remaining, zero price, Other category, and Use later priority.
Recipe suggestions and savings statistics are still demo content.

Run checks with `flutter test` and `flutter analyze`.

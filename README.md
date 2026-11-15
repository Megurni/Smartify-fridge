# Smartify fridge frontend

Flutter frontend for the Smartify fridge Flask backend.

## Run

Start the backend on port 5001, then run `flutter run` from this folder. The
default backend address is `http://localhost:5001` on web, desktop, and the iOS
simulator, and `http://10.0.2.2:5001` on the Android emulator. For a physical
device, use your computer's LAN address:

```
flutter run --dart-define=SMARTIFY_API_URL=http://192.168.1.10:5001
```

Replace the example address with the computer running Flask. New manually added
food goes on the first existing shelf. If there is no shelf, the app creates a
`Fridge` shelf. Set a specific shelf when there are several:

```
flutter run --dart-define=SMARTIFY_API_URL=http://192.168.1.10:5001 --dart-define=SMARTIFY_SHELF_ID=2
```

## Inventory data

The app reads active items from `GET /items`. The backend's `status` describes
freshness (`safe`, `expiring_soon`, `expired`, `unknown`), and its `expires_at`
drives urgency. Adding food calls `POST /item`. Removing an item calls
`POST /item/<id>/remove`; Undo calls `POST /item/<id>/restore`. The backend's
`removed_at` field is the source of truth for whether an item remains in
inventory. The app refreshes inventory when navigating between tabs. The
Accounting outcomes are saved by the backend in the same request that removes
an item. The frontend reads `GET /accounting/events` on refresh and groups
records into this week, previous week, this month, and previous month. Undo
restores the item and voids its outcome. A consumed item counts as saved only
if it was in Use First when marked consumed. Its price is snapshotted at that
moment; other consumed items add no saved value. Shopping plans remain local to
the current app session.

The backend does not expose quantity, so backend items display the frontend's
default `1 item` quantity. It sets `stored_at` when a manual item is created.

`SmartifyApp(foodRepository: ...)` still accepts a repository for tests and
previews. `InMemoryFoodRepository` provides the sample data in widget tests.

Run checks with `flutter analyze` and `flutter test`.

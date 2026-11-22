# Smartify fridge frontend

Flutter frontend for the Smartify fridge Flask backend.

## Pi deployment: localhost and Tailscale

One web build supports both http://localhost:8080 on the Pi and
http://100.112.112.84:8080 on an authorized secondary Tailscale device.
Web builds default to /api/ on the current webpage's origin. The supplied Nginx
configuration serves the frontend on 8080 and forwards /api/ to the backend on
127.0.0.1:5001. See [Pi setup instructions](deploy/pi/README.md).

Build on your development computer with `flutter build web --release`, without
a SMARTIFY_API_URL override, and deploy the files and Nginx config to the Pi.

## Local development

Start the backend on port 5001. For Flutter Web without Nginx, explicitly select
the backend (Flutter's development server does not forward /api/):

```sh
flutter run -d chrome --dart-define=SMARTIFY_API_URL=http://localhost:5001
```

For the Pi backend over Tailscale:

```sh
flutter run -d chrome --dart-define=SMARTIFY_API_URL=http://100.112.112.84:5001
```

Native defaults remain localhost:5001 on desktop/iOS and the configured Pi
100.112.112.84:5001 on Android. SMARTIFY_API_URL overrides these for other devices.
New manually added food goes on the first existing shelf, or a new Fridge shelf
if none exists. To choose a shelf, add `--dart-define=SMARTIFY_SHELF_ID=2` using
your actual backend shelf ID.

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
moment; other consumed items add no saved value. Shopping plans are saved on the current device/browser, separately for each API base and shelf.

The backend does not expose quantity, so backend items display the frontend's
default `1 item` quantity. It sets `stored_at` when a manual item is created.

`SmartifyApp(foodRepository: ...)` still accepts a repository for tests and
previews. `InMemoryFoodRepository` provides the sample data in widget tests.

Run checks with `flutter analyze` and `flutter test`.

## Recipe shopping checklist

Want to Make opens an ingredient checklist, preselected from inventory names.
Confirm the ingredients you already have in sufficient quantity; only unchecked
items are added to Shopping List. Recipe details show instructions beside
Already have / Need to buy (stacked on narrow screens). Marking an item purchased
hides it from the active shopping list and updates its recipe checklist; Undo
restores it. Purchases do not create inventory records. Plans, owned ingredients, manual shopping items and purchase state are saved locally after each change and restored when reopening the app. This does not sync across browsers/devices; clearing site data removes saved plans.

## Inventory illustrations and edit photos

Inventory tiles and the bottom sheet use Microsoft Fluent Emoji Flat (MIT;
license in assets/food_icons/LICENSE.txt). All eleven category fallbacks and
common ingredient illustrations are bundled. Other ingredient names use the
Iconify search API restricted to fluent-emoji-flat; only exact normalized
matches are accepted. Successful SVGs are cached in shared preferences. Missing
matches, offline requests and image failures use the category illustration.

Edit food shows the original shelf capture (not a per-item crop). The backend
must return image_url as a path relative to the API base, e.g.
"capture/7/image". The legacy image filesystem path is never loaded by the
browser. Missing photos show a placeholder. The companion backend patch must
be applied and deployed to the Pi before real captures can appear; the local
sample-data preview has no fridge photos.

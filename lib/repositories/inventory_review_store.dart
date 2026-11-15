import 'package:shared_preferences/shared_preferences.dart';

/// Keeps track of backend items the user has already reviewed on this device.
class InventoryReviewStore {
  InventoryReviewStore({
    required String namespace,
    SharedPreferencesAsync? prefs,
  }) : _key = 'reviewed_inventory_v1:$namespace',
       _prefs = prefs ?? SharedPreferencesAsync();

  final String _key;
  final SharedPreferencesAsync _prefs;

  Future<Set<String>> load() async =>
      (await _prefs.getStringList(_key) ?? <String>[]).toSet();

  Future<void> save(Set<String> reviewedItems) async {
    await _prefs.setStringList(_key, reviewedItems.toList()..sort());
  }
}

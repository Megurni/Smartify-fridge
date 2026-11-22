import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/shopping_plan.dart';

/// Device-local storage, separated by backend/shelf (and preview).
class ShoppingPlanStore {
  ShoppingPlanStore({required String namespace, SharedPreferencesAsync? prefs})
    : _key = 'shopping_plan_v1:$namespace',
      _prefs = prefs ?? SharedPreferencesAsync();
  final String _key;
  final SharedPreferencesAsync _prefs;
  Future<void> _tail = Future.value();

  Future<ShoppingPlan> load() async {
    await _tail;
    final raw = await _prefs.getString(_key);
    return raw == null
        ? ShoppingPlan()
        : ShoppingPlan.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> save(ShoppingPlan plan) {
    // Snapshot now, serialize writes so rapid purchases/Undo cannot reorder them.
    final snapshot = jsonEncode(plan.toJson());
    final write = _tail.then((_) => _prefs.setString(_key, snapshot));
    _tail = write.catchError((Object _) {});
    return write;
  }
}

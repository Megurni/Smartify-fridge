import 'dart:async';
import 'dart:math' as math;

import 'config/api_config.dart';

import 'models/recipe.dart';
import 'models/shopping_plan.dart';
import 'repositories/recipe_repository.dart';
import 'models/food_item.dart';
import 'models/inventory_priority.dart';
import 'models/accounting_period.dart';
import 'repositories/food_repository.dart';
import 'repositories/inventory_review_store.dart';
import 'package:flutter/foundation.dart';
export 'models/food_item.dart';
export 'models/inventory_priority.dart';
export 'repositories/food_repository.dart';
import 'package:flutter/material.dart';

part 'app_shell.dart';

part 'pages/home_page.dart';
part 'pages/insights_page.dart';
part 'pages/inventory_page.dart';
part 'pages/inventory_review_page.dart';
part 'pages/recipes_page.dart';
part 'pages/shopping_list_page.dart';
part 'widgets/common_widgets.dart';

void main() {
  const configuredUrl = String.fromEnvironment('SMARTIFY_API_URL');
  const configuredShelfId = int.fromEnvironment('SMARTIFY_SHELF_ID');
  final url = resolveApiBaseUrl(
    configuredUrl: configuredUrl,
    isWeb: kIsWeb,
    nativeDefaultUrl: defaultTargetPlatform == TargetPlatform.android
        ? 'http://100.112.112.84:5001'
        : 'http://localhost:5001',
  );
  runApp(
    SmartifyApp(
      foodRepository: HttpFoodRepository(
        baseUrl: url,
        shelfId: configuredShelfId > 0 ? configuredShelfId : null,
      ),
      inventoryReviewStore: InventoryReviewStore(
        namespace: '$url:${configuredShelfId > 0 ? configuredShelfId : 'all'}',
      ),
    ),
  );
}

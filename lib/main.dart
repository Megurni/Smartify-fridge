import 'models/food_item.dart';
import 'repositories/food_repository.dart';
export 'models/food_item.dart';
export 'repositories/food_repository.dart';
import 'package:flutter/material.dart';

part 'app_shell.dart';

part 'pages/home_page.dart';
part 'pages/insights_page.dart';
part 'pages/inventory_page.dart';
part 'pages/recipes_page.dart';
part 'widgets/common_widgets.dart';

void main() {
  runApp(const SmartifyApp());
}

import 'package:flutter_test/flutter_test.dart';
import 'package:smartify_refrigerator_demo/main.dart';

void main() {
  testWidgets('shows inventory-focused home screen', (tester) async {
    await tester.pumpWidget(const SmartifyApp());

    expect(find.text('Good morning 👋'), findsOneWidget);
    expect(find.text('SAVE IT BEFORE\nYOU WASTE IT'), findsOneWidget);
    expect(find.text('Chicken breast'), findsOneWidget);
    expect(find.text('Inventory'), findsOneWidget);
  });
}

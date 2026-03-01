import 'package:flutter_test/flutter_test.dart';
import 'package:chintaultimate/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ChintaUltimateApp());
    expect(find.text('Chinta Ultimate'), findsOneWidget);
  });
}

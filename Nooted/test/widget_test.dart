import 'package:flutter_test/flutter_test.dart';
import 'package:nootpad/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const NootPadApp());
    expect(find.text('NootPad'), findsOneWidget);
  });
}

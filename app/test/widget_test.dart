import 'package:flutter_test/flutter_test.dart';

import 'package:ai_keys_app/main.dart';

void main() {
  testWidgets('App renders home title', (WidgetTester tester) async {
    await tester.pumpWidget(const AiKeysApp());
    await tester.pump();
    expect(find.text('AI Mails'), findsOneWidget);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:secret_chat/main.dart';

void main() {
  testWidgets('App builds HomeScreen without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const SecretChatApp());
    await tester.pump();
    expect(find.textContaining('SECRET'), findsOneWidget);
  });
}

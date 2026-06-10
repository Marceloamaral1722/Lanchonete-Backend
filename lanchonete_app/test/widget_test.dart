import 'package:flutter_test/flutter_test.dart';
import 'package:lanchonete_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MaxismusApp());
    expect(find.byType(MaxismusApp), findsOneWidget);
  });
}

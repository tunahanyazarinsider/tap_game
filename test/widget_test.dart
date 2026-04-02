import 'package:flutter_test/flutter_test.dart';
import 'package:tap_city/main.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(const TapCityApp());
    expect(find.byType(TapCityApp), findsOneWidget);
  });
}

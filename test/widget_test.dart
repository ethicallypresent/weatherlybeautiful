import 'package:flutter_test/flutter_test.dart';

import 'package:weather_app/main.dart';
import 'package:weather_app/screens/home_screen.dart';

void main() {
  testWidgets('Weather app bootstraps and shows main weather UI', (WidgetTester tester) async {
    await tester.pumpWidget(const WeatherApp());
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(HomeScreen), findsOneWidget);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:pearls/main.dart';

void main() {
  testWidgets('Pearls app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const PearlsApp());
  });
}
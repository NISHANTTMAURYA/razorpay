import 'package:flutter_test/flutter_test.dart';
import 'package:mitrai/main.dart';

void main() {
  testWidgets('Mitrai app launches properly', (WidgetTester tester) async {
    await tester.pumpWidget(const MitraiApp());
    expect(find.byType(MitraiApp), findsOneWidget);
  });
}

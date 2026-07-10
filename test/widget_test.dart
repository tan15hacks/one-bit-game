import 'package:flutter_test/flutter_test.dart';
import 'package:one_bit_game/main.dart';

void main() {
  testWidgets('game screen builds', (WidgetTester tester) async {
    await tester.pumpWidget(const OneBitApp());
    expect(find.byType(GameScreen), findsOneWidget);
  });
}

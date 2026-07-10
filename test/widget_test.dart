import 'package:flutter_test/flutter_test.dart';
import 'package:one_bit_game/main.dart';

void main() {
  testWidgets('main menu renders the title and tutorial button', (tester) async {
    await tester.pumpWidget(const OneBitApp());

    expect(find.text('ONE BIT\nESCAPE'), findsOneWidget);
    expect(find.text('START TUTORIAL'), findsOneWidget);
  });
}

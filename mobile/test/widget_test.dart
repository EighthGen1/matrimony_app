import 'package:flutter_test/flutter_test.dart';
import 'package:anbu_matrimony/app/app.dart';

void main() {
  testWidgets('shows discovery API setup guidance when not configured',
      (tester) async {
    await tester.pumpWidget(const AnbuMatrimonyApp());
    await tester.pumpAndSettle();

    expect(find.text('Discover'), findsNWidgets(2));
    expect(
      find.text(
        'Discovery needs a server connection',
      ),
      findsOneWidget,
    );
  });
}

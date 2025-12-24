import 'package:flutter_test/flutter_test.dart';
import 'package:dormease/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(DormEase());

    // Verify the splash screen is shown
    expect(find.text('DormEase'), findsNothing); // Assuming splash screen has no text 'DormEase'

    // Add more widget tests as needed
  });
}

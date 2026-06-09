import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: ALUCoLabApp()));
    await tester.pump();
    expect(find.byType(ALUCoLabApp), findsOneWidget);
  });
}

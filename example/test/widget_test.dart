import 'package:accessible_flutter_tts_example/main.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    // Both plugins answer every call with success.
    for (final name in ['flutter_tts', 'accessible_flutter_tts']) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(MethodChannel(name), (call) async => 1);
    }
  });

  testWidgets('switches between the original and the accessible plugin', (tester) async {
    await tester.pumpWidget(const ExampleApp());
    expect(find.text('flutter_tts'), findsOneWidget);

    await tester.tap(find.text('Accessible'));
    await tester.pumpAndSettle();
    expect(find.text('accessible_flutter_tts'), findsOneWidget);
  });
}

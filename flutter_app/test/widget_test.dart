import 'package:flutter_test/flutter_test.dart';
import 'package:quick_translate_pro/main.dart';
import 'package:quick_translate_pro/services/native_hook_service.dart';

void main() {
  testWidgets('App shell Smoke Test', (WidgetTester tester) async {
    final hookService = NativeHookService();
    await tester.pumpWidget(QuickTranslateApp(hookService: hookService));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('QuickTrace'), findsOneWidget);
  });
}

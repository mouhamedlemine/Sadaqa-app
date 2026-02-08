import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sadaqa_mobile_app/main.dart';
import 'package:sadaqa_mobile_app/controllers/locale_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App builds smoke test', (WidgetTester tester) async {
    final localeController = LocaleController();

    await tester.pumpWidget(
      SadaqaApp(localeController: localeController),
    );

    await tester.pumpAndSettle();

    expect(find.byType(SadaqaApp), findsOneWidget);
  });
}

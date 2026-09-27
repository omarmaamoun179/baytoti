import 'package:baytoti/core/theme/app_theme.dart';
import 'package:baytoti/core/utils/screen_util_scope.dart';
import 'package:baytoti/core/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<BuildContext> pumpPage(WidgetTester tester) async {
    late BuildContext page;

    await tester.pumpWidget(ScreenUtilScope(
      child: Builder(
        builder: (_) => MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Builder(builder: (context) {
              page = context;
              return const SizedBox.expand();
            }),
          ),
        ),
      ),
    ));
    return page;
  }

  testWidgets('a toast with an action runs it, and still closes by itself',
      (tester) async {
    final page = await pumpPage(tester);
    var undone = 0;

    showAppToast(
      page,
      'Product deleted',
      actionLabel: 'Undo',
      onAction: () => undone++,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(undone, 1);

    showAppToast(
      page,
      'Product deleted',
      actionLabel: 'Undo',
      onAction: () => undone++,
    );
    await tester.pumpAndSettle();
    expect(find.text('Product deleted'), findsOneWidget);

    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    expect(find.text('Product deleted'), findsNothing);
    expect(undone, 1);
  });
}

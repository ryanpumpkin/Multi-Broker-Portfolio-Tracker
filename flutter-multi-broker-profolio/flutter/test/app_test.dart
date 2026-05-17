import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multi_broker_portfolio/app.dart';
import 'package:multi_broker_portfolio/i18n/generated/app_localizations.dart';

void main() {
  testWidgets('boots with English locale', (tester) async {
    await tester.pumpWidget(
      const MultiBrokerPortfolioApp(localeOverride: Locale('en')),
    );
    await tester.pumpAndSettle();
    final ctx = tester.element(find.byType(Scaffold));
    expect(AppLocalizations.of(ctx).appTitle, 'Multi-Broker Portfolio');
  });

  testWidgets('boots with zh_Hant locale', (tester) async {
    await tester.pumpWidget(
      const MultiBrokerPortfolioApp(
        localeOverride: Locale.fromSubtags(
          languageCode: 'zh',
          scriptCode: 'Hant',
        ),
      ),
    );
    await tester.pumpAndSettle();
    final ctx = tester.element(find.byType(Scaffold));
    expect(AppLocalizations.of(ctx).appTitle, '多券商投資組合');
  });

  testWidgets('respects themeMode override', (tester) async {
    await tester.pumpWidget(
      const MultiBrokerPortfolioApp(
        themeModeOverride: ThemeMode.dark,
        localeOverride: Locale('en'),
      ),
    );
    await tester.pumpAndSettle();
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
  });
}

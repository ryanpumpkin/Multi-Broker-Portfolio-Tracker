import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'i18n/app_locales.dart';
import 'i18n/generated/app_localizations.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

/// Root widget of the application.
///
/// Owns the [GoRouter] instance, registers localization delegates and
/// supplies the light / dark Material 3 themes. State management
/// (Riverpod) is set up at the bootstrap layer in `main.dart`; this widget
/// stays pure-Widget so it can be exercised in tests without `ProviderScope`.
class MultiBrokerPortfolioApp extends StatefulWidget {
  const MultiBrokerPortfolioApp({
    super.key,
    this.routerOverride,
    this.themeModeOverride,
    this.localeOverride,
  });

  /// Inject a pre-built router (used by tests to avoid spinning up a real
  /// `GoRouter` per case).
  final GoRouter? routerOverride;

  /// Optional override; defaults to [AppTheme.themeModeDefault].
  final ThemeMode? themeModeOverride;

  /// Optional override; when null the device locale is resolved via
  /// [AppLocales.resolve].
  final Locale? localeOverride;

  @override
  State<MultiBrokerPortfolioApp> createState() =>
      _MultiBrokerPortfolioAppState();
}

class _MultiBrokerPortfolioAppState extends State<MultiBrokerPortfolioApp> {
  late final GoRouter _router = widget.routerOverride ?? _buildDefaultRouter();

  GoRouter _buildDefaultRouter() {
    // Tests render this widget without initialising Firebase. Detect that
    // case and fall back to a router with no auth guard so widget tests
    // keep working.
    if (Firebase.apps.isEmpty) {
      return buildAppRouter();
    }
    return buildAppRouter(
      isAuthenticated: () => FirebaseAuth.instance.currentUser != null,
      authRefreshListenable: GoRouterRefreshStream(
        FirebaseAuth.instance.authStateChanges(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      onGenerateTitle: (ctx) => AppLocalizations.of(ctx).appTitle,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: widget.themeModeOverride ?? AppTheme.themeModeDefault,
      locale: widget.localeOverride,
      localizationsDelegates: const <LocalizationsDelegate<Object>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocales.supported,
      localeListResolutionCallback: (device, supported) {
        if (device == null || device.isEmpty) return AppLocales.fallback;
        return AppLocales.resolve(device.first);
      },
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}

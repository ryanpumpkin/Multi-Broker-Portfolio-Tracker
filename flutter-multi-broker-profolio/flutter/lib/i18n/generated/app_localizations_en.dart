// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Multi-Broker Portfolio';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navPositions => 'Positions';

  @override
  String get navCharts => 'Charts';

  @override
  String get navTransactions => 'Transactions';

  @override
  String get navConnections => 'Connections';

  @override
  String get navAlerts => 'Alerts';

  @override
  String get navSettings => 'Settings';

  @override
  String get placeholderScreen => 'Coming soon';

  @override
  String get settingsThemeSystem => 'Follow system';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageChineseTraditional => '繁體中文';

  @override
  String get debugLogViewerTitle => 'Log Viewer (debug)';

  @override
  String get debugLogViewerEmpty => 'No log entries yet.';
}

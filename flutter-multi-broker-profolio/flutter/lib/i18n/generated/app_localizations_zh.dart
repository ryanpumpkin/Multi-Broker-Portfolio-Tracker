// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '多券商投資組合';

  @override
  String get navDashboard => '總覽';

  @override
  String get navPositions => '持倉';

  @override
  String get navCharts => '圖表';

  @override
  String get navTransactions => '交易紀錄';

  @override
  String get navConnections => '連線';

  @override
  String get navAlerts => '提醒';

  @override
  String get navSettings => '設定';

  @override
  String get placeholderScreen => '即將推出';

  @override
  String get settingsThemeSystem => '跟隨系統';

  @override
  String get settingsThemeLight => '淺色';

  @override
  String get settingsThemeDark => '深色';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageChineseTraditional => '繁體中文';

  @override
  String get debugLogViewerTitle => '日誌檢視 (除錯)';

  @override
  String get debugLogViewerEmpty => '尚無日誌。';
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizationsZh {
  AppLocalizationsZhHant() : super('zh_Hant');

  @override
  String get appTitle => '多券商投資組合';

  @override
  String get navDashboard => '總覽';

  @override
  String get navPositions => '持倉';

  @override
  String get navCharts => '圖表';

  @override
  String get navTransactions => '交易紀錄';

  @override
  String get navConnections => '連線';

  @override
  String get navAlerts => '提醒';

  @override
  String get navSettings => '設定';

  @override
  String get placeholderScreen => '即將推出';

  @override
  String get settingsThemeSystem => '跟隨系統';

  @override
  String get settingsThemeLight => '淺色';

  @override
  String get settingsThemeDark => '深色';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageChineseTraditional => '繁體中文';

  @override
  String get debugLogViewerTitle => '日誌檢視 (除錯)';

  @override
  String get debugLogViewerEmpty => '尚無日誌。';
}

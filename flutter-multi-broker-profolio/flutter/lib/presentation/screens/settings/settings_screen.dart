import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/domain.dart';
import '../../../router/app_router.dart';
import '../../../state/state.dart';
import '../../lock/app_lock_settings_section.dart';
import '../../widgets/widgets.dart';
import '../shared/presentation_scaffold.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return PresentationScaffold(
      selectedRoute: AppRoutes.settings,
      title: 'Settings',
      body: settings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorBanner(error: error),
        data: (value) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DropdownButtonFormField<CurrencyMode>(
                key: const Key('settings_currency_mode'),
                initialValue: value.currencyMode,
                decoration: const InputDecoration(labelText: 'Currency mode'),
                items: const [
                  DropdownMenuItem(
                    value: CurrencyMode.base,
                    child: Text('Base currency'),
                  ),
                  DropdownMenuItem(
                    value: CurrencyMode.native,
                    child: Text('Native currency'),
                  ),
                ],
                onChanged: (mode) {
                  if (mode == null) return;
                  ref.read(settingsProvider.notifier).setCurrencyMode(mode);
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                key: const Key('settings_base_currency'),
                initialValue: value.baseCurrency,
                decoration: const InputDecoration(labelText: 'Base currency'),
                items: const ['USD', 'HKD', 'SGD', 'CNY']
                    .map(
                      (c) => DropdownMenuItem(value: c, child: Text(c)),
                    )
                    .toList(growable: false),
                onChanged: (currency) {
                  if (currency == null) return;
                  ref.read(settingsProvider.notifier).setBaseCurrency(currency);
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<AppThemeMode>(
                key: const Key('settings_theme_mode'),
                initialValue: value.themeMode,
                decoration: const InputDecoration(labelText: 'Theme'),
                items: const [
                  DropdownMenuItem(
                    value: AppThemeMode.system,
                    child: Text('System'),
                  ),
                  DropdownMenuItem(
                    value: AppThemeMode.light,
                    child: Text('Light'),
                  ),
                  DropdownMenuItem(
                    value: AppThemeMode.dark,
                    child: Text('Dark'),
                  ),
                ],
                onChanged: (themeMode) {
                  if (themeMode == null) return;
                  ref.read(settingsProvider.notifier).setThemeMode(themeMode);
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String?>(
                key: const Key('settings_locale'),
                initialValue: value.locale,
                decoration: const InputDecoration(labelText: 'Language'),
                items: const [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text('System'),
                  ),
                  DropdownMenuItem<String?>(
                    value: 'en',
                    child: Text('English'),
                  ),
                  DropdownMenuItem<String?>(
                    value: 'zh-Hant',
                    child: Text('繁體中文'),
                  ),
                ],
                onChanged: (locale) {
                  ref.read(settingsProvider.notifier).setLocale(locale);
                },
              ),
              const SizedBox(height: 14),
              const AppLockSettingsSection(),
              const SizedBox(height: 14),
              ListTile(
                leading: const Icon(Icons.download_outlined),
                title: const Text('Export reports'),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Export queued (placeholder).'),
                    ),
                  );
                },
              ),
              if (!kReleaseMode)
                ListTile(
                  leading: const Icon(Icons.bug_report_outlined),
                  title: const Text('Debug logs'),
                  onTap: () => context.push(AppRoutes.debugLogViewer),
                ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Sign out'),
                onTap: () async {
                  await ref.read(authProvider.notifier).signOut();
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/domain.dart';
import '../../../router/app_router.dart';
import '../../../state/state.dart';
import '../../widgets/widgets.dart';
import '../shared/presentation_scaffold.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _promptedForPin = false;

  @override
  void initState() {
    super.initState();
    // After first frame, kick off the initial portfolio refresh — gated
    // on the credential key being available (prompt for PIN if needed).
    // The provider's build() only loads from cache so the dashboard is
    // never blocked on the network; the actual broker fetch happens
    // here, exactly once per dashboard mount.
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialRefresh());
  }

  Future<void> _initialRefresh() async {
    if (_promptedForPin || !mounted) return;
    _promptedForPin = true;
    try {
      final connectionsState = await ref.read(connectionsProvider.future);
      if (!mounted) return;
      final hasE2eConnections = connectionsState.connections.any(
        (c) =>
            c.credentialMode == CredentialMode.e2e &&
            c.status != ConnectionStatus.disabled,
      );

      // If there are e2e connections and no key yet, prompt for the
      // PIN so the upcoming refresh has wrapped creds.
      if (hasE2eConnections && ref.read(credentialKeyProvider) == null) {
        final lock = await ref.read(appLockProvider.future);
        if (!lock.hasPin || !mounted) return;
        await showDialog<void>(
          context: context,
          builder: (_) => const _DashboardPinDialog(),
        );
        if (!mounted) return;
        if (ref.read(credentialKeyProvider) == null) {
          // User cancelled or PIN was wrong — skip the network call so
          // we don't overwrite the cached snapshot with a bad
          // source_health.
          return;
        }
      }

      if (!mounted) return;
      await ref.read(portfolioProvider.notifier).refresh();
    } catch (_) {
      // Swallow — this is best-effort refresh on mount. If the widget
      // tree is torn down (test disposal, route switch) before the
      // futures resolve we don't want to crash.
    }
  }

  @override
  Widget build(BuildContext context) {
    final portfolio = ref.watch(portfolioProvider);
    final connections = ref.watch(connectionsProvider);

    return PresentationScaffold(
      selectedRoute: AppRoutes.dashboard,
      title: 'Dashboard',
      actions: [
        IconButton(
          key: const Key('dashboard_refresh_button'),
          tooltip: 'Refresh',
          icon: portfolio.isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh),
          onPressed: portfolio.isLoading
              ? null
              : () => _refreshWithPinGate(context, ref),
        ),
      ],
      body: RefreshIndicator(
        // Route pull-to-refresh through the same PIN gate as the manual
        // refresh button so it doesn't fire a request without wrapped
        // credentials and overwrite the screen with source_health=down.
        onRefresh: () => _refreshWithPinGate(context, ref),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (portfolio.hasError)
              ErrorBanner(
                error: portfolio.error!,
                onRetry: () => ref.read(portfolioProvider.notifier).refresh(),
              ),
            if (portfolio.isLoading) ...[
              const LoadingShimmer(height: 110),
              const SizedBox(height: 12),
              const LoadingShimmer(height: 110),
            ] else if (portfolio.value case final data?) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total portfolio value'),
                      const SizedBox(height: 4),
                      CurrencyAmount(
                        key: const Key('dashboard_total_value'),
                        amount: data.totalBaseValue,
                        currency: data.baseCurrency,
                        baseCurrency: data.baseCurrency,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      PnlBadge(
                        key: const Key('dashboard_total_pnl'),
                        amount: data.totalUnrealizedPnlBase,
                        currency: data.baseCurrency,
                        percent: data.totalBaseValue == 0
                            ? 0
                            : 100 *
                                (data.totalUnrealizedPnlBase /
                                    data.totalBaseValue),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              AllocationDonut(
                allocations: _toPercentages(data.totalsByCurrency),
              ),
            ] else
              const EmptyState(title: 'No portfolio data yet'),
            const SizedBox(height: 14),
            Text(
              'Sources',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (connections.value case final state?)
              ...state.connections.map((c) => SourceTile(connection: c))
            else
              const EmptyState(title: 'No connections configured'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  label: const Text('Open positions'),
                  onPressed: () => context.go(AppRoutes.positions),
                ),
                ActionChip(
                  label: const Text('View charts'),
                  onPressed: () => context.go(AppRoutes.charts),
                ),
                ActionChip(
                  label: const Text('Manage alerts'),
                  onPressed: () => context.go(AppRoutes.alerts),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Refresh the portfolio, but if there are active E2E connections and no
  /// credential key cached, prompt the user for their PIN first. Otherwise
  /// the request fires without wrapped-creds and the backend returns
  /// `source_health: down — missing wrapped credentials`.
  Future<void> _refreshWithPinGate(BuildContext context, WidgetRef ref) async {
    final hasKey = ref.read(credentialKeyProvider) != null;
    final connectionsState = ref.read(connectionsProvider).valueOrNull;
    final hasE2eConnections = connectionsState?.connections.any(
          (c) => c.credentialMode == CredentialMode.e2e &&
              c.status != ConnectionStatus.disabled,
        ) ??
        false;

    if (!hasKey && hasE2eConnections) {
      final lock = await ref.read(appLockProvider.future);
      if (!context.mounted) return;
      if (!lock.hasPin) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Set up a PIN in Settings → App Lock to sync E2E connections.',
            ),
          ),
        );
      } else {
        await showDialog<void>(
          context: context,
          builder: (_) => const _DashboardPinDialog(),
        );
      }
    }

    if (!context.mounted) return;
    // Only fire the network refresh if we actually have a key for the
    // active E2E connections — otherwise the request goes out without
    // wrapped credentials and the backend reports source_health=down
    // for everything, overwriting whatever we already have on screen.
    final keyReady = ref.read(credentialKeyProvider) != null;
    if (hasE2eConnections && !keyReady) return;
    await ref.read(portfolioProvider.notifier).refresh();
  }

  Map<String, double> _toPercentages(Map<String, double> map) {
    if (map.isEmpty) {
      return const {'N/A': 100};
    }
    final total = map.values.fold<double>(0, (a, b) => a + b);
    if (total == 0) {
      return map.map((k, v) => MapEntry(k, 0));
    }
    return map.map((key, value) => MapEntry(key, 100 * value / total));
  }
}

class _DashboardPinDialog extends ConsumerStatefulWidget {
  const _DashboardPinDialog();

  @override
  ConsumerState<_DashboardPinDialog> createState() =>
      _DashboardPinDialogState();
}

class _DashboardPinDialogState extends ConsumerState<_DashboardPinDialog> {
  final _ctrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final store = ref.read(appLockStoreProvider);
      final hasher = ref.read(appLockPinHasherProvider);
      final storedHash = await store.readPinHash();
      if (storedHash == null) {
        throw StateError('No PIN configured.');
      }
      final attemptHash = await hasher.hash(_ctrl.text);
      if (attemptHash != storedHash) {
        if (!mounted) return;
        setState(() {
          _saving = false;
          _error = 'Wrong PIN.';
        });
        return;
      }
      await ref
          .read(credentialKeyProvider.notifier)
          .deriveAndCache(_ctrl.text);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Unlock to sync'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Enter your PIN so the dashboard can sync your E2E broker '
              'connections.',
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('dashboard_pin_input'),
              controller: _ctrl,
              autofocus: true,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'PIN'),
              onFieldSubmitted: (_) => _submit(),
              validator: (v) {
                if (v == null || v.length < 4) return 'PIN is required';
                return null;
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Skip'),
        ),
        FilledButton(
          key: const Key('dashboard_pin_submit'),
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Unlock'),
        ),
      ],
    );
  }
}

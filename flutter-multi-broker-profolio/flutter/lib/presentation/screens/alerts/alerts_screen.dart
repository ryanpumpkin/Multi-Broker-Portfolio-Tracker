import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/domain.dart';
import '../../../router/app_router.dart';
import '../../../state/state.dart';
import '../../widgets/widgets.dart';
import '../shared/presentation_scaffold.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(alertsProvider);

    return PresentationScaffold(
      selectedRoute: AppRoutes.alerts,
      title: 'Alerts',
      actions: [
        IconButton(
          tooltip: 'Clear trigger history',
          onPressed: () =>
              ref.read(alertsProvider.notifier).clearTriggerHistory(),
          icon: const Icon(Icons.history_toggle_off),
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('alerts_add_button'),
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (_) => const AlertFormSheet(),
        ),
        icon: const Icon(Icons.add_alert_outlined),
        label: const Text('Add'),
      ),
      body: alerts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorBanner(error: error),
        data: (state) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (state.alerts.isEmpty)
                const EmptyState(title: 'No alerts configured')
              else
                ...state.alerts.map(
                  (alert) => Card(
                    child: ListTile(
                      title: Text(_alertLabel(alert)),
                      subtitle: Text(
                        'Threshold ${alert.threshold} · ${alert.active ? 'Active' : 'Disabled'}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              builder: (_) => AlertFormSheet(existing: alert),
                            ),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            onPressed: () => ref
                                .read(alertsProvider.notifier)
                                .delete(alert.id),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              if (state.triggerHistory.isNotEmpty)
                Text(
                  'Recent triggers (${state.triggerHistory.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ...state.triggerHistory.take(10).map(
                    (event) => ListTile(
                      dense: true,
                      leading: const Icon(Icons.bolt, size: 18),
                      title: Text(event.alertId),
                      subtitle: Text(
                        '${event.triggeredAt.toLocal()}'.split('.').first,
                      ),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }

  String _alertLabel(Alert alert) {
    final scope = alert.scope.isPortfolio
        ? 'Portfolio'
        : (alert.scope.symbol ?? 'Symbol');
    return '${alert.kind.name} · $scope';
  }
}

class AlertFormSheet extends ConsumerStatefulWidget {
  const AlertFormSheet({this.existing, super.key});

  final Alert? existing;

  @override
  ConsumerState<AlertFormSheet> createState() => _AlertFormSheetState();
}

class _AlertFormSheetState extends ConsumerState<AlertFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late AlertKind _kind = widget.existing?.kind ?? AlertKind.priceAbove;
  late bool _portfolioScope = widget.existing?.scope.isPortfolio ?? false;
  late final TextEditingController _symbol = TextEditingController(
    text: widget.existing?.scope.symbol ?? '',
  );
  late final TextEditingController _threshold = TextEditingController(
    text: widget.existing?.threshold.toString() ?? '',
  );
  late bool _active = widget.existing?.active ?? true;

  @override
  void dispose() {
    _symbol.dispose();
    _threshold.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.existing == null ? 'Create alert' : 'Edit alert',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<AlertKind>(
                key: const Key('alert_form_kind'),
                initialValue: _kind,
                items: AlertKind.values
                    .map(
                      (kind) => DropdownMenuItem(
                        value: kind,
                        child: Text(kind.name),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value != null) setState(() => _kind = value);
                },
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                key: const Key('alert_form_scope_portfolio'),
                title: const Text('Apply to whole portfolio'),
                value: _portfolioScope,
                onChanged: (value) {
                  setState(() => _portfolioScope = value);
                },
              ),
              if (!_portfolioScope)
                TextFormField(
                  key: const Key('alert_form_scope_symbol'),
                  controller: _symbol,
                  decoration: const InputDecoration(labelText: 'Symbol'),
                  validator: (value) {
                    if (_portfolioScope) return null;
                    if (value == null || value.trim().isEmpty) {
                      return 'Symbol is required';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 8),
              TextFormField(
                key: const Key('alert_form_threshold'),
                controller: _threshold,
                decoration: const InputDecoration(labelText: 'Threshold'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (_portfolioScope &&
                      (_kind == AlertKind.priceAbove ||
                          _kind == AlertKind.priceBelow)) {
                    return 'Portfolio scope supports P&L alerts only';
                  }
                  final parsed = double.tryParse(value ?? '');
                  if (parsed == null || parsed <= 0) {
                    return 'Threshold must be greater than 0';
                  }
                  return null;
                },
              ),
              SwitchListTile(
                title: const Text('Active'),
                value: _active,
                onChanged: (value) => setState(() => _active = value),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('alert_form_submit'),
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) return;
                    final draft = Alert(
                      id: widget.existing?.id ??
                          'alert-${DateTime.now().millisecondsSinceEpoch}',
                      kind: _kind,
                      scope: _portfolioScope
                          ? const AlertScope.portfolio()
                          : AlertScope.symbol(
                              _symbol.text.trim().toUpperCase(),
                            ),
                      threshold: double.parse(_threshold.text.trim()),
                      active: _active,
                    );
                    if (widget.existing == null) {
                      await ref.read(alertsProvider.notifier).create(draft);
                    } else {
                      await ref
                          .read(alertsProvider.notifier)
                          .updateAlert(draft);
                    }
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                  },
                  child: const Text('Save alert'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

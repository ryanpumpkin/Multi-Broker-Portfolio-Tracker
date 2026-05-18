import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/domain.dart';
import '../../../../router/app_router.dart';
import '../../../../state/state.dart';
import '../../../widgets/widgets.dart';
import '../../shared/presentation_scaffold.dart';

class ManualHoldingsScreen extends ConsumerWidget {
  const ManualHoldingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final holdings = ref.watch(manualHoldingsProvider);

    return PresentationScaffold(
      selectedRoute: AppRoutes.connections,
      title: 'Manual holdings',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: holdings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorBanner(error: error),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(title: 'No manual holdings');
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: items
                .map(
                  (holding) => Card(
                    child: ListTile(
                      title: Text(holding.label),
                      subtitle: Text(
                        '${holding.assetClass.name} · Qty ${holding.quantity}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CurrencyAmount(
                            amount: holding.valueAmount,
                            currency: holding.valueCurrency,
                          ),
                          IconButton(
                            onPressed: () => _openForm(
                              context,
                              ref,
                              existing: holding,
                            ),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            onPressed: () => ref
                                .read(manualHoldingsProvider.notifier)
                                .delete(holding.id),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          );
        },
      ),
    );
  }

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref, {
    ManualHolding? existing,
  }) async {
    final formKey = GlobalKey<FormState>();
    final label = TextEditingController(text: existing?.label ?? '');
    final qty = TextEditingController(text: '${existing?.quantity ?? 1}');
    final currency =
        TextEditingController(text: existing?.valueCurrency ?? 'USD');
    final value = TextEditingController(text: '${existing?.valueAmount ?? 0}');
    var assetClass = existing?.assetClass ?? AssetClass.cash;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            existing == null ? 'Add manual holding' : 'Edit manual holding',
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: label,
                    decoration: const InputDecoration(labelText: 'Label'),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Label is required'
                        : null,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<AssetClass>(
                    initialValue: assetClass,
                    items: AssetClass.values
                        .map(
                          (a) => DropdownMenuItem(
                            value: a,
                            child: Text(a.name),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => assetClass = value);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: qty,
                    decoration: const InputDecoration(labelText: 'Quantity'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) => (double.tryParse(v ?? '') ?? -1) <= 0
                        ? 'Quantity must be greater than 0'
                        : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: currency,
                    decoration: const InputDecoration(labelText: 'Currency'),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Currency is required'
                        : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: value,
                    decoration:
                        const InputDecoration(labelText: 'Current value'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) => (double.tryParse(v ?? '') ?? -1) < 0
                        ? 'Value cannot be negative'
                        : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final draft = ManualHolding(
                  id: existing?.id ??
                      'mh-${DateTime.now().millisecondsSinceEpoch}',
                  label: label.text.trim(),
                  assetClass: assetClass,
                  quantity: double.parse(qty.text.trim()),
                  valueCurrency: currency.text.trim().toUpperCase(),
                  valueAmount: double.parse(value.text.trim()),
                );
                if (existing == null) {
                  await ref.read(manualHoldingsProvider.notifier).create(draft);
                } else {
                  await ref
                      .read(manualHoldingsProvider.notifier)
                      .updateHolding(draft);
                }
                if (!context.mounted) return;
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

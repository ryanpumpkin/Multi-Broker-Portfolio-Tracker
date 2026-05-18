import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/domain.dart';
import '../../../router/app_router.dart';
import '../../../state/state.dart';
import '../../widgets/widgets.dart';
import '../shared/presentation_scaffold.dart';

class ConnectionsScreen extends ConsumerWidget {
  const ConnectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connections = ref.watch(connectionsProvider);

    return PresentationScaffold(
      selectedRoute: AppRoutes.connections,
      title: 'Connections',
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('connections_add_button'),
        onPressed: () => _showAddDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: connections.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorBanner(
          error: error,
          onRetry: () => ref.read(connectionsProvider.notifier).refresh(),
        ),
        data: (state) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () => context.go(AppRoutes.manualHoldings),
                  icon: const Icon(Icons.edit_note),
                  label: const Text('Manage manual holdings'),
                ),
              ),
              const SizedBox(height: 8),
              if (state.connections.isEmpty)
                const EmptyState(title: 'No connections configured')
              else
                ...state.connections.map(
                  (connection) => SourceTile(
                    connection: connection,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButton<CredentialMode>(
                          value: connection.credentialMode,
                          onChanged: (mode) {
                            if (mode == null) return;
                            ref.read(connectionsProvider.notifier).updateMode(
                                  connection.id,
                                  mode,
                                );
                          },
                          items: const [
                            DropdownMenuItem(
                              value: CredentialMode.e2e,
                              child: Text('E2E'),
                            ),
                            DropdownMenuItem(
                              value: CredentialMode.serverKey,
                              child: Text('Server key'),
                            ),
                          ],
                        ),
                        IconButton(
                          tooltip: 'Remove',
                          onPressed: () {
                            ref
                                .read(connectionsProvider.notifier)
                                .remove(connection.id);
                          },
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    final formKey = GlobalKey<FormState>();
    var kind = ConnectionKind.longbridge;
    var mode = CredentialMode.e2e;
    final label = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add connection'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<ConnectionKind>(
                      key: const Key('connection_kind_picker'),
                      initialValue: kind,
                      items: ConnectionKind.values
                          .where((k) => k != ConnectionKind.manual)
                          .map(
                            (k) => DropdownMenuItem(
                              value: k,
                              child: Text(k.name),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => kind = value);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      key: const Key('connection_label_input'),
                      controller: label,
                      decoration:
                          const InputDecoration(labelText: 'Display label'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Label is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<CredentialMode>(
                      initialValue: mode,
                      items: const [
                        DropdownMenuItem(
                          value: CredentialMode.e2e,
                          child: Text('E2E'),
                        ),
                        DropdownMenuItem(
                          value: CredentialMode.serverKey,
                          child: Text('Server key'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => mode = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  key: const Key('connection_save_button'),
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final messenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(context);
                    try {
                      await ref.read(connectionsProvider.notifier).add(
                            Connection(
                              id: 'conn-${DateTime.now().millisecondsSinceEpoch}',
                              kind: kind,
                              label: label.text.trim(),
                              status: ConnectionStatus.unknown,
                              credentialMode: mode,
                            ),
                          );
                      if (!context.mounted) return;
                      navigator.pop();
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(content: Text('Failed to save: $e')),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

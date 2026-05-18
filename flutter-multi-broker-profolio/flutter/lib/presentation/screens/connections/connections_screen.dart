import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/crypto/e2e.dart';
import '../../../domain/domain.dart';
import '../../../router/app_router.dart';
import '../../../state/state.dart';
import '../../widgets/widgets.dart';
import '../shared/presentation_scaffold.dart';

/// Per-broker credential field definitions. Each entry is
/// (jsonKey, displayLabel, obscure).
const Map<ConnectionKind, List<(String, String, bool)>> _credentialFields = {
  ConnectionKind.longbridge: [
    ('appKey', 'App Key', false),
    ('appSecret', 'App Secret', true),
    ('accessToken', 'Access Token', true),
  ],
  ConnectionKind.ibkr: [
    ('username', 'Username', false),
    ('password', 'Password', true),
    ('tradingMode', 'Trading Mode (paper/live)', false),
  ],
  ConnectionKind.futu: [
    ('account', 'Account', false),
    ('password', 'Password', true),
    ('host', 'OpenD Host', false),
    ('port', 'OpenD Port', false),
  ],
  ConnectionKind.binance: [
    ('apiKey', 'API Key', false),
    ('apiSecret', 'API Secret', true),
    ('region', 'Region (com / us)', false),
  ],
  ConnectionKind.manual: [],
};

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
    // Encryption gate: E2E mode requires the user's PIN-derived key.
    // If app-lock isn't set up yet, nudge them to Settings first.
    final lock = await ref.read(appLockProvider.future);
    final hasPin = lock.hasPin;
    var hasKey = ref.read(credentialKeyProvider) != null;
    if (!context.mounted) return;

    if (!hasPin) {
      // No PIN set yet → nudge to Settings.
      await _showPinRequiredDialog(context, hasPin: false);
      return;
    }

    if (!hasKey) {
      // PIN exists but the in-memory key was wiped (lock / restart). Prompt
      // for the PIN inline; if the user successfully unlocks, fall through
      // to the Add Connection dialog.
      await _showPinRequiredDialog(context, hasPin: true);
      if (!context.mounted) return;
      hasKey = ref.read(credentialKeyProvider) != null;
      if (!hasKey) return; // user cancelled or PIN was wrong
    }

    await showDialog<void>(
      context: context,
      builder: (_) => const _AddConnectionDialog(),
    );
  }

  Future<void> _showPinRequiredDialog(
    BuildContext context, {
    required bool hasPin,
  }) {
    if (!hasPin) {
      // No PIN set yet — nudge the user to Settings to configure one.
      return showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('PIN required'),
          content: const Text(
            'Set up an app PIN first. Open Settings → App Lock to '
            'configure it. Your PIN is used to encrypt broker '
            'credentials so the server never sees them in plaintext.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.go(AppRoutes.settings);
              },
              child: const Text('Go to Settings'),
            ),
          ],
        ),
      );
    }
    // PIN exists but the in-memory key was wiped (lock / restart).
    // Let the user enter the PIN inline so we can re-derive the key.
    return showDialog<void>(
      context: context,
      builder: (_) => const _PinEntryDialog(),
    );
  }
}

class _AddConnectionDialog extends ConsumerStatefulWidget {
  const _AddConnectionDialog();

  @override
  ConsumerState<_AddConnectionDialog> createState() =>
      _AddConnectionDialogState();
}

class _AddConnectionDialogState extends ConsumerState<_AddConnectionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _label = TextEditingController();
  final _credCtrls = <String, TextEditingController>{};

  ConnectionKind _kind = ConnectionKind.longbridge;
  CredentialMode _mode = CredentialMode.e2e;
  bool _saving = false;

  @override
  void dispose() {
    _label.dispose();
    for (final c in _credCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _ctrlFor(String key) =>
      _credCtrls.putIfAbsent(key, TextEditingController.new);

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final fields = _credentialFields[_kind] ?? const [];
    final labelText = _label.text.trim();
    final kind = _kind;
    final mode = _mode;

    try {
      final id = 'conn-${DateTime.now().millisecondsSinceEpoch}';
      await ref.read(connectionsProvider.notifier).add(
            Connection(
              id: id,
              kind: kind,
              label: labelText,
              status: ConnectionStatus.unknown,
              credentialMode: mode,
            ),
          );

      if (fields.isNotEmpty) {
        final creds = <String, String>{
          for (final (key, _, _) in fields)
            key: _credCtrls[key]?.text.trim() ?? '',
        };
        final key = ref.read(credentialKeyProvider);
        if (key == null) {
          throw StateError(
            'Credential key missing. Unlock with your PIN and try again.',
          );
        }
        final ct = await E2eCrypto.production().encrypt(jsonEncode(creds), key);
        // `Ciphertext.toEncoded()` already returns a base64-encoded JSON
        // string; the decrypter calls `Ciphertext.fromEncoded(blob)`.
        // Wrapping it again with another base64+jsonEncode would store an
        // extra layer that fromEncoded can't peel.
        final blob = ct.toEncoded();
        await ref.read(connectionsProvider.notifier).setCredentials(id, blob);
      }

      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Saved ${kind.name} connection "$labelText". '
            'Refresh the dashboard to sync.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text('Failed to save: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final fields = _credentialFields[_kind] ?? const [];
    return AlertDialog(
      title: const Text('Add connection'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<ConnectionKind>(
                  key: const Key('connection_kind_picker'),
                  initialValue: _kind,
                  items: ConnectionKind.values
                      .where((k) => k != ConnectionKind.manual)
                      .map(
                        (k) => DropdownMenuItem(
                          value: k,
                          child: Text(k.name),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: _saving
                      ? null
                      : (value) {
                          if (value != null) setState(() => _kind = value);
                        },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  key: const Key('connection_label_input'),
                  controller: _label,
                  enabled: !_saving,
                  decoration: const InputDecoration(labelText: 'Display label'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Label is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<CredentialMode>(
                  initialValue: _mode,
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
                  onChanged: _saving
                      ? null
                      : (value) {
                          if (value != null) setState(() => _mode = value);
                        },
                ),
                if (fields.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Credentials',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Encrypted on this device with your PIN before leaving '
                    'the app.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  ...fields.map((f) {
                    final (key, lbl, obscure) = f;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: TextFormField(
                        key: Key('cred_field_$key'),
                        controller: _ctrlFor(key),
                        obscureText: obscure,
                        enabled: !_saving,
                        decoration: InputDecoration(labelText: lbl),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '$lbl is required';
                          }
                          return null;
                        },
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('connection_save_button'),
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}

class _PinEntryDialog extends ConsumerStatefulWidget {
  const _PinEntryDialog();

  @override
  ConsumerState<_PinEntryDialog> createState() => _PinEntryDialogState();
}

class _PinEntryDialogState extends ConsumerState<_PinEntryDialog> {
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

    final pin = _ctrl.text;
    try {
      // Verify the PIN matches the stored hash (we don't want to derive
      // a key from arbitrary input — wrong PIN would silently produce
      // a non-decryptable key).
      final store = ref.read(appLockStoreProvider);
      final hasher = ref.read(appLockPinHasherProvider);
      final storedHash = await store.readPinHash();
      if (storedHash == null) {
        throw StateError('No PIN configured.');
      }
      final attemptHash = await hasher.hash(pin);
      if (attemptHash != storedHash) {
        if (!mounted) return;
        setState(() {
          _saving = false;
          _error = 'Wrong PIN. Try again.';
        });
        return;
      }
      // Derive and cache the credential-encryption key.
      await ref.read(credentialKeyProvider.notifier).deriveAndCache(pin);
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
      title: const Text('Enter your PIN'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Required to encrypt broker credentials on this device.',
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('credentials_pin_input'),
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
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('credentials_pin_submit'),
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

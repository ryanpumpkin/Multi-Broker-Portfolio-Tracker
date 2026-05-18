import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/app_lock_provider.dart';

class AppLockSettingsSection extends ConsumerWidget {
  const AppLockSettingsSection({super.key});

  static const List<Duration> _timeoutOptions = [
    Duration(seconds: 0),
    Duration(seconds: 15),
    Duration(seconds: 30),
    Duration(minutes: 1),
    Duration(minutes: 5),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lock = ref.watch(appLockProvider);
    final state = lock.valueOrNull;
    if (state == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            key: const Key('lock_enabled_toggle'),
            title: const Text('Enable app lock'),
            value: state.isEnabled,
            onChanged: (value) {
              ref.read(appLockProvider.notifier).setEnabled(value);
            },
          ),
          SwitchListTile(
            key: const Key('lock_biometric_toggle'),
            title: const Text('Use biometrics'),
            value: state.biometricEnabled,
            onChanged: state.isEnabled
                ? (value) {
                    ref
                        .read(appLockProvider.notifier)
                        .setBiometricEnabled(value);
                  }
                : null,
          ),
          ListTile(
            title: const Text('Auto-lock timeout'),
            subtitle: DropdownButton<Duration>(
              key: const Key('lock_timeout_dropdown'),
              value: state.timeout,
              isExpanded: true,
              onChanged: state.isEnabled
                  ? (value) {
                      if (value == null) return;
                      ref.read(appLockProvider.notifier).setTimeout(value);
                    }
                  : null,
              items: _timeoutOptions
                  .map(
                    (d) => DropdownMenuItem(
                      value: d,
                      child: Text(_label(d)),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
          ListTile(
            key: const Key('lock_set_pin_button'),
            leading: Icon(state.hasPin ? Icons.lock_reset : Icons.password),
            title: Text(state.hasPin ? 'Change PIN' : 'Set PIN'),
            subtitle: Text(
              state.hasPin
                  ? 'Used to unlock the app and encrypt broker credentials.'
                  : 'Required to encrypt broker credentials. 4–8 digits.',
            ),
            onTap: () => _showSetPinDialog(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _showSetPinDialog(BuildContext context, WidgetRef ref) async {
    final pinCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set PIN'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const Key('lock_pin_input'),
                controller: pinCtrl,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'PIN (4–8 digits)'),
                validator: (v) {
                  if (v == null || v.length < 4 || v.length > 8) {
                    return 'PIN must be 4–8 digits';
                  }
                  if (!RegExp(r'^\d+$').hasMatch(v)) {
                    return 'Digits only';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: const Key('lock_pin_confirm_input'),
                controller: confirmCtrl,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Confirm PIN'),
                validator: (v) {
                  if (v != pinCtrl.text) return 'PINs do not match';
                  return null;
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
            key: const Key('lock_pin_save_button'),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              try {
                await ref.read(appLockProvider.notifier).setPin(
                      pin: pinCtrl.text,
                      confirmPin: confirmCtrl.text,
                    );
                if (!context.mounted) return;
                navigator.pop();
                messenger.showSnackBar(
                  const SnackBar(content: Text('PIN saved.')),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Failed: $e')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    pinCtrl.dispose();
    confirmCtrl.dispose();
  }

  String _label(Duration d) {
    if (d == Duration.zero) return 'Immediately';
    if (d.inMinutes >= 1) {
      return '${d.inMinutes} min';
    }
    return '${d.inSeconds} sec';
  }
}

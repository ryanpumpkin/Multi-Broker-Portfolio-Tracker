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
        ],
      ),
    );
  }

  String _label(Duration d) {
    if (d == Duration.zero) return 'Immediately';
    if (d.inMinutes >= 1) {
      return '${d.inMinutes} min';
    }
    return '${d.inSeconds} sec';
  }
}

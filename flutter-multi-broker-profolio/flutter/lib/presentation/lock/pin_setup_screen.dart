import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/app_lock_provider.dart';

class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({
    super.key,
    this.onCompleted,
  });

  final VoidCallback? onCompleted;

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  final TextEditingController _pin = TextEditingController();
  final TextEditingController _confirm = TextEditingController();

  @override
  void dispose() {
    _pin.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set PIN')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              key: const Key('pin_setup_pin'),
              controller: _pin,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'PIN (4-8 digits)'),
            ),
            TextField(
              key: const Key('pin_setup_confirm_pin'),
              controller: _confirm,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Confirm PIN'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('pin_setup_submit'),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                try {
                  await ref.read(appLockProvider.notifier).setPin(
                        pin: _pin.text,
                        confirmPin: _confirm.text,
                      );
                  messenger.showSnackBar(
                    const SnackBar(content: Text('PIN saved.')),
                  );
                  widget.onCompleted?.call();
                } catch (error) {
                  messenger.showSnackBar(
                    SnackBar(content: Text(error.toString())),
                  );
                }
              },
              child: const Text('Save PIN'),
            ),
          ],
        ),
      ),
    );
  }
}

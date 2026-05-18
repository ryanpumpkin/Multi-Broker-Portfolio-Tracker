import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/app_lock_provider.dart';

class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate>
    with WidgetsBindingObserver {
  final TextEditingController _pinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pinController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    ref.read(appLockProvider.notifier).handleLifecycleChange(state);
  }

  @override
  Widget build(BuildContext context) {
    final lock = ref.watch(appLockProvider);
    final data = lock.valueOrNull;
    final isLocked = data?.isLocked ?? true;
    return Stack(
      fit: StackFit.expand,
      children: [
        IgnorePointer(
          ignoring: isLocked,
          child: widget.child,
        ),
        if (isLocked)
          ColoredBox(
            color: Colors.black54,
            child: Center(
              child: Card(
                margin: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'App locked',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          key: const Key('app_lock_pin_field'),
                          controller: _pinController,
                          obscureText: true,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'PIN',
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (data != null &&
                            data.backoffUntil != null &&
                            DateTime.now().toUtc().isBefore(data.backoffUntil!))
                          Text(
                            'Too many attempts. Try again soon.',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        const SizedBox(height: 8),
                        FilledButton(
                          key: const Key('unlock_with_pin_button'),
                          onPressed: () async {
                            await ref
                                .read(appLockProvider.notifier)
                                .unlockWithPin(_pinController.text);
                            _pinController.clear();
                          },
                          child: const Text('Unlock with PIN'),
                        ),
                        if (data?.biometricEnabled ?? false) ...[
                          const SizedBox(height: 8),
                          OutlinedButton(
                            key: const Key('unlock_with_biometrics_button'),
                            onPressed: () {
                              ref
                                  .read(appLockProvider.notifier)
                                  .unlockWithBiometrics();
                            },
                            child: const Text('Use biometrics'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

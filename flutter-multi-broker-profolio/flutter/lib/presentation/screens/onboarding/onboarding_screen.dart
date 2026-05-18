import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/domain.dart';
import '../../../router/app_router.dart';
import '../../../state/state.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  String _baseCurrency = 'USD';
  ConnectionKind _kind = ConnectionKind.longbridge;
  final TextEditingController _label = TextEditingController();

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Get started')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Base currency'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            key: const Key('onboarding_base_currency'),
            initialValue: _baseCurrency,
            items: const ['USD', 'HKD', 'SGD', 'CNY']
                .map(
                  (c) => DropdownMenuItem(value: c, child: Text(c)),
                )
                .toList(growable: false),
            onChanged: (value) {
              if (value == null) return;
              setState(() => _baseCurrency = value);
            },
          ),
          const SizedBox(height: 20),
          const Text('First connection'),
          const SizedBox(height: 8),
          DropdownButtonFormField<ConnectionKind>(
            key: const Key('onboarding_connection_kind'),
            initialValue: _kind,
            items: ConnectionKind.values
                .where((kind) => kind != ConnectionKind.manual)
                .map(
                  (kind) => DropdownMenuItem(
                    value: kind,
                    child: Text(_kindLabel(kind)),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) {
              if (value == null) return;
              setState(() => _kind = value);
            },
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('onboarding_connection_label'),
            controller: _label,
            decoration: const InputDecoration(
              labelText: 'Connection label',
              hintText: 'e.g. LongBridge HK',
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('onboarding_continue'),
            onPressed: () async {
              await ref
                  .read(settingsProvider.notifier)
                  .setBaseCurrency(_baseCurrency);
              if (_label.text.trim().isNotEmpty) {
                await ref.read(connectionsProvider.notifier).add(
                      Connection(
                        id: 'conn-${DateTime.now().millisecondsSinceEpoch}',
                        kind: _kind,
                        label: _label.text.trim(),
                        status: ConnectionStatus.unknown,
                        credentialMode: CredentialMode.e2e,
                      ),
                    );
              }
              if (!context.mounted) return;
              context.go(AppRoutes.dashboard);
            },
            child: const Text('Finish setup'),
          ),
        ],
      ),
    );
  }

  String _kindLabel(ConnectionKind kind) {
    return switch (kind) {
      ConnectionKind.longbridge => 'LongBridge',
      ConnectionKind.ibkr => 'IBKR',
      ConnectionKind.futu => 'Futu',
      ConnectionKind.binance => 'Binance',
      ConnectionKind.manual => 'Manual',
    };
  }
}

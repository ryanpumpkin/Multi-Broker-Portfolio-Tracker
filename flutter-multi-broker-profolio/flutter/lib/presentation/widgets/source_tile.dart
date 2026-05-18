import 'package:flutter/material.dart';

import '../../domain/domain.dart';

class SourceTile extends StatelessWidget {
  const SourceTile({
    required this.connection,
    this.trailing,
    this.onTap,
    super.key,
  });

  final Connection connection;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final status = connection.status;
    final (dotColor, label) = switch (status) {
      ConnectionStatus.ok => (Colors.green, 'Healthy'),
      ConnectionStatus.error => (Colors.red, 'Issue'),
      ConnectionStatus.disabled => (Colors.grey, 'Disabled'),
      ConnectionStatus.unknown => (Colors.orange, 'Unknown'),
    };

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Text(_shortKind(connection.kind)),
        ),
        title: Text(connection.label),
        subtitle: Row(
          children: [
            Icon(Icons.circle, size: 10, color: dotColor),
            const SizedBox(width: 6),
            Text(label),
          ],
        ),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

  String _shortKind(ConnectionKind kind) {
    return switch (kind) {
      ConnectionKind.longbridge => 'LB',
      ConnectionKind.ibkr => 'IB',
      ConnectionKind.futu => 'FT',
      ConnectionKind.binance => 'BN',
      ConnectionKind.manual => 'MN',
    };
  }
}

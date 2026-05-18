import 'package:flutter/material.dart';

import '../../domain/domain.dart';

class SourceTile extends StatelessWidget {
  const SourceTile({
    required this.connection,
    this.trailing,
    this.onTap,
    this.now,
    super.key,
  });

  final Connection connection;
  final Widget? trailing;
  final VoidCallback? onTap;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final status = connection.status;
    final (dotColor, label) = switch (status) {
      ConnectionStatus.ok => (Colors.green, 'Healthy'),
      ConnectionStatus.error => (Colors.red, 'Issue'),
      ConnectionStatus.disabled => (Colors.grey, 'Disabled'),
      ConnectionStatus.unknown => (Colors.orange, 'Unknown'),
    };

    final errorMessage = connection.errorMessage;
    final isError = status == ConnectionStatus.error &&
        errorMessage != null &&
        errorMessage.trim().isNotEmpty;

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              child: Text(_shortKind(connection.kind)),
            ),
            title: Text(connection.label),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.circle, size: 10, color: dotColor),
                    const SizedBox(width: 6),
                    if (isError)
                      Tooltip(
                        message: errorMessage,
                        child: Text(label),
                      )
                    else
                      Text(label),
                  ],
                ),
                const SizedBox(height: 4),
                Text(_formatSyncLabel(connection.lastSyncAt, now: now)),
              ],
            ),
            trailing: trailing,
            onTap: onTap,
          ),
          if (isError)
            ExpansionTile(
              key: Key('source_error_${connection.id}'),
              title: const Text('Error details'),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(errorMessage),
                  ),
                ),
              ],
            ),
        ],
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

  String _formatSyncLabel(DateTime? at, {DateTime? now}) {
    if (at == null) return 'never synced';
    final current = (now ?? DateTime.now()).toUtc();
    final syncedAt = at.toUtc();
    if (syncedAt.isAfter(current)) return 'synced just now';

    final delta = current.difference(syncedAt);
    if (delta.inSeconds < 30) return 'synced just now';
    if (delta.inMinutes < 60) return 'synced ${delta.inMinutes} min ago';
    if (delta.inHours < 24) return 'synced ${delta.inHours} hr ago';

    final days = delta.inDays;
    return 'synced $days day${days == 1 ? '' : 's'} ago';
  }
}

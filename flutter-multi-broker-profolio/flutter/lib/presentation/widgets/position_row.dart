import 'package:flutter/material.dart';

import '../../domain/domain.dart';
import 'currency_amount.dart';
import 'pnl_badge.dart';

class PositionRow extends StatelessWidget {
  const PositionRow({
    required this.position,
    this.baseValue,
    this.basePnl,
    this.baseCurrency,
    this.onTap,
    super.key,
  });

  final Position position;
  final double? baseValue;
  final double? basePnl;
  final String? baseCurrency;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final pct = position.marketValue == 0
        ? 0.0
        : 100 * (position.unrealizedPnl / position.marketValue);

    return ListTile(
      onTap: onTap,
      title: Text(position.symbol),
      subtitle: Text('${position.name} · Qty ${position.quantity}'),
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          CurrencyAmount(
            amount: position.marketValue,
            currency: position.currency,
            baseAmount: baseValue,
            baseCurrency: baseCurrency,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          PnlBadge(
            amount: basePnl ?? position.unrealizedPnl,
            percent: pct,
            currency: baseCurrency ?? position.currency,
          ),
        ],
      ),
    );
  }
}

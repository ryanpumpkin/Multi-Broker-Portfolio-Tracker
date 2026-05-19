import 'package:flutter/material.dart';

import '../../domain/domain.dart';
import 'currency_amount.dart';
import 'pnl_badge.dart';

class PositionRow extends StatelessWidget {
  const PositionRow({
    required this.position,
    this.currentPrice,
    this.baseValue,
    this.basePnl,
    this.baseCurrency,
    this.onTap,
    super.key,
  });

  final Position position;
  final double? currentPrice;
  final double? baseValue;
  final double? basePnl;
  final String? baseCurrency;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final effectivePrice = currentPrice ?? position.currentPrice;
    final effectiveMarketValue = position.quantity * effectivePrice;
    final effectivePnl = (effectivePrice - position.avgCost) * position.quantity;
    final pct = effectiveMarketValue == 0
        ? 0.0
        : 100 * (effectivePnl / effectiveMarketValue);

    return ListTile(
      onTap: onTap,
      title: Text(position.symbol),
      subtitle: Text(
        '${position.name} · Qty ${position.quantity} · Px ${effectivePrice.toStringAsFixed(2)} ${position.currency}',
      ),
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          CurrencyAmount(
            amount: effectiveMarketValue,
            currency: position.currency,
            baseAmount: baseValue,
            baseCurrency: baseCurrency,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          PnlBadge(
            amount: basePnl ?? effectivePnl,
            percent: pct,
            currency: baseCurrency ?? position.currency,
          ),
        ],
      ),
    );
  }
}

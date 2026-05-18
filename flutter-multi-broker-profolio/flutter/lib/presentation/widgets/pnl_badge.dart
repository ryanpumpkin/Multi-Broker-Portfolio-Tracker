import 'package:flutter/material.dart';

class PnlBadge extends StatelessWidget {
  const PnlBadge({
    required this.amount,
    this.percent,
    this.currency,
    super.key,
  });

  final double amount;
  final double? percent;
  final String? currency;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final positive = amount >= 0;
    final tone = positive ? scheme.primary : scheme.error;
    final sign = positive ? '+' : '-';
    final currencyPrefix = currency == null ? '' : '$currency ';
    final absAmount = amount.abs().toStringAsFixed(2);
    final pctText =
        percent == null ? '' : ' ($sign${percent!.abs().toStringAsFixed(2)}%)';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          '$sign$currencyPrefix$absAmount$pctText',
          style: TextStyle(
            color: tone,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

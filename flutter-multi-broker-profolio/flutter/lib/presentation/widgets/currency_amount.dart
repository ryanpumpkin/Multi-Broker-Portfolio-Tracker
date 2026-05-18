import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/domain.dart';
import '../../state/settings_provider.dart';

class CurrencyAmount extends ConsumerWidget {
  const CurrencyAmount({
    required this.amount,
    required this.currency,
    this.baseAmount,
    this.baseCurrency,
    this.mode,
    this.style,
    super.key,
  });

  final double amount;
  final String currency;
  final double? baseAmount;
  final String? baseCurrency;
  final CurrencyMode? mode;
  final TextStyle? style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).value;
    final resolvedMode = mode ?? settings?.currencyMode ?? CurrencyMode.base;
    final resolvedBaseCurrency =
        baseCurrency ?? settings?.baseCurrency ?? currency;

    final displayCurrency =
        resolvedMode == CurrencyMode.base ? resolvedBaseCurrency : currency;
    final rawValue =
        resolvedMode == CurrencyMode.base ? (baseAmount ?? amount) : amount;

    final locale = Localizations.localeOf(context).toLanguageTag();
    final formatter = NumberFormat.simpleCurrency(
      locale: locale,
      name: displayCurrency,
      decimalDigits: 2,
    );

    return Text(
      formatter.format(rawValue),
      style: style,
    );
  }
}

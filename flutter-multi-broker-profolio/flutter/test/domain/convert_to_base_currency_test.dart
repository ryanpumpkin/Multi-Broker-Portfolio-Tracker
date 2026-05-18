import 'package:flutter_test/flutter_test.dart';
import 'package:multi_broker_portfolio/domain/domain.dart';

import 'fakes.dart';

void main() {
  group('ConvertToBaseCurrency', () {
    test('returns value unchanged when currencies match', () async {
      final uc = ConvertToBaseCurrency(FakeFxRepository(const {}));
      final v = await uc(
        value: 123.45,
        fromCurrency: 'USD',
        baseCurrency: 'USD',
      );
      expect(v, 123.45);
    });

    test('applies fx rate for cross-currency', () async {
      final uc = ConvertToBaseCurrency(FakeFxRepository(const {'USD/HKD': 7.8}));
      final v = await uc(
        value: 100,
        fromCurrency: 'USD',
        baseCurrency: 'HKD',
      );
      expect(v, closeTo(780, 1e-9));
    });

    test('returns null when no rate is available', () async {
      final uc = ConvertToBaseCurrency(FakeFxRepository(const {}));
      final v = await uc(
        value: 10,
        fromCurrency: 'USD',
        baseCurrency: 'HKD',
      );
      expect(v, isNull);
    });
  });
}

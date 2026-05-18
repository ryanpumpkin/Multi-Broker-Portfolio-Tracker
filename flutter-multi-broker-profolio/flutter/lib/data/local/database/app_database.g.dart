// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $PositionsCacheTable extends PositionsCache
    with TableInfo<$PositionsCacheTable, PositionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PositionsCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sourceIdMeta =
      const VerificationMeta('sourceId');
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
      'source_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _symbolMeta = const VerificationMeta('symbol');
  @override
  late final GeneratedColumn<String> symbol = GeneratedColumn<String>(
      'symbol', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _assetClassMeta =
      const VerificationMeta('assetClass');
  @override
  late final GeneratedColumn<String> assetClass = GeneratedColumn<String>(
      'asset_class', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _quantityMeta =
      const VerificationMeta('quantity');
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
      'quantity', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _avgCostMeta =
      const VerificationMeta('avgCost');
  @override
  late final GeneratedColumn<double> avgCost = GeneratedColumn<double>(
      'avg_cost', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _currentPriceMeta =
      const VerificationMeta('currentPrice');
  @override
  late final GeneratedColumn<double> currentPrice = GeneratedColumn<double>(
      'current_price', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _currencyMeta =
      const VerificationMeta('currency');
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
      'currency', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _marketValueMeta =
      const VerificationMeta('marketValue');
  @override
  late final GeneratedColumn<double> marketValue = GeneratedColumn<double>(
      'market_value', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _unrealizedPnlMeta =
      const VerificationMeta('unrealizedPnl');
  @override
  late final GeneratedColumn<double> unrealizedPnl = GeneratedColumn<double>(
      'unrealized_pnl', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _cachedAtMeta =
      const VerificationMeta('cachedAt');
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
      'cached_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        sourceId,
        symbol,
        name,
        assetClass,
        quantity,
        avgCost,
        currentPrice,
        currency,
        marketValue,
        unrealizedPnl,
        cachedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'positions_cache';
  @override
  VerificationContext validateIntegrity(Insertable<PositionRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('source_id')) {
      context.handle(_sourceIdMeta,
          sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta));
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('symbol')) {
      context.handle(_symbolMeta,
          symbol.isAcceptableOrUnknown(data['symbol']!, _symbolMeta));
    } else if (isInserting) {
      context.missing(_symbolMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('asset_class')) {
      context.handle(
          _assetClassMeta,
          assetClass.isAcceptableOrUnknown(
              data['asset_class']!, _assetClassMeta));
    } else if (isInserting) {
      context.missing(_assetClassMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(_quantityMeta,
          quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta));
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('avg_cost')) {
      context.handle(_avgCostMeta,
          avgCost.isAcceptableOrUnknown(data['avg_cost']!, _avgCostMeta));
    } else if (isInserting) {
      context.missing(_avgCostMeta);
    }
    if (data.containsKey('current_price')) {
      context.handle(
          _currentPriceMeta,
          currentPrice.isAcceptableOrUnknown(
              data['current_price']!, _currentPriceMeta));
    } else if (isInserting) {
      context.missing(_currentPriceMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(_currencyMeta,
          currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta));
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('market_value')) {
      context.handle(
          _marketValueMeta,
          marketValue.isAcceptableOrUnknown(
              data['market_value']!, _marketValueMeta));
    } else if (isInserting) {
      context.missing(_marketValueMeta);
    }
    if (data.containsKey('unrealized_pnl')) {
      context.handle(
          _unrealizedPnlMeta,
          unrealizedPnl.isAcceptableOrUnknown(
              data['unrealized_pnl']!, _unrealizedPnlMeta));
    } else if (isInserting) {
      context.missing(_unrealizedPnlMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(_cachedAtMeta,
          cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta));
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sourceId, symbol};
  @override
  PositionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PositionRow(
      sourceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source_id'])!,
      symbol: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}symbol'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      assetClass: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}asset_class'])!,
      quantity: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}quantity'])!,
      avgCost: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}avg_cost'])!,
      currentPrice: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}current_price'])!,
      currency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency'])!,
      marketValue: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}market_value'])!,
      unrealizedPnl: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}unrealized_pnl'])!,
      cachedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}cached_at'])!,
    );
  }

  @override
  $PositionsCacheTable createAlias(String alias) {
    return $PositionsCacheTable(attachedDatabase, alias);
  }
}

class PositionRow extends DataClass implements Insertable<PositionRow> {
  final String sourceId;
  final String symbol;
  final String name;
  final String assetClass;
  final double quantity;
  final double avgCost;
  final double currentPrice;
  final String currency;
  final double marketValue;
  final double unrealizedPnl;
  final DateTime cachedAt;
  const PositionRow(
      {required this.sourceId,
      required this.symbol,
      required this.name,
      required this.assetClass,
      required this.quantity,
      required this.avgCost,
      required this.currentPrice,
      required this.currency,
      required this.marketValue,
      required this.unrealizedPnl,
      required this.cachedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['source_id'] = Variable<String>(sourceId);
    map['symbol'] = Variable<String>(symbol);
    map['name'] = Variable<String>(name);
    map['asset_class'] = Variable<String>(assetClass);
    map['quantity'] = Variable<double>(quantity);
    map['avg_cost'] = Variable<double>(avgCost);
    map['current_price'] = Variable<double>(currentPrice);
    map['currency'] = Variable<String>(currency);
    map['market_value'] = Variable<double>(marketValue);
    map['unrealized_pnl'] = Variable<double>(unrealizedPnl);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  PositionsCacheCompanion toCompanion(bool nullToAbsent) {
    return PositionsCacheCompanion(
      sourceId: Value(sourceId),
      symbol: Value(symbol),
      name: Value(name),
      assetClass: Value(assetClass),
      quantity: Value(quantity),
      avgCost: Value(avgCost),
      currentPrice: Value(currentPrice),
      currency: Value(currency),
      marketValue: Value(marketValue),
      unrealizedPnl: Value(unrealizedPnl),
      cachedAt: Value(cachedAt),
    );
  }

  factory PositionRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PositionRow(
      sourceId: serializer.fromJson<String>(json['sourceId']),
      symbol: serializer.fromJson<String>(json['symbol']),
      name: serializer.fromJson<String>(json['name']),
      assetClass: serializer.fromJson<String>(json['assetClass']),
      quantity: serializer.fromJson<double>(json['quantity']),
      avgCost: serializer.fromJson<double>(json['avgCost']),
      currentPrice: serializer.fromJson<double>(json['currentPrice']),
      currency: serializer.fromJson<String>(json['currency']),
      marketValue: serializer.fromJson<double>(json['marketValue']),
      unrealizedPnl: serializer.fromJson<double>(json['unrealizedPnl']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sourceId': serializer.toJson<String>(sourceId),
      'symbol': serializer.toJson<String>(symbol),
      'name': serializer.toJson<String>(name),
      'assetClass': serializer.toJson<String>(assetClass),
      'quantity': serializer.toJson<double>(quantity),
      'avgCost': serializer.toJson<double>(avgCost),
      'currentPrice': serializer.toJson<double>(currentPrice),
      'currency': serializer.toJson<String>(currency),
      'marketValue': serializer.toJson<double>(marketValue),
      'unrealizedPnl': serializer.toJson<double>(unrealizedPnl),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  PositionRow copyWith(
          {String? sourceId,
          String? symbol,
          String? name,
          String? assetClass,
          double? quantity,
          double? avgCost,
          double? currentPrice,
          String? currency,
          double? marketValue,
          double? unrealizedPnl,
          DateTime? cachedAt}) =>
      PositionRow(
        sourceId: sourceId ?? this.sourceId,
        symbol: symbol ?? this.symbol,
        name: name ?? this.name,
        assetClass: assetClass ?? this.assetClass,
        quantity: quantity ?? this.quantity,
        avgCost: avgCost ?? this.avgCost,
        currentPrice: currentPrice ?? this.currentPrice,
        currency: currency ?? this.currency,
        marketValue: marketValue ?? this.marketValue,
        unrealizedPnl: unrealizedPnl ?? this.unrealizedPnl,
        cachedAt: cachedAt ?? this.cachedAt,
      );
  PositionRow copyWithCompanion(PositionsCacheCompanion data) {
    return PositionRow(
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      symbol: data.symbol.present ? data.symbol.value : this.symbol,
      name: data.name.present ? data.name.value : this.name,
      assetClass:
          data.assetClass.present ? data.assetClass.value : this.assetClass,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      avgCost: data.avgCost.present ? data.avgCost.value : this.avgCost,
      currentPrice: data.currentPrice.present
          ? data.currentPrice.value
          : this.currentPrice,
      currency: data.currency.present ? data.currency.value : this.currency,
      marketValue:
          data.marketValue.present ? data.marketValue.value : this.marketValue,
      unrealizedPnl: data.unrealizedPnl.present
          ? data.unrealizedPnl.value
          : this.unrealizedPnl,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PositionRow(')
          ..write('sourceId: $sourceId, ')
          ..write('symbol: $symbol, ')
          ..write('name: $name, ')
          ..write('assetClass: $assetClass, ')
          ..write('quantity: $quantity, ')
          ..write('avgCost: $avgCost, ')
          ..write('currentPrice: $currentPrice, ')
          ..write('currency: $currency, ')
          ..write('marketValue: $marketValue, ')
          ..write('unrealizedPnl: $unrealizedPnl, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(sourceId, symbol, name, assetClass, quantity,
      avgCost, currentPrice, currency, marketValue, unrealizedPnl, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PositionRow &&
          other.sourceId == this.sourceId &&
          other.symbol == this.symbol &&
          other.name == this.name &&
          other.assetClass == this.assetClass &&
          other.quantity == this.quantity &&
          other.avgCost == this.avgCost &&
          other.currentPrice == this.currentPrice &&
          other.currency == this.currency &&
          other.marketValue == this.marketValue &&
          other.unrealizedPnl == this.unrealizedPnl &&
          other.cachedAt == this.cachedAt);
}

class PositionsCacheCompanion extends UpdateCompanion<PositionRow> {
  final Value<String> sourceId;
  final Value<String> symbol;
  final Value<String> name;
  final Value<String> assetClass;
  final Value<double> quantity;
  final Value<double> avgCost;
  final Value<double> currentPrice;
  final Value<String> currency;
  final Value<double> marketValue;
  final Value<double> unrealizedPnl;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const PositionsCacheCompanion({
    this.sourceId = const Value.absent(),
    this.symbol = const Value.absent(),
    this.name = const Value.absent(),
    this.assetClass = const Value.absent(),
    this.quantity = const Value.absent(),
    this.avgCost = const Value.absent(),
    this.currentPrice = const Value.absent(),
    this.currency = const Value.absent(),
    this.marketValue = const Value.absent(),
    this.unrealizedPnl = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PositionsCacheCompanion.insert({
    required String sourceId,
    required String symbol,
    required String name,
    required String assetClass,
    required double quantity,
    required double avgCost,
    required double currentPrice,
    required String currency,
    required double marketValue,
    required double unrealizedPnl,
    required DateTime cachedAt,
    this.rowid = const Value.absent(),
  })  : sourceId = Value(sourceId),
        symbol = Value(symbol),
        name = Value(name),
        assetClass = Value(assetClass),
        quantity = Value(quantity),
        avgCost = Value(avgCost),
        currentPrice = Value(currentPrice),
        currency = Value(currency),
        marketValue = Value(marketValue),
        unrealizedPnl = Value(unrealizedPnl),
        cachedAt = Value(cachedAt);
  static Insertable<PositionRow> custom({
    Expression<String>? sourceId,
    Expression<String>? symbol,
    Expression<String>? name,
    Expression<String>? assetClass,
    Expression<double>? quantity,
    Expression<double>? avgCost,
    Expression<double>? currentPrice,
    Expression<String>? currency,
    Expression<double>? marketValue,
    Expression<double>? unrealizedPnl,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sourceId != null) 'source_id': sourceId,
      if (symbol != null) 'symbol': symbol,
      if (name != null) 'name': name,
      if (assetClass != null) 'asset_class': assetClass,
      if (quantity != null) 'quantity': quantity,
      if (avgCost != null) 'avg_cost': avgCost,
      if (currentPrice != null) 'current_price': currentPrice,
      if (currency != null) 'currency': currency,
      if (marketValue != null) 'market_value': marketValue,
      if (unrealizedPnl != null) 'unrealized_pnl': unrealizedPnl,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PositionsCacheCompanion copyWith(
      {Value<String>? sourceId,
      Value<String>? symbol,
      Value<String>? name,
      Value<String>? assetClass,
      Value<double>? quantity,
      Value<double>? avgCost,
      Value<double>? currentPrice,
      Value<String>? currency,
      Value<double>? marketValue,
      Value<double>? unrealizedPnl,
      Value<DateTime>? cachedAt,
      Value<int>? rowid}) {
    return PositionsCacheCompanion(
      sourceId: sourceId ?? this.sourceId,
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      assetClass: assetClass ?? this.assetClass,
      quantity: quantity ?? this.quantity,
      avgCost: avgCost ?? this.avgCost,
      currentPrice: currentPrice ?? this.currentPrice,
      currency: currency ?? this.currency,
      marketValue: marketValue ?? this.marketValue,
      unrealizedPnl: unrealizedPnl ?? this.unrealizedPnl,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (symbol.present) {
      map['symbol'] = Variable<String>(symbol.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (assetClass.present) {
      map['asset_class'] = Variable<String>(assetClass.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (avgCost.present) {
      map['avg_cost'] = Variable<double>(avgCost.value);
    }
    if (currentPrice.present) {
      map['current_price'] = Variable<double>(currentPrice.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (marketValue.present) {
      map['market_value'] = Variable<double>(marketValue.value);
    }
    if (unrealizedPnl.present) {
      map['unrealized_pnl'] = Variable<double>(unrealizedPnl.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PositionsCacheCompanion(')
          ..write('sourceId: $sourceId, ')
          ..write('symbol: $symbol, ')
          ..write('name: $name, ')
          ..write('assetClass: $assetClass, ')
          ..write('quantity: $quantity, ')
          ..write('avgCost: $avgCost, ')
          ..write('currentPrice: $currentPrice, ')
          ..write('currency: $currency, ')
          ..write('marketValue: $marketValue, ')
          ..write('unrealizedPnl: $unrealizedPnl, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransactionsCacheTable extends TransactionsCache
    with TableInfo<$TransactionsCacheTable, TransactionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sourceIdMeta =
      const VerificationMeta('sourceId');
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
      'source_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _timeMeta = const VerificationMeta('time');
  @override
  late final GeneratedColumn<DateTime> time = GeneratedColumn<DateTime>(
      'time', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _symbolMeta = const VerificationMeta('symbol');
  @override
  late final GeneratedColumn<String> symbol = GeneratedColumn<String>(
      'symbol', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _quantityMeta =
      const VerificationMeta('quantity');
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
      'quantity', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<double> price = GeneratedColumn<double>(
      'price', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _currencyMeta =
      const VerificationMeta('currency');
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
      'currency', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _feeMeta = const VerificationMeta('fee');
  @override
  late final GeneratedColumn<double> fee = GeneratedColumn<double>(
      'fee', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _cachedAtMeta =
      const VerificationMeta('cachedAt');
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
      'cached_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        sourceId,
        time,
        type,
        symbol,
        quantity,
        price,
        currency,
        fee,
        cachedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions_cache';
  @override
  VerificationContext validateIntegrity(Insertable<TransactionRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('source_id')) {
      context.handle(_sourceIdMeta,
          sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta));
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('time')) {
      context.handle(
          _timeMeta, time.isAcceptableOrUnknown(data['time']!, _timeMeta));
    } else if (isInserting) {
      context.missing(_timeMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('symbol')) {
      context.handle(_symbolMeta,
          symbol.isAcceptableOrUnknown(data['symbol']!, _symbolMeta));
    } else if (isInserting) {
      context.missing(_symbolMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(_quantityMeta,
          quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta));
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('price')) {
      context.handle(
          _priceMeta, price.isAcceptableOrUnknown(data['price']!, _priceMeta));
    } else if (isInserting) {
      context.missing(_priceMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(_currencyMeta,
          currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta));
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('fee')) {
      context.handle(
          _feeMeta, fee.isAcceptableOrUnknown(data['fee']!, _feeMeta));
    } else if (isInserting) {
      context.missing(_feeMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(_cachedAtMeta,
          cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta));
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransactionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      sourceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source_id'])!,
      time: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}time'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      symbol: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}symbol'])!,
      quantity: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}quantity'])!,
      price: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}price'])!,
      currency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency'])!,
      fee: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}fee'])!,
      cachedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}cached_at'])!,
    );
  }

  @override
  $TransactionsCacheTable createAlias(String alias) {
    return $TransactionsCacheTable(attachedDatabase, alias);
  }
}

class TransactionRow extends DataClass implements Insertable<TransactionRow> {
  final String id;
  final String sourceId;
  final DateTime time;
  final String type;
  final String symbol;
  final double quantity;
  final double price;
  final String currency;
  final double fee;
  final DateTime cachedAt;
  const TransactionRow(
      {required this.id,
      required this.sourceId,
      required this.time,
      required this.type,
      required this.symbol,
      required this.quantity,
      required this.price,
      required this.currency,
      required this.fee,
      required this.cachedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['source_id'] = Variable<String>(sourceId);
    map['time'] = Variable<DateTime>(time);
    map['type'] = Variable<String>(type);
    map['symbol'] = Variable<String>(symbol);
    map['quantity'] = Variable<double>(quantity);
    map['price'] = Variable<double>(price);
    map['currency'] = Variable<String>(currency);
    map['fee'] = Variable<double>(fee);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  TransactionsCacheCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCacheCompanion(
      id: Value(id),
      sourceId: Value(sourceId),
      time: Value(time),
      type: Value(type),
      symbol: Value(symbol),
      quantity: Value(quantity),
      price: Value(price),
      currency: Value(currency),
      fee: Value(fee),
      cachedAt: Value(cachedAt),
    );
  }

  factory TransactionRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionRow(
      id: serializer.fromJson<String>(json['id']),
      sourceId: serializer.fromJson<String>(json['sourceId']),
      time: serializer.fromJson<DateTime>(json['time']),
      type: serializer.fromJson<String>(json['type']),
      symbol: serializer.fromJson<String>(json['symbol']),
      quantity: serializer.fromJson<double>(json['quantity']),
      price: serializer.fromJson<double>(json['price']),
      currency: serializer.fromJson<String>(json['currency']),
      fee: serializer.fromJson<double>(json['fee']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sourceId': serializer.toJson<String>(sourceId),
      'time': serializer.toJson<DateTime>(time),
      'type': serializer.toJson<String>(type),
      'symbol': serializer.toJson<String>(symbol),
      'quantity': serializer.toJson<double>(quantity),
      'price': serializer.toJson<double>(price),
      'currency': serializer.toJson<String>(currency),
      'fee': serializer.toJson<double>(fee),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  TransactionRow copyWith(
          {String? id,
          String? sourceId,
          DateTime? time,
          String? type,
          String? symbol,
          double? quantity,
          double? price,
          String? currency,
          double? fee,
          DateTime? cachedAt}) =>
      TransactionRow(
        id: id ?? this.id,
        sourceId: sourceId ?? this.sourceId,
        time: time ?? this.time,
        type: type ?? this.type,
        symbol: symbol ?? this.symbol,
        quantity: quantity ?? this.quantity,
        price: price ?? this.price,
        currency: currency ?? this.currency,
        fee: fee ?? this.fee,
        cachedAt: cachedAt ?? this.cachedAt,
      );
  TransactionRow copyWithCompanion(TransactionsCacheCompanion data) {
    return TransactionRow(
      id: data.id.present ? data.id.value : this.id,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      time: data.time.present ? data.time.value : this.time,
      type: data.type.present ? data.type.value : this.type,
      symbol: data.symbol.present ? data.symbol.value : this.symbol,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      price: data.price.present ? data.price.value : this.price,
      currency: data.currency.present ? data.currency.value : this.currency,
      fee: data.fee.present ? data.fee.value : this.fee,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransactionRow(')
          ..write('id: $id, ')
          ..write('sourceId: $sourceId, ')
          ..write('time: $time, ')
          ..write('type: $type, ')
          ..write('symbol: $symbol, ')
          ..write('quantity: $quantity, ')
          ..write('price: $price, ')
          ..write('currency: $currency, ')
          ..write('fee: $fee, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, sourceId, time, type, symbol, quantity,
      price, currency, fee, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionRow &&
          other.id == this.id &&
          other.sourceId == this.sourceId &&
          other.time == this.time &&
          other.type == this.type &&
          other.symbol == this.symbol &&
          other.quantity == this.quantity &&
          other.price == this.price &&
          other.currency == this.currency &&
          other.fee == this.fee &&
          other.cachedAt == this.cachedAt);
}

class TransactionsCacheCompanion extends UpdateCompanion<TransactionRow> {
  final Value<String> id;
  final Value<String> sourceId;
  final Value<DateTime> time;
  final Value<String> type;
  final Value<String> symbol;
  final Value<double> quantity;
  final Value<double> price;
  final Value<String> currency;
  final Value<double> fee;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const TransactionsCacheCompanion({
    this.id = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.time = const Value.absent(),
    this.type = const Value.absent(),
    this.symbol = const Value.absent(),
    this.quantity = const Value.absent(),
    this.price = const Value.absent(),
    this.currency = const Value.absent(),
    this.fee = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionsCacheCompanion.insert({
    required String id,
    required String sourceId,
    required DateTime time,
    required String type,
    required String symbol,
    required double quantity,
    required double price,
    required String currency,
    required double fee,
    required DateTime cachedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        sourceId = Value(sourceId),
        time = Value(time),
        type = Value(type),
        symbol = Value(symbol),
        quantity = Value(quantity),
        price = Value(price),
        currency = Value(currency),
        fee = Value(fee),
        cachedAt = Value(cachedAt);
  static Insertable<TransactionRow> custom({
    Expression<String>? id,
    Expression<String>? sourceId,
    Expression<DateTime>? time,
    Expression<String>? type,
    Expression<String>? symbol,
    Expression<double>? quantity,
    Expression<double>? price,
    Expression<String>? currency,
    Expression<double>? fee,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourceId != null) 'source_id': sourceId,
      if (time != null) 'time': time,
      if (type != null) 'type': type,
      if (symbol != null) 'symbol': symbol,
      if (quantity != null) 'quantity': quantity,
      if (price != null) 'price': price,
      if (currency != null) 'currency': currency,
      if (fee != null) 'fee': fee,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionsCacheCompanion copyWith(
      {Value<String>? id,
      Value<String>? sourceId,
      Value<DateTime>? time,
      Value<String>? type,
      Value<String>? symbol,
      Value<double>? quantity,
      Value<double>? price,
      Value<String>? currency,
      Value<double>? fee,
      Value<DateTime>? cachedAt,
      Value<int>? rowid}) {
    return TransactionsCacheCompanion(
      id: id ?? this.id,
      sourceId: sourceId ?? this.sourceId,
      time: time ?? this.time,
      type: type ?? this.type,
      symbol: symbol ?? this.symbol,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      fee: fee ?? this.fee,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (time.present) {
      map['time'] = Variable<DateTime>(time.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (symbol.present) {
      map['symbol'] = Variable<String>(symbol.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (price.present) {
      map['price'] = Variable<double>(price.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (fee.present) {
      map['fee'] = Variable<double>(fee.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCacheCompanion(')
          ..write('id: $id, ')
          ..write('sourceId: $sourceId, ')
          ..write('time: $time, ')
          ..write('type: $type, ')
          ..write('symbol: $symbol, ')
          ..write('quantity: $quantity, ')
          ..write('price: $price, ')
          ..write('currency: $currency, ')
          ..write('fee: $fee, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FxRatesCacheTable extends FxRatesCache
    with TableInfo<$FxRatesCacheTable, FxRateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FxRatesCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _baseMeta = const VerificationMeta('base');
  @override
  late final GeneratedColumn<String> base = GeneratedColumn<String>(
      'base', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _quoteMeta = const VerificationMeta('quote');
  @override
  late final GeneratedColumn<String> quote = GeneratedColumn<String>(
      'quote', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _rateMeta = const VerificationMeta('rate');
  @override
  late final GeneratedColumn<double> rate = GeneratedColumn<double>(
      'rate', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _timestampMeta =
      const VerificationMeta('timestamp');
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
      'timestamp', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [base, quote, rate, timestamp];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'fx_rates_cache';
  @override
  VerificationContext validateIntegrity(Insertable<FxRateRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('base')) {
      context.handle(
          _baseMeta, base.isAcceptableOrUnknown(data['base']!, _baseMeta));
    } else if (isInserting) {
      context.missing(_baseMeta);
    }
    if (data.containsKey('quote')) {
      context.handle(
          _quoteMeta, quote.isAcceptableOrUnknown(data['quote']!, _quoteMeta));
    } else if (isInserting) {
      context.missing(_quoteMeta);
    }
    if (data.containsKey('rate')) {
      context.handle(
          _rateMeta, rate.isAcceptableOrUnknown(data['rate']!, _rateMeta));
    } else if (isInserting) {
      context.missing(_rateMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta));
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {base, quote};
  @override
  FxRateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FxRateRow(
      base: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}base'])!,
      quote: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}quote'])!,
      rate: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}rate'])!,
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}timestamp'])!,
    );
  }

  @override
  $FxRatesCacheTable createAlias(String alias) {
    return $FxRatesCacheTable(attachedDatabase, alias);
  }
}

class FxRateRow extends DataClass implements Insertable<FxRateRow> {
  final String base;
  final String quote;
  final double rate;
  final DateTime timestamp;
  const FxRateRow(
      {required this.base,
      required this.quote,
      required this.rate,
      required this.timestamp});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['base'] = Variable<String>(base);
    map['quote'] = Variable<String>(quote);
    map['rate'] = Variable<double>(rate);
    map['timestamp'] = Variable<DateTime>(timestamp);
    return map;
  }

  FxRatesCacheCompanion toCompanion(bool nullToAbsent) {
    return FxRatesCacheCompanion(
      base: Value(base),
      quote: Value(quote),
      rate: Value(rate),
      timestamp: Value(timestamp),
    );
  }

  factory FxRateRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FxRateRow(
      base: serializer.fromJson<String>(json['base']),
      quote: serializer.fromJson<String>(json['quote']),
      rate: serializer.fromJson<double>(json['rate']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'base': serializer.toJson<String>(base),
      'quote': serializer.toJson<String>(quote),
      'rate': serializer.toJson<double>(rate),
      'timestamp': serializer.toJson<DateTime>(timestamp),
    };
  }

  FxRateRow copyWith(
          {String? base, String? quote, double? rate, DateTime? timestamp}) =>
      FxRateRow(
        base: base ?? this.base,
        quote: quote ?? this.quote,
        rate: rate ?? this.rate,
        timestamp: timestamp ?? this.timestamp,
      );
  FxRateRow copyWithCompanion(FxRatesCacheCompanion data) {
    return FxRateRow(
      base: data.base.present ? data.base.value : this.base,
      quote: data.quote.present ? data.quote.value : this.quote,
      rate: data.rate.present ? data.rate.value : this.rate,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FxRateRow(')
          ..write('base: $base, ')
          ..write('quote: $quote, ')
          ..write('rate: $rate, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(base, quote, rate, timestamp);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FxRateRow &&
          other.base == this.base &&
          other.quote == this.quote &&
          other.rate == this.rate &&
          other.timestamp == this.timestamp);
}

class FxRatesCacheCompanion extends UpdateCompanion<FxRateRow> {
  final Value<String> base;
  final Value<String> quote;
  final Value<double> rate;
  final Value<DateTime> timestamp;
  final Value<int> rowid;
  const FxRatesCacheCompanion({
    this.base = const Value.absent(),
    this.quote = const Value.absent(),
    this.rate = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FxRatesCacheCompanion.insert({
    required String base,
    required String quote,
    required double rate,
    required DateTime timestamp,
    this.rowid = const Value.absent(),
  })  : base = Value(base),
        quote = Value(quote),
        rate = Value(rate),
        timestamp = Value(timestamp);
  static Insertable<FxRateRow> custom({
    Expression<String>? base,
    Expression<String>? quote,
    Expression<double>? rate,
    Expression<DateTime>? timestamp,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (base != null) 'base': base,
      if (quote != null) 'quote': quote,
      if (rate != null) 'rate': rate,
      if (timestamp != null) 'timestamp': timestamp,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FxRatesCacheCompanion copyWith(
      {Value<String>? base,
      Value<String>? quote,
      Value<double>? rate,
      Value<DateTime>? timestamp,
      Value<int>? rowid}) {
    return FxRatesCacheCompanion(
      base: base ?? this.base,
      quote: quote ?? this.quote,
      rate: rate ?? this.rate,
      timestamp: timestamp ?? this.timestamp,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (base.present) {
      map['base'] = Variable<String>(base.value);
    }
    if (quote.present) {
      map['quote'] = Variable<String>(quote.value);
    }
    if (rate.present) {
      map['rate'] = Variable<double>(rate.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FxRatesCacheCompanion(')
          ..write('base: $base, ')
          ..write('quote: $quote, ')
          ..write('rate: $rate, ')
          ..write('timestamp: $timestamp, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $QuotesCacheTable extends QuotesCache
    with TableInfo<$QuotesCacheTable, QuoteRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuotesCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _symbolMeta = const VerificationMeta('symbol');
  @override
  late final GeneratedColumn<String> symbol = GeneratedColumn<String>(
      'symbol', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<double> price = GeneratedColumn<double>(
      'price', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _currencyMeta =
      const VerificationMeta('currency');
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
      'currency', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _timestampMeta =
      const VerificationMeta('timestamp');
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
      'timestamp', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [symbol, price, currency, timestamp];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'quotes_cache';
  @override
  VerificationContext validateIntegrity(Insertable<QuoteRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('symbol')) {
      context.handle(_symbolMeta,
          symbol.isAcceptableOrUnknown(data['symbol']!, _symbolMeta));
    } else if (isInserting) {
      context.missing(_symbolMeta);
    }
    if (data.containsKey('price')) {
      context.handle(
          _priceMeta, price.isAcceptableOrUnknown(data['price']!, _priceMeta));
    } else if (isInserting) {
      context.missing(_priceMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(_currencyMeta,
          currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta));
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta));
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {symbol};
  @override
  QuoteRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuoteRow(
      symbol: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}symbol'])!,
      price: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}price'])!,
      currency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency'])!,
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}timestamp'])!,
    );
  }

  @override
  $QuotesCacheTable createAlias(String alias) {
    return $QuotesCacheTable(attachedDatabase, alias);
  }
}

class QuoteRow extends DataClass implements Insertable<QuoteRow> {
  final String symbol;
  final double price;
  final String currency;
  final DateTime timestamp;
  const QuoteRow(
      {required this.symbol,
      required this.price,
      required this.currency,
      required this.timestamp});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['symbol'] = Variable<String>(symbol);
    map['price'] = Variable<double>(price);
    map['currency'] = Variable<String>(currency);
    map['timestamp'] = Variable<DateTime>(timestamp);
    return map;
  }

  QuotesCacheCompanion toCompanion(bool nullToAbsent) {
    return QuotesCacheCompanion(
      symbol: Value(symbol),
      price: Value(price),
      currency: Value(currency),
      timestamp: Value(timestamp),
    );
  }

  factory QuoteRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuoteRow(
      symbol: serializer.fromJson<String>(json['symbol']),
      price: serializer.fromJson<double>(json['price']),
      currency: serializer.fromJson<String>(json['currency']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'symbol': serializer.toJson<String>(symbol),
      'price': serializer.toJson<double>(price),
      'currency': serializer.toJson<String>(currency),
      'timestamp': serializer.toJson<DateTime>(timestamp),
    };
  }

  QuoteRow copyWith(
          {String? symbol,
          double? price,
          String? currency,
          DateTime? timestamp}) =>
      QuoteRow(
        symbol: symbol ?? this.symbol,
        price: price ?? this.price,
        currency: currency ?? this.currency,
        timestamp: timestamp ?? this.timestamp,
      );
  QuoteRow copyWithCompanion(QuotesCacheCompanion data) {
    return QuoteRow(
      symbol: data.symbol.present ? data.symbol.value : this.symbol,
      price: data.price.present ? data.price.value : this.price,
      currency: data.currency.present ? data.currency.value : this.currency,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuoteRow(')
          ..write('symbol: $symbol, ')
          ..write('price: $price, ')
          ..write('currency: $currency, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(symbol, price, currency, timestamp);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuoteRow &&
          other.symbol == this.symbol &&
          other.price == this.price &&
          other.currency == this.currency &&
          other.timestamp == this.timestamp);
}

class QuotesCacheCompanion extends UpdateCompanion<QuoteRow> {
  final Value<String> symbol;
  final Value<double> price;
  final Value<String> currency;
  final Value<DateTime> timestamp;
  final Value<int> rowid;
  const QuotesCacheCompanion({
    this.symbol = const Value.absent(),
    this.price = const Value.absent(),
    this.currency = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QuotesCacheCompanion.insert({
    required String symbol,
    required double price,
    required String currency,
    required DateTime timestamp,
    this.rowid = const Value.absent(),
  })  : symbol = Value(symbol),
        price = Value(price),
        currency = Value(currency),
        timestamp = Value(timestamp);
  static Insertable<QuoteRow> custom({
    Expression<String>? symbol,
    Expression<double>? price,
    Expression<String>? currency,
    Expression<DateTime>? timestamp,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (symbol != null) 'symbol': symbol,
      if (price != null) 'price': price,
      if (currency != null) 'currency': currency,
      if (timestamp != null) 'timestamp': timestamp,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QuotesCacheCompanion copyWith(
      {Value<String>? symbol,
      Value<double>? price,
      Value<String>? currency,
      Value<DateTime>? timestamp,
      Value<int>? rowid}) {
    return QuotesCacheCompanion(
      symbol: symbol ?? this.symbol,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      timestamp: timestamp ?? this.timestamp,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (symbol.present) {
      map['symbol'] = Variable<String>(symbol.value);
    }
    if (price.present) {
      map['price'] = Variable<double>(price.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuotesCacheCompanion(')
          ..write('symbol: $symbol, ')
          ..write('price: $price, ')
          ..write('currency: $currency, ')
          ..write('timestamp: $timestamp, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ConnectionsMetaTable extends ConnectionsMeta
    with TableInfo<$ConnectionsMetaTable, ConnectionMetaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConnectionsMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
      'kind', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
      'label', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _credentialModeMeta =
      const VerificationMeta('credentialMode');
  @override
  late final GeneratedColumn<String> credentialMode = GeneratedColumn<String>(
      'credential_mode', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _lastSyncAtMeta =
      const VerificationMeta('lastSyncAt');
  @override
  late final GeneratedColumn<DateTime> lastSyncAt = GeneratedColumn<DateTime>(
      'last_sync_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, kind, label, status, credentialMode, lastSyncAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'connections_meta';
  @override
  VerificationContext validateIntegrity(Insertable<ConnectionMetaRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
          _kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
          _labelMeta, label.isAcceptableOrUnknown(data['label']!, _labelMeta));
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('credential_mode')) {
      context.handle(
          _credentialModeMeta,
          credentialMode.isAcceptableOrUnknown(
              data['credential_mode']!, _credentialModeMeta));
    } else if (isInserting) {
      context.missing(_credentialModeMeta);
    }
    if (data.containsKey('last_sync_at')) {
      context.handle(
          _lastSyncAtMeta,
          lastSyncAt.isAcceptableOrUnknown(
              data['last_sync_at']!, _lastSyncAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ConnectionMetaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConnectionMetaRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      kind: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      label: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}label'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      credentialMode: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}credential_mode'])!,
      lastSyncAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_sync_at']),
    );
  }

  @override
  $ConnectionsMetaTable createAlias(String alias) {
    return $ConnectionsMetaTable(attachedDatabase, alias);
  }
}

class ConnectionMetaRow extends DataClass
    implements Insertable<ConnectionMetaRow> {
  final String id;
  final String kind;
  final String label;
  final String status;
  final String credentialMode;
  final DateTime? lastSyncAt;
  const ConnectionMetaRow(
      {required this.id,
      required this.kind,
      required this.label,
      required this.status,
      required this.credentialMode,
      this.lastSyncAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['kind'] = Variable<String>(kind);
    map['label'] = Variable<String>(label);
    map['status'] = Variable<String>(status);
    map['credential_mode'] = Variable<String>(credentialMode);
    if (!nullToAbsent || lastSyncAt != null) {
      map['last_sync_at'] = Variable<DateTime>(lastSyncAt);
    }
    return map;
  }

  ConnectionsMetaCompanion toCompanion(bool nullToAbsent) {
    return ConnectionsMetaCompanion(
      id: Value(id),
      kind: Value(kind),
      label: Value(label),
      status: Value(status),
      credentialMode: Value(credentialMode),
      lastSyncAt: lastSyncAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncAt),
    );
  }

  factory ConnectionMetaRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConnectionMetaRow(
      id: serializer.fromJson<String>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      label: serializer.fromJson<String>(json['label']),
      status: serializer.fromJson<String>(json['status']),
      credentialMode: serializer.fromJson<String>(json['credentialMode']),
      lastSyncAt: serializer.fromJson<DateTime?>(json['lastSyncAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'kind': serializer.toJson<String>(kind),
      'label': serializer.toJson<String>(label),
      'status': serializer.toJson<String>(status),
      'credentialMode': serializer.toJson<String>(credentialMode),
      'lastSyncAt': serializer.toJson<DateTime?>(lastSyncAt),
    };
  }

  ConnectionMetaRow copyWith(
          {String? id,
          String? kind,
          String? label,
          String? status,
          String? credentialMode,
          Value<DateTime?> lastSyncAt = const Value.absent()}) =>
      ConnectionMetaRow(
        id: id ?? this.id,
        kind: kind ?? this.kind,
        label: label ?? this.label,
        status: status ?? this.status,
        credentialMode: credentialMode ?? this.credentialMode,
        lastSyncAt: lastSyncAt.present ? lastSyncAt.value : this.lastSyncAt,
      );
  ConnectionMetaRow copyWithCompanion(ConnectionsMetaCompanion data) {
    return ConnectionMetaRow(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      label: data.label.present ? data.label.value : this.label,
      status: data.status.present ? data.status.value : this.status,
      credentialMode: data.credentialMode.present
          ? data.credentialMode.value
          : this.credentialMode,
      lastSyncAt:
          data.lastSyncAt.present ? data.lastSyncAt.value : this.lastSyncAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConnectionMetaRow(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('label: $label, ')
          ..write('status: $status, ')
          ..write('credentialMode: $credentialMode, ')
          ..write('lastSyncAt: $lastSyncAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, kind, label, status, credentialMode, lastSyncAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConnectionMetaRow &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.label == this.label &&
          other.status == this.status &&
          other.credentialMode == this.credentialMode &&
          other.lastSyncAt == this.lastSyncAt);
}

class ConnectionsMetaCompanion extends UpdateCompanion<ConnectionMetaRow> {
  final Value<String> id;
  final Value<String> kind;
  final Value<String> label;
  final Value<String> status;
  final Value<String> credentialMode;
  final Value<DateTime?> lastSyncAt;
  final Value<int> rowid;
  const ConnectionsMetaCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.label = const Value.absent(),
    this.status = const Value.absent(),
    this.credentialMode = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConnectionsMetaCompanion.insert({
    required String id,
    required String kind,
    required String label,
    required String status,
    required String credentialMode,
    this.lastSyncAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        kind = Value(kind),
        label = Value(label),
        status = Value(status),
        credentialMode = Value(credentialMode);
  static Insertable<ConnectionMetaRow> custom({
    Expression<String>? id,
    Expression<String>? kind,
    Expression<String>? label,
    Expression<String>? status,
    Expression<String>? credentialMode,
    Expression<DateTime>? lastSyncAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (label != null) 'label': label,
      if (status != null) 'status': status,
      if (credentialMode != null) 'credential_mode': credentialMode,
      if (lastSyncAt != null) 'last_sync_at': lastSyncAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConnectionsMetaCompanion copyWith(
      {Value<String>? id,
      Value<String>? kind,
      Value<String>? label,
      Value<String>? status,
      Value<String>? credentialMode,
      Value<DateTime?>? lastSyncAt,
      Value<int>? rowid}) {
    return ConnectionsMetaCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      label: label ?? this.label,
      status: status ?? this.status,
      credentialMode: credentialMode ?? this.credentialMode,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (credentialMode.present) {
      map['credential_mode'] = Variable<String>(credentialMode.value);
    }
    if (lastSyncAt.present) {
      map['last_sync_at'] = Variable<DateTime>(lastSyncAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConnectionsMetaCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('label: $label, ')
          ..write('status: $status, ')
          ..write('credentialMode: $credentialMode, ')
          ..write('lastSyncAt: $lastSyncAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserPrefsTable extends UserPrefs
    with TableInfo<$UserPrefsTable, UserPrefRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserPrefsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_prefs';
  @override
  VerificationContext validateIntegrity(Insertable<UserPrefRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  UserPrefRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserPrefRow(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $UserPrefsTable createAlias(String alias) {
    return $UserPrefsTable(attachedDatabase, alias);
  }
}

class UserPrefRow extends DataClass implements Insertable<UserPrefRow> {
  final String key;
  final String value;
  const UserPrefRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  UserPrefsCompanion toCompanion(bool nullToAbsent) {
    return UserPrefsCompanion(
      key: Value(key),
      value: Value(value),
    );
  }

  factory UserPrefRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserPrefRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  UserPrefRow copyWith({String? key, String? value}) => UserPrefRow(
        key: key ?? this.key,
        value: value ?? this.value,
      );
  UserPrefRow copyWithCompanion(UserPrefsCompanion data) {
    return UserPrefRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserPrefRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserPrefRow &&
          other.key == this.key &&
          other.value == this.value);
}

class UserPrefsCompanion extends UpdateCompanion<UserPrefRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const UserPrefsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserPrefsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        value = Value(value);
  static Insertable<UserPrefRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserPrefsCompanion copyWith(
      {Value<String>? key, Value<String>? value, Value<int>? rowid}) {
    return UserPrefsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserPrefsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PositionsCacheTable positionsCache = $PositionsCacheTable(this);
  late final $TransactionsCacheTable transactionsCache =
      $TransactionsCacheTable(this);
  late final $FxRatesCacheTable fxRatesCache = $FxRatesCacheTable(this);
  late final $QuotesCacheTable quotesCache = $QuotesCacheTable(this);
  late final $ConnectionsMetaTable connectionsMeta =
      $ConnectionsMetaTable(this);
  late final $UserPrefsTable userPrefs = $UserPrefsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        positionsCache,
        transactionsCache,
        fxRatesCache,
        quotesCache,
        connectionsMeta,
        userPrefs
      ];
}

typedef $$PositionsCacheTableCreateCompanionBuilder = PositionsCacheCompanion
    Function({
  required String sourceId,
  required String symbol,
  required String name,
  required String assetClass,
  required double quantity,
  required double avgCost,
  required double currentPrice,
  required String currency,
  required double marketValue,
  required double unrealizedPnl,
  required DateTime cachedAt,
  Value<int> rowid,
});
typedef $$PositionsCacheTableUpdateCompanionBuilder = PositionsCacheCompanion
    Function({
  Value<String> sourceId,
  Value<String> symbol,
  Value<String> name,
  Value<String> assetClass,
  Value<double> quantity,
  Value<double> avgCost,
  Value<double> currentPrice,
  Value<String> currency,
  Value<double> marketValue,
  Value<double> unrealizedPnl,
  Value<DateTime> cachedAt,
  Value<int> rowid,
});

class $$PositionsCacheTableFilterComposer
    extends Composer<_$AppDatabase, $PositionsCacheTable> {
  $$PositionsCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get sourceId => $composableBuilder(
      column: $table.sourceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get symbol => $composableBuilder(
      column: $table.symbol, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get assetClass => $composableBuilder(
      column: $table.assetClass, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get avgCost => $composableBuilder(
      column: $table.avgCost, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get currentPrice => $composableBuilder(
      column: $table.currentPrice, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get marketValue => $composableBuilder(
      column: $table.marketValue, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get unrealizedPnl => $composableBuilder(
      column: $table.unrealizedPnl, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnFilters(column));
}

class $$PositionsCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $PositionsCacheTable> {
  $$PositionsCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get sourceId => $composableBuilder(
      column: $table.sourceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get symbol => $composableBuilder(
      column: $table.symbol, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get assetClass => $composableBuilder(
      column: $table.assetClass, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get avgCost => $composableBuilder(
      column: $table.avgCost, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get currentPrice => $composableBuilder(
      column: $table.currentPrice,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get marketValue => $composableBuilder(
      column: $table.marketValue, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get unrealizedPnl => $composableBuilder(
      column: $table.unrealizedPnl,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnOrderings(column));
}

class $$PositionsCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $PositionsCacheTable> {
  $$PositionsCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<String> get symbol =>
      $composableBuilder(column: $table.symbol, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get assetClass => $composableBuilder(
      column: $table.assetClass, builder: (column) => column);

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<double> get avgCost =>
      $composableBuilder(column: $table.avgCost, builder: (column) => column);

  GeneratedColumn<double> get currentPrice => $composableBuilder(
      column: $table.currentPrice, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<double> get marketValue => $composableBuilder(
      column: $table.marketValue, builder: (column) => column);

  GeneratedColumn<double> get unrealizedPnl => $composableBuilder(
      column: $table.unrealizedPnl, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$PositionsCacheTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PositionsCacheTable,
    PositionRow,
    $$PositionsCacheTableFilterComposer,
    $$PositionsCacheTableOrderingComposer,
    $$PositionsCacheTableAnnotationComposer,
    $$PositionsCacheTableCreateCompanionBuilder,
    $$PositionsCacheTableUpdateCompanionBuilder,
    (
      PositionRow,
      BaseReferences<_$AppDatabase, $PositionsCacheTable, PositionRow>
    ),
    PositionRow,
    PrefetchHooks Function()> {
  $$PositionsCacheTableTableManager(
      _$AppDatabase db, $PositionsCacheTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PositionsCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PositionsCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PositionsCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> sourceId = const Value.absent(),
            Value<String> symbol = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> assetClass = const Value.absent(),
            Value<double> quantity = const Value.absent(),
            Value<double> avgCost = const Value.absent(),
            Value<double> currentPrice = const Value.absent(),
            Value<String> currency = const Value.absent(),
            Value<double> marketValue = const Value.absent(),
            Value<double> unrealizedPnl = const Value.absent(),
            Value<DateTime> cachedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PositionsCacheCompanion(
            sourceId: sourceId,
            symbol: symbol,
            name: name,
            assetClass: assetClass,
            quantity: quantity,
            avgCost: avgCost,
            currentPrice: currentPrice,
            currency: currency,
            marketValue: marketValue,
            unrealizedPnl: unrealizedPnl,
            cachedAt: cachedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String sourceId,
            required String symbol,
            required String name,
            required String assetClass,
            required double quantity,
            required double avgCost,
            required double currentPrice,
            required String currency,
            required double marketValue,
            required double unrealizedPnl,
            required DateTime cachedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              PositionsCacheCompanion.insert(
            sourceId: sourceId,
            symbol: symbol,
            name: name,
            assetClass: assetClass,
            quantity: quantity,
            avgCost: avgCost,
            currentPrice: currentPrice,
            currency: currency,
            marketValue: marketValue,
            unrealizedPnl: unrealizedPnl,
            cachedAt: cachedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PositionsCacheTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PositionsCacheTable,
    PositionRow,
    $$PositionsCacheTableFilterComposer,
    $$PositionsCacheTableOrderingComposer,
    $$PositionsCacheTableAnnotationComposer,
    $$PositionsCacheTableCreateCompanionBuilder,
    $$PositionsCacheTableUpdateCompanionBuilder,
    (
      PositionRow,
      BaseReferences<_$AppDatabase, $PositionsCacheTable, PositionRow>
    ),
    PositionRow,
    PrefetchHooks Function()>;
typedef $$TransactionsCacheTableCreateCompanionBuilder
    = TransactionsCacheCompanion Function({
  required String id,
  required String sourceId,
  required DateTime time,
  required String type,
  required String symbol,
  required double quantity,
  required double price,
  required String currency,
  required double fee,
  required DateTime cachedAt,
  Value<int> rowid,
});
typedef $$TransactionsCacheTableUpdateCompanionBuilder
    = TransactionsCacheCompanion Function({
  Value<String> id,
  Value<String> sourceId,
  Value<DateTime> time,
  Value<String> type,
  Value<String> symbol,
  Value<double> quantity,
  Value<double> price,
  Value<String> currency,
  Value<double> fee,
  Value<DateTime> cachedAt,
  Value<int> rowid,
});

class $$TransactionsCacheTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionsCacheTable> {
  $$TransactionsCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceId => $composableBuilder(
      column: $table.sourceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get time => $composableBuilder(
      column: $table.time, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get symbol => $composableBuilder(
      column: $table.symbol, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get price => $composableBuilder(
      column: $table.price, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get fee => $composableBuilder(
      column: $table.fee, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnFilters(column));
}

class $$TransactionsCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionsCacheTable> {
  $$TransactionsCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceId => $composableBuilder(
      column: $table.sourceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get time => $composableBuilder(
      column: $table.time, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get symbol => $composableBuilder(
      column: $table.symbol, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get price => $composableBuilder(
      column: $table.price, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get fee => $composableBuilder(
      column: $table.fee, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnOrderings(column));
}

class $$TransactionsCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionsCacheTable> {
  $$TransactionsCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<DateTime> get time =>
      $composableBuilder(column: $table.time, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get symbol =>
      $composableBuilder(column: $table.symbol, builder: (column) => column);

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<double> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<double> get fee =>
      $composableBuilder(column: $table.fee, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$TransactionsCacheTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TransactionsCacheTable,
    TransactionRow,
    $$TransactionsCacheTableFilterComposer,
    $$TransactionsCacheTableOrderingComposer,
    $$TransactionsCacheTableAnnotationComposer,
    $$TransactionsCacheTableCreateCompanionBuilder,
    $$TransactionsCacheTableUpdateCompanionBuilder,
    (
      TransactionRow,
      BaseReferences<_$AppDatabase, $TransactionsCacheTable, TransactionRow>
    ),
    TransactionRow,
    PrefetchHooks Function()> {
  $$TransactionsCacheTableTableManager(
      _$AppDatabase db, $TransactionsCacheTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionsCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionsCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionsCacheTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> sourceId = const Value.absent(),
            Value<DateTime> time = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String> symbol = const Value.absent(),
            Value<double> quantity = const Value.absent(),
            Value<double> price = const Value.absent(),
            Value<String> currency = const Value.absent(),
            Value<double> fee = const Value.absent(),
            Value<DateTime> cachedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TransactionsCacheCompanion(
            id: id,
            sourceId: sourceId,
            time: time,
            type: type,
            symbol: symbol,
            quantity: quantity,
            price: price,
            currency: currency,
            fee: fee,
            cachedAt: cachedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String sourceId,
            required DateTime time,
            required String type,
            required String symbol,
            required double quantity,
            required double price,
            required String currency,
            required double fee,
            required DateTime cachedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              TransactionsCacheCompanion.insert(
            id: id,
            sourceId: sourceId,
            time: time,
            type: type,
            symbol: symbol,
            quantity: quantity,
            price: price,
            currency: currency,
            fee: fee,
            cachedAt: cachedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TransactionsCacheTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TransactionsCacheTable,
    TransactionRow,
    $$TransactionsCacheTableFilterComposer,
    $$TransactionsCacheTableOrderingComposer,
    $$TransactionsCacheTableAnnotationComposer,
    $$TransactionsCacheTableCreateCompanionBuilder,
    $$TransactionsCacheTableUpdateCompanionBuilder,
    (
      TransactionRow,
      BaseReferences<_$AppDatabase, $TransactionsCacheTable, TransactionRow>
    ),
    TransactionRow,
    PrefetchHooks Function()>;
typedef $$FxRatesCacheTableCreateCompanionBuilder = FxRatesCacheCompanion
    Function({
  required String base,
  required String quote,
  required double rate,
  required DateTime timestamp,
  Value<int> rowid,
});
typedef $$FxRatesCacheTableUpdateCompanionBuilder = FxRatesCacheCompanion
    Function({
  Value<String> base,
  Value<String> quote,
  Value<double> rate,
  Value<DateTime> timestamp,
  Value<int> rowid,
});

class $$FxRatesCacheTableFilterComposer
    extends Composer<_$AppDatabase, $FxRatesCacheTable> {
  $$FxRatesCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get base => $composableBuilder(
      column: $table.base, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get quote => $composableBuilder(
      column: $table.quote, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get rate => $composableBuilder(
      column: $table.rate, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnFilters(column));
}

class $$FxRatesCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $FxRatesCacheTable> {
  $$FxRatesCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get base => $composableBuilder(
      column: $table.base, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get quote => $composableBuilder(
      column: $table.quote, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get rate => $composableBuilder(
      column: $table.rate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnOrderings(column));
}

class $$FxRatesCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $FxRatesCacheTable> {
  $$FxRatesCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get base =>
      $composableBuilder(column: $table.base, builder: (column) => column);

  GeneratedColumn<String> get quote =>
      $composableBuilder(column: $table.quote, builder: (column) => column);

  GeneratedColumn<double> get rate =>
      $composableBuilder(column: $table.rate, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);
}

class $$FxRatesCacheTableTableManager extends RootTableManager<
    _$AppDatabase,
    $FxRatesCacheTable,
    FxRateRow,
    $$FxRatesCacheTableFilterComposer,
    $$FxRatesCacheTableOrderingComposer,
    $$FxRatesCacheTableAnnotationComposer,
    $$FxRatesCacheTableCreateCompanionBuilder,
    $$FxRatesCacheTableUpdateCompanionBuilder,
    (FxRateRow, BaseReferences<_$AppDatabase, $FxRatesCacheTable, FxRateRow>),
    FxRateRow,
    PrefetchHooks Function()> {
  $$FxRatesCacheTableTableManager(_$AppDatabase db, $FxRatesCacheTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FxRatesCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FxRatesCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FxRatesCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> base = const Value.absent(),
            Value<String> quote = const Value.absent(),
            Value<double> rate = const Value.absent(),
            Value<DateTime> timestamp = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FxRatesCacheCompanion(
            base: base,
            quote: quote,
            rate: rate,
            timestamp: timestamp,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String base,
            required String quote,
            required double rate,
            required DateTime timestamp,
            Value<int> rowid = const Value.absent(),
          }) =>
              FxRatesCacheCompanion.insert(
            base: base,
            quote: quote,
            rate: rate,
            timestamp: timestamp,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$FxRatesCacheTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $FxRatesCacheTable,
    FxRateRow,
    $$FxRatesCacheTableFilterComposer,
    $$FxRatesCacheTableOrderingComposer,
    $$FxRatesCacheTableAnnotationComposer,
    $$FxRatesCacheTableCreateCompanionBuilder,
    $$FxRatesCacheTableUpdateCompanionBuilder,
    (FxRateRow, BaseReferences<_$AppDatabase, $FxRatesCacheTable, FxRateRow>),
    FxRateRow,
    PrefetchHooks Function()>;
typedef $$QuotesCacheTableCreateCompanionBuilder = QuotesCacheCompanion
    Function({
  required String symbol,
  required double price,
  required String currency,
  required DateTime timestamp,
  Value<int> rowid,
});
typedef $$QuotesCacheTableUpdateCompanionBuilder = QuotesCacheCompanion
    Function({
  Value<String> symbol,
  Value<double> price,
  Value<String> currency,
  Value<DateTime> timestamp,
  Value<int> rowid,
});

class $$QuotesCacheTableFilterComposer
    extends Composer<_$AppDatabase, $QuotesCacheTable> {
  $$QuotesCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get symbol => $composableBuilder(
      column: $table.symbol, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get price => $composableBuilder(
      column: $table.price, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnFilters(column));
}

class $$QuotesCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $QuotesCacheTable> {
  $$QuotesCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get symbol => $composableBuilder(
      column: $table.symbol, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get price => $composableBuilder(
      column: $table.price, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnOrderings(column));
}

class $$QuotesCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $QuotesCacheTable> {
  $$QuotesCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get symbol =>
      $composableBuilder(column: $table.symbol, builder: (column) => column);

  GeneratedColumn<double> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);
}

class $$QuotesCacheTableTableManager extends RootTableManager<
    _$AppDatabase,
    $QuotesCacheTable,
    QuoteRow,
    $$QuotesCacheTableFilterComposer,
    $$QuotesCacheTableOrderingComposer,
    $$QuotesCacheTableAnnotationComposer,
    $$QuotesCacheTableCreateCompanionBuilder,
    $$QuotesCacheTableUpdateCompanionBuilder,
    (QuoteRow, BaseReferences<_$AppDatabase, $QuotesCacheTable, QuoteRow>),
    QuoteRow,
    PrefetchHooks Function()> {
  $$QuotesCacheTableTableManager(_$AppDatabase db, $QuotesCacheTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuotesCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuotesCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuotesCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> symbol = const Value.absent(),
            Value<double> price = const Value.absent(),
            Value<String> currency = const Value.absent(),
            Value<DateTime> timestamp = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              QuotesCacheCompanion(
            symbol: symbol,
            price: price,
            currency: currency,
            timestamp: timestamp,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String symbol,
            required double price,
            required String currency,
            required DateTime timestamp,
            Value<int> rowid = const Value.absent(),
          }) =>
              QuotesCacheCompanion.insert(
            symbol: symbol,
            price: price,
            currency: currency,
            timestamp: timestamp,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$QuotesCacheTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $QuotesCacheTable,
    QuoteRow,
    $$QuotesCacheTableFilterComposer,
    $$QuotesCacheTableOrderingComposer,
    $$QuotesCacheTableAnnotationComposer,
    $$QuotesCacheTableCreateCompanionBuilder,
    $$QuotesCacheTableUpdateCompanionBuilder,
    (QuoteRow, BaseReferences<_$AppDatabase, $QuotesCacheTable, QuoteRow>),
    QuoteRow,
    PrefetchHooks Function()>;
typedef $$ConnectionsMetaTableCreateCompanionBuilder = ConnectionsMetaCompanion
    Function({
  required String id,
  required String kind,
  required String label,
  required String status,
  required String credentialMode,
  Value<DateTime?> lastSyncAt,
  Value<int> rowid,
});
typedef $$ConnectionsMetaTableUpdateCompanionBuilder = ConnectionsMetaCompanion
    Function({
  Value<String> id,
  Value<String> kind,
  Value<String> label,
  Value<String> status,
  Value<String> credentialMode,
  Value<DateTime?> lastSyncAt,
  Value<int> rowid,
});

class $$ConnectionsMetaTableFilterComposer
    extends Composer<_$AppDatabase, $ConnectionsMetaTable> {
  $$ConnectionsMetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get label => $composableBuilder(
      column: $table.label, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get credentialMode => $composableBuilder(
      column: $table.credentialMode,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastSyncAt => $composableBuilder(
      column: $table.lastSyncAt, builder: (column) => ColumnFilters(column));
}

class $$ConnectionsMetaTableOrderingComposer
    extends Composer<_$AppDatabase, $ConnectionsMetaTable> {
  $$ConnectionsMetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get label => $composableBuilder(
      column: $table.label, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get credentialMode => $composableBuilder(
      column: $table.credentialMode,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastSyncAt => $composableBuilder(
      column: $table.lastSyncAt, builder: (column) => ColumnOrderings(column));
}

class $$ConnectionsMetaTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConnectionsMetaTable> {
  $$ConnectionsMetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get credentialMode => $composableBuilder(
      column: $table.credentialMode, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncAt => $composableBuilder(
      column: $table.lastSyncAt, builder: (column) => column);
}

class $$ConnectionsMetaTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ConnectionsMetaTable,
    ConnectionMetaRow,
    $$ConnectionsMetaTableFilterComposer,
    $$ConnectionsMetaTableOrderingComposer,
    $$ConnectionsMetaTableAnnotationComposer,
    $$ConnectionsMetaTableCreateCompanionBuilder,
    $$ConnectionsMetaTableUpdateCompanionBuilder,
    (
      ConnectionMetaRow,
      BaseReferences<_$AppDatabase, $ConnectionsMetaTable, ConnectionMetaRow>
    ),
    ConnectionMetaRow,
    PrefetchHooks Function()> {
  $$ConnectionsMetaTableTableManager(
      _$AppDatabase db, $ConnectionsMetaTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConnectionsMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConnectionsMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConnectionsMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> kind = const Value.absent(),
            Value<String> label = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String> credentialMode = const Value.absent(),
            Value<DateTime?> lastSyncAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ConnectionsMetaCompanion(
            id: id,
            kind: kind,
            label: label,
            status: status,
            credentialMode: credentialMode,
            lastSyncAt: lastSyncAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String kind,
            required String label,
            required String status,
            required String credentialMode,
            Value<DateTime?> lastSyncAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ConnectionsMetaCompanion.insert(
            id: id,
            kind: kind,
            label: label,
            status: status,
            credentialMode: credentialMode,
            lastSyncAt: lastSyncAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ConnectionsMetaTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ConnectionsMetaTable,
    ConnectionMetaRow,
    $$ConnectionsMetaTableFilterComposer,
    $$ConnectionsMetaTableOrderingComposer,
    $$ConnectionsMetaTableAnnotationComposer,
    $$ConnectionsMetaTableCreateCompanionBuilder,
    $$ConnectionsMetaTableUpdateCompanionBuilder,
    (
      ConnectionMetaRow,
      BaseReferences<_$AppDatabase, $ConnectionsMetaTable, ConnectionMetaRow>
    ),
    ConnectionMetaRow,
    PrefetchHooks Function()>;
typedef $$UserPrefsTableCreateCompanionBuilder = UserPrefsCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$UserPrefsTableUpdateCompanionBuilder = UserPrefsCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$UserPrefsTableFilterComposer
    extends Composer<_$AppDatabase, $UserPrefsTable> {
  $$UserPrefsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$UserPrefsTableOrderingComposer
    extends Composer<_$AppDatabase, $UserPrefsTable> {
  $$UserPrefsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$UserPrefsTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserPrefsTable> {
  $$UserPrefsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$UserPrefsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UserPrefsTable,
    UserPrefRow,
    $$UserPrefsTableFilterComposer,
    $$UserPrefsTableOrderingComposer,
    $$UserPrefsTableAnnotationComposer,
    $$UserPrefsTableCreateCompanionBuilder,
    $$UserPrefsTableUpdateCompanionBuilder,
    (UserPrefRow, BaseReferences<_$AppDatabase, $UserPrefsTable, UserPrefRow>),
    UserPrefRow,
    PrefetchHooks Function()> {
  $$UserPrefsTableTableManager(_$AppDatabase db, $UserPrefsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserPrefsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserPrefsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserPrefsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UserPrefsCompanion(
            key: key,
            value: value,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) =>
              UserPrefsCompanion.insert(
            key: key,
            value: value,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$UserPrefsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $UserPrefsTable,
    UserPrefRow,
    $$UserPrefsTableFilterComposer,
    $$UserPrefsTableOrderingComposer,
    $$UserPrefsTableAnnotationComposer,
    $$UserPrefsTableCreateCompanionBuilder,
    $$UserPrefsTableUpdateCompanionBuilder,
    (UserPrefRow, BaseReferences<_$AppDatabase, $UserPrefsTable, UserPrefRow>),
    UserPrefRow,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PositionsCacheTableTableManager get positionsCache =>
      $$PositionsCacheTableTableManager(_db, _db.positionsCache);
  $$TransactionsCacheTableTableManager get transactionsCache =>
      $$TransactionsCacheTableTableManager(_db, _db.transactionsCache);
  $$FxRatesCacheTableTableManager get fxRatesCache =>
      $$FxRatesCacheTableTableManager(_db, _db.fxRatesCache);
  $$QuotesCacheTableTableManager get quotesCache =>
      $$QuotesCacheTableTableManager(_db, _db.quotesCache);
  $$ConnectionsMetaTableTableManager get connectionsMeta =>
      $$ConnectionsMetaTableTableManager(_db, _db.connectionsMeta);
  $$UserPrefsTableTableManager get userPrefs =>
      $$UserPrefsTableTableManager(_db, _db.userPrefs);
}

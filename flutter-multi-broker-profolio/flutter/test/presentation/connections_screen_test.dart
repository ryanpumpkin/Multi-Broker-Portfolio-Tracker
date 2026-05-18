import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multi_broker_portfolio/domain/domain.dart';
import 'package:multi_broker_portfolio/presentation/screens/connections/connections_screen.dart';
import 'package:multi_broker_portfolio/state/repository_providers.dart';

import 'presentation_test_harness.dart';

void main() {
  testWidgets('shows relative sync labels including never synced', (
    tester,
  ) async {
    final now = DateTime.now().toUtc();
    final repo = _StaticConnectionsRepository([
      Connection(
        id: 'lb',
        kind: ConnectionKind.longbridge,
        label: 'LongBridge',
        status: ConnectionStatus.ok,
        credentialMode: CredentialMode.e2e,
        lastSyncAt: now.subtract(const Duration(minutes: 3)),
      ),
      const Connection(
        id: 'bn',
        kind: ConnectionKind.binance,
        label: 'Binance',
        status: ConnectionStatus.unknown,
        credentialMode: CredentialMode.serverKey,
      ),
    ]);

    await tester.pumpWidget(
      wrapForTest(
        const ConnectionsScreen(),
        overrides: [
          ...buildAppLockUnlockedOverrides(),
          connectionsRepositoryProvider.overrideWithValue(repo),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            (widget.data ?? '').startsWith('synced ') &&
            (widget.data ?? '').contains(' min ago'),
      ),
      findsOneWidget,
    );
    expect(find.text('never synced'), findsOneWidget);
  });

  testWidgets('error status shows tooltip and expandable details',
      (tester) async {
    const error = 'Broker authentication failed';
    final repo = _StaticConnectionsRepository(const [
      Connection(
        id: 'ib',
        kind: ConnectionKind.ibkr,
        label: 'IBKR',
        status: ConnectionStatus.error,
        credentialMode: CredentialMode.e2e,
        errorMessage: error,
      ),
    ]);

    await tester.pumpWidget(
      wrapForTest(
        const ConnectionsScreen(),
        overrides: [
          ...buildAppLockUnlockedOverrides(),
          connectionsRepositoryProvider.overrideWithValue(repo),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Error details'), findsOneWidget);

    await tester.longPress(find.text('Issue'));
    await tester.pumpAndSettle();
    expect(find.text(error), findsWidgets);

    await tester.tap(find.text('Error details'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('source_error_ib')), findsOneWidget);
    expect(find.text(error), findsWidgets);
  });
}

class _StaticConnectionsRepository implements ConnectionsRepository {
  _StaticConnectionsRepository(this._items);

  final List<Connection> _items;

  @override
  Future<Connection> add(Connection connection) async {
    _items.add(connection);
    return connection;
  }

  @override
  Future<List<Connection>> list() async =>
      List<Connection>.unmodifiable(_items);

  @override
  Future<void> remove(String connectionId) async {
    _items.removeWhere((c) => c.id == connectionId);
  }

  @override
  Future<void> setCredentials(
    String connectionId,
    String encryptedBlob,
  ) async {}

  @override
  Future<Connection> updateMode(
    String connectionId,
    CredentialMode mode,
  ) async {
    final index = _items.indexWhere((c) => c.id == connectionId);
    if (index < 0) throw StateError('missing connection');
    _items[index] = _items[index].copyWith(credentialMode: mode);
    return _items[index];
  }
}

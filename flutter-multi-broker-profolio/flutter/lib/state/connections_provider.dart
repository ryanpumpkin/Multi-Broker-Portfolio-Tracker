import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/domain.dart';
import 'repository_providers.dart';

final connectionsProvider =
    AsyncNotifierProvider<ConnectionsController, ConnectionsState>(
  ConnectionsController.new,
);

class ConnectionsState {
  const ConnectionsState(
      {required this.connections, required this.healthBySource,});

  final List<Connection> connections;
  final Map<String, ConnectionStatus> healthBySource;

  static ConnectionsState fromConnections(List<Connection> connections) {
    return ConnectionsState(
      connections: List<Connection>.unmodifiable(connections),
      healthBySource: Map<String, ConnectionStatus>.unmodifiable(
        <String, ConnectionStatus>{
          for (final connection in connections)
            connection.id: connection.status,
        },
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConnectionsState &&
          runtimeType == other.runtimeType &&
          _listEquals(connections, other.connections) &&
          _mapEquals(healthBySource, other.healthBySource);

  @override
  int get hashCode => Object.hash(
        Object.hashAll(connections),
        Object.hashAllUnordered(
          healthBySource.entries
              .map((entry) => Object.hash(entry.key, entry.value)),
        ),
      );

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static bool _mapEquals<K, V>(Map<K, V> a, Map<K, V> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || b[key] != a[key]) return false;
    }
    return true;
  }
}

class ConnectionsController extends AsyncNotifier<ConnectionsState> {
  @override
  Future<ConnectionsState> build() async {
    final connections = await ref.read(connectionsRepositoryProvider).list();
    return ConnectionsState.fromConnections(connections);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final connections = await ref.read(connectionsRepositoryProvider).list();
      return ConnectionsState.fromConnections(connections);
    });
  }

  Future<Connection> add(Connection connection) async {
    final created =
        await ref.read(connectionsRepositoryProvider).add(connection);
    await _reloadQuietly();
    return created;
  }

  Future<void> remove(String connectionId) async {
    await ref.read(connectionsRepositoryProvider).remove(connectionId);
    await _reloadQuietly();
  }

  Future<Connection> updateMode(
      String connectionId, CredentialMode mode,) async {
    final updated = await ref
        .read(connectionsRepositoryProvider)
        .updateMode(connectionId, mode);
    await _reloadQuietly();
    return updated;
  }

  Future<void> _reloadQuietly() async {
    final connections = await ref.read(connectionsRepositoryProvider).list();
    state = AsyncData(ConnectionsState.fromConnections(connections));
  }
}

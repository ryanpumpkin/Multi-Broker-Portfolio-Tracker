import '../entities/connection.dart';

/// Manages user-configured broker / exchange / manual connections.
abstract class ConnectionsRepository {
  Future<List<Connection>> list();

  Future<Connection> add(Connection connection);

  Future<void> remove(String connectionId);

  Future<Connection> updateMode(
    String connectionId,
    CredentialMode mode,
  );
}

class AppLockSettings {
  const AppLockSettings({
    required this.enabled,
    required this.biometricEnabled,
    required this.timeout,
  });

  final bool enabled;
  final bool biometricEnabled;
  final Duration timeout;

  AppLockSettings copyWith({
    bool? enabled,
    bool? biometricEnabled,
    Duration? timeout,
  }) {
    return AppLockSettings(
      enabled: enabled ?? this.enabled,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      timeout: timeout ?? this.timeout,
    );
  }
}

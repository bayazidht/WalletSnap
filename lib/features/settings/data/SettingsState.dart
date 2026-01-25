class SettingsState {
  final String currency;
  final bool isCloudBackupEnabled;
  final String lastSyncTime;

  SettingsState({
    required this.currency,
    required this.isCloudBackupEnabled,
    required this.lastSyncTime,
  });

  SettingsState copyWith({
    String? currency,
    bool? isCloudBackupEnabled,
    String? lastSyncTime,
  }) {
    return SettingsState(
      currency: currency ?? this.currency,
      isCloudBackupEnabled: isCloudBackupEnabled ?? this.isCloudBackupEnabled,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
    );
  }
}
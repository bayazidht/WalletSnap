import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/SettingsState.dart';

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(() {
  return SettingsNotifier();
});

class SettingsNotifier extends Notifier<SettingsState> {
  static const String _currencyKey = 'selectedCurrency';
  static const String _backupKey = 'isCloudBackupEnabled';
  static const String _syncKey = 'lastSyncTime';

  @override
  SettingsState build() {
    return SettingsState(
      currency: '\$',
      isCloudBackupEnabled: true,
      lastSyncTime: 'Never',
    );
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final currency = prefs.getString(_currencyKey) ?? '\$';
    final isBackupEnabled = prefs.getBool(_backupKey) ?? true;
    final lastSync = prefs.getString(_syncKey) ?? 'Never';

    state = SettingsState(
      currency: currency,
      isCloudBackupEnabled: isBackupEnabled,
      lastSyncTime: lastSync,
    );
  }

  Future<void> setCurrency(String newCurrency) async {
    state = state.copyWith(currency: newCurrency);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, newCurrency);
  }

  Future<void> toggleCloudBackup(bool enabled) async {
    state = state.copyWith(isCloudBackupEnabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_backupKey, enabled);
  }

  Future<void> updateSyncTime(String timeStr) async {
    state = state.copyWith(lastSyncTime: timeStr);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_syncKey, timeStr);
  }
}
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class UiPreferencesController extends ChangeNotifier {
  static const boxName = 'ui_settings_box';
  static const themeModeKey = 'theme_mode';
  static const themeModeSyncPendingKey = '${themeModeKey}_sync_pending';

  ThemeMode _themeMode = ThemeMode.system;
  bool _initialized = false;
  bool _syncPending = false;

  ThemeMode get themeMode => _themeMode;
  bool get initialized => _initialized;
  bool get syncPending => _syncPending;

  Future<void> init() async {
    if (_initialized) return;
    try {
      final box = await _openBox();
      _themeMode = themeModeFromWire(box.get(themeModeKey) as String?);
      _syncPending = box.get(themeModeSyncPendingKey) == true;
    } catch (_) {
      // Keep the in-memory default/current value when Hive is not available
      // (common in widget tests) or persistence cannot be opened.
    } finally {
      _initialized = true;
      notifyListeners();
    }
  }

  Future<void> setThemeMode(
    ThemeMode mode, {
    bool markSyncPending = false,
  }) async {
    if (_themeMode == mode && _syncPending == markSyncPending) return;
    _themeMode = mode;
    _syncPending = markSyncPending;
    notifyListeners();
    try {
      final box = await _openBox();
      await box.put(themeModeKey, themeModeToWire(mode));
      await box.put(themeModeSyncPendingKey, markSyncPending);
    } catch (_) {
      // Theme preference is non-sensitive. If local storage is unavailable,
      // keep the in-memory value so the current session still reacts.
    }
  }

  Future<void> applyBackendTheme(String? value) async {
    await setThemeMode(themeModeFromWire(value), markSyncPending: false);
  }

  Future<void> markSynced() async {
    if (!_syncPending) return;
    _syncPending = false;
    notifyListeners();
    try {
      final box = await _openBox();
      await box.put(themeModeSyncPendingKey, false);
    } catch (_) {}
  }

  static ThemeMode themeModeFromWire(String? value) {
    return switch (value?.toLowerCase()) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  static String themeModeToWire(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
  }

  Future<Box<dynamic>> _openBox() async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box(boxName);
    }
    throw StateError('UI settings box is not open.');
  }
}

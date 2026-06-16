import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_app/app.dart';
import 'package:flutter_app/data/gym_state.dart';
import 'package:flutter_app/models/gym_models.dart';
import 'package:flutter_app/theme/ui_preferences_controller.dart';
import 'package:flutter_app/widgets/app_shell.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

LoggedInUser _adminUser() {
  return LoggedInUser(
    id: 'admin-id',
    email: 'admin@example.com',
    rol: GymRole.admin,
    nombreCompleto: 'Admin Test',
    estado: 'ACTIVE',
    themePreference: 'light',
  );
}

void main() {
  test('theme mode wire mapping supports system light and dark', () {
    expect(
      UiPreferencesController.themeModeFromWire('system'),
      ThemeMode.system,
    );
    expect(UiPreferencesController.themeModeFromWire('light'), ThemeMode.light);
    expect(UiPreferencesController.themeModeFromWire('dark'), ThemeMode.dark);
    expect(UiPreferencesController.themeModeFromWire(null), ThemeMode.system);

    expect(UiPreferencesController.themeModeToWire(ThemeMode.system), 'system');
    expect(UiPreferencesController.themeModeToWire(ThemeMode.light), 'light');
    expect(UiPreferencesController.themeModeToWire(ThemeMode.dark), 'dark');
  });

  test('readableOn chooses high contrast ink for light and dark surfaces', () {
    expect(readableOn(const Color(0xFFD2FF3A)), const Color(0xFF0B0B0B));
    expect(readableOn(const Color(0xFF161618)), Colors.white);
  });

  test(
    'theme preference restores pending sync flag from local storage',
    () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'ui_preferences_test_',
      );
      Hive.init(tempDir.path);
      final box = await Hive.openBox(UiPreferencesController.boxName);
      addTearDown(() async {
        final controllerBoxOpen = Hive.isBoxOpen(
          UiPreferencesController.boxName,
        );
        if (controllerBoxOpen) {
          await Hive.box(UiPreferencesController.boxName).close();
        }
        await Hive.deleteBoxFromDisk(UiPreferencesController.boxName);
        await tempDir.delete(recursive: true);
      });

      await box.put(UiPreferencesController.themeModeKey, 'dark');
      await box.put(UiPreferencesController.themeModeSyncPendingKey, true);

      final controller = UiPreferencesController();
      addTearDown(controller.dispose);
      await controller.init();

      expect(controller.themeMode, ThemeMode.dark);
      expect(controller.syncPending, isTrue);

      await controller.markSynced();
      expect(controller.syncPending, isFalse);
      expect(box.get(UiPreferencesController.themeModeSyncPendingKey), isFalse);
    },
  );

  testWidgets('admin role can render with light theme preference', (
    tester,
  ) async {
    final state = GymState(startBackground: false);
    addTearDown(state.dispose);

    await state.updateThemeMode(ThemeMode.light);
    state.setCurrentGymActiveForTest(active: true);
    state.setCurrentUserForTest(_adminUser());

    await tester.pumpWidget(
      GymStateProvider(notifier: state, child: const SasGymApp()),
    );

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.themeMode, ThemeMode.light);
  });
}

// tests/providers/active_routine_provider_test.dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:flutter_app/providers/routine_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    final tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);
    await Hive.openBox('gym_cache');
  });

  tearDown(() async {
    await Hive.box('gym_cache').clear();
    await Hive.box('gym_cache').close();
  });

  test(
    'loadActiveRoutine returns API data when online and backend mode',
    () async {
      final mockDio = Dio();
      mockDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response(
                requestOptions: options,
                data: {'id': 'r1', 'name': 'Test'},
              ),
            );
          },
        ),
      );
      final container = ProviderContainer(
        overrides: [
          activeRoutineProvider.overrideWith(
            (ref) => ActiveRoutineNotifier(dio: mockDio),
          ),
        ],
      );
      final notifier = container.read(activeRoutineProvider.notifier);
      final result = await notifier.loadActiveRoutine(
        isOnline: true,
        isBackendMode: true,
      );
      expect(result, isNotNull);
      expect(result!['id'], 'r1');
      final cached = Hive.box('gym_cache').get('active_routine');
      expect(cached, isNotNull);
    },
  );

  test('loadActiveRoutine falls back to Hive when API fails', () async {
    await Hive.box('gym_cache').put('active_routine', {'id': 'cached'});
    final mockDio = Dio();
    mockDio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.reject(
            DioException(requestOptions: options, error: 'Network error'),
          );
        },
      ),
    );
    final container = ProviderContainer(
      overrides: [
        activeRoutineProvider.overrideWith(
          (ref) => ActiveRoutineNotifier(dio: mockDio),
        ),
      ],
    );
    final notifier = container.read(activeRoutineProvider.notifier);
    final result = await notifier.loadActiveRoutine(
      isOnline: true,
      isBackendMode: true,
    );
    expect(result, isNotNull);
    expect(result!['id'], 'cached');
  });
}

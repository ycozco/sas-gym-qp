// tests/providers/active_diet_provider_test.dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:flutter_app/providers/diet_provider.dart';

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

  test('loadActiveDiet returns API data when online', () async {
    final mockDio = Dio();
    mockDio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response(
              requestOptions: options,
              data: {'id': 'd1', 'name': 'Keto'},
            ),
          );
        },
      ),
    );
    final container = ProviderContainer(
      overrides: [
        activeDietProvider.overrideWith(
          (ref) => ActiveDietNotifier(dio: mockDio),
        ),
      ],
    );
    final notifier = container.read(activeDietProvider.notifier);
    final result = await notifier.loadActiveDiet(
      isOnline: true,
      isBackendMode: true,
    );
    expect(result, isNotNull);
    expect(result!['id'], 'd1');
    final cached = Hive.box('gym_cache').get('active_diet');
    expect(cached, isNotNull);
  });

  test('loadActiveDiet falls back to Hive on failure', () async {
    await Hive.box('gym_cache').put('active_diet', {'id': 'cached'});
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
        activeDietProvider.overrideWith(
          (ref) => ActiveDietNotifier(dio: mockDio),
        ),
      ],
    );
    final notifier = container.read(activeDietProvider.notifier);
    final result = await notifier.loadActiveDiet(
      isOnline: true,
      isBackendMode: true,
    );
    expect(result, isNotNull);
    expect(result!['id'], 'cached');
  });
}

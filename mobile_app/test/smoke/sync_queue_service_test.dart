import 'dart:io';

import 'package:flutter_app/core/services/sync_queue_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('sync_queue_test_');
    Hive.init(tempDir.path);
    await Hive.openBox('sync_queue_box');
  });

  tearDown(() async {
    if (Hive.isBoxOpen('sync_queue_box')) {
      await Hive.box('sync_queue_box').close();
    }
    await Hive.deleteBoxFromDisk('sync_queue_box');
    await tempDir.delete(recursive: true);
  });

  test('enqueue creates idempotency metadata', () async {
    await SyncQueueService.enqueue('/members/workout-log', 'POST', {
      'sets': 3,
    }, idempotencyKey: 'workout-1');

    final queue = SyncQueueService.getQueue();
    expect(queue, hasLength(1));
    expect(queue.first['idempotencyKey'], 'workout-1');
    expect(queue.first['attempts'], 0);
    expect(queue.first['expiresAt'], isNotNull);
  });

  test('financial enqueue requires idempotencyKey', () async {
    expect(
      () => SyncQueueService.enqueue('/payments/pos-charge', 'POST', {
        'total': 10,
      }, financial: true),
      throwsArgumentError,
    );
  });

  test('processQueue increments attempts and keeps failed tx', () async {
    await SyncQueueService.enqueue('/members/workout-log', 'POST', {
      'sets': 3,
    }, idempotencyKey: 'workout-1');

    final success = await SyncQueueService.processQueue(
      now: DateTime(2026, 1, 1),
      sender: (method, endpoint, data, idempotencyKey) async {
        throw Exception('network down');
      },
    );

    final queue = SyncQueueService.getQueue();
    expect(success, isFalse);
    expect(queue, hasLength(1));
    expect(queue.first['attempts'], 1);
    expect(queue.first['lastAttemptAt'], isNotNull);
    expect(queue.first['lastError'], contains('network down'));
  });

  test('processQueue discards expired tx', () async {
    await SyncQueueService.enqueue('/members/workout-log', 'POST', {
      'sets': 3,
    }, ttl: const Duration(seconds: 1));

    final success = await SyncQueueService.processQueue(
      now: DateTime.now().add(const Duration(days: 1)),
      sender: (method, endpoint, data, idempotencyKey) async {},
    );

    expect(success, isFalse);
    expect(SyncQueueService.getQueue(), isEmpty);
  });
}

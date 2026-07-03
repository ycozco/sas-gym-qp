import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../core/network/api_client.dart';
import '../core/storage/secure_storage.dart';

class ActiveRoutineNotifier
    extends StateNotifier<AsyncValue<Map<String, dynamic>?>> {
  ActiveRoutineNotifier() : super(const AsyncValue.loading());

  static const _cacheTtl = Duration(days: 7);

  Future<String?> _cacheKeyForUser(String userId) async {
    final tenantId = await SecureStorage.getTenantId();
    if (tenantId == null || tenantId.isEmpty || userId.isEmpty) {
      return null;
    }
    return 'training:$tenantId:$userId:active-routine';
  }

  Future<Map<String, dynamic>?> loadActiveRoutine({
    required bool isOnline,
    required bool isBackendMode,
    required String userId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final box = Hive.box('gym_cache');
      final cacheKey = await _cacheKeyForUser(userId);

      if (isBackendMode && isOnline) {
        try {
          final response = await ApiClient().dio.get('/routines/active');
          if (response.data != null) {
            final data = Map<String, dynamic>.from(response.data as Map);
            if (cacheKey != null) {
              await box.put(cacheKey, {
                'savedAt': DateTime.now().toIso8601String(),
                'data': data,
              });
            }
            state = AsyncValue.data(data);
            return data;
          }

          if (cacheKey != null) {
            await box.delete(cacheKey);
          }
          state = const AsyncValue.data(null);
          return null;
        } on DioException catch (e, stackTrace) {
          final statusCode = e.response?.statusCode;
          final isHttpAccessError = statusCode == 401 || statusCode == 403;
          final isNetworkError =
              e.type == DioExceptionType.connectionError ||
              e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout ||
              e.type == DioExceptionType.sendTimeout;

          if (isHttpAccessError) {
            if (cacheKey != null) {
              await box.delete(cacheKey);
            }
            state = AsyncValue.error(e, stackTrace);
            return null;
          }

          if (!isNetworkError) {
            state = AsyncValue.error(e, stackTrace);
            return null;
          }
        }
      }

      if (cacheKey != null) {
        final cached = box.get(cacheKey);
        if (cached is Map) {
          final rawSavedAt = cached['savedAt']?.toString();
          final savedAt = rawSavedAt == null
              ? null
              : DateTime.tryParse(rawSavedAt);
          final rawData = cached['data'];
          final isFresh =
              savedAt != null &&
              DateTime.now().difference(savedAt) <= _cacheTtl;

          if (isFresh && rawData is Map) {
            final data = Map<String, dynamic>.from(rawData);
            state = AsyncValue.data(data);
            return data;
          }

          await box.delete(cacheKey);
        }
      }

      state = const AsyncValue.data(null);
      return null;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return null;
    }
  }

  Future<bool> saveWorkoutSession(
    Map<String, dynamic> session, {
    required bool isOnline,
    required bool isBackendMode,
    required String userId,
  }) async {
    if (isBackendMode) {
      if (isOnline) {
        try {
          await ApiClient().dio.post('/members/workout-log', data: session);
          return true;
        } catch (e) {
          // Error de red, caer al almacenamiento offline.
        }
      }

      final box = Hive.box('gym_cache');
      final queueKey =
          (await _cacheKeyForUser(
            userId,
          ))?.replaceFirst('active-routine', 'offline-workout-queue') ??
          'training:offline-workout-queue';
      final List<dynamic> queue = box.get(queueKey) ?? [];
      queue.add(session);
      await box.put(queueKey, queue);
      return false;
    }

    return true;
  }
}

final activeRoutineProvider =
    StateNotifierProvider<
      ActiveRoutineNotifier,
      AsyncValue<Map<String, dynamic>?>
    >((ref) {
      return ActiveRoutineNotifier();
    });

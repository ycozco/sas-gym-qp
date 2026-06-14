import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../core/network/api_client.dart';

class ActiveRoutineNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>?>> {
  ActiveRoutineNotifier() : super(const AsyncValue.loading());

  /**
   * Carga la rutina activa del miembro, intentando del servidor si hay conexión,
   * o haciendo fallback a la caché local de Hive.
   */
  Future<Map<String, dynamic>?> loadActiveRoutine({
    required bool isOnline,
    required bool isBackendMode,
  }) async {
    state = const AsyncValue.loading();
    try {
      final box = Hive.box('gym_cache');

      if (isBackendMode && isOnline) {
        try {
          final response = await ApiClient().dio.get('/routines/active');
          if (response.data != null) {
            final data = Map<String, dynamic>.from(response.data as Map);
            await box.put('active_routine', data);
            state = AsyncValue.data(data);
            return data;
          }
        } catch (e) {
          // Si falla la API de red, permitimos que caiga al fallback de caché
        }
      }

      // Fallback a Hive local
      final cached = box.get('active_routine');
      if (cached != null && cached is Map) {
        final data = Map<String, dynamic>.from(cached);
        state = AsyncValue.data(data);
        return data;
      }

      state = const AsyncValue.data(null);
      return null;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return null;
    }
  }

  /**
   * Registra una sesión de entrenamiento (workout session) de forma online u offline.
   */
  Future<bool> saveWorkoutSession(
    Map<String, dynamic> session, {
    required bool isOnline,
    required bool isBackendMode,
  }) async {
    if (isBackendMode) {
      if (isOnline) {
        try {
          await ApiClient().dio.post('/members/workout-log', data: session);
          return true;
        } catch (e) {
          // Error en red, guardar en cola offline
        }
      }

      // Guardar localmente en Hive
      final box = Hive.box('gym_cache');
      final List<dynamic> queue = box.get('offline_workout_queue') ?? [];
      queue.add(session);
      await box.put('offline_workout_queue', queue);
      return false;
    }
    // Modo demo
    return true;
  }
}

// Proveedor de estado de la rutina activa
final activeRoutineProvider = StateNotifierProvider<ActiveRoutineNotifier, AsyncValue<Map<String, dynamic>?>>((ref) {
  return ActiveRoutineNotifier();
});

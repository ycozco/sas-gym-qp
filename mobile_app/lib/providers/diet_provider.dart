import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../core/network/api_client.dart';

class ActiveDietNotifier
    extends StateNotifier<AsyncValue<Map<String, dynamic>?>> {
  ActiveDietNotifier({Dio? dio})
    : _dio = dio ?? ApiClient().dio,
      super(const AsyncValue.loading());

  final Dio _dio;

  /// Carga la dieta activa del miembro, intentando del servidor si hay conexión,
  /// o haciendo fallback a la caché local de Hive.
  Future<Map<String, dynamic>?> loadActiveDiet({
    required bool isOnline,
    required bool isBackendMode,
  }) async {
    state = const AsyncValue.loading();
    try {
      final box = Hive.box('gym_cache');

      if (isBackendMode && isOnline) {
        try {
          final response = await _dio.get('/diets/me');
          if (response.data != null) {
            final data = Map<String, dynamic>.from(response.data as Map);
            await box.put('active_diet', data);
            state = AsyncValue.data(data);
            return data;
          }
        } catch (e) {
          // Si falla la API de red, permitimos que caiga al fallback de caché
        }
      }

      // Fallback a Hive local
      final cached = box.get('active_diet');
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
}

// Proveedor de estado de la dieta activa
final activeDietProvider =
    StateNotifierProvider<
      ActiveDietNotifier,
      AsyncValue<Map<String, dynamic>?>
    >((ref) {
      return ActiveDietNotifier();
    });

import '../../../data/gym_state.dart';
import '../../../models/gym_models.dart';

MemberRecord getLoggedMember(GymState state) {
  final user = state.currentUser;
  final backendPayments = state.memberPayments;
  final profile = user?.memberProfile;
  final trainer = profile?['trainer'] as Map<String, dynamic>?;
  final trainerUser = trainer?['user'] as Map<String, dynamic>?;
  final medidasJson = profile?['medidas_json'] as Map<String, dynamic>?;
  return state.allMembersIncludingSoftDeleted.firstWhere(
    (m) => m.dni == user?.dni,
    orElse: () {
      if (user != null) {
        return MemberRecord(
          dni: user.dni ?? '',
          name: user.nombreCompleto,
          phone: user.celular ?? '',
          email: user.email,
          startDate: 'Hoy',
          goal: profile?['objetivo']?.toString() ?? 'Sin objetivo registrado',
          sessions: 0,
          lastSeen: 'Sin registro',
          state: (user.memberships != null && user.memberships!.isNotEmpty)
              ? user.memberships!.first['estado']?.toString().toLowerCase() ??
                    'expired'
              : (user.estado == 'ACTIVE' ? 'active' : 'expired'),

          assignedTrainer:
              trainerUser?['nombre_completo']?.toString() ??
              profile?['trainer_name']?.toString() ??
              'Sin entrenador asignado',
          paymentHistory: backendPayments,
          physicalMeasurements: {
            if (profile?['peso_kg'] != null)
              'peso': (profile?['peso_kg'] as num).toDouble(),
            if (profile?['altura_cm'] != null)
              'altura': (profile?['altura_cm'] as num).toDouble(),
            if (medidasJson?['cintura'] != null)
              'cintura': (medidasJson!['cintura'] as num).toDouble(),
            if (medidasJson?['pecho'] != null)
              'pecho': (medidasJson!['pecho'] as num).toDouble(),
            if (medidasJson?['cadera'] != null)
              'cadera': (medidasJson!['cadera'] as num).toDouble(),
          },
          progressImages:
              (profile?['fotos_comparativas'] as List<dynamic>?)
                  ?.map((item) => item.toString())
                  .toList() ??
              const [],
          todayCheckIn: profile?['modo_activo'] == true,
          isActiveInGym: profile?['modo_activo'] == true,
        );
      }
      return MemberRecord(
        dni: '',
        name: 'Socio',
        phone: '',
        email: '',
        startDate: '',
        goal: 'Sin objetivo registrado',
        sessions: 0,
        lastSeen: 'Sin registro',
        state: 'expired',
        assignedTrainer: 'Sin entrenador asignado',
        paymentHistory: const [],
        physicalMeasurements: const {},
        progressImages: const [],
      );
    },
  );
}

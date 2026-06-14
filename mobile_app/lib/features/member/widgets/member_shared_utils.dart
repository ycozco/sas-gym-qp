import '../../../data/gym_state.dart';
import '../../../models/gym_models.dart';

MemberRecord getLoggedMember(GymState state) {
  final user = state.currentUser;
  final backendPayments = state.memberPayments;
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
          goal: user.memberProfile?['objetivo'] ?? 'Hipertrofia',
          sessions: 0,
          lastSeen: 'Hoy',
          state: (user.memberships != null && user.memberships!.isNotEmpty)
              ? user.memberships!.first['estado']?.toString().toLowerCase() ??
                    'expired'
              : (user.estado == 'ACTIVE' ? 'active' : 'expired'),

          assignedTrainer:
              user.memberProfile?['trainer_name']?.toString() ??
              'Carlos Mendoza',
          paymentHistory: backendPayments,
          physicalMeasurements: {
            'peso':
                (user.memberProfile?['peso_kg'] as num?)?.toDouble() ?? 70.0,
            'altura':
                (user.memberProfile?['altura_cm'] as num?)?.toDouble() ?? 170.0,
          },
          progressImages: [],
        );
      }
      return state.allMembersIncludingSoftDeleted.first;
    },
  );
}

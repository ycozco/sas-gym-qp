// TODO(arch-future): este archivo importa material.dart porque varios
// modelos cargan tipos de UI (Color, IconData) directamente. Una
// iteracion posterior puede separar los DTOs puros (LoggedInUser,
// MemberRecord, PaymentRecord, etc.) en `models/` Dart-only y mover
// los catalogos visuales (RolePalette, MetricItem, ExerciseItem)
// a `theme/` o a la feature correspondiente.
import 'package:flutter/material.dart';

enum GymRole { member, trainer, cashier, admin, superadmin }

extension GymRoleX on GymRole {
  String get label => switch (this) {
        GymRole.member => 'Usuario',
        GymRole.trainer => 'Entrenador',
        GymRole.cashier => 'Caja',
        GymRole.admin => 'Admin',
        GymRole.superadmin => 'SuperAdmin',
      };

  String get subtitle => switch (this) {
        GymRole.member => 'Experiencia del socio',
        GymRole.trainer => 'Planificación y progreso',
        GymRole.cashier => 'Operación limitada',
        GymRole.admin => 'Gestión total y auditoría',
        GymRole.superadmin => 'Métricas de la red y control',
      };
}

class RolePalette {
  const RolePalette({
    required this.accent,
    required this.accentInk,
    required this.surfaceTint,
    required this.gradient,
    required this.label,
  });

  final Color accent;
  final Color accentInk;
  final Color surfaceTint;
  final Gradient gradient;
  final String label;
}

class MetricItem {
  const MetricItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.note,
  });

  final IconData icon;
  final String label;
  final String value;
  final String note;
}

class WorkoutDay {
  const WorkoutDay({
    required this.day,
    required this.number,
    required this.group,
    required this.today,
    required this.rest,
  });

  final String day;
  final int number;
  final String group;
  final bool today;
  final bool rest;
}

class ExerciseItem {
  final String? id;
  final String name;
  final String muscle;
  final int sets;
  final String reps;
  final int? weight;
  final int restSeconds;
  final IconData icon;
  final bool available;

  ExerciseItem({
    this.id,
    required this.name,
    required this.muscle,
    required this.sets,
    required this.reps,
    required this.weight,
    required this.restSeconds,
    required this.icon,
    required this.available,
  });

  ExerciseItem copyWith({
    String? id,
    String? name,
    String? muscle,
    int? sets,
    String? reps,
    int? weight,
    int? restSeconds,
    IconData? icon,
    bool? available,
  }) {
    return ExerciseItem(
      id: id ?? this.id,
      name: name ?? this.name,
      muscle: muscle ?? this.muscle,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      restSeconds: restSeconds ?? this.restSeconds,
      icon: icon ?? this.icon,
      available: available ?? this.available,
    );
  }
}

class Announcement {
  final String id;
  final String tag;
  final String title;
  final String detail;
  final String time;
  final String severidad;
  final bool activo;

  Announcement({
    this.id = '',
    required this.tag,
    required this.title,
    required this.detail,
    required this.time,
    this.severidad = 'INFO',
    this.activo = true,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    final createdAtStr = json['created_at'] ?? json['createdAt'];
    String friendlyTime = 'Ahora';
    if (createdAtStr != null) {
      try {
        final dt = DateTime.parse(createdAtStr.toString());
        final diff = DateTime.now().difference(dt);
        if (diff.inMinutes < 1) {
          friendlyTime = 'Ahora';
        } else if (diff.inMinutes < 60) {
          friendlyTime = 'Hace ${diff.inMinutes}m';
        } else if (diff.inHours < 24) {
          friendlyTime = 'Hace ${diff.inHours}h';
        } else {
          friendlyTime = 'Hace ${diff.inDays}d';
        }
      } catch (_) {
        friendlyTime = 'Reciente';
      }
    }

    final sev = json['severidad'] ?? 'INFO';
    return Announcement(
      id: json['id'] ?? '',
      tag: json['tag'] ?? sev,
      title: json['titulo'] ?? '',
      detail: json['descripcion'] ?? '',
      time: friendlyTime,
      severidad: sev,
      activo: json['activo'] ?? true,
    );
  }
}

class PaymentRecord {
  final String id;
  final String planName;
  final double price;
  final String date;
  final String method; // Yape, Plin, Tarjeta, Manual
  final String state; // pending, approved, rejected
  final String? receiptUrl; // simulated file path or image

  PaymentRecord({
    required this.id,
    required this.planName,
    required this.price,
    required this.date,
    required this.method,
    required this.state,
    this.receiptUrl,
  });

  PaymentRecord copyWith({
    String? id,
    String? planName,
    double? price,
    String? date,
    String? method,
    String? state,
    String? receiptUrl,
  }) {
    return PaymentRecord(
      id: id ?? this.id,
      planName: planName ?? this.planName,
      price: price ?? this.price,
      date: date ?? this.date,
      method: method ?? this.method,
      state: state ?? this.state,
      receiptUrl: receiptUrl ?? this.receiptUrl,
    );
  }
}

class MemberRecord {
  final String dni;
  final String name;
  final String phone;
  final String email;
  final String startDate;
  final String goal;
  final int sessions;
  final String lastSeen;
  final String state; // active, expired, grace, baja_logica
  final String assignedTrainer;
  final List<PaymentRecord> paymentHistory;
  final Map<String, double> physicalMeasurements; // weight, height, chest, waist, hips
  final List<String> progressImages; // Simulated images
  final bool todayCheckIn;
  final bool isActiveInGym;

  MemberRecord({
    required this.dni,
    required this.name,
    required this.phone,
    required this.email,
    required this.startDate,
    required this.goal,
    required this.sessions,
    required this.lastSeen,
    required this.state,
    required this.assignedTrainer,
    required this.paymentHistory,
    required this.physicalMeasurements,
    required this.progressImages,
    this.todayCheckIn = false,
    this.isActiveInGym = false,
  });

  MemberRecord copyWith({
    String? dni,
    String? name,
    String? phone,
    String? email,
    String? startDate,
    String? goal,
    int? sessions,
    String? lastSeen,
    String? state,
    String? assignedTrainer,
    List<PaymentRecord>? paymentHistory,
    Map<String, double>? physicalMeasurements,
    List<String>? progressImages,
    bool? todayCheckIn,
    bool? isActiveInGym,
  }) {
    return MemberRecord(
      dni: dni ?? this.dni,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      startDate: startDate ?? this.startDate,
      goal: goal ?? this.goal,
      sessions: sessions ?? this.sessions,
      lastSeen: lastSeen ?? this.lastSeen,
      state: state ?? this.state,
      assignedTrainer: assignedTrainer ?? this.assignedTrainer,
      paymentHistory: paymentHistory ?? this.paymentHistory,
      physicalMeasurements: physicalMeasurements ?? this.physicalMeasurements,
      progressImages: progressImages ?? this.progressImages,
      todayCheckIn: todayCheckIn ?? this.todayCheckIn,
      isActiveInGym: isActiveInGym ?? this.isActiveInGym,
    );
  }
}

class ProductItem {
  final String name;
  final String category;
  final double price;
  final int stock;
  final String icon;
  final bool readOnlyLogs;

  ProductItem({
    required this.name,
    required this.category,
    required this.price,
    required this.stock,
    required this.icon,
    this.readOnlyLogs = false,
  });

  ProductItem copyWith({
    String? name,
    String? category,
    double? price,
    int? stock,
    String? icon,
    bool? readOnlyLogs,
  }) {
    return ProductItem(
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      icon: icon ?? this.icon,
      readOnlyLogs: readOnlyLogs ?? this.readOnlyLogs,
    );
  }
}

class AuditEntry {
  final String time;
  final String action;
  final String detail;
  final String actor;
  final Color color;

  AuditEntry({
    required this.time,
    required this.action,
    required this.detail,
    required this.actor,
    required this.color,
  });
}

class CashierAccount {
  final String name;
  final String shift;
  final List<String> permissions;
  final bool active;

  CashierAccount({
    required this.name,
    required this.shift,
    required this.permissions,
    required this.active,
  });

  CashierAccount copyWith({
    String? name,
    String? shift,
    List<String>? permissions,
    bool? active,
  }) {
    return CashierAccount(
      name: name ?? this.name,
      shift: shift ?? this.shift,
      permissions: permissions ?? this.permissions,
      active: active ?? this.active,
    );
  }
}

class ShiftWindow {
  final String start;
  final String end;
  final String remaining;
  final String code;
  final String assignedBy;

  const ShiftWindow({
    required this.start,
    required this.end,
    required this.remaining,
    required this.code,
    required this.assignedBy,
  });
}

class GymObservation {
  final String id;
  final String memberName;
  final String category;
  final String description;
  final String date;
  final String? imageUrl;

  GymObservation({
    required this.id,
    required this.memberName,
    required this.category,
    required this.description,
    required this.date,
    this.imageUrl,
  });
}

class SaaSClient {
  final String id;
  final String name;
  final String logo;
  final String location;
  final String membersCount;
  final bool active;

  SaaSClient({
    required this.id,
    required this.name,
    required this.logo,
    required this.location,
    required this.membersCount,
    required this.active,
  });

  SaaSClient copyWith({
    String? id,
    String? name,
    String? logo,
    String? location,
    String? membersCount,
    bool? active,
  }) {
    return SaaSClient(
      id: id ?? this.id,
      name: name ?? this.name,
      logo: logo ?? this.logo,
      location: location ?? this.location,
      membersCount: membersCount ?? this.membersCount,
      active: active ?? this.active,
    );
  }
}

class LoggedInUser {
  final String id;
  final String email;
  final GymRole rol;
  final String nombreCompleto;
  final String? dni;
  final String? celular;
  final String? fotoUrl;
  final String estado;
  final Map<String, dynamic>? trainerProfile;
  final Map<String, dynamic>? memberProfile;
  final List<dynamic>? memberships;

  LoggedInUser({
    required this.id,
    required this.email,
    required this.rol,
    required this.nombreCompleto,
    this.dni,
    this.celular,
    this.fotoUrl,
    required this.estado,
    this.trainerProfile,
    this.memberProfile,
    this.memberships,
  });

  factory LoggedInUser.fromJson(Map<String, dynamic> json) {
    return LoggedInUser(
      id: json['id'] as String,
      email: json['email'] as String,
      rol: parseRole(json['rol'] as String),
      nombreCompleto: json['nombre_completo'] as String,
      dni: json['dni'] as String?,
      celular: json['celular'] as String?,
      fotoUrl: json['foto_url'] as String?,
      estado: json['estado'] as String,
      trainerProfile: json['trainer_profile'] as Map<String, dynamic>?,
      memberProfile: json['member_profile'] as Map<String, dynamic>?,
      memberships: json['memberships'] as List<dynamic>?,
    );
  }
}


GymRole parseRole(String roleStr) {
  return switch (roleStr.toUpperCase()) {
    'SUPER_ADMIN' => GymRole.superadmin,
    'ADMIN' => GymRole.admin,
    'CAJA' => GymRole.cashier,
    'TRAINER' => GymRole.trainer,
    'MEMBER' || _ => GymRole.member,
  };
}

class CashierSession {
  final String id;
  final String cajeroId;
  final double montoApertura;
  final double? montoCierreEfectivo;
  final double? montoCierreTransferencia;
  final double? montoCierreYape;
  final double? montoCierrePOS;
  final double totalVentasEfectivo;
  final double totalVentasTransferencia;
  final double totalVentasYape;
  final double totalVentasPOS;
  final double totalIngresos;
  final double diferencia;
  final String? observaciones;
  final String estado;
  final String fechaApertura;
  final String? fechaCierre;

  CashierSession({
    required this.id,
    required this.cajeroId,
    required this.montoApertura,
    this.montoCierreEfectivo,
    this.montoCierreTransferencia,
    this.montoCierreYape,
    this.montoCierrePOS,
    required this.totalVentasEfectivo,
    required this.totalVentasTransferencia,
    required this.totalVentasYape,
    required this.totalVentasPOS,
    required this.totalIngresos,
    required this.diferencia,
    this.observaciones,
    required this.estado,
    required this.fechaApertura,
    this.fechaCierre,
  });

  factory CashierSession.fromJson(Map<String, dynamic> json) {
    return CashierSession(
      id: json['id'] as String,
      cajeroId: json['cajero_id'] as String,
      montoApertura: (json['monto_apertura'] as num).toDouble(),
      montoCierreEfectivo: json['monto_cierre_efectivo'] != null
          ? (json['monto_cierre_efectivo'] as num).toDouble()
          : null,
      montoCierreTransferencia: json['monto_cierre_transferencia'] != null
          ? (json['monto_cierre_transferencia'] as num).toDouble()
          : null,
      montoCierreYape: json['monto_cierre_yape'] != null
          ? (json['monto_cierre_yape'] as num).toDouble()
          : null,
      montoCierrePOS: json['monto_cierre_pos'] != null
          ? (json['monto_cierre_pos'] as num).toDouble()
          : null,
      totalVentasEfectivo: (json['total_ventas_efectivo'] as num? ?? 0).toDouble(),
      totalVentasTransferencia: (json['total_ventas_transferencia'] as num? ?? 0).toDouble(),
      totalVentasYape: (json['total_ventas_yape'] as num? ?? 0).toDouble(),
      totalVentasPOS: (json['total_ventas_pos'] as num? ?? 0).toDouble(),
      totalIngresos: (json['total_ingresos'] as num? ?? 0).toDouble(),
      diferencia: (json['diferencia'] as num? ?? 0).toDouble(),
      observaciones: json['observaciones'] as String?,
      estado: json['estado'] as String,
      fechaApertura: json['fecha_apertura'] as String,
      fechaCierre: json['fecha_cierre'] as String?,
    );
  }
}

class MovimientoCaja {
  final String id;
  final String cajaId;
  final String tipo; // ingreso | egreso
  final double monto;
  final String descripcion;
  final String createdAt;

  MovimientoCaja({
    required this.id,
    required this.cajaId,
    required this.tipo,
    required this.monto,
    required this.descripcion,
    required this.createdAt,
  });

  factory MovimientoCaja.fromJson(Map<String, dynamic> json) {
    return MovimientoCaja(
      id: json['id'] as String,
      cajaId: json['caja_id'] as String,
      tipo: json['tipo'] as String,
      monto: (json['monto'] as num).toDouble(),
      descripcion: json['descripcion'] as String,
      createdAt: json['created_at'] as String,
    );
  }
}

class UserPoints {
  final String usuarioId;
  final int puntosDisponibles;
  final int puntosTotalesGanados;
  final int puntosTotalesCanjeados;

  UserPoints({
    required this.usuarioId,
    required this.puntosDisponibles,
    required this.puntosTotalesGanados,
    required this.puntosTotalesCanjeados,
  });

  factory UserPoints.fromJson(Map<String, dynamic> json) {
    return UserPoints(
      usuarioId: json['usuario_id'] as String,
      puntosDisponibles: json['puntos_disponibles'] as int? ?? 0,
      puntosTotalesGanados: json['puntos_totales_ganados'] as int? ?? 0,
      puntosTotalesCanjeados: json['puntos_totales_canjeados'] as int? ?? 0,
    );
  }
}

class PointsMovement {
  final String id;
  final String usuarioId;
  final String tipo; // ingreso | canje | ajuste | devolucion
  final int cantidad;
  final int saldoAnterior;
  final int saldoNuevo;
  final String descripcion;
  final String createdAt;

  PointsMovement({
    required this.id,
    required this.usuarioId,
    required this.tipo,
    required this.cantidad,
    required this.saldoAnterior,
    required this.saldoNuevo,
    required this.descripcion,
    required this.createdAt,
  });

  factory PointsMovement.fromJson(Map<String, dynamic> json) {
    return PointsMovement(
      id: json['id'] as String,
      usuarioId: json['usuario_id'] as String,
      tipo: json['tipo'] as String,
      cantidad: json['cantidad'] as int,
      saldoAnterior: json['saldo_anterior'] as int,
      saldoNuevo: json['saldo_nuevo'] as int,
      descripcion: json['descripcion'] as String,
      createdAt: json['created_at'] as String,
    );
  }
}
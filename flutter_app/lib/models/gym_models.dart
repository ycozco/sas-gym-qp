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
  final String name;
  final String muscle;
  final int sets;
  final String reps;
  final int? weight;
  final int restSeconds;
  final IconData icon;
  final bool available;

  ExerciseItem({
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
  final String tag;
  final String title;
  final String detail;
  final String time;

  Announcement({
    required this.tag,
    required this.title,
    required this.detail,
    required this.time,
  });
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
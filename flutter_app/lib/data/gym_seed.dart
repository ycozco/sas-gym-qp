import 'package:flutter/material.dart';

import '../models/gym_models.dart';

final Map<GymRole, RolePalette> rolePalettes = <GymRole, RolePalette>{
  GymRole.member: RolePalette(
    accent: const Color(0xFFD2FF3A),
    accentInk: const Color(0xFF0B0B0B),
    surfaceTint: const Color(0xFFF8F6EE),
    gradient: const LinearGradient(
      colors: [Color(0xFFF8F6EE), Color(0xFFF1F7D8)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    label: 'Experiencia del socio',
  ),
  GymRole.trainer: RolePalette(
    accent: const Color(0xFF0066FF),
    accentInk: Colors.white,
    surfaceTint: const Color(0xFFF2F7FF),
    gradient: const LinearGradient(
      colors: [Color(0xFFF2F7FF), Color(0xFFDCEBFF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    label: 'Planificación y progreso',
  ),
  GymRole.cashier: RolePalette(
    accent: const Color(0xFFFF7A1A),
    accentInk: Colors.white,
    surfaceTint: const Color(0xFFFFF4EA),
    gradient: const LinearGradient(
      colors: [Color(0xFFFFF4EA), Color(0xFFFFE0C3)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    label: 'Operación limitada',
  ),
  GymRole.admin: RolePalette(
    accent: const Color(0xFF7A5AE0),
    accentInk: Colors.white,
    surfaceTint: const Color(0xFFF6F1FF),
    gradient: const LinearGradient(
      colors: [Color(0xFFF6F1FF), Color(0xFFE0D5FF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    label: 'Gestión total y auditoría',
  ),
  GymRole.superadmin: RolePalette(
    accent: const Color(0xFFE91E63),
    accentInk: Colors.white,
    surfaceTint: const Color(0xFFFFF2F6),
    gradient: const LinearGradient(
      colors: [Color(0xFFFFF2F6), Color(0xFFFFD1DF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    label: 'Métricas de la red y control',
  ),
};

const List<MetricItem> memberMetrics = <MetricItem>[
  MetricItem(icon: Icons.calendar_month, label: 'Esta semana', value: '3 / 6', note: '+1 vs sem. anterior'),
  MetricItem(icon: Icons.workspace_premium, label: 'Membresía', value: '14 días', note: 'Vence el 4 jun'),
];

const List<WorkoutDay> memberWeek = <WorkoutDay>[
  WorkoutDay(day: 'Lun', number: 19, group: 'Pecho', today: false, rest: false),
  WorkoutDay(day: 'Mar', number: 20, group: 'Pull', today: false, rest: false),
  WorkoutDay(day: 'Mié', number: 21, group: 'Push', today: true, rest: false),
  WorkoutDay(day: 'Jue', number: 22, group: 'Pierna', today: false, rest: false),
  WorkoutDay(day: 'Vie', number: 23, group: 'Full body', today: false, rest: false),
  WorkoutDay(day: 'Sáb', number: 24, group: 'Core', today: false, rest: false),
  WorkoutDay(day: 'Dom', number: 25, group: 'Descanso', today: false, rest: true),
];

final List<ExerciseItem> memberExercises = <ExerciseItem>[
  ExerciseItem(name: 'Press de banca', muscle: 'Pecho', sets: 4, reps: '8-10', weight: 70, restSeconds: 90, icon: Icons.fitness_center, available: true),
  ExerciseItem(name: 'Press inclinado con mancuernas', muscle: 'Pecho superior', sets: 4, reps: '10-12', weight: 24, restSeconds: 75, icon: Icons.fitness_center, available: true),
  ExerciseItem(name: 'Aperturas en máquina', muscle: 'Pecho', sets: 3, reps: '12-15', weight: 35, restSeconds: 60, icon: Icons.bolt, available: true),
  ExerciseItem(name: 'Press militar barra', muscle: 'Hombro', sets: 4, reps: '8-10', weight: 40, restSeconds: 90, icon: Icons.fitness_center, available: true),
  ExerciseItem(name: 'Elevaciones laterales', muscle: 'Hombro', sets: 4, reps: '12-15', weight: 10, restSeconds: 60, icon: Icons.bolt, available: true),
  ExerciseItem(name: 'Fondos en paralelas', muscle: 'Tríceps', sets: 3, reps: 'Al fallo', weight: null, restSeconds: 90, icon: Icons.chevron_right, available: true),
];

final List<Announcement> gymAnnouncements = <Announcement>[
  Announcement(tag: 'EVENTO', title: 'Clases gratis sábado', detail: 'Funcional al aire libre 8am · Parque Kennedy', time: 'Hace 2h'),
  Announcement(tag: 'AVISO', title: 'Mantenimiento jueves', detail: 'Máquina Smith fuera de servicio de 6 a 9pm', time: 'Ayer'),
];


final List<ExerciseItem> exerciseLibrary = <ExerciseItem>[
  ExerciseItem(name: 'Press de banca', muscle: 'Pecho', sets: 4, reps: '8-10', weight: 70, restSeconds: 90, icon: Icons.fitness_center, available: true),
  ExerciseItem(name: 'Sentadilla con barra', muscle: 'Pierna', sets: 5, reps: '6-8', weight: 90, restSeconds: 120, icon: Icons.fitness_center, available: true),
  ExerciseItem(name: 'Peso muerto convencional', muscle: 'Espalda', sets: 5, reps: '5-6', weight: 100, restSeconds: 150, icon: Icons.fitness_center, available: true),
  ExerciseItem(name: 'Press militar', muscle: 'Hombro', sets: 4, reps: '8-10', weight: 40, restSeconds: 90, icon: Icons.fitness_center, available: true),
  ExerciseItem(name: 'Remo con barra', muscle: 'Espalda', sets: 4, reps: '10-12', weight: 55, restSeconds: 75, icon: Icons.bolt, available: true),
  ExerciseItem(name: 'Hip thrust', muscle: 'Glúteo', sets: 4, reps: '10-12', weight: 80, restSeconds: 75, icon: Icons.fitness_center, available: true),
  ExerciseItem(name: 'Curl bíceps mancuerna', muscle: 'Bíceps', sets: 3, reps: '12-15', weight: 12, restSeconds: 60, icon: Icons.bolt, available: false),
  ExerciseItem(name: 'Fondos en paralelas', muscle: 'Tríceps', sets: 3, reps: 'Al fallo', weight: null, restSeconds: 90, icon: Icons.fitness_center, available: true),
];

const List<MetricItem> trainerMetrics = <MetricItem>[
  MetricItem(icon: Icons.people, label: 'Activos hoy', value: '5', note: '+2 vs ayer'),
  MetricItem(icon: Icons.timer_outlined, label: 'Sesiones semana', value: '23', note: '+18% vs semana pasada'),
];

const List<MetricItem> cashierMetrics = <MetricItem>[
  MetricItem(icon: Icons.output, label: 'Asistencias', value: '28', note: 'desde las 6:00'),
  MetricItem(icon: Icons.point_of_sale, label: 'Ventas', value: '11', note: 'S/ 245 productos'),
];

const ShiftWindow activeShift = ShiftWindow(
  start: '06:00',
  end: '14:00',
  remaining: '3h 42m',
  code: 'CJ-002',
  assignedBy: 'Sandra Aguilar',
);

final List<ProductItem> products = <ProductItem>[
  ProductItem(name: 'Botella de agua 600ml', category: 'Bebidas', price: 3, stock: 124, icon: '💧', readOnlyLogs: true),
  ProductItem(name: 'Proteína whey · porción', category: 'Suplementos', price: 12, stock: 38, icon: '💪', readOnlyLogs: true),
  ProductItem(name: 'Pre-entreno · scoop', category: 'Suplementos', price: 8, stock: 22, icon: '⚡', readOnlyLogs: true),
  ProductItem(name: 'Barra energética', category: 'Snacks', price: 5, stock: 56, icon: '🍫', readOnlyLogs: true),
  ProductItem(name: 'Polo oficial SaaaS', category: 'Merch', price: 45, stock: 18, icon: '👕', readOnlyLogs: true),
  ProductItem(name: 'Toalla deportiva', category: 'Accesorios', price: 5, stock: 12, icon: '🏃', readOnlyLogs: true),
  ProductItem(name: 'Creatina · porción', category: 'Suplementos', price: 6, stock: 41, icon: '💊', readOnlyLogs: true),
  ProductItem(name: 'Shaker 600ml', category: 'Merch', price: 18, stock: 9, icon: '🥤', readOnlyLogs: true),
];

final List<CashierAccount> cashiers = <CashierAccount>[
  CashierAccount(name: 'Mariana Quispe', shift: '06:00 - 14:00', permissions: <String>['Cobros', 'Asistencia', 'Ventas', 'Productos', 'Usuarios'], active: true),
  CashierAccount(name: 'Luis Yupanqui', shift: '14:00 - 22:00', permissions: <String>['Cobros', 'Asistencia', 'Ventas', 'Productos'], active: true),
  CashierAccount(name: 'Valeria Ruiz', shift: '18:00 - 22:00', permissions: <String>['Cobros', 'Usuarios', 'Log lectura'], active: false),
];

final List<AuditEntry> cashierLogs = <AuditEntry>[
  AuditEntry(time: '11:30', action: 'Cobró membresía', detail: 'Rosa Mendieta · S/ 120 · Yape', actor: 'Mariana Q.', color: Color(0xFF00B85C)),
  AuditEntry(time: '10:22', action: 'Cobró membresía', detail: 'Jorge Paredes · S/ 1.080 · Tarjeta', actor: 'Mariana Q.', color: Color(0xFF00B85C)),
  AuditEntry(time: '09:48', action: 'Vendió producto', detail: 'Polo oficial L · S/ 45 · Yape', actor: 'Mariana Q.', color: Color(0xFF0066FF)),
  AuditEntry(time: '09:14', action: 'Editó usuario', detail: 'Ana Torres · actualizó celular', actor: 'Mariana Q.', color: Color(0xFFFFB300)),
  AuditEntry(time: '08:42', action: 'Registró ingreso', detail: 'Mateo Salas · QR escaneado', actor: 'Mariana Q.', color: Color(0xFF5C5C5C)),
];

final List<AuditEntry> auditLog = <AuditEntry>[
  AuditEntry(time: '11:30', action: 'Cobró membresía', detail: 'Rosa Mendieta · S/ 120 · Yape', actor: 'Caja · Mariana Q.', color: Color(0xFF00B85C)),
  AuditEntry(time: '10:45', action: 'Creó cajero', detail: 'Nuevo usuario de caja con turno 06:00 - 14:00', actor: 'Admin · Sandra A.', color: Color(0xFF7A5AE0)),
  AuditEntry(time: '10:22', action: 'Actualizó precio', detail: 'Whey porción S/ 12 → S/ 13', actor: 'Admin · Sandra A.', color: Color(0xFF7A5AE0)),
  AuditEntry(time: '09:48', action: 'Baja lógica', detail: 'Usuario Pedro Quispe desactivado sin borrar historial', actor: 'Caja · Mariana Q.', color: Color(0xFFFF7A1A)),
  AuditEntry(time: '09:14', action: 'Editó usuario', detail: 'Ana Torres · celular actualizado', actor: 'Caja · Mariana Q.', color: Color(0xFFFFB300)),
  AuditEntry(time: '08:42', action: 'Publicó rutina', detail: 'Push · Pecho + Hombros a 3 alumnos', actor: 'Trainer · Carlos M.', color: Color(0xFF0066FF)),
];

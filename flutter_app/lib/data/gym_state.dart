import 'package:flutter/material.dart';
import '../models/gym_models.dart';

class GymState extends ChangeNotifier {
  GymState() {
    _initializeData();
  }

  // Active SaaS Client (instance)
  String _selectedClientId = 'gym_santiago';
  String get selectedClientId => _selectedClientId;

  // Settings
  int graceDays = 1;
  int alertDays = 5;

  // Collections
  final List<MemberRecord> _members = [];
  final List<ProductItem> _products = [];
  final List<CashierAccount> _cashiers = [];
  final List<AuditEntry> _auditLogs = [];
  final List<Announcement> _announcements = [];
  final List<GymObservation> _observations = [];
  final List<SaaSClient> _saClients = [];

  // Getters
  List<MemberRecord> get members => _members.where((m) => m.state != 'baja_logica').toList();
  List<MemberRecord> get allMembersIncludingSoftDeleted => _members;
  List<ProductItem> get products => _products;
  List<CashierAccount> get cashiers => _cashiers;
  List<AuditEntry> get auditLogs => _auditLogs;
  List<Announcement> get announcements => _announcements;
  List<GymObservation> get observations => _observations;
  List<SaaSClient> get saClients => _saClients;

  // Verification: is current gym blocked?
  bool get isCurrentGymActive {
    final client = _saClients.firstWhere(
      (c) => c.id == _selectedClientId,
      orElse: () => SaaSClient(id: '', name: '', logo: '', location: '', membersCount: '0', active: true),
    );
    return client.active;
  }

  void selectClient(String clientId) {
    _selectedClientId = clientId;
    notifyListeners();
  }

  // --- Attendance scanning ---
  String recordAttendance(String memberDni) {
    final index = _members.indexWhere((m) => m.dni == memberDni);
    if (index == -1) {
      _addLog('Escáner', 'Acceso denegado', 'DNI $memberDni no registrado', Colors.red);
      return 'not_found';
    }

    final member = _members[index];
    if (member.state == 'baja_logica') {
      _addLog('Escáner', 'Acceso denegado', '${member.name} está inactivo (baja lógica)', Colors.red);
      return 'denied';
    }

    if (member.state == 'expired') {
      _addLog('Escáner', 'Acceso denegado', 'Membresía de ${member.name} vencida', Colors.red);
      return 'denied';
    }

    // Determine state
    String result = 'granted';
    Color logColor = const Color(0xFF00B85C);
    String detail = '${member.name} ingresó al gimnasio (QR verificado)';

    if (member.state == 'grace') {
      result = 'grace';
      logColor = const Color(0xFFFFB300);
      detail = '${member.name} ingresó en día de gracia (Renovación pendiente)';
    }

    _members[index] = member.copyWith(
      sessions: member.sessions + 1,
      lastSeen: 'Hoy',
      todayCheckIn: true,
      isActiveInGym: true,
    );

    _addLog('Escáner', 'Registro de ingreso', detail, logColor);
    notifyListeners();
    return result;
  }

  void checkoutMember(String memberDni) {
    final index = _members.indexWhere((m) => m.dni == memberDni);
    if (index != -1) {
      final member = _members[index];
      _members[index] = member.copyWith(
        todayCheckIn: false,
        isActiveInGym: false,
      );
      _addLog('Escáner', 'Registro de salida', '${member.name} salió del gimnasio', const Color(0xFF5C5C5C));
      notifyListeners();
    }
  }

  // --- Manual payments flow ---
  void submitManualPayment({
    required String memberDni,
    required String planName,
    required double price,
    required String method,
    required String receiptName,
  }) {
    final index = _members.indexWhere((m) => m.dni == memberDni);
    if (index == -1) return;

    final member = _members[index];
    final newPayment = PaymentRecord(
      id: 'PAY-${DateTime.now().millisecondsSinceEpoch}',
      planName: planName,
      price: price,
      date: _formatCurrentDate(),
      method: method,
      state: 'pending',
      receiptUrl: receiptName,
    );

    final updatedHistory = List<PaymentRecord>.from(member.paymentHistory)..add(newPayment);
    _members[index] = member.copyWith(paymentHistory: updatedHistory);

    _addLog('Socio', 'Subió comprobante', '${member.name} cargó comprobante manual para $planName (S/ $price)', const Color(0xFF0066FF));
    notifyListeners();
  }

  void approveManualPayment(String memberDni, String paymentId) {
    final mIndex = _members.indexWhere((m) => m.dni == memberDni);
    if (mIndex == -1) return;

    final member = _members[mIndex];
    final pIndex = member.paymentHistory.indexWhere((p) => p.id == paymentId);
    if (pIndex == -1) return;

    final payment = member.paymentHistory[pIndex];
    final updatedPayment = payment.copyWith(state: 'approved');
    final updatedHistory = List<PaymentRecord>.from(member.paymentHistory)..[pIndex] = updatedPayment;

    _members[mIndex] = member.copyWith(
      paymentHistory: updatedHistory,
      state: 'active', // Reactively activate their membership
      lastSeen: 'Hoy',
    );

    _addLog('Admin', 'Aprobó pago', 'Pago $paymentId de ${member.name} aprobado. Membresía activada.', const Color(0xFF00B85C));
    notifyListeners();
  }

  void rejectManualPayment(String memberDni, String paymentId) {
    final mIndex = _members.indexWhere((m) => m.dni == memberDni);
    if (mIndex == -1) return;

    final member = _members[mIndex];
    final pIndex = member.paymentHistory.indexWhere((p) => p.id == paymentId);
    if (pIndex == -1) return;

    final payment = member.paymentHistory[pIndex];
    final updatedPayment = payment.copyWith(state: 'rejected');
    final updatedHistory = List<PaymentRecord>.from(member.paymentHistory)..[pIndex] = updatedPayment;

    _members[mIndex] = member.copyWith(paymentHistory: updatedHistory);

    _addLog('Admin', 'Rechazó pago', 'Pago $paymentId de ${member.name} rechazado.', Colors.red);
    notifyListeners();
  }

  // --- POS checkout ---
  void chargePOS({
    required String memberDni,
    required List<Map<String, dynamic>> cartItems,
    required double total,
    required String paymentMethod,
  }) {
    final mIndex = _members.indexWhere((m) => m.dni == memberDni);
    if (mIndex == -1) return;

    final member = _members[mIndex];
    final updatedHistory = List<PaymentRecord>.from(member.paymentHistory);
    bool boughtMembership = false;

    for (var item in cartItems) {
      final name = item['name'] as String;
      final price = (item['price'] as num).toDouble();
      final qty = item['qty'] as int;

      // Check if it's a membership plan
      if (name.contains('Membresía') || name.contains('Plan')) {
        boughtMembership = true;
        updatedHistory.add(PaymentRecord(
          id: 'PAY-${DateTime.now().millisecondsSinceEpoch}',
          planName: name,
          price: price * qty,
          date: _formatCurrentDate(),
          method: paymentMethod,
          state: 'approved',
        ));
      } else {
        // Decrease product stock
        final prodIndex = _products.indexWhere((p) => p.name == name);
        if (prodIndex != -1) {
          final prod = _products[prodIndex];
          _products[prodIndex] = prod.copyWith(stock: (prod.stock - qty).clamp(0, 9999));
        }
      }
    }

    _members[mIndex] = member.copyWith(
      paymentHistory: updatedHistory,
      state: boughtMembership ? 'active' : member.state,
    );

    _addLog(
      'Caja',
      'Venta POS',
      '${member.name} pagó S/ $total via $paymentMethod. Items: ${cartItems.map((c) => "${c['qty']}x ${c['name']}").join(", ")}',
      const Color(0xFF00B85C),
    );
    notifyListeners();
  }

  // --- CRUD members ---
  void addMember(MemberRecord member) {
    _members.add(member);
    _addLog('Admin', 'Creó socio', 'Socio registrado: ${member.name} (DNI ${member.dni})', const Color(0xFF7A5AE0));
    notifyListeners();
  }

  void updateMember(String dni, MemberRecord updated) {
    final index = _members.indexWhere((m) => m.dni == dni);
    if (index != -1) {
      _members[index] = updated;
      _addLog('Admin', 'Editó socio', 'Socio ${updated.name} actualizado.', const Color(0xFFFFB300));
      notifyListeners();
    }
  }

  void toggleMemberLogicDelete(String memberDni) {
    final index = _members.indexWhere((m) => m.dni == memberDni);
    if (index == -1) return;

    final member = _members[index];
    if (member.state == 'baja_logica') {
      // Restore to active or expired
      final hasActivePayment = member.paymentHistory.any((p) => p.state == 'approved');
      final restoredState = hasActivePayment ? 'active' : 'expired';
      _members[index] = member.copyWith(state: restoredState);
      _addLog('Admin', 'Restauró socio', 'Usuario ${member.name} reactivado.', const Color(0xFF00B85C));
    } else {
      // Soft-delete
      _members[index] = member.copyWith(state: 'baja_logica', todayCheckIn: false, isActiveInGym: false);
      _addLog('Admin', 'Baja lógica', 'Usuario ${member.name} desactivado (baja lógica).', const Color(0xFFFF7A1A));
    }
    notifyListeners();
  }

  // --- CRUD products ---
  void addProduct(ProductItem product) {
    _products.add(product);
    _addLog('Caja', 'Creó producto', 'Producto agregado: ${product.name} (Stock: ${product.stock})', const Color(0xFF0066FF));
    notifyListeners();
  }

  void updateProduct(String oldName, ProductItem updated) {
    final index = _products.indexWhere((p) => p.name == oldName);
    if (index != -1) {
      _products[index] = updated;
      _addLog('Admin', 'Editó producto', 'Producto ${updated.name} modificado.', const Color(0xFFFFB300));
      notifyListeners();
    }
  }

  void deleteProductPhysical(String productName) {
    final index = _products.indexWhere((p) => p.name == productName);
    if (index != -1) {
      _products.removeAt(index);
      _addLog('Admin', 'Eliminó producto', 'Eliminado definitivamente de inventario: $productName', Colors.red);
      notifyListeners();
    }
  }

  // --- Cashier permissions ---
  void toggleCashierPermission(String cashierName, String permission) {
    final index = _cashiers.indexWhere((c) => c.name == cashierName);
    if (index == -1) return;

    final cashier = _cashiers[index];
    final updatedPermissions = List<String>.from(cashier.permissions);
    if (updatedPermissions.contains(permission)) {
      updatedPermissions.remove(permission);
    } else {
      updatedPermissions.add(permission);
    }

    _cashiers[index] = cashier.copyWith(permissions: updatedPermissions);
    _addLog('Admin', 'Permisos cajero', 'Modificó permisos de $cashierName: $permission', const Color(0xFF7A5AE0));
    notifyListeners();
  }

  void toggleCashierActive(String cashierName) {
    final index = _cashiers.indexWhere((c) => c.name == cashierName);
    if (index == -1) return;

    final cashier = _cashiers[index];
    _cashiers[index] = cashier.copyWith(active: !cashier.active);
    _addLog('Admin', 'Estado cajero', '$cashierName marcado como ${!cashier.active ? 'inactivo' : 'activo'}', const Color(0xFF7A5AE0));
    notifyListeners();
  }

  // --- Settings ---
  void updateGymSettings(int graceDays, int alertDays) {
    this.graceDays = graceDays;
    this.alertDays = alertDays;
    _addLog('Admin', 'Ajustes gimnasio', 'Días gracia: $graceDays, alertas: $alertDays', const Color(0xFF7A5AE0));
    notifyListeners();
  }

  // --- SaaS Client management ---
  void toggleSaClient(String clientId) {
    final index = _saClients.indexWhere((c) => c.id == clientId);
    if (index == -1) return;

    final client = _saClients[index];
    final nextState = !client.active;
    _saClients[index] = client.copyWith(active: nextState);

    _addLog(
      'SuperAdmin',
      nextState ? 'Habilitó Gym' : 'Suspendió Gym',
      'Sede/Cliente ${client.name} ${nextState ? 'activado' : 'bloqueado'} en la plataforma SaaS.',
      nextState ? const Color(0xFF00B85C) : Colors.red,
    );
    notifyListeners();
  }

  // --- Observations ---
  void addObservation(String category, String description, String memberName) {
    final id = 'OBS-${DateTime.now().millisecondsSinceEpoch}';
    final date = _formatCurrentDate();
    _observations.add(GymObservation(
      id: id,
      memberName: memberName,
      category: category,
      description: description,
      date: date,
    ));
    _addLog('Socio', 'Reportó problema', 'Socio $memberName reportó en $category: $description', const Color(0xFFFF7A1A));
    notifyListeners();
  }

  // --- Announcements ---
  void addAnnouncement(String tag, String title, String detail) {
    _announcements.insert(0, Announcement(
      tag: tag,
      title: title,
      detail: detail,
      time: 'Ahora',
    ));
    _addLog('Admin', 'Creó anuncio', 'Nuevo aviso [$tag]: $title', const Color(0xFF7A5AE0));
    notifyListeners();
  }

  // --- Helpers ---
  void _addLog(String actor, String action, String detail, [Color color = const Color(0xFF5C5C5C)]) {
    _auditLogs.insert(0, AuditEntry(
      time: _formatCurrentTime(),
      action: action,
      detail: detail,
      actor: actor,
      color: color,
    ));
  }

  String _formatCurrentTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  String _formatCurrentDate() {
    final now = DateTime.now();
    return '${now.day} de ${_getMonthName(now.month)}';
  }

  String _getMonthName(int month) {
    const months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    return months[month - 1];
  }

  void _initializeData() {
    // SaaS clients
    _saClients.addAll([
      SaaSClient(id: 'gym_santiago', name: 'SAS Gym Santiago', logo: '🏋️', location: 'Av. Providencia, Santiago', membersCount: '154', active: true),
      SaaSClient(id: 'gym_lima', name: 'SAS Gym Lima Centro', logo: '💪', location: 'Jr. Carabaya, Lima', membersCount: '89', active: true),
      SaaSClient(id: 'gym_bogota', name: 'SAS Gym Bogotá Norte', logo: '⚡', location: 'Cl. 85, Bogotá', membersCount: '124', active: false),
    ]);

    // Initial products
    _products.addAll([
      ProductItem(name: 'Botella de agua 600ml', category: 'Bebidas', price: 3.0, stock: 124, icon: '💧'),
      ProductItem(name: 'Proteína whey · porción', category: 'Suplementos', price: 12.0, stock: 38, icon: '💪'),
      ProductItem(name: 'Pre-entreno · scoop', category: 'Suplementos', price: 8.0, stock: 22, icon: '⚡'),
      ProductItem(name: 'Barra energética', category: 'Snacks', price: 5.0, stock: 56, icon: '🍫'),
      ProductItem(name: 'Polo oficial SaaaS', category: 'Merch', price: 45.0, stock: 18, icon: '👕'),
      ProductItem(name: 'Toalla deportiva', category: 'Accesorios', price: 15.0, stock: 12, icon: '🏃'),
    ]);

    // Initial cashiers
    _cashiers.addAll([
      CashierAccount(name: 'Mariana Quispe', shift: '06:00 - 14:00', permissions: ['Cobros', 'Asistencia', 'Ventas', 'Productos', 'Usuarios'], active: true),
      CashierAccount(name: 'Luis Yupanqui', shift: '14:00 - 22:00', permissions: ['Cobros', 'Asistencia', 'Ventas', 'Productos'], active: true),
      CashierAccount(name: 'Valeria Ruiz', shift: '18:00 - 22:00', permissions: ['Cobros', 'Usuarios'], active: false),
    ]);

    // Initial announcements
    _announcements.addAll([
      Announcement(tag: 'EVENTO', title: 'Clases gratis sábado', detail: 'Funcional al aire libre 8am · Parque Kennedy', time: 'Hace 2h'),
      Announcement(tag: 'AVISO', title: 'Mantenimiento jueves', detail: 'Máquina Smith fuera de servicio de 6 a 9pm', time: 'Ayer'),
    ]);

    // Initial observations / complaints
    _observations.addAll([
      GymObservation(id: 'OBS-1', memberName: 'Diego Castro', category: 'Equipamiento', description: 'La polea alta del lado izquierdo suena extraño y vibra mucho.', date: '20 de may'),
      GymObservation(id: 'OBS-2', memberName: 'Rosa Mendieta', category: 'Limpieza', description: 'Falta jabón líquido en el baño de mujeres del segundo piso.', date: '19 de may'),
    ]);

    // Audit logs
    _auditLogs.addAll([
      AuditEntry(time: '11:30', action: 'Cobró membresía', detail: 'Rosa Mendieta · S/ 120 · Yape', actor: 'Caja · Mariana Q.', color: const Color(0xFF00B85C)),
      AuditEntry(time: '10:45', action: 'Creó cajero', detail: 'Nuevo usuario de caja con turno 06:00 - 14:00', actor: 'Admin · Sandra A.', color: const Color(0xFF7A5AE0)),
      AuditEntry(time: '10:22', action: 'Actualizó precio', detail: 'Whey porción S/ 12 → S/ 13', actor: 'Admin · Sandra A.', color: const Color(0xFF7A5AE0)),
      AuditEntry(time: '09:48', action: 'Baja lógica', detail: 'Usuario Pedro Quispe desactivado sin borrar historial', actor: 'Caja · Mariana Q.', color: const Color(0xFFFF7A1A)),
      AuditEntry(time: '09:14', action: 'Editó usuario', detail: 'Ana Torres · celular actualizado', actor: 'Caja · Mariana Q.', color: const Color(0xFFFFB300)),
      AuditEntry(time: '08:42', action: 'Publicó rutina', detail: 'Push · Pecho + Hombros a 3 alumnos', actor: 'Trainer · Carlos M.', color: const Color(0xFF0066FF)),
    ]);

    // Initial members with richer data
    _members.addAll([
      MemberRecord(
        dni: '12345678',
        name: 'Mateo Salas',
        phone: '987654321',
        email: 'mateo@mail.com',
        startDate: '01 de ene',
        goal: 'Hipertrofia',
        sessions: 47,
        lastSeen: 'Hoy',
        state: 'active',
        assignedTrainer: 'Carlos M.',
        isActiveInGym: true,
        physicalMeasurements: {'peso': 78.5, 'altura': 1.78, 'pecho': 98.0, 'cintura': 82.0, 'cadera': 94.0},
        progressImages: [],
        paymentHistory: [
          PaymentRecord(id: 'PAY-101', planName: 'Plan Mensual Oro', price: 150.0, date: '01 de may', method: 'Yape', state: 'approved'),
          PaymentRecord(id: 'PAY-100', planName: 'Plan Mensual Oro', price: 150.0, date: '01 de abr', method: 'Yape', state: 'approved'),
        ],
      ),
      MemberRecord(
        dni: '87654321',
        name: 'Lucía Fernández',
        phone: '912345678',
        email: 'lucia@mail.com',
        startDate: '15 de feb',
        goal: 'Pérdida grasa',
        sessions: 32,
        lastSeen: 'Ayer',
        state: 'active',
        assignedTrainer: 'Carlos M.',
        isActiveInGym: false,
        physicalMeasurements: {'peso': 62.1, 'altura': 1.64, 'pecho': 88.0, 'cintura': 68.0, 'cadera': 99.0},
        progressImages: [],
        paymentHistory: [
          PaymentRecord(id: 'PAY-102', planName: 'Plan Trimestral Platinium', price: 400.0, date: '15 de feb', method: 'Tarjeta', state: 'approved'),
        ],
      ),
      MemberRecord(
        dni: '11223344',
        name: 'Diego Castro',
        phone: '955667788',
        email: 'diego@mail.com',
        startDate: '10 de mar',
        goal: 'Fuerza máx.',
        sessions: 64,
        lastSeen: 'Hace 2d',
        state: 'expired',
        assignedTrainer: 'Carlos M.',
        isActiveInGym: false,
        physicalMeasurements: {'peso': 89.2, 'altura': 1.82, 'pecho': 106.0, 'cintura': 88.0, 'cadera': 101.0},
        progressImages: [],
        paymentHistory: [
          PaymentRecord(id: 'PAY-103', planName: 'Plan Mensual Plata', price: 120.0, date: '10 de mar', method: 'Plin', state: 'approved'),
        ],
      ),
      MemberRecord(
        dni: '44332211',
        name: 'Rosa Mendieta',
        phone: '933442211',
        email: 'rosa@mail.com',
        startDate: '05 de may',
        goal: 'Tonificación',
        sessions: 18,
        lastSeen: 'Hace 4d',
        state: 'active',
        assignedTrainer: 'Carlos M.',
        isActiveInGym: false,
        physicalMeasurements: {'peso': 55.4, 'altura': 1.58, 'pecho': 84.0, 'cintura': 64.0, 'cadera': 90.0},
        progressImages: [],
        paymentHistory: [
          PaymentRecord(id: 'PAY-104', planName: 'Plan Mensual Plata', price: 120.0, date: '05 de may', method: 'Yape', state: 'approved'),
        ],
      ),
      MemberRecord(
        dni: '55667788',
        name: 'Ana Torres',
        phone: '977889900',
        email: 'ana@mail.com',
        startDate: '20 de abr',
        goal: 'Mensual',
        sessions: 21,
        lastSeen: '1 día gracia',
        state: 'grace',
        assignedTrainer: 'Carlos M.',
        isActiveInGym: false,
        physicalMeasurements: {'peso': 58.0, 'altura': 1.60, 'pecho': 86.0, 'cintura': 67.0, 'cadera': 92.0},
        progressImages: [],
        paymentHistory: [
          PaymentRecord(id: 'PAY-105', planName: 'Plan Mensual Oro', price: 150.0, date: '20 de abr', method: 'Tarjeta', state: 'approved'),
        ],
      ),
      MemberRecord(
        dni: '99887766',
        name: 'Pedro Quispe',
        phone: '999888777',
        email: 'pedro@mail.com',
        startDate: '01 de may',
        goal: 'Rehabilitación',
        sessions: 9,
        lastSeen: 'Hace 8d',
        state: 'baja_logica',
        assignedTrainer: 'Carlos M.',
        isActiveInGym: false,
        physicalMeasurements: {'peso': 73.0, 'altura': 1.70, 'pecho': 92.0, 'cintura': 85.0, 'cadera': 96.0},
        progressImages: [],
        paymentHistory: [
          PaymentRecord(id: 'PAY-106', planName: 'Plan Mensual Plata', price: 120.0, date: '01 de may', method: 'Yape', state: 'approved'),
        ],
      ),
      MemberRecord(
        dni: '00000000',
        name: 'Juan Perez (Manual Test)',
        phone: '900000000',
        email: 'juan@mail.com',
        startDate: '21 de may',
        goal: 'Hipertrofia',
        sessions: 0,
        lastSeen: 'Nunca',
        state: 'expired',
        assignedTrainer: 'Carlos M.',
        isActiveInGym: false,
        physicalMeasurements: {'peso': 80.0, 'altura': 1.75},
        progressImages: [],
        paymentHistory: [],
      ),
    ]);
  }
}

class GymStateProvider extends InheritedNotifier<GymState> {
  const GymStateProvider({
    super.key,
    required GymState super.notifier,
    required super.child,
  });

  static GymState of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<GymStateProvider>();
    assert(provider != null, 'No GymStateProvider found in context');
    return provider!.notifier!;
  }
}

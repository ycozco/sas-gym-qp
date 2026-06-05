import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import '../models/gym_models.dart';
import '../core/network/api_client.dart';
import '../core/config/app_config.dart';
import '../core/storage/secure_storage.dart';
import '../core/services/websocket_service.dart';
import '../core/services/sync_queue_service.dart';
import '../theme/ui_preferences_controller.dart';

// TODO(arch-future): este ChangeNotifier global concentra sesion,
// catalogos, red, websockets y caches offline. Una iteracion posterior
// puede partirlo en notifiers por feature (auth, member, payments,
// saas) usando Riverpod/Bloc. No es alcance del plan de migracion
// arquitectonica actual.
class GymState extends ChangeNotifier {
  GymState({bool startBackground = true}) {
    uiPreferences.addListener(_relayUiPreferenceChanges);
    _initUiPreferences();
    if (AppConfig.isDemoMode) {
      _initializeData();
    }
    _initAuthListener();
    if (startBackground) {
      checkAuth();
      _initConnectivity();
    }
  }

  final UiPreferencesController uiPreferences = UiPreferencesController();

  ThemeMode get themeMode => uiPreferences.themeMode;
  bool get themePreferenceSyncPending => uiPreferences.syncPending;

  void _relayUiPreferenceChanges() {
    notifyListeners();
  }

  Future<void> _initUiPreferences() async {
    await uiPreferences.init();
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    await uiPreferences.setThemeMode(mode, markSyncPending: isBackendMode);
    await _syncThemePreferenceIfNeeded();
  }

  Future<void> _syncThemePreferenceIfNeeded() async {
    if (!isBackendMode || !uiPreferences.syncPending) return;

    try {
      await ApiClient().dio.patch(
        '/auth/me/preferences',
        data: {
          'themeMode': UiPreferencesController.themeModeToWire(
            uiPreferences.themeMode,
          ),
        },
      );
      await uiPreferences.markSynced();
    } catch (e) {
      AppLogger.debug('Error syncing theme preference', e);
    }
  }

  @visibleForTesting
  void setCurrentUserForTest(LoggedInUser? user) {
    _currentUser = user;
    _authLoading = false;
    notifyListeners();
  }

  @visibleForTesting
  void setCurrentGymActiveForTest({required bool active}) {
    final id = _selectedClientId.isEmpty ? 'gym_test' : _selectedClientId;
    final index = _saClients.indexWhere((c) => c.id == id);
    if (index == -1) {
      _saClients.add(
        SaaSClient(
          id: id,
          name: 'Test Gym',
          logo: '🧪',
          location: 'Test',
          membersCount: '0',
          active: active,
        ),
      );
    } else {
      _saClients[index] = _saClients[index].copyWith(active: active);
    }
    notifyListeners();
  }

  // --- Auth State ---
  LoggedInUser? _currentUser;
  bool _authLoading = false;
  String? _authError;

  LoggedInUser? get currentUser => _currentUser;
  bool get authLoading => _authLoading;
  String? get authError => _authError;

  void _initAuthListener() {
    ApiClient.onUnauthorized = () {
      _currentUser = null;
      _authError = 'Sesión expirada. Inicia sesión nuevamente.';
      notifyListeners();
    };

    ApiClient.onTenantSuspended = () {
      final tenantId = _selectedClientId;
      final index = _saClients.indexWhere((c) => c.id == tenantId);
      if (index != -1) {
        _saClients[index] = _saClients[index].copyWith(active: false);
        _addLog(
          'SaaS',
          'Suscripción Bloqueada',
          'El gimnasio fue suspendido por administración.',
          Colors.red,
        );
        notifyListeners();
      }
    };
  }

  Future<void> checkAuth() async {
    _authLoading = true;
    notifyListeners();

    try {
      final token = await SecureStorage.getToken();
      final tenantId = await SecureStorage.getTenantId();

      if (token == null || tenantId == null) {
        _currentUser = null;
        _authLoading = false;
        notifyListeners();
        return;
      }

      final response = await ApiClient().dio.get('/auth/me');
      _clearLocalDemoData();
      _currentUser = LoggedInUser.fromJson(
        response.data as Map<String, dynamic>,
      );
      _selectedClientId = tenantId;
      _authError = null;
      final hadPendingThemeSync = uiPreferences.syncPending;
      await _syncThemePreferenceIfNeeded();
      if (!hadPendingThemeSync) {
        await uiPreferences.applyBackendTheme(_currentUser!.themePreference);
      }
      _connectSocket();
      loadAnnouncements();
      if (_currentUser?.rol == GymRole.superadmin) {
        loadSaaSClients();
      } else if (_currentUser?.rol == GymRole.admin) {
        loadObservations();
        loadAuditLogs();
      }
      loadTenantSettings();
      loadMembershipPlans(includeInactive: _currentUser?.rol == GymRole.admin);
    } catch (e) {
      await SecureStorage.clearAll();
      _currentUser = null;
    } finally {
      _authLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login({
    required String emailOrDni,
    required String password,
  }) async {
    _authLoading = true;
    _authError = null;
    notifyListeners();

    try {
      final response = await ApiClient().dio.post(
        '/auth/login',
        data: {'emailOrDni': emailOrDni, 'password': password},
      );

      final token = response.data['token'] as String;
      final returnedTenantId = response.data['tenantId'] as String;

      await SecureStorage.saveToken(token);
      await SecureStorage.saveTenantId(returnedTenantId);

      final profileResponse = await ApiClient().dio.get('/auth/me');
      _clearLocalDemoData();
      _currentUser = LoggedInUser.fromJson(
        profileResponse.data as Map<String, dynamic>,
      );
      _selectedClientId = returnedTenantId;
      _authError = null;
      _authLoading = false;
      final hadPendingThemeSync = uiPreferences.syncPending;
      await _syncThemePreferenceIfNeeded();
      if (!hadPendingThemeSync) {
        await uiPreferences.applyBackendTheme(_currentUser!.themePreference);
      }
      _connectSocket();
      loadAnnouncements();
      if (_currentUser?.rol == GymRole.superadmin) {
        loadSaaSClients();
      } else if (_currentUser?.rol == GymRole.admin) {
        loadObservations();
        loadAuditLogs();
      }
      loadTenantSettings();
      loadMembershipPlans(includeInactive: _currentUser?.rol == GymRole.admin);
      notifyListeners();
      return true;
    } on DioException catch (e) {
      String message = 'Error de conexión con el servidor.';
      if (e.response != null && e.response!.data != null) {
        final data = e.response!.data;
        if (data is Map && data.containsKey('message')) {
          final errMessage = data['message'];
          message = errMessage is List
              ? errMessage.join('\n')
              : errMessage.toString();
        }
      }
      _authError = message;
      _currentUser = null;
      _authLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _authError = 'Ocurrió un error inesperado al iniciar sesión.';
      _currentUser = null;
      _authLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _closeSocket();
    _authLoading = true;
    notifyListeners();
    await SecureStorage.clearAll();
    if (Hive.isBoxOpen('gym_cache')) {
      await Hive.box('gym_cache').clear();
    }
    if (Hive.isBoxOpen('sync_queue_box')) {
      await SyncQueueService.clearQueue();
    }
    _currentUser = null;
    _authError = null;
    _authLoading = false;
    notifyListeners();
  }

  Future<bool> recoverPassword(String email) async {
    try {
      await ApiClient().dio.post(
        '/auth/forgot-password',
        data: {'email': email},
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  // Active SaaS Client (instance)
  String _selectedClientId = 'gym_santiago';
  String get selectedClientId => _selectedClientId;

  // Settings
  int graceDays = 1;
  int alertDays = 5;
  TenantSettings? _tenantSettings;
  final List<MembershipPlan> _membershipPlans = [];

  TenantSettings? get tenantSettings => _tenantSettings;
  List<MembershipPlan> get membershipPlans => List.unmodifiable(_membershipPlans);
  MembershipPlan? get defaultMembershipPlan =>
      _membershipPlans.isEmpty ? null : _membershipPlans.first;

  // Collections
  final List<MemberRecord> _members = [];
  final List<ProductItem> _products = [];
  final List<CashierAccount> _cashiers = [];
  final List<AuditEntry> _auditLogs = [];
  final List<Announcement> _announcements = [];
  final List<GymObservation> _observations = [];
  final List<SaaSClient> _saClients = [];

  // Getters
  List<MemberRecord> get members =>
      _members.where((m) => m.state != 'baja_logica').toList();
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
      orElse: () => SaaSClient(
        id: '',
        name: '',
        logo: '',
        location: '',
        membersCount: '0',
        active: true,
      ),
    );
    return client.active;
  }

  void selectClient(String clientId) {
    _selectedClientId = clientId;
    notifyListeners();
  }

  void _clearLocalDemoData() {
    _members.clear();
    _products.clear();
    _cashiers.clear();
    _auditLogs.clear();
    _announcements.clear();
    _observations.clear();
    _saClients.clear();
  }

  bool get isBackendMode => _currentUser != null;

  Future<Map<String, dynamic>> verifyAttendanceBackend({
    required String dni,
    required String otpToken,
  }) async {
    try {
      final response = await ApiClient().dio.post(
        '/attendance/verify',
        data: {'dni': dni, 'otpToken': otpToken},
      );
      final data = response.data;
      final verdict = data['verdict'] as String? ?? 'RED';
      final reason = data['reason'] as String? ?? 'Error de validación';
      final memberJson = data['member'] as Map<String, dynamic>?;

      final Color logColor = verdict == 'GREEN'
          ? const Color(0xFF00B85C)
          : (verdict == 'AMBER' ? const Color(0xFFFFB300) : Colors.red);

      final fullName = memberJson?['fullName'] as String? ?? 'Socio';
      _addLog(
        'Escáner',
        'Registro de ingreso (API)',
        '$fullName: $reason',
        logColor,
      );

      // Update local state if the user was checked in
      if (verdict == 'GREEN' || verdict == 'AMBER') {
        final localIdx = _members.indexWhere((m) => m.dni == dni);
        if (localIdx != -1) {
          _members[localIdx] = _members[localIdx].copyWith(
            sessions: _members[localIdx].sessions + 1,
            lastSeen: 'Hoy',
            todayCheckIn: true,
            isActiveInGym: true,
          );
        }
      }

      notifyListeners();

      if (memberJson == null) {
        return {'verdict': verdict, 'reason': reason, 'member': null};
      }

      final String backendStatus = (memberJson['status'] as String? ?? '')
          .toLowerCase();
      final String mappedState = verdict == 'GREEN'
          ? 'active'
          : (verdict == 'AMBER'
                ? 'grace'
                : (backendStatus.contains('suspend')
                      ? 'suspended'
                      : (backendStatus.contains('inactiv') ||
                                backendStatus.contains('pend')
                            ? 'inactive'
                            : 'expired')));

      final daysLeft = memberJson['daysLeft'] as int?;

      // Build a MemberRecord from backend response to feed the verdict screen
      MemberRecord tempRecord = MemberRecord(
        dni: dni,
        name: fullName,
        phone: memberJson['phone'] as String? ?? '',
        email: memberJson['email'] as String? ?? '',
        startDate: 'Hoy',
        goal: memberJson['planName'] as String? ?? 'Membresía',
        sessions: 0,
        lastSeen: 'Hoy',
        state: mappedState,
        assignedTrainer: '',
        paymentHistory: [],
        physicalMeasurements: {},
        progressImages: [],
        daysLeft: daysLeft,
      );

      return {'verdict': verdict, 'reason': reason, 'member': tempRecord};
    } on DioException catch (e) {
      String reason = 'Error de conexión o token inválido.';
      if (e.response != null && e.response!.data != null) {
        final data = e.response!.data;
        if (data is Map && data.containsKey('reason')) {
          reason = data['reason'].toString();
        } else if (data is Map && data.containsKey('message')) {
          reason = data['message'].toString();
        }
      }
      _addLog(
        'Escáner',
        'Error API',
        'Fallo al verificar: $reason',
        Colors.red,
      );
      notifyListeners();
      return {'verdict': 'RED', 'reason': reason, 'member': null};
    } catch (e) {
      _addLog(
        'Escáner',
        'Error API',
        'Fallo al verificar asistencia: $e',
        Colors.red,
      );
      notifyListeners();
      return {
        'verdict': 'RED',
        'reason': 'Error de red inesperado.',
        'member': null,
      };
    }
  }

  Future<Map<String, dynamic>> simulateAttendanceAccessBackend({
    required String dni,
  }) async {
    try {
      final response = await ApiClient().dio.post(
        '/attendance/simulation-access',
        data: {'dni': dni},
      );
      return _mapAttendanceResponse(dni, response.data);
    } catch (e) {
      _addLog(
        'Escaner',
        'Simulacion de ingreso',
        'No se pudo simular el QR temporal.',
        Colors.red,
      );
      notifyListeners();
      return {
        'verdict': 'RED',
        'reason': 'No se pudo simular el QR temporal.',
        'member': null,
      };
    }
  }

  Map<String, dynamic> _mapAttendanceResponse(String dni, dynamic data) {
    final verdict = data['verdict'] as String? ?? 'RED';
    final reason = data['reason'] as String? ?? 'Error de validacion';
    final memberJson = data['member'] as Map<String, dynamic>?;

    final Color logColor = verdict == 'GREEN'
        ? const Color(0xFF00B85C)
        : (verdict == 'AMBER' ? const Color(0xFFFFB300) : Colors.red);

    final fullName = memberJson?['fullName'] as String? ?? 'Socio';
    _addLog(
      'Escaner',
      'Registro de ingreso (API)',
      '$fullName: $reason',
      logColor,
    );

    if (verdict == 'GREEN' || verdict == 'AMBER') {
      final localIdx = _members.indexWhere((m) => m.dni == dni);
      if (localIdx != -1) {
        _members[localIdx] = _members[localIdx].copyWith(
          sessions: _members[localIdx].sessions + 1,
          lastSeen: 'Hoy',
          todayCheckIn: true,
          isActiveInGym: true,
        );
      }
    }

    notifyListeners();

    if (memberJson == null) {
      return {'verdict': verdict, 'reason': reason, 'member': null};
    }

    final String backendStatus = (memberJson['status'] as String? ?? '')
        .toLowerCase();
    final String mappedState = verdict == 'GREEN'
        ? 'active'
        : (verdict == 'AMBER'
              ? 'grace'
              : (backendStatus.contains('suspend')
                    ? 'suspended'
                    : (backendStatus.contains('inactiv') ||
                              backendStatus.contains('pend')
                          ? 'inactive'
                          : 'expired')));

    final daysLeft = memberJson['daysLeft'] as int?;

    final tempRecord = MemberRecord(
      dni: dni,
      name: fullName,
      phone: memberJson['phone'] as String? ?? '',
      email: memberJson['email'] as String? ?? '',
      startDate: 'Hoy',
      goal: memberJson['planName'] as String? ?? 'Membresia',
      sessions: 0,
      lastSeen: 'Hoy',
      state: mappedState,
      assignedTrainer: '',
      paymentHistory: [],
      physicalMeasurements: {},
      progressImages: [],
      daysLeft: daysLeft,
    );

    return {'verdict': verdict, 'reason': reason, 'member': tempRecord};
  }

  // --- Attendance scanning ---
  String recordAttendance(String memberDni) {
    final index = _members.indexWhere((m) => m.dni == memberDni);
    if (index == -1) {
      _addLog(
        'Escáner',
        'Acceso denegado',
        'DNI $memberDni no registrado',
        Colors.red,
      );
      return 'not_found';
    }

    final member = _members[index];
    if (member.state == 'baja_logica') {
      _addLog(
        'Escáner',
        'Acceso denegado',
        '${member.name} está inactivo (baja lógica)',
        Colors.red,
      );
      return 'denied';
    }

    if (member.state == 'expired') {
      _addLog(
        'Escáner',
        'Acceso denegado',
        'Membresía de ${member.name} vencida',
        Colors.red,
      );
      return 'denied';
    }

    if (member.state == 'pending' || member.state == 'inactive') {
      _addLog(
        'Escáner',
        'Acceso denegado',
        'Membresía de ${member.name} en espera de verificación',
        Colors.red,
      );
      return 'denied';
    }

    if (member.state == 'suspended') {
      _addLog(
        'Escáner',
        'Acceso denegado',
        'Cuenta de ${member.name} suspendida administrativamente',
        Colors.red,
      );
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
      _addLog(
        'Escáner',
        'Registro de salida',
        '${member.name} salió del gimnasio',
        const Color(0xFF5C5C5C),
      );
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

    final updatedHistory = List<PaymentRecord>.from(member.paymentHistory)
      ..add(newPayment);
    _members[index] = member.copyWith(paymentHistory: updatedHistory);

    _addLog(
      'Socio',
      'Subió comprobante',
      '${member.name} cargó comprobante manual para $planName (S/ $price)',
      const Color(0xFF0066FF),
    );
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
    final updatedHistory = List<PaymentRecord>.from(member.paymentHistory)
      ..[pIndex] = updatedPayment;

    _members[mIndex] = member.copyWith(
      paymentHistory: updatedHistory,
      state: 'active', // Reactively activate their membership
      lastSeen: 'Hoy',
    );

    _addLog(
      'Admin',
      'Aprobó pago',
      'Pago $paymentId de ${member.name} aprobado. Membresía activada.',
      const Color(0xFF00B85C),
    );
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
    final updatedHistory = List<PaymentRecord>.from(member.paymentHistory)
      ..[pIndex] = updatedPayment;

    _members[mIndex] = member.copyWith(paymentHistory: updatedHistory);

    _addLog(
      'Admin',
      'Rechazó pago',
      'Pago $paymentId de ${member.name} rechazado.',
      Colors.red,
    );
    notifyListeners();
  }

  // --- Backend payments and POS integration ---
  Future<bool> uploadReceiptBackend({
    required String planName,
    required double price,
    required String method,
    required List<int> fileBytes,
    required String fileName,
  }) async {
    try {
      final formData = FormData.fromMap({
        'monto': price.toString(),
        'metodo': method,
        'planNombre': planName,
        'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
      });

      await ApiClient().dio.post('/payments/upload-receipt', data: formData);

      // Reload auth info to refresh state
      await checkAuth();
      return true;
    } catch (e) {
      AppLogger.debug('Error uploading receipt to backend', e);
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getPendingPaymentsBackend() async {
    try {
      final response = await ApiClient().dio.get('/payments/pending');
      final data = response.data as List;
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      AppLogger.debug('Error fetching pending payments', e);
      return [];
    }
  }

  Future<bool> resolvePaymentBackend({
    required String paymentId,
    required String status, // APPROVED | REJECTED
    required String comments,
  }) async {
    try {
      await ApiClient().dio.post(
        '/payments/$paymentId/resolve',
        data: {'status': status, 'comments': comments},
      );

      // Reload auth / local state if needed
      await checkAuth();
      return true;
    } catch (e) {
      AppLogger.debug('Error resolving payment', e);
      return false;
    }
  }

  Future<bool> checkShiftBackend() async {
    try {
      final response = await ApiClient().dio.get('/payments/check-shift');
      return response.data['isActive'] as bool? ?? false;
    } catch (e) {
      AppLogger.debug('Error checking shift backend', e);
      return false;
    }
  }

  Future<bool> chargePOSBackend({
    required String memberDni,
    required List<Map<String, dynamic>> cartItems,
    required double total,
    required String paymentMethod,
    List<Map<String, dynamic>>? payments,
  }) async {
    try {
      final data = <String, dynamic>{
        'memberDni': memberDni,
        'cartItems': cartItems,
        'total': total,
        'paymentMethod': paymentMethod,
        ...?(payments == null ? null : {'payments': payments}),
      };

      await ApiClient().dio.post('/payments/pos-charge', data: data);

      // Update local state by adding log
      _addLog(
        'Caja',
        'Cobró POS (API)',
        'Cobró S/ $total a DNI $memberDni via $paymentMethod',
        const Color(0xFF00B85C),
      );
      notifyListeners();
      return true;
    } catch (e) {
      AppLogger.debug('Error processing POS charge backend', e);
      rethrow;
    }
  }

  // --- Turnos y Sesiones de Caja ---

  Future<Map<String, dynamic>?> openCajaBackend(
    double montoApertura,
    String? observaciones,
  ) async {
    try {
      final response = await ApiClient().dio.post(
        '/payments/caja/open',
        data: {
          'montoApertura': montoApertura,
          'observaciones': observaciones ?? '',
        },
      );
      _addLog(
        'Caja',
        'Apertura de Caja (API)',
        'Abrió caja con saldo S/ $montoApertura',
        const Color(0xFF0066FF),
      );
      notifyListeners();
      return response.data as Map<String, dynamic>?;
    } catch (e) {
      AppLogger.debug('Error al abrir caja', e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getActiveCajaBackend() async {
    try {
      final response = await ApiClient().dio.get('/payments/caja/active');
      return response.data as Map<String, dynamic>?;
    } catch (e) {
      AppLogger.debug('Error al obtener caja activa', e);
      return null;
    }
  }

  Future<Map<String, dynamic>?> createEgressBackend({
    required double monto,
    required String motivo,
    String? metodoPago,
    String? descripcionAdicional,
  }) async {
    try {
      final response = await ApiClient().dio.post(
        '/payments/caja/egress',
        data: {
          'monto': monto,
          'motivo': motivo,
          'metodoPago': metodoPago ?? 'efectivo',
          'descripcionAdicional': descripcionAdicional ?? '',
        },
      );
      _addLog(
        'Caja',
        'Egreso de Caja (API)',
        'Registró egreso de S/ $monto por: $motivo',
        Colors.red,
      );
      notifyListeners();
      return response.data as Map<String, dynamic>?;
    } catch (e) {
      AppLogger.debug('Error al crear egreso de caja', e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getCajaDetailsBackend() async {
    try {
      final response = await ApiClient().dio.get('/payments/caja/details');
      return response.data as Map<String, dynamic>?;
    } catch (e) {
      AppLogger.debug('Error al obtener arqueo de caja', e);
      return null;
    }
  }

  Future<Map<String, dynamic>?> closeCajaBackend({
    required double cash,
    required double transfer,
    required double yape,
    required double pos,
    String? observations,
  }) async {
    try {
      final response = await ApiClient().dio.post(
        '/payments/caja/close',
        data: {
          'montoCierreEfectivo': cash,
          'montoCierreTransferencia': transfer,
          'montoCierreYape': yape,
          'montoCierrePOS': pos,
          'observaciones': observations ?? '',
        },
      );
      final diferencia = response.data['diferencia'] ?? 0.0;
      _addLog(
        'Caja',
        'Cierre de Caja (API)',
        'Cerró caja. Diferencia: S/ $diferencia',
        const Color(0xFF5C5C5C),
      );
      notifyListeners();
      return response.data as Map<String, dynamic>?;
    } catch (e) {
      AppLogger.debug('Error al cerrar caja', e);
      rethrow;
    }
  }

  // --- Ventas de Membresías ---

  Future<Map<String, dynamic>?> registerMembershipSaleBackend({
    required String userId,
    String? planId,
    required String planNombre,
    required int duracionDias,
    required double monto,
    double descuentoPorcentaje = 0,
    double descuentoMonto = 0,
    required String ventaToken,
    required List<Map<String, dynamic>> pagos,
    String? fechaInicio,
    String? fechaVencimiento,
    String? observaciones,
  }) async {
    try {
      final data = {
        'userId': userId,
        'planNombre': planNombre,
        'duracionDias': duracionDias,
        'monto': monto,
        'descuentoPorcentaje': descuentoPorcentaje,
        'descuentoMonto': descuentoMonto,
        'ventaToken': ventaToken,
        'pagos': pagos,
        'fechaInicio': fechaInicio,
        'fechaVencimiento': fechaVencimiento,
        'observaciones': observaciones ?? '',
      };
      if (planId != null) {
        data['planId'] = planId;
      }
      final response = await ApiClient().dio.post(
        '/payments/membership-sale',
        data: data,
      );
      final plan = response.data['planNombre'] ?? planNombre;
      final pagado = response.data['montoPagado'] ?? monto;
      _addLog(
        'Caja',
        'Venta Membresía (API)',
        'Membresía $plan registrada. Monto: S/ $pagado',
        const Color(0xFF00B85C),
      );
      notifyListeners();
      return response.data as Map<String, dynamic>?;
    } catch (e) {
      AppLogger.debug('Error al registrar venta de membresia', e);
      rethrow;
    }
  }

  // --- Búsqueda de Socios por Relevancia ---

  Future<List<dynamic>> searchMembersBackend(
    String query, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await ApiClient().dio.get(
        '/members/search',
        queryParameters: {'q': query, 'page': page, 'limit': limit},
      );
      return response.data as List;
    } catch (e) {
      AppLogger.debug('Error en busqueda de socios', e);
      return [];
    }
  }

  // --- Asistencia y Huellas ---

  Future<Map<String, dynamic>?> registerFingerprintBackend({
    required String userId,
    required String dedo,
    required String datosHuella,
    required String signature,
  }) async {
    try {
      final response = await ApiClient().dio.post(
        '/attendance/fingerprint/register',
        data: {
          'userId': userId,
          'dedo': dedo,
          'datosHuella': datosHuella,
          'signature': signature,
        },
      );
      return response.data as Map<String, dynamic>?;
    } catch (e) {
      AppLogger.debug('Error al registrar huella digital', e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> verifyFingerprintBackend({
    required String tokenRegistro,
    required String hashVerificacion,
    String? ipOrigen,
    String? dispositivoId,
  }) async {
    try {
      final response = await ApiClient().dio.post(
        '/attendance/fingerprint/verify',
        data: {
          'tokenRegistro': tokenRegistro,
          'hashVerificacion': hashVerificacion,
          'ipOrigen': ipOrigen,
          'dispositivoId': dispositivoId,
        },
      );
      final verdict = response.data['verdict'] as String? ?? 'RED';
      final reason =
          response.data['reason'] as String? ?? 'Error de validación';
      final memberJson = response.data['member'] as Map<String, dynamic>?;

      final Color logColor = verdict == 'GREEN'
          ? const Color(0xFF00B85C)
          : (verdict == 'AMBER' ? const Color(0xFFFFB300) : Colors.red);

      final fullName = memberJson?['fullName'] as String? ?? 'Socio';
      _addLog(
        'Biometría',
        'Ingreso Huella (API)',
        '$fullName: $reason',
        logColor,
      );
      notifyListeners();

      return response.data as Map<String, dynamic>?;
    } catch (e) {
      AppLogger.debug('Error al verificar huella digital', e);
      rethrow;
    }
  }

  // --- POS checkout ---

  void chargePOS({
    required String memberDni,
    required List<Map<String, dynamic>> cartItems,
    required double total,
    required String paymentMethod,
    List<Map<String, dynamic>>? payments,
  }) {
    final String methodStr = payments != null
        ? payments.map((p) => "${p['metodo']}: S/ ${p['monto']}").join(', ')
        : paymentMethod;

    if (memberDni == 'ANONIMO') {
      for (var item in cartItems) {
        final name = item['name'] as String;
        final qty = item['qty'] as int;
        final prodIndex = _products.indexWhere((p) => p.name == name);
        if (prodIndex != -1) {
          final prod = _products[prodIndex];
          _products[prodIndex] = prod.copyWith(
            stock: (prod.stock - qty).clamp(0, 9999),
          );
        }
      }
      _addLog(
        'Caja',
        'Venta POS Anónima',
        'Cliente Anónimo pagó S/ $total via $methodStr. Items: ${cartItems.map((c) => "${c['qty']}x ${c['name']}").join(", ")}',
        const Color(0xFF00B85C),
      );
      notifyListeners();
      return;
    }

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
        updatedHistory.add(
          PaymentRecord(
            id: 'PAY-${DateTime.now().millisecondsSinceEpoch}',
            planName: name,
            price: price * qty,
            date: _formatCurrentDate(),
            method: methodStr,
            state: 'approved',
          ),
        );
      } else {
        // Decrease product stock
        final prodIndex = _products.indexWhere((p) => p.name == name);
        if (prodIndex != -1) {
          final prod = _products[prodIndex];
          _products[prodIndex] = prod.copyWith(
            stock: (prod.stock - qty).clamp(0, 9999),
          );
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
      '${member.name} pagó S/ $total via $methodStr. Items: ${cartItems.map((c) => "${c['qty']}x ${c['name']}").join(", ")}',
      const Color(0xFF00B85C),
    );
    notifyListeners();
  }

  // --- CRUD members ---
  void addMember(MemberRecord member) {
    _members.add(member);
    _addLog(
      'Admin',
      'Creó socio',
      'Socio registrado: ${member.name} (DNI ${member.dni})',
      const Color(0xFF7A5AE0),
    );
    notifyListeners();
  }

  void updateMember(String dni, MemberRecord updated) {
    final index = _members.indexWhere((m) => m.dni == dni);
    if (index != -1) {
      _members[index] = updated;
      _addLog(
        'Admin',
        'Editó socio',
        'Socio ${updated.name} actualizado.',
        const Color(0xFFFFB300),
      );
      notifyListeners();
    }
  }

  void toggleMemberLogicDelete(String memberDni) {
    final index = _members.indexWhere((m) => m.dni == memberDni);
    if (index == -1) return;

    final member = _members[index];
    if (member.state == 'baja_logica') {
      // Restore to active or expired
      final hasActivePayment = member.paymentHistory.any(
        (p) => p.state == 'approved',
      );
      final restoredState = hasActivePayment ? 'active' : 'expired';
      _members[index] = member.copyWith(state: restoredState);
      _addLog(
        'Admin',
        'Restauró socio',
        'Usuario ${member.name} reactivado.',
        const Color(0xFF00B85C),
      );
    } else {
      // Soft-delete
      _members[index] = member.copyWith(
        state: 'baja_logica',
        todayCheckIn: false,
        isActiveInGym: false,
      );
      _addLog(
        'Admin',
        'Baja lógica',
        'Usuario ${member.name} desactivado (baja lógica).',
        const Color(0xFFFF7A1A),
      );
    }
    notifyListeners();
  }

  // --- CRUD products ---
  void addProduct(ProductItem product) {
    _products.add(product);
    _addLog(
      'Caja',
      'Creó producto',
      'Producto agregado: ${product.name} (Stock: ${product.stock})',
      const Color(0xFF0066FF),
    );
    notifyListeners();
  }

  void updateProduct(String oldName, ProductItem updated) {
    final index = _products.indexWhere((p) => p.name == oldName);
    if (index != -1) {
      _products[index] = updated;
      _addLog(
        'Admin',
        'Editó producto',
        'Producto ${updated.name} modificado.',
        const Color(0xFFFFB300),
      );
      notifyListeners();
    }
  }

  void deleteProductPhysical(String productName) {
    final index = _products.indexWhere((p) => p.name == productName);
    if (index != -1) {
      _products.removeAt(index);
      _addLog(
        'Admin',
        'Eliminó producto',
        'Eliminado definitivamente de inventario: $productName',
        Colors.red,
      );
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
    _addLog(
      'Admin',
      'Permisos cajero',
      'Modificó permisos de $cashierName: $permission',
      const Color(0xFF7A5AE0),
    );
    notifyListeners();
  }

  void toggleCashierActive(String cashierName) {
    final index = _cashiers.indexWhere((c) => c.name == cashierName);
    if (index == -1) return;

    final cashier = _cashiers[index];
    _cashiers[index] = cashier.copyWith(active: !cashier.active);
    _addLog(
      'Admin',
      'Estado cajero',
      '$cashierName marcado como ${!cashier.active ? 'inactivo' : 'activo'}',
      const Color(0xFF7A5AE0),
    );
    notifyListeners();
  }

  // --- Tenant settings and membership plans ---
  Future<void> loadTenantSettings() async {
    if (!isBackendMode) return;
    try {
      final response = await ApiClient().dio.get('/tenants/me');
      _tenantSettings = TenantSettings.fromJson(
        response.data as Map<String, dynamic>,
      );
      graceDays = _tenantSettings!.graceDays;
      alertDays = _tenantSettings!.alertDays;
      notifyListeners();
    } catch (e) {
      AppLogger.debug('Error loading tenant settings', e);
    }
  }

  Future<void> saveTenantSettings({
    String? name,
    String? logoUrl,
    String? address,
    String? phone,
    String? schedule,
    String? description,
    String? primaryColor,
    String? secondaryColor,
    String? accentColor,
    int? graceDays,
    int? alertDays,
  }) async {
    if (!isBackendMode) {
      if (graceDays != null && alertDays != null) {
        updateGymSettings(graceDays, alertDays);
      }
      return;
    }
    final data = <String, dynamic>{};
    if (name != null) data['nombre'] = name;
    if (logoUrl != null) data['logoUrl'] = logoUrl;
    if (address != null) data['direccion'] = address;
    if (phone != null) data['telefono'] = phone;
    if (schedule != null) data['horario'] = schedule;
    if (description != null) data['descripcion'] = description;
    if (primaryColor != null) data['colorPrimario'] = primaryColor;
    if (secondaryColor != null) data['colorSecundario'] = secondaryColor;
    if (accentColor != null) data['colorAcento'] = accentColor;
    if (graceDays != null) data['diasGracia'] = graceDays;
    if (alertDays != null) data['diasAlertaVencimiento'] = alertDays;

    final response = await ApiClient().dio.patch(
      '/tenants/me/settings',
      data: data,
    );
    _tenantSettings = TenantSettings.fromJson(
      response.data as Map<String, dynamic>,
    );
    this.graceDays = _tenantSettings!.graceDays;
    this.alertDays = _tenantSettings!.alertDays;
    _addLog(
      'Admin',
      'Personalizacion tenant',
      'Actualizo configuracion del gimnasio.',
      const Color(0xFF7A5AE0),
    );
    notifyListeners();
  }

  Future<void> loadMembershipPlans({bool includeInactive = false}) async {
    if (!isBackendMode) return;
    try {
      final response = await ApiClient().dio.get(
        '/membership-plans',
        queryParameters: {'includeInactive': includeInactive},
      );
      final items = (response.data as List)
          .map((item) => MembershipPlan.fromJson(item as Map<String, dynamic>))
          .toList();
      _membershipPlans
        ..clear()
        ..addAll(items);
      notifyListeners();
    } catch (e) {
      AppLogger.debug('Error loading membership plans', e);
    }
  }

  Future<void> saveMembershipPlan({
    String? id,
    required String name,
    required int durationDays,
    required double price,
    String? description,
    String? color,
    int order = 0,
    bool active = true,
  }) async {
    final data = {
      'nombre': name,
      'descripcion': description ?? '',
      'duracionDias': durationDays,
      'precio': price,
      'color': color ?? '#2F6BFF',
      'orden': order,
      'activo': active,
    };
    if (id == null || id.isEmpty) {
      await ApiClient().dio.post('/membership-plans', data: data);
    } else {
      await ApiClient().dio.patch('/membership-plans/$id', data: data);
    }
    await loadMembershipPlans(includeInactive: true);
  }

  Future<void> deactivateMembershipPlan(String id) async {
    await ApiClient().dio.delete('/membership-plans/$id');
    await loadMembershipPlans(includeInactive: true);
  }

  // --- Settings ---
  void updateGymSettings(int graceDays, int alertDays) {
    this.graceDays = graceDays;
    this.alertDays = alertDays;
    _addLog(
      'Admin',
      'Ajustes gimnasio',
      'Días gracia: $graceDays, alertas: $alertDays',
      const Color(0xFF7A5AE0),
    );
    notifyListeners();
  }

  // --- Observations ---
  void addObservation(String category, String description, String memberName) {
    final id = 'OBS-${DateTime.now().millisecondsSinceEpoch}';
    final date = _formatCurrentDate();
    _observations.add(
      GymObservation(
        id: id,
        memberName: memberName,
        category: category,
        description: description,
        date: date,
      ),
    );
    _addLog(
      'Socio',
      'Reportó problema',
      'Socio $memberName reportó en $category: $description',
      const Color(0xFFFF7A1A),
    );
    notifyListeners();
  }

  // --- Announcements ---
  Future<void> loadAnnouncements() async {
    if (isBackendMode) {
      try {
        final response = await ApiClient().dio.get('/announcements');
        final List<dynamic> data = response.data;
        _announcements.clear();
        for (var item in data) {
          _announcements.add(Announcement.fromJson(item));
        }
        notifyListeners();
      } catch (e) {
        AppLogger.debug('Error loading announcements', e);
      }
    }
  }

  Future<void> addAnnouncement(String tag, String title, String detail) async {
    if (isBackendMode) {
      try {
        String severity = 'INFO';
        if (tag == 'AVISO' || tag == 'WARNING') severity = 'WARNING';
        if (tag == 'ALERTA' || tag == 'DANGER') severity = 'DANGER';

        await ApiClient().dio.post(
          '/announcements',
          data: {'titulo': title, 'descripcion': detail, 'severidad': severity},
        );

        await loadAnnouncements();
        _addLog(
          'Admin',
          'Creó anuncio (API)',
          'Nuevo aviso [$severity]: $title',
          const Color(0xFF7A5AE0),
        );
      } catch (e) {
        AppLogger.debug('Error creating announcement on backend', e);
      }
    } else {
      _announcements.insert(
        0,
        Announcement(tag: tag, title: title, detail: detail, time: 'Ahora'),
      );
      _addLog(
        'Admin',
        'Creó anuncio',
        'Nuevo aviso [$tag]: $title',
        const Color(0xFF7A5AE0),
      );
      notifyListeners();
    }
  }

  Future<void> dismissAnnouncement(String key) async {
    try {
      final box = Hive.box('gym_cache');
      final List<dynamic> dismissed = List.from(
        box.get('dismissed_banner_ids', defaultValue: []),
      );
      if (!dismissed.contains(key)) {
        dismissed.add(key);
        await box.put('dismissed_banner_ids', dismissed);
        notifyListeners();
      }
    } catch (e) {
      AppLogger.debug('Error dismissing announcement', e);
    }
  }

  // --- Helpers ---
  void _addLog(
    String actor,
    String action,
    String detail, [
    Color color = const Color(0xFF5C5C5C),
  ]) {
    _auditLogs.insert(
      0,
      AuditEntry(
        time: _formatCurrentTime(),
        action: action,
        detail: detail,
        actor: actor,
        color: color,
      ),
    );
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
    const months = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    return months[month - 1];
  }

  void _initializeData() {
    // SaaS clients
    _saClients.addAll([
      SaaSClient(
        id: 'gym_santiago',
        name: 'SAS Gym Santiago',
        logo: '🏋️',
        location: 'Av. Providencia, Santiago',
        membersCount: '154',
        active: true,
      ),
      SaaSClient(
        id: 'gym_lima',
        name: 'SAS Gym Lima Centro',
        logo: '💪',
        location: 'Jr. Carabaya, Lima',
        membersCount: '89',
        active: true,
      ),
      SaaSClient(
        id: 'gym_bogota',
        name: 'SAS Gym Bogotá Norte',
        logo: '⚡',
        location: 'Cl. 85, Bogotá',
        membersCount: '124',
        active: false,
      ),
    ]);

    // Initial products
    _products.addAll([
      ProductItem(
        name: 'Botella de agua 600ml',
        category: 'Bebidas',
        price: 3.0,
        stock: 124,
        icon: '💧',
      ),
      ProductItem(
        name: 'Proteína whey · porción',
        category: 'Suplementos',
        price: 12.0,
        stock: 38,
        icon: '💪',
      ),
      ProductItem(
        name: 'Pre-entreno · scoop',
        category: 'Suplementos',
        price: 8.0,
        stock: 22,
        icon: '⚡',
      ),
      ProductItem(
        name: 'Barra energética',
        category: 'Snacks',
        price: 5.0,
        stock: 56,
        icon: '🍫',
      ),
      ProductItem(
        name: 'Polo oficial SaaaS',
        category: 'Merch',
        price: 45.0,
        stock: 18,
        icon: '👕',
      ),
      ProductItem(
        name: 'Toalla deportiva',
        category: 'Accesorios',
        price: 15.0,
        stock: 12,
        icon: '🏃',
      ),
    ]);

    // Initial cashiers
    _cashiers.addAll([
      CashierAccount(
        name: 'Mariana Quispe',
        shift: '06:00 - 14:00',
        permissions: [
          'Cobros',
          'Asistencia',
          'Ventas',
          'Productos',
          'Usuarios',
        ],
        active: true,
      ),
      CashierAccount(
        name: 'Luis Yupanqui',
        shift: '14:00 - 22:00',
        permissions: ['Cobros', 'Asistencia', 'Ventas', 'Productos'],
        active: true,
      ),
      CashierAccount(
        name: 'Valeria Ruiz',
        shift: '18:00 - 22:00',
        permissions: ['Cobros', 'Usuarios'],
        active: false,
      ),
    ]);

    // Initial announcements
    _announcements.addAll([
      Announcement(
        tag: 'EVENTO',
        title: 'Clases gratis sábado',
        detail: 'Funcional al aire libre 8am · Parque Kennedy',
        time: 'Hace 2h',
      ),
      Announcement(
        tag: 'AVISO',
        title: 'Mantenimiento jueves',
        detail: 'Máquina Smith fuera de servicio de 6 a 9pm',
        time: 'Ayer',
      ),
    ]);

    // Initial observations / complaints
    _observations.addAll([
      GymObservation(
        id: 'OBS-1',
        memberName: 'Diego Castro',
        category: 'Equipamiento',
        description:
            'La polea alta del lado izquierdo suena extraño y vibra mucho.',
        date: '20 de may',
      ),
      GymObservation(
        id: 'OBS-2',
        memberName: 'Rosa Mendieta',
        category: 'Limpieza',
        description:
            'Falta jabón líquido en el baño de mujeres del segundo piso.',
        date: '19 de may',
      ),
    ]);

    // Audit logs
    _auditLogs.addAll([
      AuditEntry(
        time: '11:30',
        action: 'Cobró membresía',
        detail: 'Rosa Mendieta · S/ 120 · Yape',
        actor: 'Caja · Mariana Q.',
        color: const Color(0xFF00B85C),
      ),
      AuditEntry(
        time: '10:45',
        action: 'Creó cajero',
        detail: 'Nuevo usuario de caja con turno 06:00 - 14:00',
        actor: 'Admin · Sandra A.',
        color: const Color(0xFF7A5AE0),
      ),
      AuditEntry(
        time: '10:22',
        action: 'Actualizó precio',
        detail: 'Whey porción S/ 12 → S/ 13',
        actor: 'Admin · Sandra A.',
        color: const Color(0xFF7A5AE0),
      ),
      AuditEntry(
        time: '09:48',
        action: 'Baja lógica',
        detail: 'Usuario Pedro Quispe desactivado sin borrar historial',
        actor: 'Caja · Mariana Q.',
        color: const Color(0xFFFF7A1A),
      ),
      AuditEntry(
        time: '09:14',
        action: 'Editó usuario',
        detail: 'Ana Torres · celular actualizado',
        actor: 'Caja · Mariana Q.',
        color: const Color(0xFFFFB300),
      ),
      AuditEntry(
        time: '08:42',
        action: 'Publicó rutina',
        detail: 'Push · Pecho + Hombros a 3 alumnos',
        actor: 'Trainer · Carlos M.',
        color: const Color(0xFF0066FF),
      ),
    ]);

    // Initial members with richer data
    _members.addAll([
      MemberRecord(
        dni: '11111111',
        name: 'Mateo Salas Socio',
        phone: '987654321',
        email: 'miembro@gymsmart.com',
        startDate: '01 de ene',
        goal: 'Hipertrofia',
        sessions: 47,
        lastSeen: 'Hoy',
        state: 'active',
        assignedTrainer: 'Carlos M.',
        isActiveInGym: true,
        physicalMeasurements: {
          'peso': 78.5,
          'altura': 1.78,
          'pecho': 98.0,
          'cintura': 82.0,
          'cadera': 94.0,
        },
        progressImages: [],
        paymentHistory: [
          PaymentRecord(
            id: 'PAY-101',
            planName: 'Plan Mensual Oro',
            price: 150.0,
            date: '01 de may',
            method: 'Yape',
            state: 'approved',
          ),
          PaymentRecord(
            id: 'PAY-100',
            planName: 'Plan Mensual Oro',
            price: 150.0,
            date: '01 de abr',
            method: 'Yape',
            state: 'approved',
          ),
        ],
      ),
      MemberRecord(
        dni: '22222222',
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
        physicalMeasurements: {
          'peso': 62.1,
          'altura': 1.64,
          'pecho': 88.0,
          'cintura': 68.0,
          'cadera': 99.0,
        },
        progressImages: [],
        paymentHistory: [
          PaymentRecord(
            id: 'PAY-102',
            planName: 'Plan Trimestral Platinium',
            price: 400.0,
            date: '15 de feb',
            method: 'Tarjeta',
            state: 'approved',
          ),
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
        physicalMeasurements: {
          'peso': 89.2,
          'altura': 1.82,
          'pecho': 106.0,
          'cintura': 88.0,
          'cadera': 101.0,
        },
        progressImages: [],
        paymentHistory: [
          PaymentRecord(
            id: 'PAY-103',
            planName: 'Plan Mensual Plata',
            price: 120.0,
            date: '10 de mar',
            method: 'Plin',
            state: 'approved',
          ),
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
        physicalMeasurements: {
          'peso': 55.4,
          'altura': 1.58,
          'pecho': 84.0,
          'cintura': 64.0,
          'cadera': 90.0,
        },
        progressImages: [],
        paymentHistory: [
          PaymentRecord(
            id: 'PAY-104',
            planName: 'Plan Mensual Plata',
            price: 120.0,
            date: '05 de may',
            method: 'Yape',
            state: 'approved',
          ),
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
        physicalMeasurements: {
          'peso': 58.0,
          'altura': 1.60,
          'pecho': 86.0,
          'cintura': 67.0,
          'cadera': 92.0,
        },
        progressImages: [],
        paymentHistory: [
          PaymentRecord(
            id: 'PAY-105',
            planName: 'Plan Mensual Oro',
            price: 150.0,
            date: '20 de abr',
            method: 'Tarjeta',
            state: 'approved',
          ),
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
        physicalMeasurements: {
          'peso': 73.0,
          'altura': 1.70,
          'pecho': 92.0,
          'cintura': 85.0,
          'cadera': 96.0,
        },
        progressImages: [],
        paymentHistory: [
          PaymentRecord(
            id: 'PAY-106',
            planName: 'Plan Mensual Plata',
            price: 120.0,
            date: '01 de may',
            method: 'Yape',
            state: 'approved',
          ),
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

  // --- FASE 5 & 6: Connectivity, Hive & WebSockets ---
  bool _isOnline = true;
  bool get isOnline => _isOnline;
  StreamSubscription? _connectivitySubscription;
  final WebSocketService _webSocketService = WebSocketService();

  void _initConnectivity() {
    // Verificar conectividad inicial
    Connectivity().checkConnectivity().then((event) {
      final hasConnection = !event.contains(ConnectivityResult.none);
      _updateConnectionStatus(hasConnection);
    });

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      event,
    ) {
      final hasConnection = !event.contains(ConnectivityResult.none);
      _updateConnectionStatus(hasConnection);
    });
  }

  void _updateConnectionStatus(bool online) {
    if (_isOnline != online) {
      _isOnline = online;
      _addLog(
        'Red',
        'Estado de Conexión',
        _isOnline ? 'Online (Conectado)' : 'Offline (Desconectado)',
        _isOnline ? Colors.green : Colors.red,
      );
      notifyListeners();
      if (_isOnline) {
        if (isBackendMode) {
          _syncThemePreferenceIfNeeded();
          syncOfflineLogs();
          SyncQueueService.processQueue();
        }
      }
    }
  }

  @override
  void dispose() {
    uiPreferences.removeListener(_relayUiPreferenceChanges);
    uiPreferences.dispose();
    _connectivitySubscription?.cancel();
    _closeSocket();
    super.dispose();
  }

  // WebSocket Connection
  void _connectSocket() {
    _closeSocket();

    _webSocketService.onTenantSuspended = () async {
      final tenantId = await SecureStorage.getTenantId();
      if (tenantId != null) {
        final index = _saClients.indexWhere((c) => c.id == tenantId);
        if (index != -1) {
          _saClients[index] = _saClients[index].copyWith(active: false);
          _addLog(
            'SaaS',
            'Suscripción Bloqueada',
            'El gimnasio fue suspendido por administración en tiempo real.',
            Colors.red,
          );
          notifyListeners();
        }
      }
    };

    _webSocketService.connect();
  }

  void _closeSocket() {
    _webSocketService.disconnect();
  }

  // Carga de Rutinas
  Future<Map<String, dynamic>?> loadActiveRoutine() async {
    final box = Hive.box('gym_cache');

    if (isBackendMode && _isOnline) {
      try {
        final response = await ApiClient().dio.get('/routines/active');
        if (response.data != null) {
          await box.put('active_routine', response.data);
          return response.data as Map<String, dynamic>;
        }
      } catch (e) {
        AppLogger.debug('Error loading active routine from backend', e);
      }
    }

    // Fallback de caché local en Hive
    final cached = box.get('active_routine');
    if (cached != null) {
      if (cached is Map) {
        return Map<String, dynamic>.from(cached);
      }
    }

    return null;
  }

  // Guardado de Sesiones de Entrenamiento
  Future<bool> saveWorkoutSession(Map<String, dynamic> session) async {
    if (isBackendMode) {
      if (_isOnline) {
        try {
          await ApiClient().dio.post('/members/workout-log', data: session);
          _addLog(
            'Entrenamiento',
            'Log de esfuerzo',
            'Sesión sincronizada con el servidor.',
            Colors.green,
          );
          return true;
        } catch (e) {
          AppLogger.debug('Error posting workout log, saving offline', e);
        }
      }

      // Guardar en cola offline de Hive
      final box = Hive.box('gym_cache');
      final List<dynamic> queue = box.get('offline_workout_queue') ?? [];
      queue.add(session);
      await box.put('offline_workout_queue', queue);
      _addLog(
        'Entrenamiento',
        'Log de esfuerzo (Offline)',
        'Sin conexión. Sesión guardada localmente.',
        Colors.orange,
      );
      notifyListeners();
      return false;
    } else {
      // Demo mode fallback
      _addLog(
        'Entrenamiento',
        'Log de esfuerzo (Demo)',
        'Sesión registrada en modo demo.',
        Colors.green,
      );
      return true;
    }
  }

  Future<void> syncOfflineLogs() async {
    final box = Hive.box('gym_cache');
    final List<dynamic>? queue = box.get('offline_workout_queue');
    if (queue == null || queue.isEmpty) return;

    AppLogger.debug(
      'Sincronizando ${queue.length} logs de entrenamiento offline...',
    );

    final List<dynamic> remaining = [];
    for (var session in queue) {
      try {
        await ApiClient().dio.post('/members/workout-log', data: session);
        AppLogger.debug('Log offline sincronizado correctamente.');
      } catch (e) {
        AppLogger.debug('Fallo al sincronizar log offline, re-encolando', e);
        remaining.add(session);
      }
    }

    await box.put('offline_workout_queue', remaining);
    if (remaining.isEmpty) {
      _addLog(
        'Sincronización',
        'Entrenamientos Offline',
        'Todos los logs pendientes fueron enviados.',
        Colors.green,
      );
    } else {
      _addLog(
        'Sincronización',
        'Entrenamientos Offline',
        'Fallo al enviar algunos logs (re-encolados).',
        Colors.orange,
      );
    }
    notifyListeners();
  }

  // Observations Module
  Future<void> loadObservations() async {
    if (isBackendMode) {
      try {
        final response = await ApiClient().dio.get('/observations');
        final List<dynamic> data = response.data;
        _observations.clear();
        for (var item in data) {
          _observations.add(
            GymObservation(
              id: item['id'],
              category: item['texto']
                  .toString()
                  .split(']')[0]
                  .replaceAll('[', ''),
              description: item['texto']
                  .toString()
                  .split(']')
                  .skip(1)
                  .join(']'),
              memberName: item['autor_rol'] == 'MEMBER'
                  ? 'Socio'
                  : 'Entrenador',
              date: item['created_at'].toString().split('T')[0],
              imageUrl: item['foto_url'],
            ),
          );
        }
        notifyListeners();
      } catch (e) {
        AppLogger.debug('Error loading observations', e);
      }
    }
  }

  Future<bool> uploadObservationBackend({
    required String category,
    required String description,
    required List<int>? fileBytes,
    required String? fileName,
  }) async {
    try {
      final Map<String, dynamic> dataMap = {
        'category': category,
        'description': description,
      };

      if (fileBytes != null && fileName != null) {
        dataMap['file'] = MultipartFile.fromBytes(
          fileBytes,
          filename: fileName,
        );
      }

      final formData = FormData.fromMap(dataMap);

      await ApiClient().dio.post('/observations/upload', data: formData);
      await loadObservations(); // Refrescar bandeja
      return true;
    } catch (e) {
      AppLogger.debug('Error uploading observation', e);
      return false;
    }
  }

  int _auditLogsPage = 1;
  bool _hasMoreAuditLogs = true;
  bool _loadingMoreAuditLogs = false;

  int get auditLogsPage => _auditLogsPage;
  bool get hasMoreAuditLogs => _hasMoreAuditLogs;
  bool get loadingMoreAuditLogs => _loadingMoreAuditLogs;

  Future<void> loadAuditLogs({bool refresh = true}) async {
    if (isBackendMode) {
      if (refresh) {
        _auditLogsPage = 1;
        _hasMoreAuditLogs = true;
        _auditLogs.clear();
      } else {
        if (!_hasMoreAuditLogs || _loadingMoreAuditLogs) return;
        _loadingMoreAuditLogs = true;
        notifyListeners();
      }

      try {
        final response = await ApiClient().dio.get(
          '/reports/audit-logs',
          queryParameters: {'page': _auditLogsPage, 'limit': 20},
        );
        final List<dynamic> data = response.data;
        if (data.length < 20) {
          _hasMoreAuditLogs = false;
        } else {
          _auditLogsPage++;
        }
        for (var item in data) {
          final createdAt = item['created_at'] as String?;
          final timeStr = createdAt != null
              ? createdAt.split('T').last.substring(0, 5)
              : _formatCurrentTime();
          _auditLogs.add(
            AuditEntry(
              time: timeStr,
              actor: item['rol'] == 'SUPER_ADMIN'
                  ? 'SuperAdmin'
                  : (item['rol'] == 'ADMIN' ? 'Admin' : 'Cajero'),
              action:
                  '${item['entidad'].toString().toUpperCase()} - ${item['accion']}',
              detail: item['detalles'] != null
                  ? item['detalles'].toString()
                  : 'Detalles de la operación',
              color: item['accion'] == 'DELETE'
                  ? Colors.red
                  : (item['accion'] == 'POST' ? Colors.green : Colors.blue),
            ),
          );
        }
      } catch (e) {
        AppLogger.debug('Error loading audit logs', e);
      } finally {
        _loadingMoreAuditLogs = false;
        notifyListeners();
      }
    }
  }

  // SaaS Clients Module
  Future<void> loadSaaSClients() async {
    if (isBackendMode) {
      try {
        final response = await ApiClient().dio.get('/tenants');
        final List<dynamic> data = response.data;
        _saClients.clear();
        for (var item in data) {
          _saClients.add(
            SaaSClient(
              id: item['id'],
              name: item['nombre'],
              logo: item['logo_url'] ?? '🏋️',
              location: item['direccion'] ?? 'Ubicación',
              membersCount: '154',
              active: item['activo'],
            ),
          );
        }
        notifyListeners();
      } catch (e) {
        AppLogger.debug('Error loading saClients', e);
      }
    }
  }

  void toggleSaClient(String clientId) async {
    final index = _saClients.indexWhere((c) => c.id == clientId);
    if (index == -1) return;

    final client = _saClients[index];
    final nextState = !client.active;

    if (isBackendMode) {
      try {
        await ApiClient().dio.post('/tenants/$clientId/toggle');
        _saClients[index] = client.copyWith(active: nextState);
        _addLog(
          'SuperAdmin',
          nextState ? 'Habilitó Sede (API)' : 'Suspendió Sede (API)',
          'Sede/Cliente ${client.name} ${nextState ? 'activado' : 'bloqueado'} en la plataforma.',
          nextState ? const Color(0xFF00B85C) : Colors.red,
        );
        notifyListeners();
      } catch (e) {
        AppLogger.debug('Error toggling tenant status', e);
      }
    } else {
      _saClients[index] = client.copyWith(active: nextState);
      _addLog(
        'SuperAdmin',
        nextState ? 'Habilitó Gym' : 'Suspendió Gym',
        'Sede/Cliente ${client.name} ${nextState ? 'activado' : 'bloqueado'} en la plataforma SaaS.',
        nextState ? const Color(0xFF00B85C) : Colors.red,
      );
      notifyListeners();
    }
  }
}

class GymStateProvider extends InheritedNotifier<GymState> {
  const GymStateProvider({
    super.key,
    required GymState super.notifier,
    required super.child,
  });

  static GymState of(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<GymStateProvider>();
    assert(provider != null, 'No GymStateProvider found in context');
    return provider!.notifier!;
  }
}

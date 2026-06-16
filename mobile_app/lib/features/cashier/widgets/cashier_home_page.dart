import 'package:flutter/material.dart';
import '../../../../models/gym_models.dart';
import '../../../../data/gym_state.dart';
import '../../../../theme/app_theme_tokens.dart';
import '../../../../widgets/app_shell.dart';

class CashierHomePage extends StatelessWidget {
  const CashierHomePage({
    super.key,
    required this.palette,
    required this.state,
  });

  final RolePalette palette;
  final GymState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.sasColors;
    final myLogs = state.auditLogs
        .where((log) => log.actor.contains('Caja'))
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        RoleHeroHeader(
          palette: palette,
          title: 'Caja y Accesos',
          subtitle:
              'Valida ingresos, cobra operaciones y deja trazabilidad inmediata.',
          trailing: StatusPill(
            label: 'TURNO EN CURSO',
            color: palette.accent,
            solid: true,
          ),
        ),
        const SizedBox(height: 18),
        _TurnSummary(palette: palette, logs: myLogs),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: MetricTile(
                icon: Icons.qr_code_scanner_rounded,
                label: 'Asistencias Hoy',
                value: '${state.members.where((m) => m.todayCheckIn).length}',
                note: 'En este turno',
                accent: palette.accent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricTile(
                icon: Icons.inventory_2_outlined,
                label: 'Stock Crítico',
                value: '${state.products.where((p) => p.stock < 20).length}',
                note: 'Menos de 20 un.',
                accent: Colors.redAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const SectionHeader(title: 'Operación Auditada'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: themedCardDecoration(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.security_rounded, color: colors.info, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Operas bajo perfil de Cajero Autorizado.',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Todas las transacciones de ventas y aprobaciones de asistencia son registradas con tu firma digital en la bitácora global del administrador.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: colors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _CashierSessionPanel(palette: palette, state: state),
        const SizedBox(height: 24),
        SectionHeader(
          title: 'Mis logs de auditoría',
          action: '${myLogs.length} hoy',
        ),
        if (myLogs.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: themedCardDecoration(context),
            child: Center(
              child: Text(
                'No has registrado movimientos en este turno.',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          )
        else
          Column(
            children: myLogs.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: LogTile(
                  icon:
                      entry.action.contains('Cobró') ||
                          entry.action.contains('Venta')
                      ? Icons.point_of_sale_rounded
                      : Icons.qr_code_scanner_rounded,
                  title: entry.action,
                  detail: entry.detail,
                  time: entry.time,
                  color: entry.color,
                  locked: true,
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}

class _CashierSessionPanel extends StatefulWidget {
  const _CashierSessionPanel({required this.palette, required this.state});

  final RolePalette palette;
  final GymState state;

  @override
  State<_CashierSessionPanel> createState() => _CashierSessionPanelState();
}

class _CashierSessionPanelState extends State<_CashierSessionPanel> {
  Map<String, dynamic>? _activeCaja;
  Map<String, dynamic>? _details;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refreshCaja();
  }

  Future<void> _refreshCaja() async {
    if (!widget.state.isBackendMode) {
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final active = await widget.state.getActiveCajaBackend();
      Map<String, dynamic>? details;
      if (_isOpenCaja(active)) {
        details = await widget.state.getCajaDetailsBackend();
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _activeCaja = active;
        _details = details;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = _friendlyError(e);
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  bool _isOpenCaja(Map<String, dynamic>? caja) {
    return caja != null && caja['estado'] == 'abierta';
  }

  double _numValue(Map<String, dynamic>? source, String key) {
    final value = source?[key];
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _friendlyError(Object e) {
    final text = e.toString();
    if (text.contains('No tienes una caja abierta')) {
      return 'No hay caja abierta actualmente.';
    }
    if (text.contains('Ya tienes una caja abierta')) {
      return 'Ya existe una caja abierta para este cajero.';
    }
    return 'No se pudo completar la operación de caja.';
  }

  Future<void> _showOpenDialog() async {
    final montoCtrl = TextEditingController(text: '100');
    final obsCtrl = TextEditingController(text: 'Prueba caja móvil');
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        final colors = context.sasColors;
        return AlertDialog(
          backgroundColor: colors.surface,
          title: const Text('Abrir caja'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: montoCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Saldo inicial'),
              ),
              TextField(
                controller: obsCtrl,
                decoration: const InputDecoration(labelText: 'Observación'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Abrir'),
            ),
          ],
        );
      },
    );
    if (result != true) {
      return;
    }
    await _runCajaAction(() async {
      await widget.state.openCajaBackend(
        double.tryParse(montoCtrl.text.trim()) ?? 0,
        obsCtrl.text.trim(),
      );
    });
  }

  Future<void> _showEgressDialog() async {
    final montoCtrl = TextEditingController(text: '30');
    final motivoCtrl = TextEditingController(text: 'Prueba egreso móvil');
    String metodo = 'efectivo';
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        final colors = context.sasColors;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: colors.surface,
              title: const Text('Registrar egreso'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: montoCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Monto'),
                  ),
                  TextField(
                    controller: motivoCtrl,
                    decoration: const InputDecoration(labelText: 'Motivo'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: metodo,
                    decoration: const InputDecoration(labelText: 'Método'),
                    items: const [
                      DropdownMenuItem(
                        value: 'efectivo',
                        child: Text('Efectivo'),
                      ),
                      DropdownMenuItem(value: 'yape', child: Text('Yape')),
                      DropdownMenuItem(
                        value: 'transferencia',
                        child: Text('Transferencia'),
                      ),
                      DropdownMenuItem(value: 'pos', child: Text('POS')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => metodo = value);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Registrar'),
                ),
              ],
            );
          },
        );
      },
    );
    if (result != true) {
      return;
    }
    await _runCajaAction(() async {
      await widget.state.createEgressBackend(
        monto: double.tryParse(montoCtrl.text.trim()) ?? 0,
        motivo: motivoCtrl.text.trim(),
        metodoPago: metodo,
      );
    });
  }

  Future<void> _showCloseDialog() async {
    final stats = (_details?['stats'] as Map?)?.cast<String, dynamic>();
    final cashCtrl = TextEditingController(
      text: _numValue(stats, 'efectivo_esperado').toStringAsFixed(2),
    );
    final transferCtrl = TextEditingController(
      text:
          (_numValue(stats, 'total_ventas_transferencia') -
                  _numValue(stats, 'transferencia_egreso'))
              .toStringAsFixed(2),
    );
    final yapeCtrl = TextEditingController(
      text:
          (_numValue(stats, 'total_ventas_yape') -
                  _numValue(stats, 'yape_egreso'))
              .toStringAsFixed(2),
    );
    final posCtrl = TextEditingController(
      text:
          (_numValue(stats, 'total_ventas_pos') -
                  _numValue(stats, 'pos_egreso'))
              .toStringAsFixed(2),
    );
    final obsCtrl = TextEditingController(text: 'Cierre prueba caja móvil');
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        final colors = context.sasColors;
        return AlertDialog(
          backgroundColor: colors.surface,
          title: const Text('Cerrar caja'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: cashCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Efectivo cierre',
                  ),
                ),
                TextField(
                  controller: transferCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Transferencia cierre',
                  ),
                ),
                TextField(
                  controller: yapeCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Yape/Plin cierre',
                  ),
                ),
                TextField(
                  controller: posCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'POS cierre'),
                ),
                TextField(
                  controller: obsCtrl,
                  decoration: const InputDecoration(labelText: 'Observación'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
    if (result != true) {
      return;
    }
    await _runCajaAction(() async {
      await widget.state.closeCajaBackend(
        cash: double.tryParse(cashCtrl.text.trim()) ?? 0,
        transfer: double.tryParse(transferCtrl.text.trim()) ?? 0,
        yape: double.tryParse(yapeCtrl.text.trim()) ?? 0,
        pos: double.tryParse(posCtrl.text.trim()) ?? 0,
        observations: obsCtrl.text.trim(),
      );
    });
  }

  Future<void> _runCajaAction(Future<void> Function() action) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await action();
      await _refreshCaja();
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _error = _friendlyError(e));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sasColors;
    final isOpen = _isOpenCaja(_activeCaja);
    final caja =
        (_details?['caja'] as Map?)?.cast<String, dynamic>() ?? _activeCaja;
    final stats = (_details?['stats'] as Map?)?.cast<String, dynamic>();
    final movements = (_details?['movements'] as List?) ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Turno de caja',
          action: _loading ? 'Sincronizando' : 'Backend',
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: themedCardDecoration(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  StatusPill(
                    label: isOpen ? 'CAJA ABIERTA' : 'SIN CAJA ABIERTA',
                    color: isOpen ? widget.palette.accent : colors.warning,
                    solid: true,
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Actualizar caja',
                    onPressed: _loading ? null : _refreshCaja,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (!widget.state.isBackendMode)
                Text(
                  'Disponible solo cuando APP_MODE=backend.',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                )
              else ...[
                if (_error != null) ...[
                  Text(
                    _error!,
                    style: TextStyle(
                      color: colors.danger,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (caja != null) ...[
                  _SessionMetricRow(
                    label: 'Saldo apertura',
                    value:
                        'S/ ${_numValue(caja, 'monto_apertura').toStringAsFixed(2)}',
                  ),
                  _SessionMetricRow(
                    label: 'Efectivo esperado',
                    value:
                        'S/ ${_numValue(stats, 'efectivo_esperado').toStringAsFixed(2)}',
                  ),
                  _SessionMetricRow(
                    label: 'Total esperado',
                    value:
                        'S/ ${(_numValue(caja, 'monto_apertura') + _numValue(stats, 'total_esperado')).toStringAsFixed(2)}',
                  ),
                  _SessionMetricRow(
                    label: 'Movimientos',
                    value: '${movements.length}',
                  ),
                  const SizedBox(height: 12),
                ],
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      style: roleFilledPillButtonStyle(
                        backgroundColor: widget.palette.accent,
                        foregroundColor: widget.palette.accentInk,
                      ),
                      onPressed: _loading || isOpen ? null : _showOpenDialog,
                      icon: const Icon(Icons.lock_open_rounded, size: 18),
                      label: const Text('Abrir'),
                    ),
                    ElevatedButton.icon(
                      style: roleFilledPillButtonStyle(
                        backgroundColor: colors.warning,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _loading || !isOpen ? null : _showEgressDialog,
                      icon: const Icon(
                        Icons.remove_circle_outline_rounded,
                        size: 18,
                      ),
                      label: const Text('Egreso'),
                    ),
                    ElevatedButton.icon(
                      style: roleFilledPillButtonStyle(
                        backgroundColor: colors.danger,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _loading || !isOpen ? null : _showCloseDialog,
                      icon: const Icon(Icons.lock_rounded, size: 18),
                      label: const Text('Cerrar'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SessionMetricRow extends StatelessWidget {
  const _SessionMetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.sasColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: colors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _TurnSummary extends StatelessWidget {
  const _TurnSummary({required this.palette, required this.logs});

  final RolePalette palette;
  final List<AuditEntry> logs;

  @override
  Widget build(BuildContext context) {
    final colors = context.sasColors;
    final chargeLogs = logs.where(
      (l) => l.action.contains('Cobró') || l.action.contains('Venta'),
    );
    double revenue = 0;
    final reg = RegExp(r'S/\s*([0-9.]+)');
    for (var l in chargeLogs) {
      final match = reg.firstMatch(l.detail);
      if (match != null) {
        revenue += double.tryParse(match.group(1)!) ?? 0.0;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: themedCardDecoration(context, color: colors.surfaceElevated),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'SALDO DEL TURNO',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w900,
                  color: palette.accent,
                ),
              ),
              const Spacer(),
              StatusPill(
                label: 'CIERRA 14:00',
                color: palette.accent,
                solid: true,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'S/ ${revenue.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: colors.textPrimary,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${chargeLogs.length} transacciones registradas en este turno.',
            style: TextStyle(
              fontSize: 13,
              color: colors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

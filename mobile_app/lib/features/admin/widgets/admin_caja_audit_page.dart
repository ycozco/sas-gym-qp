import 'package:flutter/material.dart';
import '../../../../models/gym_models.dart';
import '../../../../data/gym_state.dart';
import '../../../../theme/app_theme_tokens.dart';
import '../../../../widgets/app_shell.dart';
import 'admin_dashboard_page.dart';

class AdminCajaAuditPage extends StatefulWidget {
  const AdminCajaAuditPage({
    super.key,
    required this.palette,
    required this.state,
    required this.onBack,
  });

  final RolePalette palette;
  final GymState state;
  final VoidCallback onBack;

  @override
  State<AdminCajaAuditPage> createState() => _AdminCajaAuditPageState();
}

class _AdminCajaAuditPageState extends State<AdminCajaAuditPage> {
  bool _loading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _refreshCashiers();
  }

  Future<void> _refreshCashiers() async {
    setState(() => _loading = true);
    try {
      await widget.state.loadCashiers();
    } catch (_) {
      // Safe fallback
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showEditSessionDialog(BuildContext context, CashierSession session) {
    showDialog(
      context: context,
      builder: (context) => _AdminEditCajaDialog(
        palette: widget.palette,
        state: widget.state,
        session: session,
        onSuccess: () => _refreshCashiers(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sasColors;

    final filteredCashiers = widget.state.cashiers.where((c) {
      final query = _searchQuery.toLowerCase();
      return c.name.toLowerCase().contains(query) ||
          c.shift.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
          onPressed: widget.onBack,
        ),
        title: const Text(
          'Auditoría de Cajas',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refreshCashiers,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshCashiers,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            // Search box
            Container(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.border),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                style: TextStyle(fontSize: 14, color: colors.textPrimary),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  hintText: 'Buscar cajero o estado...',
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(height: 18),

            if (_loading && widget.state.cashiers.isEmpty)
              const SizedBox(
                height: 150,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (filteredCashiers.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: adminCardDecoration(context),
                child: const Center(
                  child: Text(
                    'No se encontraron cajeros con turnos registrados.',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
            else
              ...filteredCashiers.map((cashier) {
                return _buildCashierCard(context, cashier, colors);
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildCashierCard(
    BuildContext context,
    CashierAccount cashier,
    dynamic colors,
  ) {
    final activeShift = cashier.shift.toLowerCase() == 'abierta';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: adminCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header info
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: widget.palette.accent.withValues(alpha: 0.12),
                child: Icon(Icons.person_rounded, color: widget.palette.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cashier.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14.5,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      cashier.active
                          ? 'Cajero Habilitado'
                          : 'Cajero Suspendido',
                      style: TextStyle(fontSize: 11, color: colors.textMuted),
                    ),
                  ],
                ),
              ),
              StatusPill(
                label: cashier.shift.toUpperCase(),
                color: activeShift ? widget.palette.accent : Colors.grey,
                solid: activeShift,
              ),
            ],
          ),
          const SizedBox(height: 16),

          Text(
            'Historial de Turnos Recientes:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),

          if (cashier.sessionHistory.isEmpty)
            Text(
              'No registra turnos en el sistema.',
              style: TextStyle(
                fontSize: 12,
                color: colors.textMuted,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            ...cashier.sessionHistory.take(3).map((session) {
              return _buildSessionTile(context, session, colors);
            }),
        ],
      ),
    );
  }

  Widget _buildSessionTile(
    BuildContext context,
    CashierSession session,
    dynamic colors,
  ) {
    final isOpen = session.estado == 'abierta';
    final hasDiff = session.diferencia != 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOpen
              ? widget.palette.accent.withValues(alpha: 0.2)
              : (hasDiff
                    ? Colors.redAccent.withValues(alpha: 0.2)
                    : colors.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                isOpen ? 'Turno Activo (En Curso)' : 'Turno Cerrado',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: isOpen ? widget.palette.accent : colors.textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: () => _showEditSessionDialog(context, session),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: Icon(
                    Icons.edit_rounded,
                    size: 12,
                    color: widget.palette.accent,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _formatDate(session.fechaApertura),
                style: TextStyle(fontSize: 11, color: colors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _metricLabel(
                'Apertura',
                'S/ ${session.montoApertura.toStringAsFixed(0)}',
                colors,
              ),
              if (!isOpen) ...[
                _metricLabel(
                  'Cierre Real',
                  'S/ ${session.totalIngresos.toStringAsFixed(0)}',
                  colors,
                ),
                _metricLabel(
                  'Diferencia',
                  'S/ ${session.diferencia.toStringAsFixed(2)}',
                  colors,
                  valueColor: hasDiff ? Colors.redAccent : Colors.green,
                ),
              ] else
                _metricLabel(
                  'Teórico',
                  'Esperando cuadre',
                  colors,
                  valueColor: Colors.blueAccent,
                ),
            ],
          ),

          if (!isOpen && hasDiff) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2C1315),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_rounded,
                    color: Colors.redAccent,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Obs: ${session.observaciones ?? "Sin justificar"}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _metricLabel(
    String label,
    String value,
    dynamic colors, {
    Color? valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: colors.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: valueColor ?? colors.textPrimary,
          ),
        ),
      ],
    );
  }

  String _formatDate(String isoStr) {
    try {
      final dt = DateTime.parse(isoStr);
      return '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoStr;
    }
  }
}

class _AdminEditCajaDialog extends StatefulWidget {
  const _AdminEditCajaDialog({
    required this.palette,
    required this.state,
    required this.session,
    required this.onSuccess,
  });

  final RolePalette palette;
  final GymState state;
  final CashierSession session;
  final VoidCallback onSuccess;

  @override
  State<_AdminEditCajaDialog> createState() => _AdminEditCajaDialogState();
}

class _AdminEditCajaDialogState extends State<_AdminEditCajaDialog> {
  late final TextEditingController _montoAperturaCtrl;
  late final TextEditingController _fechaAperturaCtrl;
  late final TextEditingController _fechaCierreCtrl;
  late final TextEditingController _montoCierreEfectivoCtrl;
  late final TextEditingController _montoCierreTransferenciaCtrl;
  late final TextEditingController _montoCierreYapeCtrl;
  late final TextEditingController _montoCierrePOSCtrl;
  late final TextEditingController _observacionesCtrl;
  late String _estado;

  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _estado = widget.session.estado;
    _montoAperturaCtrl = TextEditingController(
      text: widget.session.montoApertura.toStringAsFixed(2),
    );
    _fechaAperturaCtrl = TextEditingController(
      text: widget.session.fechaApertura,
    );
    _fechaCierreCtrl = TextEditingController(
      text: widget.session.fechaCierre ?? '',
    );
    _montoCierreEfectivoCtrl = TextEditingController(
      text: (widget.session.montoCierreEfectivo ?? 0.0).toStringAsFixed(2),
    );
    _montoCierreTransferenciaCtrl = TextEditingController(
      text: (widget.session.montoCierreTransferencia ?? 0.0).toStringAsFixed(2),
    );
    _montoCierreYapeCtrl = TextEditingController(
      text: (widget.session.montoCierreYape ?? 0.0).toStringAsFixed(2),
    );
    _montoCierrePOSCtrl = TextEditingController(
      text: (widget.session.montoCierrePOS ?? 0.0).toStringAsFixed(2),
    );
    _observacionesCtrl = TextEditingController(
      text: widget.session.observaciones ?? '',
    );
  }

  @override
  void dispose() {
    _montoAperturaCtrl.dispose();
    _fechaAperturaCtrl.dispose();
    _fechaCierreCtrl.dispose();
    _montoCierreEfectivoCtrl.dispose();
    _montoCierreTransferenciaCtrl.dispose();
    _montoCierreYapeCtrl.dispose();
    _montoCierrePOSCtrl.dispose();
    _observacionesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sasColors;

    return AlertDialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.border),
      ),
      title: Row(
        children: [
          Icon(Icons.edit_rounded, color: widget.palette.accent),
          const SizedBox(width: 8),
          Text(
            'Editar Turno de Caja',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 340,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _estado,
                  dropdownColor: colors.surface,
                  style: TextStyle(color: colors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Estado',
                    labelStyle: TextStyle(color: colors.textMuted),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: colors.border),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'abierta', child: Text('Abierta')),
                    DropdownMenuItem(value: 'cerrada', child: Text('Cerrada')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _estado = val;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _montoAperturaCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: TextStyle(color: colors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Monto Apertura (S/)',
                    labelStyle: TextStyle(color: colors.textMuted),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: colors.border),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _fechaAperturaCtrl,
                  style: TextStyle(color: colors.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Fecha Apertura (Horario)',
                    labelStyle: TextStyle(color: colors.textMuted),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: colors.border),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Requerido' : null,
                ),
                if (_estado == 'cerrada') ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _fechaCierreCtrl,
                    style: TextStyle(color: colors.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Fecha Cierre',
                      labelStyle: TextStyle(color: colors.textMuted),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: colors.border),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _montoCierreEfectivoCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: TextStyle(color: colors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Cierre Efectivo (S/)',
                      labelStyle: TextStyle(color: colors.textMuted),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: colors.border),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _montoCierreTransferenciaCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: TextStyle(color: colors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Cierre Transferencia (S/)',
                      labelStyle: TextStyle(color: colors.textMuted),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: colors.border),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _montoCierreYapeCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: TextStyle(color: colors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Cierre Yape/Plin (S/)',
                      labelStyle: TextStyle(color: colors.textMuted),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: colors.border),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _montoCierrePOSCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: TextStyle(color: colors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Cierre Tarjeta/POS (S/)',
                      labelStyle: TextStyle(color: colors.textMuted),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: colors.border),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                TextFormField(
                  controller: _observacionesCtrl,
                  style: TextStyle(color: colors.textPrimary, fontSize: 14),
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Observaciones / Justificación',
                    labelStyle: TextStyle(color: colors.textMuted),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: colors.border),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: Text('Cancelar', style: TextStyle(color: colors.textMuted)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.palette.accent,
            foregroundColor: widget.palette.accentInk,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: _loading
              ? null
              : () async {
                  if (!_formKey.currentState!.validate()) return;
                  setState(() => _loading = true);
                  try {
                    await widget.state.adminEditCaja(
                      widget.session.id,
                      montoApertura: double.parse(_montoAperturaCtrl.text),
                      fechaApertura: _fechaAperturaCtrl.text,
                      fechaCierre: _fechaCierreCtrl.text.isEmpty
                          ? null
                          : _fechaCierreCtrl.text,
                      estado: _estado,
                      montoCierreEfectivo: double.parse(
                        _montoCierreEfectivoCtrl.text,
                      ),
                      montoCierreTransferencia: double.parse(
                        _montoCierreTransferenciaCtrl.text,
                      ),
                      montoCierreYape: double.parse(_montoCierreYapeCtrl.text),
                      montoCierrePOS: double.parse(_montoCierrePOSCtrl.text),
                      observaciones: _observacionesCtrl.text,
                    );
                    if (context.mounted) {
                      widget.onSuccess();
                      Navigator.pop(context);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${e.toString()}'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _loading = false);
                  }
                },
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }
}

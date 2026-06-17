import 'package:flutter/material.dart';
import '../../../../models/gym_models.dart';
import '../../../../data/gym_state.dart';
import '../../../../theme/app_theme_tokens.dart';
import '../../../../widgets/app_shell.dart';

class AperturaCajaDialog extends StatefulWidget {
  const AperturaCajaDialog({
    super.key,
    required this.palette,
    required this.state,
    required this.onSuccess,
  });

  final RolePalette palette;
  final GymState state;
  final VoidCallback onSuccess;

  @override
  State<AperturaCajaDialog> createState() => _AperturaCajaDialogState();
}

class _AperturaCajaDialogState extends State<AperturaCajaDialog> {
  final _montoCtrl = TextEditingController(text: '150.0');
  final _obsCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  @override
  void dispose() {
    _montoCtrl.dispose();
    _obsCtrl.dispose();
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
          Icon(Icons.vpn_key_rounded, color: widget.palette.accent),
          const SizedBox(width: 8),
          Text(
            'Apertura de Caja',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Indica el efectivo base inicial que tienes físicamente en la gaveta de dinero:',
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _montoCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Monto de Apertura (S/) *',
                  prefixText: 'S/ ',
                ),
                style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Requerido';
                  final d = double.tryParse(val.trim());
                  if (d == null || d < 0) return 'Monto inválido';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _obsCtrl,
                decoration: const InputDecoration(
                  labelText: 'Observaciones (Opcional)',
                  hintText: 'Ej. Billetes sueltos para cambio...',
                ),
                style: TextStyle(color: colors.textPrimary),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: Text(
            'Cancelar',
            style: TextStyle(color: colors.textSecondary, fontWeight: FontWeight.bold),
          ),
        ),
        ElevatedButton(
          style: roleFilledPillButtonStyle(
            backgroundColor: widget.palette.accent,
            foregroundColor: widget.palette.accentInk,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          onPressed: _loading
              ? null
              : () async {
                  if (!_formKey.currentState!.validate()) return;
                  setState(() => _loading = true);
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    final double val = double.parse(_montoCtrl.text.trim());
                    await widget.state.openCaja(val, obs: _obsCtrl.text.trim());
                    if (mounted) {
                      navigator.pop();
                      widget.onSuccess();
                    }
                  } catch (e) {
                    if (mounted) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Error al abrir caja: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _loading = false);
                  }
                },
          child: _loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('ABRIR CAJA', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

class EgresoCajaDialog extends StatefulWidget {
  const EgresoCajaDialog({
    super.key,
    required this.palette,
    required this.state,
    required this.onSuccess,
  });

  final RolePalette palette;
  final GymState state;
  final VoidCallback onSuccess;

  @override
  State<EgresoCajaDialog> createState() => _EgresoCajaDialogState();
}

class _EgresoCajaDialogState extends State<EgresoCajaDialog> {
  final _montoCtrl = TextEditingController();
  final _motivoCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _metodoPago = 'efectivo';
  bool _loading = false;

  @override
  void dispose() {
    _montoCtrl.dispose();
    _motivoCtrl.dispose();
    _descCtrl.dispose();
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
          const Icon(Icons.outbox_rounded, color: Colors.redAccent),
          const SizedBox(width: 8),
          Text(
            'Registrar Salida / Egreso',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Registra un retiro manual de dinero de la caja física:',
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _montoCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Monto de Egreso (S/) *',
                  prefixText: 'S/ ',
                ),
                style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Requerido';
                  final d = double.tryParse(val.trim());
                  if (d == null || d <= 0) return 'Monto inválido';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _motivoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Concepto / Motivo *',
                  hintText: 'Ej. Pago de taxi, útiles de limpieza...',
                ),
                style: TextStyle(color: colors.textPrimary),
                validator: (val) => val == null || val.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Descripción adicional',
                  hintText: 'Ej. Factura N° 124...',
                ),
                style: TextStyle(color: colors.textPrimary),
                maxLines: 2,
              ),
              const SizedBox(height: 14),
              Text(
                'Medio de pago afectado:',
                style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                dropdownColor: colors.surface,
                value: _metodoPago,
                style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: const [
                  DropdownMenuItem(value: 'efectivo', child: Text('Efectivo (Gaveta)')),
                  DropdownMenuItem(value: 'transferencia', child: Text('Transferencia Bancaria')),
                  DropdownMenuItem(value: 'yape', child: Text('Yape / Plin')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _metodoPago = val);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: Text(
            'Cancelar',
            style: TextStyle(color: colors.textSecondary, fontWeight: FontWeight.bold),
          ),
        ),
        ElevatedButton(
          style: roleFilledPillButtonStyle(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          onPressed: _loading
              ? null
              : () async {
                  if (!_formKey.currentState!.validate()) return;
                  setState(() => _loading = true);
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    final double val = double.parse(_montoCtrl.text.trim());
                    await widget.state.registerEgreso(
                      val,
                      _motivoCtrl.text.trim(),
                      paymentMethod: _metodoPago,
                      extraDesc: _descCtrl.text.trim(),
                    );
                    if (mounted) {
                      navigator.pop();
                      widget.onSuccess();
                    }
                  } catch (e) {
                    if (mounted) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Error al registrar egreso: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _loading = false);
                  }
                },
          child: _loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('REGISTRAR EGRESO', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

class ArqueoCajaDialog extends StatefulWidget {
  const ArqueoCajaDialog({
    super.key,
    required this.palette,
    required this.state,
    required this.onSuccess,
  });

  final RolePalette palette;
  final GymState state;
  final VoidCallback onSuccess;

  @override
  State<ArqueoCajaDialog> createState() => _ArqueoCajaDialogState();
}

class _ArqueoCajaDialogState extends State<ArqueoCajaDialog> {
  CajaDetails? _details;
  bool _loadingDetails = true;
  bool _submitting = false;

  // counted physical amounts
  final _cashCtrl = TextEditingController(text: '');
  final _transferCtrl = TextEditingController(text: '');
  final _yapeCtrl = TextEditingController(text: '');
  final _posCtrl = TextEditingController(text: '');
  final _obsCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  @override
  void dispose() {
    _cashCtrl.dispose();
    _transferCtrl.dispose();
    _yapeCtrl.dispose();
    _posCtrl.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchDetails() async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final details = await widget.state.getCajaDetails();
      if (mounted) {
        setState(() {
          _details = details;
          _loadingDetails = false;
        });
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Error al obtener cuadre teórico: $e'), backgroundColor: Colors.red),
        );
        navigator.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sasColors;

    if (_loadingDetails || _details == null) {
      return AlertDialog(
        backgroundColor: colors.surface,
        content: const SizedBox(
          height: 100,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Obteniendo arqueo del sistema...', style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      );
    }

    final stats = _details!.stats;
    final opening = _details!.caja.montoApertura;

    // Parsed inputs or defaults to 0
    final double physicalCash = double.tryParse(_cashCtrl.text.trim()) ?? 0.0;
    final double physicalTransfer = double.tryParse(_transferCtrl.text.trim()) ?? 0.0;
    final double physicalYape = double.tryParse(_yapeCtrl.text.trim()) ?? 0.0;
    final double physicalPOS = double.tryParse(_posCtrl.text.trim()) ?? 0.0;

    final double totalContado = physicalCash + physicalTransfer + physicalYape + physicalPOS;
    final double totalSistema = opening + stats.totalEsperado;
    final double diferencia = totalContado - totalSistema;

    return AlertDialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: colors.border),
      ),
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      title: Row(
        children: [
          Icon(Icons.balance_rounded, color: widget.palette.accent),
          const SizedBox(width: 8),
          Text(
            'Arqueo y Cierre de Caja',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Totales comparativos
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.surfaceAlt,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.border),
                  ),
                  child: Column(
                    children: [
                      _rowTeorico('Saldo de Apertura:', 'S/ ${opening.toStringAsFixed(2)}', colors),
                      _rowTeorico('Ventas Netas esperadas:', 'S/ ${stats.totalEsperado.toStringAsFixed(2)}', colors),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'EFECTIVO ESPERADO GAVETA:',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: colors.textSecondary),
                          ),
                          Text(
                            'S/ ${stats.efectivoEsperado.toStringAsFixed(2)}',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: colors.textPrimary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'TOTAL ESPERADO SISTEMA:',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: colors.textSecondary),
                          ),
                          Text(
                            'S/ ${totalSistema.toStringAsFixed(2)}',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: colors.accent),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Ingresa el arqueo físico real de dinero contado:',
                  style: TextStyle(color: colors.textSecondary, fontSize: 12.5, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                // Inputs por método
                _buildPhysicalInput('Efectivo Físico (Gaveta)', _cashCtrl, stats.efectivoEsperado, colors),
                _buildPhysicalInput('Transferencias Bancarias', _transferCtrl, stats.totalVentasTransferencia - stats.transferenciaEgreso, colors),
                _buildPhysicalInput('Yape / Plin Recibido', _yapeCtrl, stats.totalVentasYape - stats.yapeEgreso, colors),
                _buildPhysicalInput('Tarjeta POS Recibido', _posCtrl, stats.totalVentasPOS - stats.posEgreso, colors),

                const SizedBox(height: 12),

                // Diferencia
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: diferencia == 0.0
                        ? const Color(0xFF132D1C)
                        : (diferencia.abs() < 10.0 ? const Color(0xFF33230C) : const Color(0xFF2C1315)),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: diferencia == 0.0
                          ? Colors.green.withValues(alpha: 0.3)
                          : (diferencia.abs() < 10.0 ? Colors.orange.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        diferencia == 0.0
                            ? Icons.check_circle_outline_rounded
                            : Icons.warning_amber_rounded,
                        color: diferencia == 0.0 ? Colors.green : (diferencia.abs() < 10.0 ? Colors.orange : Colors.red),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              diferencia == 0.0
                                  ? 'Caja Cuadrada'
                                  : (diferencia > 0 ? 'Sobrante en Caja' : 'Faltante en Caja'),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: diferencia == 0.0 ? Colors.green : (diferencia.abs() < 10.0 ? Colors.orange : Colors.red),
                              ),
                            ),
                            Text(
                              diferencia == 0.0
                                  ? 'Los montos físicos coinciden con el sistema.'
                                  : 'Hay una diferencia física de S/ ${diferencia.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 11, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'S/ ${diferencia.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: diferencia == 0.0 ? Colors.green : (diferencia.abs() < 10.0 ? Colors.orange : Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),
                TextFormField(
                  controller: _obsCtrl,
                  decoration: InputDecoration(
                    labelText: diferencia == 0.0 ? 'Notas de cierre (Opcional)' : 'Justificación de diferencia (Obligatorio) *',
                    hintText: 'Ej. Faltó dar vuelto de 2 soles...',
                  ),
                  style: TextStyle(color: colors.textPrimary),
                  maxLines: 2,
                  validator: (val) {
                    if (diferencia != 0.0) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Debes justificar la diferencia para cerrar.';
                      }
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: Text(
            'Cancelar',
            style: TextStyle(color: colors.textSecondary, fontWeight: FontWeight.bold),
          ),
        ),
        ElevatedButton(
          style: roleFilledPillButtonStyle(
            backgroundColor: widget.palette.accent,
            foregroundColor: widget.palette.accentInk,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          onPressed: _submitting
              ? null
              : () async {
                  if (!_formKey.currentState!.validate()) return;
                  setState(() => _submitting = true);
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await widget.state.closeCaja(
                      cash: physicalCash,
                      transfer: physicalTransfer,
                      yape: physicalYape,
                      pos: physicalPOS,
                      observations: _obsCtrl.text.trim(),
                    );
                    if (mounted) {
                      navigator.pop();
                      widget.onSuccess();
                    }
                  } catch (e) {
                    if (mounted) {
                      messenger.showSnackBar(
                        SnackBar(content: Text('Error al cerrar caja: $e'), backgroundColor: Colors.red),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _submitting = false);
                  }
                },
          child: _submitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('CERRAR CAJA', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _rowTeorico(String title, String value, dynamic colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12.5)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildPhysicalInput(String label, TextEditingController controller, double expected, dynamic colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: colors.textPrimary)),
                Text('Esperado: S/ ${expected.toStringAsFixed(2)}', style: TextStyle(color: colors.textMuted, fontSize: 11)),
              ],
            ),
          ),
          Container(
            width: 130,
            height: 42,
            decoration: BoxDecoration(
              color: colors.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.border),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary, fontSize: 13.5),
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: '0.00',
                prefixText: 'S/ ',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

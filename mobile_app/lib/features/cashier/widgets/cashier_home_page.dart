import 'package:flutter/material.dart';
import '../../../../models/gym_models.dart';
import '../../../../data/gym_state.dart';
import '../../../../theme/app_theme_tokens.dart';
import '../../../../widgets/app_shell.dart';
import 'caja_dialogs.dart';

class CashierHomePage extends StatefulWidget {
  const CashierHomePage({
    super.key,
    required this.palette,
    required this.state,
  });

  final RolePalette palette;
  final GymState state;

  @override
  State<CashierHomePage> createState() => _CashierHomePageState();
}

class _CashierHomePageState extends State<CashierHomePage> {
  bool _loadingDetails = false;
  CajaDetails? _details;

  @override
  void initState() {
    super.initState();
    _loadCajaDetails();
  }

  Future<void> _loadCajaDetails() async {
    if (widget.state.activeCaja == null) {
      setState(() {
        _details = null;
        _loadingDetails = false;
      });
      return;
    }
    setState(() => _loadingDetails = true);
    try {
      final details = await widget.state.getCajaDetails();
      if (mounted) {
        setState(() {
          _details = details;
        });
      }
    } catch (e) {
      // Silet fail or fallback
    } finally {
      if (mounted) setState(() => _loadingDetails = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sasColors;
    final activeCaja = widget.state.activeCaja;
    final isCajaOpen = activeCaja != null;

    final myLogs = widget.state.auditLogs
        .where((log) => log.actor.contains('Caja'))
        .toList();

    return RefreshIndicator(
      onRefresh: () async {
        await widget.state.checkActiveCaja();
        await _loadCajaDetails();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          RoleHeroHeader(
            palette: widget.palette,
            title: 'Caja y Accesos',
            subtitle: 'Valida ingresos, cobra operaciones y deja trazabilidad inmediata.',
            trailing: StatusPill(
              label: isCajaOpen ? 'CAJA ABIERTA' : 'CAJA CERRADA',
              color: isCajaOpen ? widget.palette.accent : Colors.red,
              solid: true,
            ),
          ),
          const SizedBox(height: 18),

          // Caja state banner / action
          if (!isCajaOpen)
            _buildClosedCajaBanner(context, colors)
          else ...[
            _buildOpenCajaDashboard(context, colors, activeCaja),
            const SizedBox(height: 20),
            _buildQuickActions(context, colors),
          ],

          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: MetricTile(
                  icon: Icons.qr_code_scanner_rounded,
                  label: 'Asistencias Hoy',
                  value: '${widget.state.members.where((m) => m.todayCheckIn).length}',
                  note: 'En este turno',
                  accent: widget.palette.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MetricTile(
                  icon: Icons.inventory_2_outlined,
                  label: 'Stock Crítico',
                  value: '${widget.state.products.where((p) => p.stock < 20).length}',
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
                    icon: entry.action.contains('Cobró') || entry.action.contains('Venta')
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
      ),
    );
  }

  Widget _buildClosedCajaBanner(BuildContext context, dynamic colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2C1315),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lock_rounded, color: Colors.redAccent, size: 24),
              SizedBox(width: 10),
              Text(
                'Caja Cerrada',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.redAccent),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Debes realizar la apertura de caja e indicar el saldo inicial en efectivo para poder procesar pagos en el POS o vender membresías.',
            style: TextStyle(fontSize: 13, color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: roleFilledPillButtonStyle(
                backgroundColor: widget.palette.accent,
                foregroundColor: widget.palette.accentInk,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.vpn_key_rounded),
              label: const Text('APERTURAR TURNO DE CAJA', style: TextStyle(fontWeight: FontWeight.w900)),
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (context) => AperturaCajaDialog(
                    palette: widget.palette,
                    state: widget.state,
                    onSuccess: () {
                      _loadCajaDetails();
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpenCajaDashboard(BuildContext context, dynamic colors, CashierSession activeCaja) {
    final double saldoTotal = _details?.stats.efectivoEsperado ?? activeCaja.montoApertura;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: themedCardDecoration(context, color: colors.surfaceElevated),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'SALDO EN EFECTIVO ESPERADO',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w900,
                  color: widget.palette.accent,
                ),
              ),
              const Spacer(),
              _loadingDetails
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : InkWell(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AjustarMontoAperturaDialog(
                            palette: widget.palette,
                            state: widget.state,
                            initialAmount: activeCaja.montoApertura,
                            onSuccess: () {
                              _loadCajaDetails();
                            },
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Row(
                          children: [
                            Text(
                              'Apertura: S/ ${activeCaja.montoApertura.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: colors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.edit_rounded,
                              size: 10,
                              color: widget.palette.accent,
                            ),
                          ],
                        ),
                      ),
                    ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'S/ ${saldoTotal.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: colors.textPrimary,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 8),
          if (_details != null)
            Text(
              'Ingresos: S/ ${_details!.stats.totalEsperado.toStringAsFixed(2)} (POS: S/ ${_details!.stats.totalVentasPOS.toStringAsFixed(0)} · Yape: S/ ${_details!.stats.totalVentasYape.toStringAsFixed(0)})',
              style: TextStyle(
                fontSize: 12.5,
                color: colors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            )
          else
            Text(
              'Cargando detalles de transacciones...',
              style: TextStyle(fontSize: 12, color: colors.textMuted),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, dynamic colors) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            style: roleOutlinedPillButtonStyle(
              foregroundColor: Colors.redAccent,
              backgroundColor: Colors.redAccent.withValues(alpha: 0.05),
              side: const BorderSide(color: Colors.redAccent),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.outbox_rounded),
            label: const Text('REGISTRAR EGRESO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (context) => EgresoCajaDialog(
                  palette: widget.palette,
                  state: widget.state,
                  onSuccess: () {
                    _loadCajaDetails();
                  },
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            style: roleFilledPillButtonStyle(
              backgroundColor: widget.palette.accent,
              foregroundColor: widget.palette.accentInk,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.balance_rounded),
            label: const Text('ARQUEAR Y CERRAR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (context) => ArqueoCajaDialog(
                  palette: widget.palette,
                  state: widget.state,
                  onSuccess: () {
                    _loadCajaDetails();
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}


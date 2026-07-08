import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../data/gym_state.dart';
import '../../../../models/gym_models.dart';
import '../../../../theme/app_theme_tokens.dart';
import '../../../../widgets/app_shell.dart';

class CashierScanPage extends StatefulWidget {
  const CashierScanPage({
    super.key,
    required this.palette,
    required this.state,
    required this.scanInput,
    required this.onScanChanged,
    required this.onTriggerVerdict,
    required this.onDayPass,
  });

  final RolePalette palette;
  final GymState state;
  final String scanInput;
  final Function(String) onScanChanged;
  final Function(String, MemberRecord?, String) onTriggerVerdict;
  final Function(String memberDni, {String? planName, double? price}) onDayPass;

  @override
  State<CashierScanPage> createState() => _CashierScanPageState();
}

class _CashierScanPageState extends State<CashierScanPage> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
  );
  bool _processingScan = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sasColors;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        RoleHeroHeader(
          palette: widget.palette,
          title: 'Escáner de sala',
          subtitle:
              'Escanea el QR del socio y valida reglas de entrada al instante.',
        ),
        const SizedBox(height: 18),
        Container(
          height: 260,
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF2C2C2C), width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                MobileScanner(
                  controller: _scannerController,
                  onDetect: (capture) {
                    final value = capture.barcodes
                        .map((barcode) => barcode.rawValue)
                        .whereType<String>()
                        .firstOrNull;
                    if (value != null) _triggerScan(value);
                  },
                ),
                Center(
                  child: Container(
                    width: 148,
                    height: 148,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: widget.palette.accent,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.66),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _processingScan
                                ? Icons.sync_rounded
                                : Icons.qr_code_scanner_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _processingScan
                                ? 'VALIDANDO ACCESO'
                                : 'CAMARA ACTIVA',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: themedCardDecoration(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Lectura QR o DNI',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
              ),
              const SizedBox(height: 8),
              Text(
                'Apunta la cámara al QR del socio. Si hay contingencia, pega el contenido QR manualmente.',
                style: TextStyle(color: colors.textSecondary, fontSize: 12.5),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: colors.surfaceAlt,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colors.border),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: TextField(
                        keyboardType: TextInputType.number,
                        onChanged: widget.onScanChanged,
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Contenido QR: DNI|TOKEN',
                          hintStyle: TextStyle(color: colors.textMuted),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: roleFilledPillButtonStyle(
                      backgroundColor: widget.palette.accent,
                      foregroundColor: widget.palette.accentInk,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                    ),
                    onPressed: () {
                      if (widget.scanInput.isNotEmpty) {
                        _triggerScan(widget.scanInput);
                      }
                    },
                    child: const Text(
                      'Validar QR',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.palette.accent.withValues(alpha: 0.12),
                widget.palette.accent.withValues(alpha: 0.04),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.palette.accent.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.palette.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.local_activity_rounded,
                      color: widget.palette.accent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pase por un día',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          'Emite un acceso diario rápido - S/ 25.00',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: widget.palette.accent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'S/ 25',
                      style: TextStyle(
                        color: widget.palette.accentInk,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: colors.border),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _dayPassButton(
                      context,
                      icon: Icons.person_off_rounded,
                      label: 'Pase anónimo',
                      subtitle: 'Sin registro',
                      onTap: () => widget.onDayPass(
                        'ANONIMO',
                        planName: 'Pase por un día',
                        price: 25.0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _dayPassButton(
                      context,
                      icon: Icons.badge_rounded,
                      label: 'Pase con DNI',
                      subtitle: 'Registrar o buscar',
                      onTap: () => _showDayPassDniDialog(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dayPassButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final colors = context.sasColors;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: widget.palette.accent, size: 26),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12.5,
                  color: colors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(color: colors.textSecondary, fontSize: 10.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDayPassDniDialog(BuildContext context) {
    final controller = TextEditingController();
    final colors = context.sasColors;
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.badge_rounded, color: widget.palette.accent, size: 26),
              const SizedBox(width: 10),
              Text(
                'Pase con DNI',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ingresa el DNI del cliente. Si no existe en el sistema se registrará automáticamente como nuevo socio.',
                  style: TextStyle(color: colors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  maxLength: 8,
                  decoration: InputDecoration(
                    labelText: 'DNI del cliente',
                    prefixIcon: const Icon(Icons.person_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancelar',
                style: TextStyle(color: colors.textSecondary),
              ),
            ),
            ElevatedButton(
              style: roleFilledPillButtonStyle(
                backgroundColor: widget.palette.accent,
                foregroundColor: widget.palette.accentInk,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onPressed: () {
                final dni = controller.text.trim();
                if (dni.isEmpty) return;
                Navigator.pop(ctx);
                widget.onDayPass(dni, planName: 'Pase por un día', price: 25.0);
              },
              child: const Text(
                'Emitir pase',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _triggerScan(String input) async {
    final rawInput = input.trim();
    if (rawInput.isEmpty || _processingScan) return;

    setState(() => _processingScan = true);
    await _scannerController.stop();

    try {
      final hasQrPayload = rawInput.contains('|');
      final parts = hasQrPayload ? rawInput.split('|') : <String>[];
      final dni = hasQrPayload ? parts.first : rawInput;
      final otpToken = hasQrPayload && parts.length > 1 ? parts[1] : '';

      if (!hasQrPayload || otpToken.isEmpty) {
        widget.onTriggerVerdict('denied', null, dni);
        return;
      }

      final response = await widget.state.verifyAttendanceBackend(
        dni: dni,
        otpToken: otpToken,
      );

      final verdict = response['verdict'];
      final member = response['member'] as MemberRecord?;

      String resultStr = 'denied';
      if (verdict == 'GREEN') resultStr = 'granted';
      if (verdict == 'AMBER') resultStr = 'grace';
      if (verdict == 'RED' && member == null) {
        final reason = response['reason']?.toString().toLowerCase() ?? '';
        if (reason.contains('no registrado') ||
            reason.contains('dni inválido')) {
          resultStr = 'not_found';
        }
      }

      widget.onTriggerVerdict(resultStr, member, dni);
    } finally {
      if (mounted) {
        setState(() => _processingScan = false);
      }
    }
  }
}

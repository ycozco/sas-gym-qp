import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../data/gym_state.dart';
import '../../../../models/gym_models.dart';
import '../../../../theme/app_theme_tokens.dart';
import '../../../../widgets/app_shell.dart';

class AdminScannerPage extends StatefulWidget {
  const AdminScannerPage({
    super.key,
    required this.palette,
    required this.state,
    required this.scanInput,
    required this.isLaserMoving,
    required this.onScanInputChanged,
    required this.onTriggerVerdict,
  });

  final RolePalette palette;
  final GymState state;
  final String scanInput;
  final bool isLaserMoving;
  final ValueChanged<String> onScanInputChanged;
  final Function(String, MemberRecord?, String) onTriggerVerdict;

  @override
  State<AdminScannerPage> createState() => _AdminScannerPageState();
}

class _AdminScannerPageState extends State<AdminScannerPage> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
  );
  bool _processingScan = false;
  String? _scanMessage;

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
          title: 'Escáner Admin',
          subtitle:
              'Escanea el QR real del socio y valida el acceso en la API.',
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
                'Lectura QR',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
              ),
              const SizedBox(height: 8),
              Text(
                'Apunta la cámara al QR del socio. En contingencia, pega el contenido QR completo.',
                style: TextStyle(color: colors.textSecondary, fontSize: 12.5),
              ),
              if (_scanMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _scanMessage!,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
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
                        keyboardType: TextInputType.text,
                        onChanged: widget.onScanInputChanged,
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
      ],
    );
  }

  Future<void> _triggerScan(String input) async {
    final rawInput = input.trim();
    if (rawInput.isEmpty || _processingScan) return;

    final parts = rawInput.split('|');
    final dni = parts.isNotEmpty ? parts.first.trim() : '';
    final otpToken = parts.length > 1 ? parts[1].trim() : '';
    if (dni.isEmpty || otpToken.isEmpty) {
      setState(() {
        _scanMessage = 'QR inválido. El formato esperado es DNI|TOKEN.';
      });
      return;
    }

    setState(() {
      _processingScan = true;
      _scanMessage = null;
    });
    await _scannerController.stop();

    try {
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
        final reason = response['reason']?.toString() ?? '';
        if (reason.contains('no registrado') ||
            reason.contains('DNI inválido')) {
          resultStr = 'not_found';
        }
      }

      if (!mounted) return;
      widget.onTriggerVerdict(resultStr, member, dni);
    } finally {
      if (mounted) {
        setState(() => _processingScan = false);
        await _scannerController.start();
      }
    }
  }
}

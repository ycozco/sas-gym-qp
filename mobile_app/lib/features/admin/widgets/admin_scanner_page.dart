import 'package:flutter/material.dart';
import 'package:otp/otp.dart';
import '../../../../core/config/app_config.dart';
import '../../../../models/gym_models.dart';
import '../../../../data/gym_state.dart';
import '../../../../theme/app_theme_tokens.dart';
import '../../../../widgets/app_shell.dart';
import 'admin_dashboard_page.dart';

class AdminScannerPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final colors = context.sasColors;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        RoleHeroHeader(
          palette: palette,
          title: 'Escáner Admin',
          subtitle: 'Simula accesos y valida de forma reactiva el estatus del socio.',
        ),
        const SizedBox(height: 18),

        // Laser Viewport Graphics
        Container(
          height: 220,
          decoration: BoxDecoration(
            color: const Color(0xFF16161A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF2E2E38), width: 1.5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                const AdminLaserSweepLine(),
                Center(
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      border: Border.all(color: palette.accent, width: 2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.videocam_rounded, color: Colors.redAccent, size: 14),
                          SizedBox(width: 6),
                          Text('CAM_SIM_ONLINE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
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

        // Simulator Dashboard Form
        Container(
          padding: const EdgeInsets.all(20),
          decoration: adminCardDecoration(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Simulación de Accesos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              Text(
                'Selecciona un socio de prueba para validar reactivamente las reglas de admisión.',
                style: TextStyle(color: colors.textSecondary, fontSize: 12.5, height: 1.4),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _scanSimButton('Mateo (Activo)', '11111111'),
                  _scanSimButton('Ana (En Gracia)', '55667788'),
                  _scanSimButton('Diego (Vencido)', '11223344'),
                  _scanSimButton('DNI Inválido', '99999999'),
                ],
              ),
              const SizedBox(height: 20),
              Divider(height: 1, color: colors.border),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: colors.surfaceAlt,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.border),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: TextField(
                        keyboardType: TextInputType.number,
                        onChanged: onScanInputChanged,
                        style: TextStyle(fontSize: 14, color: colors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Digitar DNI del socio...',
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
                      backgroundColor: palette.accent,
                      foregroundColor: palette.accentInk,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    ),
                    onPressed: () {
                      if (scanInput.isNotEmpty) {
                        _triggerScan(scanInput);
                      }
                    },
                    child: const Text('Escanear', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _scanSimButton(String label, String dni) {
    return ElevatedButton(
      style: roleOutlinedPillButtonStyle(
        foregroundColor: palette.accent,
        backgroundColor: palette.accent.withValues(alpha: 0.08),
        side: BorderSide(color: palette.accent.withValues(alpha: 0.18)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      onPressed: () => _triggerScan(dni),
      child: Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
    );
  }

  void _triggerScan(String input) async {
    String rawInput = input.trim();
    if (rawInput.isEmpty) return;

    if (state.isBackendMode && !rawInput.contains('|')) {
      final res = await state.simulateAttendanceAccessBackend(dni: rawInput);
      final verdict = res['verdict'];
      final member = res['member'] as MemberRecord?;

      String resultStr = 'denied';
      if (verdict == 'GREEN') resultStr = 'granted';
      if (verdict == 'AMBER') resultStr = 'grace';
      if (verdict == 'RED' && member == null) {
        final reason = res['reason']?.toString() ?? '';
        if (reason.contains('no registrado') || reason.contains('DNI invÃ¡lido')) {
          resultStr = 'not_found';
        }
      }

      onTriggerVerdict(resultStr, member, rawInput);
      return;
    }

    String dni = rawInput;
    String otpToken = '';
    final hasQrPayload = rawInput.contains('|');
    
    if (hasQrPayload) {
      final parts = rawInput.split('|');
      dni = parts[0];
      otpToken = parts[1];
    } else if (state.isBackendMode) {
      onTriggerVerdict('denied', null, dni);
      return;
    } else {
      final secret = AppConfig.demoTotpSecretForDni(dni);
      final time = DateTime.now().millisecondsSinceEpoch;
      if (secret != null) {
        try {
          otpToken = OTP.generateTOTPCodeString(
            secret,
            time,
            interval: 30,
            length: 6,
            algorithm: Algorithm.SHA1,
          );
        } catch (e) {
          AppLogger.debug('Error generating simulator TOTP', e);
        }
      }
    }

    if (state.isBackendMode) {
      final res = await state.verifyAttendanceBackend(dni: dni, otpToken: otpToken);
      final verdict = res['verdict'];
      final member = res['member'] as MemberRecord?;

      String resultStr = 'denied';
      if (verdict == 'GREEN') resultStr = 'granted';
      if (verdict == 'AMBER') resultStr = 'grace';
      if (verdict == 'RED' && member == null) {
        final reason = res['reason']?.toString() ?? '';
        if (reason.contains('no registrado') || reason.contains('DNI inválido')) {
          resultStr = 'not_found';
        }
      }

      onTriggerVerdict(resultStr, member, dni);
    } else {
      final result = state.recordAttendance(dni);
      final memberIndex = state.allMembersIncludingSoftDeleted.indexWhere((m) => m.dni == dni);
      final MemberRecord? member = memberIndex != -1 ? state.allMembersIncludingSoftDeleted[memberIndex] : null;
      onTriggerVerdict(result, member, dni);
    }
  }
}

class AdminLaserSweepLine extends StatefulWidget {
  const AdminLaserSweepLine({super.key});

  @override
  State<AdminLaserSweepLine> createState() => _AdminLaserSweepLineState();
}

class _AdminLaserSweepLineState extends State<AdminLaserSweepLine> with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Positioned(
          top: _animController.value * 210 + 5,
          left: 10,
          right: 10,
          child: Container(
            height: 2.5,
            decoration: BoxDecoration(
              color: Colors.limeAccent,
              boxShadow: [
                BoxShadow(
                  color: Colors.lime.withValues(alpha: 0.8),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

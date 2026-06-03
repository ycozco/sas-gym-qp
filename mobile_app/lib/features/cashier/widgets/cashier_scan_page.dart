import 'package:flutter/material.dart';
import 'package:otp/otp.dart';
import '../../../../models/gym_models.dart';
import '../../../../data/gym_state.dart';
import '../../../../widgets/app_shell.dart';

class CashierScanPage extends StatelessWidget {
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
  /// Called with (memberDni, planName, price) when issuing a day pass.
  /// memberDni == 'ANONIMO' for anonymous pass.
  final Function(String memberDni, {String? planName, double? price}) onDayPass;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        RoleHeroHeader(
          palette: palette,
          title: 'Escáner de Sala',
          subtitle: 'Simula accesos y valida reglas de entrada al instante.',
        ),
        const SizedBox(height: 18),

        // Scanner Graphic with Overlay Grid
        Container(
          height: 240,
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF2C2C2C), width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Animated red laser sweep line
                const LaserSweepLine(),
                // Corner grid markers
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.videocam_rounded, color: Colors.red, size: 14),
                          SizedBox(width: 6),
                          Text('CAM_SIMULATOR_ON',
                              style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold)),
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

        // Interactive Scanner Simulator Actions
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE6E2D8)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Simulación de Escaneo QR',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
              ),
              const SizedBox(height: 8),
              Text(
                'Selecciona un socio preconfigurado o digita un DNI para probar las reglas de acceso reactivas.',
                style: TextStyle(color: Colors.black.withValues(alpha: 0.6), fontSize: 12.5),
              ),
              const SizedBox(height: 16),
              // Preset scan test buttons
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _scanSimButton('Mateo Salas (Activo)', '11111111'),
                  _scanSimButton('Ana Torres (En Gracia)', '55667788'),
                  _scanSimButton('Diego Castro (Vencido)', '11223344'),
                  _scanSimButton('Rosa Mendieta (Activa)', '44332211'),
                  _scanSimButton('DNI Inválido', '99999999'),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(height: 1, color: Color(0xFFE8E4D9)),
              const SizedBox(height: 20),
              // Custom DNI field
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F6F6),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2DDD5)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: TextField(
                        keyboardType: TextInputType.number,
                        onChanged: onScanChanged,
                        style: const TextStyle(fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Digitar DNI del socio...',
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
                    child: const Text('Escanear DNI', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ─── Pase por un Día ────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                palette.accent.withValues(alpha: 0.12),
                palette.accent.withValues(alpha: 0.04),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.accent.withValues(alpha: 0.3), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: palette.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.local_activity_rounded, color: palette.accent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pase por un Día',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                        ),
                        Text(
                          'Emite un acceso diario rápido — S/ 25.00',
                          style: TextStyle(color: Colors.black.withValues(alpha: 0.55), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: palette.accent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'S/ 25',
                      style: TextStyle(
                        color: palette.accentInk,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFE8E4D9)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _dayPassButton(
                      context,
                      icon: Icons.person_off_rounded,
                      label: 'Pase Anónimo',
                      subtitle: 'Sin registro',
                      onTap: () => onDayPass('ANONIMO', planName: 'Pase por un Día', price: 25.0),
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
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE6E2D8)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: palette.accent, size: 26),
              const SizedBox(height: 6),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5)),
              Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 10.5)),
            ],
          ),
        ),
      ),
    );
  }

  void _showDayPassDniDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.badge_rounded, color: palette.accent, size: 26),
              const SizedBox(width: 10),
              const Text('Pase con DNI', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
            ],
          ),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ingresa el DNI del cliente. Si no existe en el sistema se registrará automáticamente como nuevo socio.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
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
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: roleFilledPillButtonStyle(
                backgroundColor: palette.accent,
                foregroundColor: palette.accentInk,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: () {
                final dni = controller.text.trim();
                if (dni.isEmpty) return;
                Navigator.pop(ctx);
                onDayPass(dni, planName: 'Pase por un Día', price: 25.0);
              },
              child: const Text('Emitir Pase', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
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
    String dni = input;
    String otpToken = '';
    
    if (input.contains('|')) {
      final parts = input.split('|');
      dni = parts[0];
      otpToken = parts[1];
    } else {
      final secret = '${dni}_secure_totp_secret_key_2026';
      final time = DateTime.now().millisecondsSinceEpoch;
      try {
        otpToken = OTP.generateTOTPCodeString(
          secret,
          time,
          interval: 30,
          length: 6,
          algorithm: Algorithm.SHA1,
        );
      } catch (e) {
        debugPrint('Error generating simulator TOTP: $e');
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

class LaserSweepLine extends StatefulWidget {
  const LaserSweepLine({super.key});

  @override
  State<LaserSweepLine> createState() => _LaserSweepLineState();
}

class _LaserSweepLineState extends State<LaserSweepLine> with SingleTickerProviderStateMixin {
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
          top: _animController.value * 230 + 5,
          left: 10,
          right: 10,
          child: Container(
            height: 2.5,
            decoration: BoxDecoration(
              color: Colors.redAccent,
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.8),
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


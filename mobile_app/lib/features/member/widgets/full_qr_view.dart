import 'dart:async';
import 'package:flutter/material.dart';
import 'package:otp/otp.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/config/app_config.dart';
import '../../../data/gym_state.dart';
import '../../../models/gym_models.dart';
import 'member_shared_utils.dart';

class FullQRView extends StatefulWidget {
  const FullQRView({super.key, required this.palette, required this.onBack});

  final RolePalette palette;
  final VoidCallback onBack;

  @override
  State<FullQRView> createState() => _FullQRViewState();
}

class _FullQRViewState extends State<FullQRView> {
  int _secondsLeft = 30;
  String _qrData = '';
  String? _qrError;
  Timer? _timer;

  bool _canGenerateQr(MemberRecord member) {
    return member.state == 'active' || member.state == 'grace';
  }

  String _blockedReason(MemberRecord member) {
    if (member.state == 'suspended') {
      return 'Tu cuenta o membresía está suspendida. Acércate a recepción para regularizar tu acceso.';
    }
    if (member.state == 'expired') {
      return 'Tu membresía está vencida. Renueva tu plan para reactivar el QR de acceso.';
    }
    if (member.state == 'pending') {
      return 'Tu membresía está pendiente de aprobación. El QR se activará cuando el pago sea confirmado.';
    }
    return 'Tu membresía no está activa. Acércate a recepción para regularizar tu acceso.';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startTimer();
    });
  }

  void _startTimer() {
    _updateQrData();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      final now = DateTime.now();
      setState(() {
        _secondsLeft = 30 - (now.second % 30);
        if (_secondsLeft == 30) {
          _updateQrData();
        }
      });
    });
  }

  void _updateQrData() {
    if (!mounted) return;
    final state = GymStateProvider.of(context);
    final member = getLoggedMember(state);
    if (!_canGenerateQr(member)) {
      setState(() {
        _qrData = '';
        _qrError = _blockedReason(member);
      });
      return;
    }
    final userDni = state.currentUser?.dni ?? '11111111';
    final profile = state.currentUser?.memberProfile;
    final secret =
        profile?['qr_secret']?.toString() ??
        profile?['qrSecret']?.toString() ??
        AppConfig.demoTotpSecretForDni(userDni);
    if (secret == null || secret.isEmpty) {
      setState(() {
        _qrData = '';
        _qrError =
            'QR no disponible. Solicita al backend emitir un secreto de acceso.';
      });
      return;
    }
    final time = DateTime.now().millisecondsSinceEpoch;
    try {
      final token = OTP.generateTOTPCodeString(
        secret,
        time,
        interval: 30,
        length: 6,
        algorithm: Algorithm.SHA1,
      );
      setState(() {
        _qrData = '$userDni|$token';
        _qrError = null;
      });
    } catch (e) {
      AppLogger.debug('Error generating TOTP', e);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = GymStateProvider.of(context);
    final member = getLoggedMember(state);
    final bool isGranted = _canGenerateQr(member);
    final blockedReason = _blockedReason(member);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
          onPressed: widget.onBack,
        ),
        title: const Text(
          'CÓDIGO DE ACCESO QR',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!isGranted) ...[
                Container(
                  width: 230,
                  height: 230,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1111),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red, width: 1.5),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.block_rounded, color: Colors.red, size: 58),
                      SizedBox(height: 14),
                      Text(
                        'QR BLOQUEADO',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  blockedReason,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 18),
              ] else ...[
                // Real scannable QR code
                Container(
                  width: 230,
                  height: 230,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFE2DDD5),
                      width: 1.5,
                    ),
                  ),
                  child: _qrData.isEmpty
                      ? Center(
                          child: _qrError == null
                              ? const CircularProgressIndicator()
                              : Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(
                                    _qrError!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                        )
                      : QrImageView(
                          data: _qrData,
                          version: QrVersions.auto,
                          size: 200.0,
                          eyeStyle: QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: isGranted ? Colors.black : Colors.red[900]!,
                          ),
                          dataModuleStyle: QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: isGranted ? Colors.black : Colors.red[900]!,
                          ),
                        ),
                ),
              ],
              const SizedBox(height: 12),
              if (_qrData.isNotEmpty) ...[
                Text(
                  'Token: ${_qrData.split('|').last}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Status indicator
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isGranted
                      ? (member.state == 'grace'
                            ? const Color(0xFFFFB300).withValues(alpha: 0.15)
                            : const Color(0xFF00B85C).withValues(alpha: 0.15))
                      : Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isGranted
                        ? (member.state == 'grace'
                              ? const Color(0xFFFFB300)
                              : const Color(0xFF00B85C))
                        : Colors.red,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isGranted ? Icons.check_circle : Icons.cancel,
                      color: isGranted
                          ? (member.state == 'grace'
                                ? const Color(0xFFFFB300)
                                : const Color(0xFF00B85C))
                          : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isGranted
                          ? (member.state == 'grace'
                                ? 'ACCESO EN GRACIA'
                                : 'ACCESO CONCEDIDO')
                          : 'ACCESO DENEGADO',
                      style: TextStyle(
                        color: isGranted
                            ? (member.state == 'grace'
                                  ? const Color(0xFFFFB300)
                                  : const Color(0xFF00B85C))
                            : Colors.red,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              Text(
                'El código se actualiza automáticamente en $_secondsLeft segundos',
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Text(
                'Acerca esta pantalla al lector óptico en la entrada del establecimiento para registrar tu ingreso.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

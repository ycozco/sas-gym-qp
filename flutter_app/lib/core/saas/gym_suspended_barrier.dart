import 'package:flutter/material.dart';

/// Blocks app interaction with a premium "Suspended SaaS Instance" display.
/// Transversal: lo consume directamente `app.dart` cuando el tenant
/// queda inactivo, asi que vive en `core/saas/` y no en una feature.
class GymSuspendedBarrier extends StatelessWidget {
  const GymSuspendedBarrier({super.key, required this.onContactAdmin});

  final VoidCallback onContactAdmin;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.red, width: 2),
                ),
                child: const Icon(Icons.block_outlined, size: 48, color: Colors.red),
              ),
              const SizedBox(height: 28),
              const Text(
                'SERVICIO SUSPENDIDO',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Esta sede del gimnasio ha sido suspendida temporalmente por administración de la red SaaaS GYM debido a temas de facturación pendientes.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.headset_mic),
                label: const Text('Contactar Soporte SaaS', style: TextStyle(fontWeight: FontWeight.w800)),
                onPressed: onContactAdmin,
              ),
              const SizedBox(height: 12),
              Text(
                'Código de Error: CLIENT_SUSPENDED_BILLING',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

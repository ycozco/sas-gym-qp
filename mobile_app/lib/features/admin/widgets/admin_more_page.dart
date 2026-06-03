import 'package:flutter/material.dart';
import '../../../../models/gym_models.dart';
import '../../../../data/gym_state.dart';
import '../../../../widgets/app_shell.dart';
import 'admin_dashboard_page.dart';

class AdminMorePage extends StatelessWidget {
  const AdminMorePage({
    super.key,
    required this.palette,
    required this.state,
    required this.onNavigate,
  });

  final RolePalette palette;
  final GymState state;
  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const PageStorageKey<String>('admin-more'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        const SectionHeader(title: 'Módulos Administrativos', action: 'Más opciones'),
        _menuItem(
          icon: Icons.rate_review_rounded,
          title: 'Bandeja de Pagos Comprobante',
          subtitle: 'Aprobar o rechazar pagos manuales de socios',
          color: const Color(0xFF7A5AE0),
          onTap: () => onNavigate('payment_approvals'),
        ),
        _menuItem(
          icon: Icons.inventory_2_outlined,
          title: 'Inventario de Productos',
          subtitle: 'CRUD completo y eliminación definitiva',
          color: const Color(0xFFFF7A1A),
          onTap: () => onNavigate('product_inventory'),
        ),
        _menuItem(
          icon: Icons.fact_check_outlined,
          title: 'Bitácora de Auditoría',
          subtitle: 'Logs detallados con filtros por rol',
          color: const Color(0xFF0066FF),
          onTap: () => onNavigate('audit_logs'),
        ),
        _menuItem(
          icon: Icons.chat_bubble_outline_rounded,
          title: 'Buzón de Observaciones',
          subtitle: 'Reclamos y sugerencias de los socios',
          color: Colors.blueGrey,
          onTap: () => onNavigate('observations'),
        ),
        _menuItem(
          icon: Icons.campaign_rounded,
          title: 'Publicar Anuncio',
          subtitle: 'Crear avisos generales para el inicio del socio',
          color: const Color(0xFF00B85C),
          onTap: () => onNavigate('announcement_form'),
        ),
        _menuItem(
          icon: Icons.tune_rounded,
          title: 'Ajustes del Gimnasio',
          subtitle: 'Días de gracia, tiempos de alerta y reglas de negocio',
          color: Colors.brown,
          onTap: () => onNavigate('settings'),
        ),
      ],
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: adminCardDecoration(),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 11.5, color: Colors.white60, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white38),
            ],
          ),
        ),
      ),
    );
  }
}

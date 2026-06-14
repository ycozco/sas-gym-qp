import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../../data/gym_state.dart';
import '../../../models/gym_models.dart';
import '../../../theme/app_theme_tokens.dart';
import '../../../widgets/app_shell.dart';
import 'member_shared_utils.dart';

class MemberHomePage extends StatelessWidget {
  const MemberHomePage({super.key, required this.palette, required this.onGo});

  final RolePalette palette;
  final Function(String, [Map<String, dynamic>?]) onGo;

  @override
  Widget build(BuildContext context) {
    final state = GymStateProvider.of(context);
    final mateo = getLoggedMember(state);

    final isExpired = mateo.state == 'expired';
    final isGrace = mateo.state == 'grace';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 36),
      children: [
        RoleHeroHeader(
          palette: palette,
          title: 'Panel del Socio',
          subtitle: 'Accede rápido a tus clases, membresía y QR de ingreso.',
        ),
        const SizedBox(height: 16),
        HeroCard(palette: palette, member: mateo, onGo: onGo),
        const SizedBox(height: 16),

        // Alert banners if expired or grace
        if (isExpired)
          _buildAlertBanner(
            context,
            'MEMBRESÍA VENCIDA',
            'Tu pase ha expirado. Renueva en línea para reactivar tu código QR de acceso.',
            Colors.redAccent,
            Icons.error_outline,
            'Pagar ahora',
            () => onGo('pay'),
          ),
        if (isGrace)
          _buildAlertBanner(
            context,
            'DÍA DE GRACIA ACTIVO',
            'Tu membresía venció ayer. Tienes acceso permitido solo por hoy. Por favor regulariza tu plan.',
            const Color(0xFFFFB300),
            Icons.warning_amber_rounded,
            'Renovar plan',
            () => onGo('pay'),
          ),

        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: MetricTile(
                icon: Icons.calendar_month,
                label: 'Esta semana',
                value: '${mateo.sessions} asists.',
                note: 'Racha activa',
                accent: palette.accent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricTile(
                icon: Icons.workspace_premium,
                label: 'Estado',
                value: mateo.state == 'active'
                    ? 'Activo'
                    : mateo.state == 'grace'
                    ? 'Gracia'
                    : 'Vencido',
                note: mateo.state == 'active'
                    ? 'Vence el 4 de jun'
                    : 'Sin días restantes',
                accent: mateo.state == 'active'
                    ? const Color(0xFF00B85C)
                    : mateo.state == 'grace'
                    ? const Color(0xFFFFB300)
                    : Colors.redAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),

        // Action shortcuts
        SectionHeader(title: 'Acciones Rápidas'),
        Row(
          children: [
            Expanded(
              child: ActionTile(
                icon: Icons.groups_rounded,
                label: 'Clases Grupales',
                note: 'Reserva tu cupo',
                accent: palette.accent,
                onTap: () => onGo('classes'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ActionTile(
                icon: Icons.restaurant_rounded,
                label: 'Mi Dieta',
                note: 'Ver plan nutricional',
                accent: palette.accent,
                onTap: () => onGo('diet'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ActionTile(
                icon: Icons.rate_review_rounded,
                label: 'Sugerencias',
                note: 'Enviar sugerencia',
                accent: palette.accent,
                onTap: () => onGo('observation'),
              ),
            ),
            const SizedBox(width: 12),
            const Spacer(),
          ],
        ),

        const SizedBox(height: 22),
        SectionHeader(title: 'Avisos del Gimnasio'),
        Builder(
          builder: (context) {
            final colors = context.sasColors;
            final box = Hive.isBoxOpen('gym_cache')
                ? Hive.box('gym_cache')
                : null;
            final List<dynamic> dismissedIds = box != null
                ? box.get('dismissed_banner_ids', defaultValue: [])
                : [];
            final activeAnnouncements = state.announcements.where((item) {
              final key = item.id.isNotEmpty ? item.id : item.title;
              return !dismissedIds.contains(key);
            }).toList();

            if (activeAnnouncements.isEmpty) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: _cardDecoration(context),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        color: Color(0xFF00B85C),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No hay avisos pendientes hoy.',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: activeAnnouncements.map((item) {
                Color severityColor;
                String label;

                final sev = item.severidad.toUpperCase();
                if (sev == 'WARNING' || item.tag == 'AVISO') {
                  severityColor = const Color(0xFFFFB300);
                  label = 'AVISO';
                } else if (sev == 'DANGER' ||
                    sev == 'ALERT' ||
                    item.tag == 'ALERTA') {
                  severityColor = Colors.redAccent;
                  label = 'ALERTA';
                } else {
                  severityColor = const Color(0xFF7A5AE0); // Violeta electrico
                  label = 'INFO';
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: _cardDecoration(context),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 4,
                          height: 56,
                          decoration: BoxDecoration(
                            color: severityColor,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  StatusPill(
                                    label: label,
                                    color: severityColor,
                                    solid: true,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    item.time,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: colors.textMuted,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item.title,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                item.detail,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: colors.textSecondary,
                                  height: 1.4,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: colors.textMuted,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            final key = item.id.isNotEmpty
                                ? item.id
                                : item.title;
                            state.dismissAnnouncement(key);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAlertBanner(
    BuildContext context,
    String title,
    String text,
    Color color,
    IconData icon,
    String btnText,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12.5,
              height: 1.3,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            style: roleFilledPillButtonStyle(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumHeight: 36,
            ),
            onPressed: onTap,
            child: Text(
              btnText,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration(BuildContext context) {
    return themedCardDecoration(context, radius: 12);
  }
}

class HeroCard extends StatelessWidget {
  const HeroCard({
    super.key,
    required this.palette,
    required this.member,
    required this.onGo,
  });

  final RolePalette palette;
  final MemberRecord member;
  final Function(String, [Map<String, dynamic>?]) onGo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: palette.gradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.accent.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusPill(
                label: 'SOCIO SAS',
                color: palette.accent,
                solid: true,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.black87,
                ),
                onPressed: () => onGo('notifications'),
              ),
              const SizedBox(width: 4),
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white.withOpacity(0.9),
                child: const Text(
                  'MS',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Hola, ${member.name.split(' ')[0]} 👋',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tienes tu rutina lista para hoy. Mantén el ritmo.',
            style: TextStyle(
              fontSize: 13.5,
              color: Color(0xFF5E5E5E),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

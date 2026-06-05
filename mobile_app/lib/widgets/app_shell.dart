import 'package:flutter/material.dart';

import '../data/gym_seed.dart';
import '../models/gym_models.dart';
import '../theme/app_theme_tokens.dart';

Color readableOn(Color background) {
  return background.computeLuminance() > 0.45
      ? const Color(0xFF0B0B0B)
      : Colors.white;
}

BoxDecoration themedCardDecoration(
  BuildContext context, {
  double radius = 16,
  Color? color,
  Color? borderColor,
}) {
  final colors = context.sasColors;
  return BoxDecoration(
    color: color ?? colors.surface,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: borderColor ?? colors.border, width: 1.0),
  );
}

class RoleSurface extends StatelessWidget {
  const RoleSurface({super.key, required this.palette, required this.child});

  final RolePalette palette;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = context.sasColors;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [colors.background, colors.surface]
              : [palette.surfaceTint, colors.background],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: palette.gradient,
                boxShadow: [
                  BoxShadow(
                    color: palette.accent.withValues(
                      alpha: isDark ? 0.08 : 0.18,
                    ),
                    blurRadius: 60,
                    spreadRadius: 12,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: -90,
            bottom: -120,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.accent.withValues(alpha: isDark ? 0.02 : 0.06),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class RoleTabs extends StatelessWidget {
  const RoleTabs({super.key, required this.selected, required this.onChanged});

  final GymRole selected;
  final ValueChanged<GymRole> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: GymRole.values
              .map(
                (role) => _RoleTab(
                  role: role,
                  selected: role == selected,
                  onTap: () => onChanged(role),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _RoleTab extends StatelessWidget {
  const _RoleTab({
    required this.role,
    required this.selected,
    required this.onTap,
  });

  final GymRole role;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = rolePalettes[role]!;
    final colors = context.sasColors;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: selected ? palette.accent : colors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: selected ? palette.accent : colors.border),
        boxShadow: [
          if (selected)
            BoxShadow(
              color: palette.accent.withValues(alpha: 0.16),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                role.label,
                style: TextStyle(
                  color: selected ? palette.accentInk : colors.textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                role.subtitle,
                style: TextStyle(
                  color: selected
                      ? palette.accentInk.withValues(alpha: 0.85)
                      : colors.textSecondary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onTap,
  });

  final String title;
  final String? action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.sasColors;
    final actionColor = colors.textSecondary;
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: -0.2,
    );
    final actionStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: actionColor,
      fontWeight: FontWeight.w700,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: titleStyle?.copyWith(color: colors.textPrimary),
            ),
          ),
          if (action != null)
            GestureDetector(
              onTap: onTap,
              child: Text(action!, style: actionStyle),
            ),
        ],
      ),
    );
  }
}

class RoleHeroHeader extends StatelessWidget {
  const RoleHeroHeader({
    super.key,
    required this.palette,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final RolePalette palette;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.sasColors;
    final surfaceColor = colors.surface;
    final borderColor = colors.border;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: palette.accent,
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: palette.accent.withValues(alpha: 0.22),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );
  }
}

ButtonStyle roleFilledPillButtonStyle({
  required Color backgroundColor,
  required Color foregroundColor,
  EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
    horizontal: 18,
    vertical: 14,
  ),
  double minimumHeight = 48,
  BorderSide? side,
}) {
  return ElevatedButton.styleFrom(
    backgroundColor: backgroundColor,
    foregroundColor: foregroundColor,
    elevation: 0,
    padding: padding,
    minimumSize: Size(0, minimumHeight),
    shape: const StadiumBorder(),
    side: side,
  );
}

ButtonStyle roleOutlinedPillButtonStyle({
  required Color foregroundColor,
  Color? backgroundColor,
  EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
    horizontal: 18,
    vertical: 14,
  ),
  double minimumHeight = 48,
  BorderSide? side,
}) {
  return OutlinedButton.styleFrom(
    foregroundColor: foregroundColor,
    backgroundColor: backgroundColor,
    padding: padding,
    minimumSize: Size(0, minimumHeight),
    shape: const StadiumBorder(),
    side:
        side ??
        BorderSide(color: foregroundColor.withValues(alpha: 0.24), width: 1.4),
  );
}

ButtonStyle roleTextPillButtonStyle({
  required Color foregroundColor,
  EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 12,
  ),
  BorderSide? side,
}) {
  return TextButton.styleFrom(
    foregroundColor: foregroundColor,
    padding: padding,
    shape: const StadiumBorder(),
    side:
        side ??
        BorderSide(color: foregroundColor.withValues(alpha: 0.24), width: 1.2),
  );
}

class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.note,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final String note;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = context.sasColors;
    final cardColor = colors.surface;
    final borderColor = colors.border;
    final labelColor = colors.textSecondary;
    final valueColor = colors.textPrimary;
    final noteColor = colors.textMuted;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.15)
                : const Color(0x11000000),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: accent),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: labelColor),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            note,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: noteColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class BounceInteractive extends StatefulWidget {
  const BounceInteractive({super.key, required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  State<BounceInteractive> createState() => _BounceInteractiveState();
}

class _BounceInteractiveState extends State<BounceInteractive>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      _controller.reverse();
      widget.onTap!();
    }
  }

  void _onTapCancel() {
    if (widget.onTap != null) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
  }
}

class ActionTile extends StatelessWidget {
  const ActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.note,
    required this.accent,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String note;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.sasColors;
    final cardColor = colors.surface;
    final borderColor = colors.border;
    final labelColor = colors.textPrimary;
    final noteColor = colors.textSecondary;

    return BounceInteractive(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 18, color: accent),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: labelColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              note,
              style: TextStyle(
                fontSize: 10.5,
                color: noteColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    this.solid = false,
  });

  final String label;
  final Color color;
  final bool solid;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: solid ? color : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: solid ? readableOn(color) : color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class LogTile extends StatelessWidget {
  const LogTile({
    super.key,
    required this.icon,
    required this.title,
    required this.detail,
    required this.time,
    required this.color,
    this.locked = false,
  });

  final IconData icon;
  final String title;
  final String detail;
  final String time;
  final Color color;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final colors = context.sasColors;
    final cardColor = colors.surface;
    final borderColor = colors.border;
    final titleColor = colors.textPrimary;
    final detailColor = colors.textSecondary;
    final timeColor = colors.textMuted;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                        ),
                      ),
                    ),
                    if (locked)
                      const StatusPill(
                        label: 'SOLO LECTURA',
                        color: Color(0xFF5C5C5C),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  detail,
                  style: TextStyle(
                    fontSize: 11.8,
                    color: detailColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            time,
            style: TextStyle(
              fontSize: 11.5,
              color: timeColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class RoleNavItem {
  const RoleNavItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class RoleNavBar extends StatelessWidget {
  const RoleNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.accent,
    required this.accentInk,
    required this.onChanged,
  });

  final List<RoleNavItem> items;
  final int currentIndex;
  final Color accent;
  final Color accentInk;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.sasColors;
    final navBgColor = colors.surface;
    final labelColor = colors.textMuted;
    // Selected label uses the role accent; selected icon sits on the accent indicator.
    final selectedLabelColor = accent;
    final selectedIconColor = accentInk; // icon sits on top of accent indicator

    return NavigationBarTheme(
      data: NavigationBarThemeData(
        indicatorColor: accent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? selectedLabelColor : labelColor,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? selectedIconColor : labelColor,
            size: 20,
          );
        }),
      ),
      child: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onChanged,
        backgroundColor: navBgColor,
        height: 68,
        destinations: items
            .map(
              (item) => NavigationDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.icon),
                label: item.label,
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../models/gym_models.dart';
import '../../../../data/gym_state.dart';
import '../../../../theme/app_theme_tokens.dart';
import '../../../../theme/ui_preferences_controller.dart';
import '../../../../widgets/app_shell.dart';
import 'admin_dashboard_page.dart';

class AdminObservationsPage extends StatelessWidget {
  const AdminObservationsPage({
    super.key,
    required this.palette,
    required this.state,
    required this.onBack,
  });

  final RolePalette palette;
  final GymState state;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colors = context.sasColors;
    final observations = state.observations;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
          onPressed: onBack,
        ),
        title: const Text(
          'Observaciones y Quejas',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: observations.isEmpty
          ? Center(
              child: Text(
                'No hay observaciones registradas.',
                style: TextStyle(color: colors.textMuted),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              itemCount: observations.length,
              itemBuilder: (context, index) {
                final obs = observations[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: adminCardDecoration(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Socio: ${obs.memberName}',
                            style: TextStyle(
                              color: palette.accent,
                              fontWeight: FontWeight.bold,
                              fontSize: 12.5,
                            ),
                          ),
                          Text(
                            obs.date,
                            style: TextStyle(
                              color: colors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        obs.description,
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.4,
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.rate_review_outlined,
                            color: colors.textMuted,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Registrado por: ${obs.memberName}',
                            style: TextStyle(
                              color: colors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class AdminAnnouncementFormPage extends StatefulWidget {
  const AdminAnnouncementFormPage({
    super.key,
    required this.palette,
    required this.state,
    required this.onBack,
  });

  final RolePalette palette;
  final GymState state;
  final VoidCallback onBack;

  @override
  State<AdminAnnouncementFormPage> createState() =>
      _AdminAnnouncementFormPageState();
}

class _AdminAnnouncementFormPageState extends State<AdminAnnouncementFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sasColors;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
          onPressed: widget.onBack,
        ),
        title: const Text(
          'Nuevo Anuncio Global',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: adminCardDecoration(context),
              child: Column(
                children: [
                  TextFormField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Título del Anuncio *',
                    ),
                    validator: (val) =>
                        val == null || val.trim().isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Descripción / Contenido *',
                    ),
                    validator: (val) =>
                        val == null || val.trim().isEmpty ? 'Requerido' : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: roleFilledPillButtonStyle(
                backgroundColor: widget.palette.accent,
                foregroundColor: widget.palette.accentInk,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  widget.state.addAnnouncement(
                    'AVISO',
                    _titleCtrl.text.trim(),
                    _descCtrl.text.trim(),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Anuncio global publicado en tiempo real.'),
                      backgroundColor: Color(0xFF00B85C),
                    ),
                  );
                  widget.onBack();
                }
              },
              child: const Text(
                'Publicar Anuncio',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({
    super.key,
    required this.palette,
    required this.state,
    required this.onBack,
  });

  final RolePalette palette;
  final GymState state;
  final VoidCallback onBack;

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  late int _graceDays;
  late int _alertDays;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _logoCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _scheduleCtrl;
  late final TextEditingController _descriptionCtrl;

  @override
  void initState() {
    super.initState();
    _graceDays = widget.state.graceDays;
    _alertDays = widget.state.alertDays;
    final tenant = widget.state.tenantSettings;
    _nameCtrl = TextEditingController(text: tenant?.name ?? '');
    _logoCtrl = TextEditingController(text: tenant?.logoUrl ?? '');
    _addressCtrl = TextEditingController(text: tenant?.address ?? '');
    _phoneCtrl = TextEditingController(text: tenant?.phone ?? '');
    _scheduleCtrl = TextEditingController(text: tenant?.schedule ?? '');
    _descriptionCtrl = TextEditingController(text: tenant?.description ?? '');
    widget.state.loadTenantSettings();
    widget.state.loadMembershipPlans(includeInactive: true);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _logoCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _scheduleCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _showPlanDialog(
    BuildContext context, {
    MembershipPlan? plan,
  }) async {
    final nameCtrl = TextEditingController(text: plan?.name ?? '');
    final descCtrl = TextEditingController(text: plan?.description ?? '');
    final daysCtrl = TextEditingController(text: '${plan?.durationDays ?? 30}');
    final priceCtrl = TextEditingController(text: '${plan?.price ?? 120}');
    final colorCtrl = TextEditingController(text: plan?.color ?? '#2F6BFF');
    final orderCtrl = TextEditingController(text: '${plan?.order ?? 0}');
    var active = plan?.active ?? true;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(plan == null ? 'Nuevo plan' : 'Editar plan'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Descripcion',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: daysCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Duracion en dias',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: priceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(labelText: 'Precio'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: colorCtrl,
                      decoration: const InputDecoration(labelText: 'Color HEX'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: orderCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Orden'),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: active,
                      title: const Text('Activo'),
                      onChanged: (value) =>
                          setDialogState(() => active = value),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final days = int.tryParse(daysCtrl.text.trim());
                    final price = double.tryParse(priceCtrl.text.trim());
                    if (nameCtrl.text.trim().isEmpty ||
                        days == null ||
                        price == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Completa nombre, duracion y precio.'),
                        ),
                      );
                      return;
                    }
                    await widget.state.saveMembershipPlan(
                      id: plan?.id,
                      name: nameCtrl.text.trim(),
                      description: descCtrl.text.trim(),
                      durationDays: days,
                      price: price,
                      color: colorCtrl.text.trim(),
                      order: int.tryParse(orderCtrl.text.trim()) ?? 0,
                      active: active,
                    );
                    if (context.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    nameCtrl.dispose();
    descCtrl.dispose();
    daysCtrl.dispose();
    priceCtrl.dispose();
    colorCtrl.dispose();
    orderCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sasColors;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
          onPressed: widget.onBack,
        ),
        title: const Text(
          'Configuración del Sistema',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: adminCardDecoration(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Apariencia',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Define si la app usa el tema del sistema, claro u oscuro.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: colors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: Icon(Icons.brightness_auto_rounded),
                      label: Text('Sistema'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode_rounded),
                      label: Text('Claro'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode_rounded),
                      label: Text('Oscuro'),
                    ),
                  ],
                  selected: {widget.state.themeMode},
                  onSelectionChanged: (selection) {
                    widget.state.updateThemeMode(selection.first);
                    setState(() {});
                  },
                ),
                if (widget.state.themePreferenceSyncPending) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Pendiente de sincronizar con tu cuenta.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: colors.warning,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  'Actual: ${UiPreferencesController.themeModeToWire(widget.state.themeMode)}',
                  style: TextStyle(fontSize: 11, color: colors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: adminCardDecoration(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Datos del gimnasio',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre comercial',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _logoCtrl,
                  decoration: const InputDecoration(labelText: 'Logo URL'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _addressCtrl,
                  decoration: const InputDecoration(labelText: 'Direccion'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Telefono'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _scheduleCtrl,
                  decoration: const InputDecoration(labelText: 'Horario'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _descriptionCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Descripcion'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: adminCardDecoration(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Planes de membresia',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: colors.textPrimary,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Nuevo plan',
                      onPressed: () => _showPlanDialog(context),
                      icon: Icon(
                        Icons.add_circle_outline_rounded,
                        color: widget.palette.accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (widget.state.membershipPlans.isEmpty)
                  Text(
                    'No hay planes cargados.',
                    style: TextStyle(color: colors.textMuted, fontSize: 12.5),
                  )
                else
                  ...widget.state.membershipPlans.map((plan) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        plan.active
                            ? Icons.card_membership_rounded
                            : Icons.block_rounded,
                        color: plan.active
                            ? widget.palette.accent
                            : colors.textMuted,
                      ),
                      title: Text(
                        plan.name,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      subtitle: Text(
                        '${plan.durationDays} dias - S/ ${plan.price}${plan.active ? '' : ' - inactivo'}',
                        style: TextStyle(color: colors.textSecondary),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Editar',
                            onPressed: () =>
                                _showPlanDialog(context, plan: plan),
                            icon: Icon(
                              Icons.edit_outlined,
                              color: colors.textSecondary,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Desactivar',
                            onPressed: plan.active
                                ? () => widget.state.deactivateMembershipPlan(
                                    plan.id,
                                  )
                                : null,
                            icon: Icon(
                              Icons.visibility_off_outlined,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                const SizedBox(height: 8),
                Text(
                  'Las ediciones aplican solo a nuevas ventas. Las membresias en curso conservan su snapshot historico.',
                  style: TextStyle(color: colors.textMuted, fontSize: 11.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: adminCardDecoration(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Reglas de Control de Membresía',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Afecta directamente el veredicto del escáner y notificaciones de los socios.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.grey,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),

                // Grace days slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Días de Gracia del Gimnasio:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '$_graceDays días',
                      style: TextStyle(
                        color: widget.palette.accent,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Periodo extra posterior al vencimiento donde se permite el check-in (Veredicto Amarillo).',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                Slider(
                  value: _graceDays.toDouble(),
                  min: 0,
                  max: 5,
                  divisions: 5,
                  label: '$_graceDays',
                  onChanged: (val) => setState(() => _graceDays = val.round()),
                ),

                const SizedBox(height: 18),

                // Warning days slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Alerta de Vencimiento Próximo:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '$_alertDays días',
                      style: TextStyle(
                        color: widget.palette.accent,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Días antes del vencimiento para notificar al socio en su dashboard de inicio.',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                Slider(
                  value: _alertDays.toDouble(),
                  min: 1,
                  max: 15,
                  divisions: 14,
                  label: '$_alertDays',
                  onChanged: (val) => setState(() => _alertDays = val.round()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: roleFilledPillButtonStyle(
              backgroundColor: widget.palette.accent,
              foregroundColor: widget.palette.accentInk,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              await widget.state.saveTenantSettings(
                name: _nameCtrl.text.trim(),
                logoUrl: _logoCtrl.text.trim(),
                address: _addressCtrl.text.trim(),
                phone: _phoneCtrl.text.trim(),
                schedule: _scheduleCtrl.text.trim(),
                description: _descriptionCtrl.text.trim(),
                graceDays: _graceDays,
                alertDays: _alertDays,
              );
              if (!mounted) return;
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Ajustes del gimnasio guardados.'),
                  backgroundColor: Color(0xFF00B85C),
                ),
              );
              widget.onBack();
            },
            child: const Text(
              'Guardar Ajustes',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

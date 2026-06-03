import 'package:flutter/material.dart';
import '../../../../models/gym_models.dart';
import '../../../../data/gym_state.dart';
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
    final observations = state.observations;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: onBack,
        ),
        title: const Text('Observaciones y Quejas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: observations.isEmpty
          ? const Center(
              child: Text('No hay observaciones registradas.', style: TextStyle(color: Colors.white38)),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              itemCount: observations.length,
              itemBuilder: (context, index) {
                final obs = observations[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: adminCardDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Socio: ${obs.memberName}', style: TextStyle(color: palette.accent, fontWeight: FontWeight.bold, fontSize: 12.5)),
                          Text(obs.date, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        obs.description,
                        style: const TextStyle(fontSize: 13.5, height: 1.4, color: Colors.white70),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.rate_review_outlined, color: Colors.white30, size: 16),
                          const SizedBox(width: 6),
                          Text('Registrado por: ${obs.memberName}', style: const TextStyle(color: Colors.white30, fontSize: 11)),
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
  State<AdminAnnouncementFormPage> createState() => _AdminAnnouncementFormPageState();
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: widget.onBack,
        ),
        title: const Text('Nuevo Anuncio Global', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: adminCardDecoration(),
              child: Column(
                children: [
                  TextFormField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(labelText: 'Título del Anuncio *'),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Descripción / Contenido *'),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Requerido' : null,
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
                    const SnackBar(content: Text('Anuncio global publicado en tiempo real.'), backgroundColor: Color(0xFF00B85C)),
                  );
                  widget.onBack();
                }
              },
              child: const Text('Publicar Anuncio', style: TextStyle(fontWeight: FontWeight.bold)),
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

  @override
  void initState() {
    super.initState();
    _graceDays = widget.state.graceDays;
    _alertDays = widget.state.alertDays;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: widget.onBack,
        ),
        title: const Text('Configuración del Sistema', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: adminCardDecoration(),
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
                  style: TextStyle(fontSize: 12.5, color: Colors.grey, height: 1.4),
                ),
                const SizedBox(height: 20),

                // Grace days slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Días de Gracia del Gimnasio:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('$_graceDays días', style: TextStyle(color: widget.palette.accent, fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 4),
                const Text('Periodo extra posterior al vencimiento donde se permite el check-in (Veredicto Amarillo).', style: TextStyle(fontSize: 11, color: Colors.grey)),
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
                    const Text('Alerta de Vencimiento Próximo:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('$_alertDays días', style: TextStyle(color: widget.palette.accent, fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 4),
                const Text('Días antes del vencimiento para notificar al socio en su dashboard de inicio.', style: TextStyle(fontSize: 11, color: Colors.grey)),
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
            onPressed: () {
              widget.state.updateGymSettings(_graceDays, _alertDays);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ajustes del gimnasio guardados reactivamente.'), backgroundColor: Color(0xFF00B85C)),
              );
              widget.onBack();
            },
            child: const Text('Guardar Ajustes', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}

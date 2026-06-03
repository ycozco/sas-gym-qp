import 'package:flutter/material.dart';
import '../../../../models/gym_models.dart';
import '../../../../data/gym_state.dart';
import '../../../../widgets/app_shell.dart';
import 'admin_dashboard_page.dart';

class AdminMemberFormPage extends StatefulWidget {
  const AdminMemberFormPage({
    super.key,
    required this.palette,
    required this.state,
    this.member,
    this.prefilledDni,
    required this.onBack,
  });

  final RolePalette palette;
  final GymState state;
  final MemberRecord? member;
  final String? prefilledDni;
  final VoidCallback onBack;

  @override
  State<AdminMemberFormPage> createState() => _AdminMemberFormPageState();
}

class _AdminMemberFormPageState extends State<AdminMemberFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _dniCtrl;
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _goalCtrl;
  late TextEditingController _trainerCtrl;
  late String _status;

  @override
  void initState() {
    super.initState();
    _dniCtrl = TextEditingController(text: widget.member?.dni ?? widget.prefilledDni ?? '');
    _nameCtrl = TextEditingController(text: widget.member?.name ?? '');
    _phoneCtrl = TextEditingController(text: widget.member?.phone ?? '');
    _emailCtrl = TextEditingController(text: widget.member?.email ?? '');
    _goalCtrl = TextEditingController(text: widget.member?.goal ?? '');
    _trainerCtrl = TextEditingController(text: widget.member?.assignedTrainer ?? '');
    _status = widget.member?.state ?? 'expired';
  }

  @override
  void dispose() {
    _dniCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _goalCtrl.dispose();
    _trainerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.member != null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: widget.onBack,
        ),
        title: Text(
          isEdit ? 'Editar Socio' : 'Nuevo Socio',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
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
                    controller: _dniCtrl,
                    keyboardType: TextInputType.number,
                    enabled: !isEdit, // DNI cannot be changed once created
                    decoration: const InputDecoration(labelText: 'DNI / Documento *'),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre Completo *'),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Teléfono / Celular'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _goalCtrl,
                    decoration: const InputDecoration(labelText: 'Objetivo (ej: Bajar peso / Plan)'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _trainerCtrl,
                    decoration: const InputDecoration(labelText: 'Entrenador Asignado'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _status,
                    decoration: const InputDecoration(labelText: 'Estado Inicial'),
                    items: const [
                      DropdownMenuItem(value: 'active', child: Text('Activo')),
                      DropdownMenuItem(value: 'expired', child: Text('Vencido')),
                      DropdownMenuItem(value: 'grace', child: Text('Periodo de Gracia')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _status = val);
                      }
                    },
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
                  if (isEdit) {
                    final updated = MemberRecord(
                      dni: widget.member!.dni,
                      name: _nameCtrl.text.trim(),
                      phone: _phoneCtrl.text.trim(),
                      email: _emailCtrl.text.trim(),
                      startDate: widget.member!.startDate,
                      goal: _goalCtrl.text.trim(),
                      sessions: widget.member!.sessions,
                      lastSeen: widget.member!.lastSeen,
                      state: _status,
                      assignedTrainer: _trainerCtrl.text.trim(),
                      paymentHistory: widget.member!.paymentHistory,
                      physicalMeasurements: widget.member!.physicalMeasurements,
                      progressImages: widget.member!.progressImages,
                    );
                    widget.state.updateMember(widget.member!.dni, updated);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Socio actualizado exitosamente.'), backgroundColor: Color(0xFF00B85C)),
                    );
                  } else {
                    final newM = MemberRecord(
                      dni: _dniCtrl.text.trim(),
                      name: _nameCtrl.text.trim(),
                      phone: _phoneCtrl.text.trim(),
                      email: _emailCtrl.text.trim(),
                      startDate: 'Hoy',
                      goal: _goalCtrl.text.trim(),
                      sessions: 0,
                      lastSeen: 'Nunca',
                      state: _status,
                      assignedTrainer: _trainerCtrl.text.trim(),
                      paymentHistory: [],
                      physicalMeasurements: {},
                      progressImages: [],
                    );
                    widget.state.addMember(newM);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Nuevo socio registrado con éxito.'), backgroundColor: Color(0xFF00B85C)),
                    );
                  }
                  widget.onBack();
                }
              },
              child: Text(
                isEdit ? 'Guardar Cambios' : 'Registrar Socio',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

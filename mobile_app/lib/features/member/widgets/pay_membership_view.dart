import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;
import '../../../core/config/app_config.dart';
import '../../../data/gym_state.dart';
import '../../../widgets/app_shell.dart';
import '../../../models/gym_models.dart';

class PayMembershipView extends StatefulWidget {
  const PayMembershipView({
    super.key,
    required this.palette,
    required this.onBack,
  });

  final RolePalette palette;
  final VoidCallback onBack;

  @override
  State<PayMembershipView> createState() => _PayMembershipViewState();
}

class _PayMembershipViewState extends State<PayMembershipView> {
  String? _selectedPlan;
  String _selectedMethod = 'Yape';
  bool _uploaded = false;
  String _uploadedFileName = '';
  bool _submitting = false;
  List<int>? _selectedFileBytes;
  bool _compressing = false;

  List<MembershipPlan> _plans(GymState state) {
    final activePlans = state.membershipPlans.where((p) => p.active).toList();
    if (activePlans.isNotEmpty) return activePlans;
    return const [
      MembershipPlan(id: 'mensual-plata', name: 'Mensual Plata', durationDays: 30, price: 120),
      MembershipPlan(id: 'mensual-oro', name: 'Mensual Oro', durationDays: 30, price: 150),
      MembershipPlan(id: 'trimestral-platinium', name: 'Trimestral Platinium', durationDays: 90, price: 400),
    ];
  }

  Future<void> _pickAndCompressFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.size > AppConfig.maxLocalImageBytes) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El archivo supera el tamano maximo permitido.')),
        );
        return;
      }

      final rawBytes = file.bytes;
      if (rawBytes == null) return;

      setState(() {
        _compressing = true;
        _uploadedFileName = file.name;
        _uploaded = false;
      });

      await Future.delayed(const Duration(milliseconds: 100));
      final compressedBytes = await _compressImage(rawBytes);

      setState(() {
        _selectedFileBytes = compressedBytes;
        _uploaded = true;
        _compressing = false;
      });
    } catch (e) {
      AppLogger.debug('Error picking/compressing file', e);
      setState(() {
        _compressing = false;
      });
    }
  }

  Future<List<int>> _compressImage(List<int> bytes) async {
    try {
      final img.Image? decoded = img.decodeImage(Uint8List.fromList(bytes));
      if (decoded == null) return bytes;

      img.Image resized = decoded;
      if (decoded.width > 1080 || decoded.height > 1080) {
        resized = img.copyResize(
          decoded,
          width: decoded.width > decoded.height ? 1080 : null,
          height: decoded.height >= decoded.width ? 1080 : null,
        );
      }

      final compressed = img.encodeJpg(resized, quality: 80);
      return compressed;
    } catch (e) {
      AppLogger.debug('Compression error', e);
      return bytes;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = GymStateProvider.of(context);
    final plans = _plans(state);
    _selectedPlan ??= plans.first.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('RENOVAR MEMBRESÍA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: widget.onBack,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Select plan
          const Text('1. Selecciona tu plan', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 10),
          ...List.generate(plans.length, (index) {
            final plan = plans[index];
            final isSelected = _selectedPlan == plan.id;

            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected ? widget.palette.accent : const Color(0xFFE8E4D9),
                  width: isSelected ? 2 : 1,
                ),
              ),
              color: Colors.white,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  setState(() {
                    _selectedPlan = plan.id;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.black : Colors.grey,
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? Center(
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.black,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${plan.name} (S/ ${plan.price})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(height: 4),
                            Text(plan.description ?? '${plan.durationDays} dias de acceso.', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 24),

          // Select payment method
          const Text('2. Método de Pago', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _selectedMethod,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
            items: const [
              DropdownMenuItem(value: 'Yape', child: Text('Yape (QR)')),
              DropdownMenuItem(value: 'Plin', child: Text('Plin (QR)')),
              DropdownMenuItem(value: 'Tarjeta', child: Text('Tarjeta de Crédito / Débito (Culqi)')),
              DropdownMenuItem(value: 'Manual', child: Text('Depósito Bancario (Acreditación Manual)')),
            ],
            onChanged: (val) {
              setState(() {
                _selectedMethod = val ?? 'Yape';
              });
            },
          ),
          const SizedBox(height: 24),

          // Payment details depending on method
          if (_selectedMethod == 'Yape' || _selectedMethod == 'Plin') ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2DDD5)),
              ),
              child: Column(
                children: [
                  const Text('Escanea este código QR desde tu app:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 14),
                  Container(
                    width: 140,
                    height: 140,
                    color: Colors.grey[200],
                    child: const Icon(Icons.qr_code, size: 100),
                  ),
                  const SizedBox(height: 10),
                  const Text('Número: 987-654-321', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Upload verification section (always needed for simulated flows to show approval)
          const Text('3. Comprobante de Pago', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _compressing ? null : _pickAndCompressFile,
            child: Container(
              height: 110,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _uploaded ? const Color(0xFF00B85C) : const Color(0xFFFF7A1A),
                  style: BorderStyle.solid,
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: _compressing
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF7A1A))),
                        const SizedBox(height: 8),
                        Text('Comprimiendo imagen...', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      ],
                    )
                  : _uploaded
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle, color: Color(0xFF00B85C), size: 32),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(_uploadedFileName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                            Text('Comprimido con éxito a ${(_selectedFileBytes?.length ?? 0) ~/ 1024} KB', style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                          ],
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_upload_outlined, color: Color(0xFFFF7A1A), size: 36),
                            SizedBox(height: 8),
                            Text('Cargar Imagen de Comprobante', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            Text('Formatos: JPG, PNG (Auto-comprimir < 2MB)', style: TextStyle(color: Colors.grey, fontSize: 11)),
                          ],
                        ),
            ),
          ),
          const SizedBox(height: 36),

          ElevatedButton(
            style: roleFilledPillButtonStyle(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              minimumHeight: 56,
            ),
            onPressed: (_uploaded && _selectedPlan != null && !_submitting)
                ? () async {
                    final messenger = ScaffoldMessenger.of(context);
                    setState(() => _submitting = true);
                    
                    final selected = plans.firstWhere(
                      (p) => p.id == _selectedPlan,
                      orElse: () => plans.first,
                    );
                    final planName = selected.name;
                    final price = selected.price;

                    if (state.isBackendMode && _selectedFileBytes != null) {
                      final success = await state.uploadReceiptBackend(
                        planName: planName,
                        price: price,
                        method: _selectedMethod,
                        fileBytes: _selectedFileBytes!,
                        fileName: _uploadedFileName,
                      );
                      
                      setState(() => _submitting = false);
                      
                      if (success) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Pago enviado para acreditación. Un administrador lo revisará.'),
                            backgroundColor: Color(0xFF0066FF),
                          ),
                        );
                        widget.onBack();
                      } else {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Error al enviar el pago al servidor.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } else {
                      // Demo mode fallback
                      Future.delayed(const Duration(milliseconds: 800), () {
                        if (!mounted) return;
                        state.submitManualPayment(
                          memberDni: state.currentUser?.dni ?? '11111111',
                          planName: planName,
                          price: price,
                          method: _selectedMethod,
                          receiptName: _uploadedFileName,
                        );

                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Pago enviado para acreditación (Modo Demo).'),
                            backgroundColor: Color(0xFF0066FF),
                          ),
                        );
                        setState(() => _submitting = false);
                        widget.onBack();
                      });
                    }
                  }
                : null,
            child: _submitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Enviar a Verificación', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
          ),
        ],
      ),
    );
  }
}

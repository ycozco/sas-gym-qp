import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import '../../../core/config/app_config.dart';
import '../../../core/services/local_image_picker.dart';
import '../../../data/gym_state.dart';
import '../../../models/gym_models.dart';
import '../../../theme/app_theme_tokens.dart';
import '../../../widgets/app_shell.dart';

class ReportObservationView extends StatefulWidget {
  const ReportObservationView({
    super.key,
    required this.palette,
    required this.onBack,
  });

  final RolePalette palette;
  final VoidCallback onBack;

  @override
  State<ReportObservationView> createState() => _ReportObservationViewState();
}

class _ReportObservationViewState extends State<ReportObservationView> {
  final _descCtrl = TextEditingController();
  String _category = 'Equipamiento';
  PickedLocalImage? _selectedFile;
  bool _isUploading = false;

  Future<void> _pickImage() async {
    try {
      final file = await LocalImagePicker.pickImage();
      if (file == null) return;
      if (file.size > AppConfig.maxLocalImageBytes) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La imagen supera el tamano maximo permitido.'),
          ),
        );
        return;
      }

      setState(() {
        _selectedFile = file;
      });
    } catch (e) {
      AppLogger.debug('Error picking image', e);
    }
  }

  Future<List<int>?> _compressImage(Uint8List bytes) async {
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;
      return img.encodeJpg(decoded, quality: 80);
    } catch (e) {
      AppLogger.debug('Error compressing image', e);
      return null;
    }
  }

  Future<void> _submit(GymState state) async {
    if (_descCtrl.text.isEmpty) return;

    setState(() {
      _isUploading = true;
    });

    try {
      bool success = false;
      if (state.isBackendMode) {
        List<int>? fileBytes;
        String? fileName;

        if (_selectedFile != null) {
          final compressed = await _compressImage(_selectedFile!.bytes);
          if (compressed != null) {
            fileBytes = compressed;
            fileName = _selectedFile!.name.replaceAll(
              RegExp(r'\.[^.]+$'),
              '.jpg',
            );
          } else {
            fileBytes = _selectedFile!.bytes;
            fileName = _selectedFile!.name;
          }
        }

        success = await state.uploadObservationBackend(
          category: _category,
          description: _descCtrl.text,
          fileBytes: fileBytes,
          fileName: fileName,
        );
      } else {
        state.addObservation(
          _category,
          _descCtrl.text,
          state.currentUser?.nombreCompleto ?? 'Mateo Salas',
        );
        success = true;
      }

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reporte enviado correctamente.'),
              backgroundColor: Color(0xFF00B85C),
            ),
          );
          widget.onBack();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al enviar el reporte. Inténtalo de nuevo.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ocurrió un error inesperado.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = GymStateProvider.of(context);
    final colors = context.sasColors;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'BUZÓN DE OBSERVACIONES',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: widget.onBack,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reporta un problema o sugerencia',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tu sugerencia será revisada por la administración del local.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            const Text(
              'Categoría',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: colors.surfaceAlt,
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Equipamiento',
                  child: Text('Equipamiento (Máquinas)'),
                ),
                DropdownMenuItem(
                  value: 'Limpieza',
                  child: Text('Limpieza y Aseo'),
                ),
                DropdownMenuItem(
                  value: 'Personal',
                  child: Text('Atención del personal'),
                ),
                DropdownMenuItem(
                  value: 'Sugerencia',
                  child: Text('Sugerencia General'),
                ),
              ],
              onChanged: (val) {
                setState(() {
                  _category = val ?? 'Equipamiento';
                });
              },
            ),
            const SizedBox(height: 20),

            const Text(
              'Descripción del suceso',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descCtrl,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Detalla lo ocurrido o tu propuesta aquí...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                fillColor: colors.surfaceAlt,
                filled: true,
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Adjuntar Foto (Opcional)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _isUploading ? null : _pickImage,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.border),
                ),
                child: _selectedFile != null
                    ? Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(
                              _selectedFile!.bytes,
                              height: 150,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Color(0xFF00B85C),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _selectedFile!.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _selectedFile = null;
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      )
                    : const Column(
                        children: [
                          Icon(
                            Icons.camera_alt_outlined,
                            size: 36,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Seleccionar imagen de la galería',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 36),

            if (_isUploading)
              const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD2FF3A)),
                ),
              )
            else
              ElevatedButton(
                style: roleFilledPillButtonStyle(
                  backgroundColor: widget.palette.accent,
                  foregroundColor: widget.palette.accentInk,
                  minimumHeight: 56,
                ),
                onPressed: () => _submit(state),
                child: const Text(
                  'Enviar Reporte',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

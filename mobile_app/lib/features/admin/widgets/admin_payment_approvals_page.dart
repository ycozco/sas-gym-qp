import 'package:flutter/material.dart';
import '../../../data/gym_state.dart';
import '../../../models/gym_models.dart';
import '../../../theme/app_theme_tokens.dart';
import '../../../widgets/app_shell.dart';
import '../../../core/network/api_client.dart';

class AdminPaymentApprovalsPage extends StatefulWidget {
  const AdminPaymentApprovalsPage({
    super.key,
    required this.palette,
    required this.state,
    required this.onBack,
  });

  final RolePalette palette;
  final GymState state;
  final VoidCallback onBack;

  @override
  State<AdminPaymentApprovalsPage> createState() =>
      _AdminPaymentApprovalsPageState();
}

class _AdminPaymentApprovalsPageState extends State<AdminPaymentApprovalsPage> {
  List<Map<String, dynamic>> _pendingPayments = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadPendingPayments();
  }

  Future<void> _loadPendingPayments() async {
    if (!widget.state.isBackendMode) return;
    setState(() => _loading = true);
    final list = await widget.state.getPendingPaymentsBackend();
    if (mounted) {
      setState(() {
        _pendingPayments = list;
        _loading = false;
      });
    }
  }

  String _getReceiptUrl(String filename) {
    if (filename.startsWith('http')) return filename;
    final path = filename.startsWith('/uploads')
        ? filename
        : '/uploads/receipts/$filename';
    final baseUrl = ApiClient().dio.options.baseUrl;
    final host = baseUrl.replaceAll('/api/v1', '');
    return '$host$path';
  }

  BoxDecoration _cardDecoration(BuildContext context) {
    final colors = context.sasColors;
    return BoxDecoration(
      color: colors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: colors.border),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sasColors;
    // Generate list of pending payments
    List<Map<String, dynamic>> pendingList = [];
    if (widget.state.isBackendMode) {
      for (var item in _pendingPayments) {
        final membership = item['membership'] ?? {};
        final user = membership['user'] ?? {};

        pendingList.add({
          'paymentId': item['id'],
          'name': user['nombre_completo'] ?? 'Socio',
          'dni': user['dni'] ?? '',
          'planName': membership['plan_nombre'] ?? 'Membresía',
          'price': (item['monto'] as num?)?.toDouble() ?? 0.0,
          'date': item['timestamp']?.toString().split('T')[0] ?? 'Hoy',
          'method': item['metodo']?.toString() ?? 'Efectivo',
          'receiptUrl': item['comprobante_url'] ?? '',
        });
      }
    } else {
      // In demo mode, we just build the list from memory
      for (var m in widget.state.allMembersIncludingSoftDeleted) {
        for (var p in m.paymentHistory) {
          if (p.state == 'pending') {
            pendingList.add({
              'paymentId': p.id,
              'name': m.name,
              'dni': m.dni,
              'planName': p.planName,
              'price': p.price,
              'date': p.date,
              'method': p.method,
              'receiptUrl': p.receiptUrl,
            });
          }
        }
      }
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Bandeja de Aprobaciones',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: widget.onBack,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (widget.state.isBackendMode)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _loadPendingPayments,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : pendingList.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    color: Colors.grey.shade400,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '¡Todo al día!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'No hay comprobantes de pago pendientes.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: pendingList.length,
              itemBuilder: (context, index) {
                final item = pendingList[index];
                final String paymentId = item['paymentId'];
                final String name = item['name'];
                final String dni = item['dni'];
                final String planName = item['planName'];
                final double price = item['price'];
                final String date = item['date'];
                final String method = item['method'];
                final String receiptUrl = item['receiptUrl'] ?? '';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: _cardDecoration(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: widget.palette.accent.withValues(
                                alpha: 0.1,
                              ),
                              foregroundColor: widget.palette.accent,
                              child: const Icon(Icons.person),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14.5,
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'DNI: $dni',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2C0F14),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'PENDIENTE',
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Divider(height: 24, color: colors.border),
                        _rowItem(context, 'Plan solicitado:', planName),
                        _rowItem(context, 'Importe a pagar:', 'S/ $price'),
                        _rowItem(context, 'Fecha envío:', date),
                        _rowItem(context, 'Método registrado:', method),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => _showReceiptPreview(
                            context,
                            receiptUrl,
                            price,
                            name,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colors.surfaceAlt,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: colors.border),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.image_outlined,
                                  color: colors.textSecondary,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    receiptUrl.split('/').last.isEmpty
                                        ? 'comprobante.jpg'
                                        : receiptUrl.split('/').last,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      decoration: TextDecoration.underline,
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.remove_red_eye_outlined,
                                  size: 18,
                                  color: colors.textSecondary,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: roleOutlinedPillButtonStyle(
                                  foregroundColor: Colors.redAccent,
                                  side: const BorderSide(
                                    color: Colors.redAccent,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                onPressed: () async {
                                  final messenger = ScaffoldMessenger.of(
                                    context,
                                  );
                                  if (widget.state.isBackendMode) {
                                    final ok = await widget.state
                                        .resolvePaymentBackend(
                                          paymentId: paymentId,
                                          status: 'REJECTED',
                                          comments:
                                              'Comprobante inválido o ilegible.',
                                        );
                                    if (ok) {
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Pago rechazado en el servidor.',
                                          ),
                                          backgroundColor: Colors.redAccent,
                                        ),
                                      );
                                      _loadPendingPayments();
                                    }
                                  } else {
                                    widget.state.rejectManualPayment(
                                      dni,
                                      paymentId,
                                    );
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Pago rechazado (Modo Demo).',
                                        ),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  }
                                },
                                child: const Text(
                                  'Rechazar',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                style: roleFilledPillButtonStyle(
                                  backgroundColor: const Color(0xFF00B85C),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                onPressed: () async {
                                  final messenger = ScaffoldMessenger.of(
                                    context,
                                  );
                                  if (widget.state.isBackendMode) {
                                    final ok = await widget.state
                                        .resolvePaymentBackend(
                                          paymentId: paymentId,
                                          status: 'APPROVED',
                                          comments:
                                              'Aprobado por administración.',
                                        );
                                    if (ok) {
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Pago aprobado. Membresía del socio activada.',
                                          ),
                                          backgroundColor: Color(0xFF00B85C),
                                        ),
                                      );
                                      _loadPendingPayments();
                                    }
                                  } else {
                                    widget.state.approveManualPayment(
                                      dni,
                                      paymentId,
                                    );
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Pago aprobado. Socio activado (Modo Demo).',
                                        ),
                                        backgroundColor: Color(0xFF00B85C),
                                      ),
                                    );
                                  }
                                },
                                child: const Text(
                                  'Aprobar e Iniciar',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _rowItem(BuildContext context, String label, String value) {
    final colors = context.sasColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _showReceiptPreview(
    BuildContext context,
    String filename,
    double price,
    String memberName,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        final colors = context.sasColors;
        return Dialog(
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Comprobante de Depósito',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (widget.state.isBackendMode && filename.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      height: 320,
                      color: colors.surfaceAlt,
                      child: Image.network(
                        _getReceiptUrl(filename),
                        fit: BoxFit.contain,
                        errorBuilder: (ctx, err, stack) => const Center(
                          child: Text(
                            'Error al cargar imagen del comprobante.\nMostrando plantilla simulada.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    height: 320,
                    decoration: BoxDecoration(
                      color: colors.surfaceAlt,
                      border: Border.all(color: colors.border),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Colors.green,
                          size: 48,
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'TRANSFERENCIA EXITOSA',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white38,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'S/ ${price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Divider(color: colors.border),
                        const SizedBox(height: 10),
                        const ReceiptField('Destinatario', 'SaaS GYM S.A.C.'),
                        const ReceiptField('Operación', '784918239'),
                        const ReceiptField('Fecha y hora', 'Reciente'),
                        ReceiptField('Referencia', 'Socio: $memberName'),
                        const Spacer(),
                        Text(
                          'Archivo: ${filename.split('/').last}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ReceiptField extends StatelessWidget {
  const ReceiptField(this.label, this.value, {super.key});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11.5, color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../data/gym_state.dart';
import '../../../models/gym_models.dart';
import '../../../theme/app_theme_tokens.dart';
import '../../../widgets/app_shell.dart';

class CashierPOSPage extends StatefulWidget {
  const CashierPOSPage({
    super.key,
    required this.palette,
    required this.state,
    required this.selectedMemberDni,
    required this.cartItems,
    required this.cashPaid,
    required this.paymentMethod,
    required this.onMemberChanged,
    required this.onCartChanged,
    required this.onCashPaidChanged,
    required this.onPaymentMethodChanged,
    required this.onClearCart,
  });

  final RolePalette palette;
  final GymState state;
  final String? selectedMemberDni;
  final List<Map<String, dynamic>> cartItems;
  final double cashPaid;
  final String paymentMethod;
  final Function(String?) onMemberChanged;
  final VoidCallback onCartChanged;
  final Function(double) onCashPaidChanged;
  final Function(String) onPaymentMethodChanged;
  final VoidCallback onClearCart;

  @override
  State<CashierPOSPage> createState() => _CashierPOSPageState();
}

class _CashierPOSPageState extends State<CashierPOSPage> {
  // Available POS inventory (physical goods only, memberships moved to dedicated tab)
  final List<Map<String, dynamic>> _posItems = [
    {'name': 'Botella de agua 600ml', 'price': 3.0, 'icon': '💧', 'category': 'Bebidas'},
    {'name': 'Proteína whey porción', 'price': 12.0, 'icon': '💪', 'category': 'Suplementos'},
    {'name': 'Pre-entreno scoop', 'price': 8.0, 'icon': '⚡', 'category': 'Suplementos'},
    {'name': 'Barra energética', 'price': 5.0, 'icon': '🍫', 'category': 'Snacks'},
  ];

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
    final double subtotal = widget.cartItems.fold(0, (sum, item) => sum + (item['price'] * item['qty']));
    final double discount = subtotal > 300.0 ? subtotal * 0.05 : 0.0; // 5% discount for bulk
    final double total = subtotal - discount;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
      children: [
        const SectionHeader(title: 'Punto de Venta (POS)', action: 'Carrito de compras'),
        const SizedBox(height: 8),

        // Member selection dropdown & Anonymous Sale Button
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: _cardDecoration(context),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: (widget.selectedMemberDni != null &&
                            widget.selectedMemberDni != 'ANONIMO' &&
                            widget.state.members.any((m) => m.dni == widget.selectedMemberDni))
                        ? widget.selectedMemberDni
                        : null,
                    disabledHint: const Text('Venta Anónima Activa', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
                    hint: const Text('Seleccionar Socio destinatario...', style: TextStyle(fontWeight: FontWeight.w600)),
                    items: widget.state.members.map((m) {
                      return DropdownMenuItem(
                        value: m.dni,
                        child: Text('${m.name} (DNI ${m.dni}) · Plan: ${m.state}'),
                      );
                    }).toList(),
                    onChanged: widget.selectedMemberDni == 'ANONIMO' ? null : widget.onMemberChanged,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (widget.selectedMemberDni == 'ANONIMO')
              ElevatedButton.icon(
                style: roleOutlinedPillButtonStyle(
                  foregroundColor: Colors.red,
                  backgroundColor: Colors.red.withValues(alpha: 0.05),
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                icon: const Icon(Icons.close_rounded, size: 18),
                label: const Text('Asociar Socio', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                onPressed: () {
                  widget.onMemberChanged(null);
                },
              )
            else
              ElevatedButton.icon(
                style: roleOutlinedPillButtonStyle(
                  foregroundColor: widget.palette.accent,
                  backgroundColor: widget.palette.accent.withValues(alpha: 0.05),
                  side: BorderSide(color: widget.palette.accent),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                icon: const Icon(Icons.person_outline_rounded, size: 18),
                label: const Text('Anónimo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                onPressed: () {
                  widget.onMemberChanged('ANONIMO');
                },
              ),
          ],
        ),
        const SizedBox(height: 18),

        // Cart items display
        Container(
          padding: const EdgeInsets.all(18),
          decoration: _cardDecoration(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.shopping_cart_outlined, color: colors.textSecondary),
                  const SizedBox(width: 8),
                  Text('Items en Carrito', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5, color: colors.textPrimary)),
                  const Spacer(),
                  if (widget.cartItems.isNotEmpty)
                    TextButton(
                      onPressed: widget.onClearCart,
                      child: const Text('Vaciar', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (widget.cartItems.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: Text('El carrito está vacío. Agrega items del catálogo inferior.',
                        style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                )
              else
                Column(
                  children: [
                    ...widget.cartItems.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Text(item['icon'], style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item['name'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: colors.textPrimary)),
                                  Text('S/ ${item['price']} x ${item['qty']}', style: TextStyle(color: colors.textSecondary, fontSize: 11.5)),
                                ],
                              ),
                            ),
                            // Qty controls
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, size: 20),
                              onPressed: () {
                                setState(() {
                                  if (item['qty'] > 1) {
                                    item['qty']--;
                                  } else {
                                    widget.cartItems.remove(item);
                                  }
                                });
                                widget.onCartChanged();
                              },
                            ),
                            Text('${item['qty']}', style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary)),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, size: 20),
                              onPressed: () {
                                setState(() {
                                  item['qty']++;
                                });
                                widget.onCartChanged();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
                              onPressed: () {
                                setState(() {
                                  widget.cartItems.remove(item);
                                });
                                widget.onCartChanged();
                              },
                            ),
                          ],
                        ),
                      );
                    }),
                    Divider(height: 20, color: colors.border),
                    _priceSummaryRow(context, 'Subtotal', 'S/ ${subtotal.toStringAsFixed(2)}'),
                    _priceSummaryRow(context, 'Descuento', '- S/ ${discount.toStringAsFixed(2)}'),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('TOTAL VENTA', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: colors.textPrimary)),
                        Text('S/ ${total.toStringAsFixed(2)}',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 19, color: colors.accent)),
                      ],
                    ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        // Checkout & Payment Methods Drawer Button (Continue to Payment)
        if (widget.cartItems.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: _cardDecoration(context),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: roleFilledPillButtonStyle(
                  backgroundColor: widget.palette.accent,
                  foregroundColor: widget.palette.accentInk,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  if (widget.selectedMemberDni == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Por favor, selecciona un Socio destinatario primero')),
                    );
                    return;
                  }
                  _openPaymentCheckoutDialog(total);
                },
                child: const Text('CONTINUAR AL PAGO', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ),
          ),
        const SizedBox(height: 22),

        // Catalog header
        const SectionHeader(title: 'Catálogo POS de Venta'),
        Column(
          children: _posItems.map((item) {
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              color: colors.surface,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: colors.border),
              ),
              child: ListTile(
                leading: Text(item['icon'] as String, style: const TextStyle(fontSize: 22)),
                title: Text(item['name'] as String, style: TextStyle(fontWeight: FontWeight.w800, color: colors.textPrimary)),
                subtitle: Text(item['category'] as String, style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('S/ ${item['price']}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: colors.textPrimary)),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: Icon(Icons.add_shopping_cart_rounded, color: colors.accent),
                      onPressed: () {
                        setState(() {
                          final idx = widget.cartItems.indexWhere((c) => c['name'] == item['name']);
                          if (idx != -1) {
                            widget.cartItems[idx]['qty']++;
                          } else {
                            widget.cartItems.add({
                              'name': item['name'],
                              'price': item['price'],
                              'qty': 1,
                              'icon': item['icon'],
                            });
                          }
                        });
                        widget.onCartChanged();
                      },
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _priceSummaryRow(BuildContext context, String title, String val) {
    final colors = context.sasColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold)),
          Text(val, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colors.textPrimary)),
        ],
      ),
    );
  }

  void _openPaymentCheckoutDialog(double total) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool isCombined = false;
        
        // Single payment state
        String selectedSingleMethod = 'Efectivo';
        double cashReceived = 0.0;
        
        // Combined payment state
        final Map<String, double> combinedAmounts = {
          'Efectivo': 0.0,
          'Yape': 0.0,
          'Plin': 0.0,
          'Tarjeta': 0.0,
        };

        // Text editing controllers to prevent cursor resets
        final Map<String, TextEditingController> controllers = {
          'Efectivo': TextEditingController(text: ''),
          'Yape': TextEditingController(text: ''),
          'Plin': TextEditingController(text: ''),
          'Tarjeta': TextEditingController(text: ''),
        };
        final cashReceivedController = TextEditingController(text: '');

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final double sumCombined = combinedAmounts.values.fold(0, (sum, val) => sum + val);
            final double remainingCombined = (total - sumCombined).clamp(0.0, 999999.0);
            final double changeCombined = (sumCombined - total).clamp(0.0, 999999.0);

            final double changeSingle = (cashReceived - total).clamp(0.0, 999999.0);

            bool canConfirm = false;
            if (!isCombined) {
              if (selectedSingleMethod == 'Efectivo') {
                canConfirm = cashReceived >= total;
              } else {
                canConfirm = true;
              }
            } else {
              canConfirm = sumCombined >= total;
            }

            final dialogColors = context.sasColors;

            return AlertDialog(
              backgroundColor: dialogColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: dialogColors.border),
              ),
              titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              actionsPadding: const EdgeInsets.fromLTRB(24, 10, 24, 20),
              title: Row(
                children: [
                  Icon(Icons.point_of_sale_rounded, color: dialogColors.accent, size: 28),
                  const SizedBox(width: 8),
                  Text('Procesar Pago', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18.5, color: dialogColors.textPrimary)),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: dialogColors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 380,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Total indicator banner
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: dialogColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: dialogColors.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Monto Total a Pagar:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: dialogColors.textPrimary)),
                            Text('S/ ${total.toStringAsFixed(2)}',
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: dialogColors.accent)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Segmented control to choose Pago Único or Pago Combinado
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: roleFilledPillButtonStyle(
                                backgroundColor: !isCombined ? widget.palette.accent : const Color(0xFFF0EFEA),
                                foregroundColor: !isCombined ? widget.palette.accentInk : dialogColors.textPrimary,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                minimumHeight: 38,
                              ),
                              onPressed: () => setStateDialog(() => isCombined = false),
                              child: const Text('Pago Único', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              style: roleFilledPillButtonStyle(
                                backgroundColor: isCombined ? widget.palette.accent : const Color(0xFFF0EFEA),
                                foregroundColor: isCombined ? widget.palette.accentInk : dialogColors.textPrimary,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                minimumHeight: 38,
                              ),
                              onPressed: () => setStateDialog(() => isCombined = true),
                              child: const Text('Pago Combinado', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      if (!isCombined) ...[
                        const Text('Selecciona el Método de Pago:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        const SizedBox(height: 8),
                        Row(
                          children: ['Efectivo', 'Yape', 'Plin', 'Tarjeta'].map((m) {
                            final sel = selectedSingleMethod == m;
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 2),
                                child: ChoiceChip(
                                  showCheckmark: false,
                                  label: Text(m, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: sel ? widget.palette.accentInk : dialogColors.textPrimary)),
                                  selected: sel,
                                  selectedColor: widget.palette.accent,
                                  backgroundColor: dialogColors.surfaceAlt,
                                  side: BorderSide(color: dialogColors.border),
                                  shape: const StadiumBorder(),
                                  onSelected: (val) {
                                    if (val) {
                                      setStateDialog(() => selectedSingleMethod = m);
                                    }
                                  },
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),

                        if (selectedSingleMethod == 'Efectivo') ...[
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Efectivo Recibido (S/)',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                              Container(
                                width: 120,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: dialogColors.surfaceAlt,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: dialogColors.border),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: TextField(
                                  controller: cashReceivedController,
                                  keyboardType: TextInputType.number,
                                  onChanged: (val) {
                                    setStateDialog(() {
                                      cashReceived = double.tryParse(val) ?? 0.0;
                                    });
                                  },
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    hintText: '0.00',
                                  ),
                                  style: TextStyle(fontWeight: FontWeight.bold, color: dialogColors.textPrimary),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Vuelto a Entregar:', style: TextStyle(color: dialogColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                              Text('S/ ${changeSingle.toStringAsFixed(2)}',
                                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: cashReceived >= total ? Colors.green : Colors.red)),
                            ],
                          ),
                        ],
                      ] else ...[
                        const Text('Ingresa los montos por método:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                        const SizedBox(height: 10),
                        ...['Efectivo', 'Yape', 'Plin', 'Tarjeta'].map((method) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                SizedBox(width: 80, child: Text(method, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                                Expanded(
                                  child: Container(
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: dialogColors.surfaceAlt,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: dialogColors.border),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: TextField(
                                      controller: controllers[method],
                                      keyboardType: TextInputType.number,
                                      onChanged: (val) {
                                        setStateDialog(() {
                                          combinedAmounts[method] = double.tryParse(val) ?? 0.0;
                                        });
                                      },
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        hintText: '0.00',
                                      ),
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: dialogColors.textPrimary),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        Divider(height: 20, color: dialogColors.border),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Suma Ingresada:', style: TextStyle(color: dialogColors.textSecondary, fontSize: 12.5, fontWeight: FontWeight.bold)),
                            Text('S/ ${sumCombined.toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        if (sumCombined < total)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Monto Restante:', style: TextStyle(color: Colors.red, fontSize: 12.5, fontWeight: FontWeight.bold)),
                              Text('S/ ${remainingCombined.toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.red)),
                            ],
                          )
                        else
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Vuelto:', style: TextStyle(color: Colors.green, fontSize: 12.5, fontWeight: FontWeight.bold)),
                              Text('S/ ${changeCombined.toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.green)),
                            ],
                          ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancelar', style: TextStyle(color: dialogColors.textSecondary, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  style: roleFilledPillButtonStyle(
                    backgroundColor: canConfirm ? widget.palette.accent : dialogColors.textMuted,
                    foregroundColor: canConfirm ? widget.palette.accentInk : Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onPressed: !canConfirm
                      ? null
                      : () async {
                          Navigator.pop(context); // close checkout dialog first

                          final String methodStr = isCombined ? 'Combinado' : selectedSingleMethod;
                          final List<Map<String, dynamic>>? paymentsList = isCombined
                              ? combinedAmounts.entries
                                  .where((e) => e.value > 0)
                                  .map((e) => {'metodo': e.key, 'monto': e.value})
                                  .toList()
                              : null;

                          if (widget.state.isBackendMode) {
                            try {
                              final ok = await widget.state.chargePOSBackend(
                                memberDni: widget.selectedMemberDni!,
                                cartItems: widget.cartItems,
                                total: total,
                                paymentMethod: methodStr,
                                payments: paymentsList,
                              );
                              if (ok && context.mounted) {
                                _showPOSReceiptSuccess(context, total, methodStr);
                                widget.onClearCart();
                              }
                            } catch (e) {
                              if (context.mounted) {
                                String errorMsg = 'Error al procesar la venta en el servidor.';
                                if (e is DioException && e.response != null && e.response!.data != null) {
                                  final data = e.response!.data;
                                  if (data is Map && data.containsKey('message')) {
                                    errorMsg = data['message'].toString();
                                  }
                                }
                                showDialog(
                                  context: context,
                                  builder: (ctx) {
                                    final dialogColors = ctx.sasColors;
                                    return AlertDialog(
                                      backgroundColor: dialogColors.surface,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        side: BorderSide(
                                          color: dialogColors.border,
                                        ),
                                      ),
                                      title: const Text(
                                        'Operación Denegada',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red,
                                        ),
                                      ),
                                      content: Text(errorMsg),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: const Text(
                                            'Entendido',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              }
                            }
                          } else {
                            // Demo mode fallback
                            widget.state.chargePOS(
                              memberDni: widget.selectedMemberDni!,
                              cartItems: widget.cartItems,
                              total: total,
                              paymentMethod: methodStr,
                              payments: paymentsList,
                            );
                            _showPOSReceiptSuccess(context, total, methodStr);
                            widget.onClearCart();
                          }
                        },
                  child: const Text('Confirmar Venta', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showPOSReceiptSuccess(BuildContext context, double total, String method) {
    showDialog(
      context: context,
      builder: (ctx) {
        final colors = ctx.sasColors;
        return AlertDialog(
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: colors.border),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF00B85C), size: 64),
              const SizedBox(height: 18),
              Text('Venta Completada', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: colors.textPrimary)),
              const SizedBox(height: 8),
              Text('Se registró el cobro de S/ $total via $method correctamente.',
                  textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),
              ElevatedButton(
                style: roleFilledPillButtonStyle(
                  backgroundColor: colors.accent,
                  foregroundColor: widget.palette.accentInk,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  minimumHeight: 44,
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Listo', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../models/gym_models.dart';
import '../../../../data/gym_state.dart';
import '../../../../widgets/app_shell.dart';
import 'admin_dashboard_page.dart';

class AdminProductInventoryPage extends StatelessWidget {
  const AdminProductInventoryPage({
    super.key,
    required this.palette,
    required this.state,
    required this.productSearchQuery,
    required this.onProductSearchChanged,
    required this.onBack,
    required this.onAddProduct,
    required this.onEditProduct,
  });

  final RolePalette palette;
  final GymState state;
  final String productSearchQuery;
  final ValueChanged<String> onProductSearchChanged;
  final VoidCallback onBack;
  final VoidCallback onAddProduct;
  final Function(ProductItem) onEditProduct;

  @override
  Widget build(BuildContext context) {
    final filteredProducts = state.products.where((p) {
      return p.name.toLowerCase().contains(productSearchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: onBack,
        ),
        title: const Text('Inventario y Productos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_rounded, color: Colors.white),
            onPressed: onAddProduct,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: TextField(
              onChanged: onProductSearchChanged,
              decoration: InputDecoration(
                hintText: 'Buscar productos...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: const Color(0xFF16161A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF232329)),
                ),
              ),
            ),
          ),
          Expanded(
            child: filteredProducts.isEmpty
                ? const Center(
                    child: Text('No hay productos en el inventario.', style: TextStyle(color: Colors.white38)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final p = filteredProducts[index];
                      final isLowStock = p.stock < 20;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: adminCardDecoration(),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: isLowStock ? Colors.redAccent.withValues(alpha: 0.15) : palette.accent.withValues(alpha: 0.12),
                              foregroundColor: isLowStock ? Colors.redAccent : palette.accent,
                              child: const Icon(Icons.inventory_2_outlined),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Stock: ${p.stock} unidades · Categoría: ${p.category}',
                                    style: TextStyle(color: isLowStock ? Colors.redAccent : Colors.white60, fontSize: 11.5),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('S/ ${p.price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                                const SizedBox(height: 6),
                                GestureDetector(
                                  onTap: () => onEditProduct(p),
                                  child: Text(
                                    'Editar',
                                    style: TextStyle(color: palette.accent, fontWeight: FontWeight.bold, fontSize: 11.5, decoration: TextDecoration.underline),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class AdminProductFormPage extends StatefulWidget {
  const AdminProductFormPage({
    super.key,
    required this.palette,
    required this.state,
    this.product,
    required this.onBack,
  });

  final RolePalette palette;
  final GymState state;
  final ProductItem? product;
  final VoidCallback onBack;

  @override
  State<AdminProductFormPage> createState() => _AdminProductFormPageState();
}

class _AdminProductFormPageState extends State<AdminProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _stockCtrl;
  late TextEditingController _categoryCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.product?.name ?? '');
    _priceCtrl = TextEditingController(text: widget.product?.price.toString() ?? '');
    _stockCtrl = TextEditingController(text: widget.product?.stock.toString() ?? '');
    _categoryCtrl = TextEditingController(text: widget.product?.category ?? 'Bebidas');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: widget.onBack,
        ),
        title: Text(isEdit ? 'Editar Producto' : 'Nuevo Producto', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre del Producto *'),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Precio (S/) *'),
                    validator: (val) => val == null || double.tryParse(val) == null ? 'Ingresa precio válido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _stockCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Stock Inicial *'),
                    validator: (val) => val == null || int.tryParse(val) == null ? 'Ingresa stock válido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _categoryCtrl,
                    decoration: const InputDecoration(labelText: 'Categoría (ej: Suplementos, Bebidas)'),
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
                  final parsedPrice = double.parse(_priceCtrl.text);
                  final parsedStock = int.parse(_stockCtrl.text);

                  if (isEdit) {
                    final updated = ProductItem(
                      name: _nameCtrl.text.trim(),
                      price: parsedPrice,
                      stock: parsedStock,
                      category: _categoryCtrl.text.trim(),
                      icon: widget.product!.icon,
                    );
                    widget.state.updateProduct(widget.product!.name, updated);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Producto actualizado exitosamente.'), backgroundColor: Color(0xFF00B85C)),
                    );
                  } else {
                    final newP = ProductItem(
                      name: _nameCtrl.text.trim(),
                      price: parsedPrice,
                      stock: parsedStock,
                      category: _categoryCtrl.text.trim(),
                      icon: '📦',
                    );
                    widget.state.addProduct(newP);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Producto registrado exitosamente.'), backgroundColor: Color(0xFF00B85C)),
                    );
                  }
                  widget.onBack();
                }
              },
              child: Text(isEdit ? 'Guardar Cambios' : 'Registrar Producto', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

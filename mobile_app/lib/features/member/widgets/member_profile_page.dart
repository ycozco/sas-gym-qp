import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../../data/gym_state.dart';
import '../../../models/gym_models.dart';
import '../../../widgets/app_shell.dart';
import 'member_shared_utils.dart';

class MemberProfilePage extends StatefulWidget {
  const MemberProfilePage({
    super.key,
    required this.palette,
    required this.onGo,
    required this.onThemeChanged,
  });

  final RolePalette palette;
  final Function(String, [Map<String, dynamic>?]) onGo;
  final VoidCallback onThemeChanged;

  @override
  State<MemberProfilePage> createState() => _MemberProfilePageState();
}

class _MemberProfilePageState extends State<MemberProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedActivity = 'Moderado';
  String _selectedGoal = 'Mantenimiento';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = GymStateProvider.of(context);
      state.loadMemberPoints();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = GymStateProvider.of(context);
    final mateo = getLoggedMember(state);

    return Column(
      children: [
        // Tab header
        TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: const Color(0xFF757575),
          indicatorColor: widget.palette.accent,
          indicatorWeight: 3.5,
          tabs: const [
            Tab(text: 'Privado'),
            Tab(text: 'Social'),
            Tab(text: 'Físico'),
            Tab(text: 'Puntos'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildPrivateTab(mateo),
              _buildSocialTab(state),
              _buildPhysicalTab(mateo),
              _buildPointsTab(state),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPointsTab(GymState state) {
    final balance =
        state.memberPointsSummary?['balance'] as Map<String, dynamic>?;
    final points = (balance?['puntos_disponibles'] as num?)?.toInt() ?? 0;
    final earnedPoints =
        (balance?['puntos_totales_ganados'] as num?)?.toInt() ?? 0;
    final redeemedPoints =
        (balance?['puntos_totales_canjeados'] as num?)?.toInt() ?? 0;

    final List<dynamic> exchanges =
        (state.memberPointsSummary?['exchanges'] as List<dynamic>?) ?? [];
    final List<dynamic> movements =
        (state.memberPointsSummary?['movements'] as List<dynamic>?) ?? [];

    final catalog = state.pointsCatalog;
    final List<dynamic> products =
        (catalog?['products'] as List<dynamic>?) ?? [];
    final List<dynamic> memberships =
        (catalog?['memberships'] as List<dynamic>?) ?? [];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        // Resumen de puntos card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: _cardDecoration(context),
          child: Column(
            children: [
              const Icon(
                Icons.stars_rounded,
                color: Color(0xFFD2FF3A),
                size: 48,
              ),
              const SizedBox(height: 12),
              const Text(
                'Tus Puntos SAS',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF757575),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$points',
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text(
                        'Ganados',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF757575),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$earnedPoints',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 1,
                    height: 24,
                    color: const Color(0xFFECEAE4),
                  ),
                  Column(
                    children: [
                      const Text(
                        'Canjeados',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF757575),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$redeemedPoints',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

        // Catálogo de Premios
        const SizedBox(height: 24),
        const Text(
          'CATÁLOGO DE PREMIOS DISPONIBLES',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 12,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        if (products.isEmpty && memberships.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: _cardDecoration(context),
              child: const Center(
                child: Text(
                  'No hay premios disponibles en el catálogo hoy.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
            ),
          )
        else ...[
          // Render memberships
          ...memberships.map(
            (item) =>
                _buildCatalogItemRow(context, state, item, 'membresia', points),
          ),
          // Render products
          ...products.map(
            (item) =>
                _buildCatalogItemRow(context, state, item, 'producto', points),
          ),
        ],

        const SizedBox(height: 24),

        // Historial de Canjes (Exchanges)
        const Text(
          'HISTORIAL DE CANJES',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 12,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        if (exchanges.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: _cardDecoration(context),
              child: const Center(
                child: Text(
                  'No has realizado canjes aún.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
            ),
          )
        else
          ...exchanges.map((exc) {
            final date = exc['fecha_canje']?.toString().split('T').first ?? '—';
            final cost = (exc['costo_puntos'] as num?)?.toInt() ?? 0;
            final product = exc['producto'] as Map<String, dynamic>?;
            final membership = exc['membresia_puntos'] as Map<String, dynamic>?;
            final name = product != null
                ? (product['nombre']?.toString() ?? 'Producto')
                : (membership != null
                      ? (membership['nombre']?.toString() ?? 'Membresía')
                      : 'Canje');
            final estado = exc['estado']?.toString() ?? 'COMPLETED';

            Color statusColor = const Color(0xFF00B85C);
            String statusText = 'Completado';
            if (estado == 'PENDING') {
              statusColor = const Color(0xFFFFB300);
              statusText = 'Pendiente';
            } else if (estado == 'REJECTED') {
              statusColor = Colors.redAccent;
              statusText = 'Rechazado';
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: _cardDecoration(context),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        product != null
                            ? Icons.shopping_bag_rounded
                            : Icons.card_membership_rounded,
                        color: statusColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$date · $statusText',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '-$cost pts',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

        const SizedBox(height: 24),

        // Historial de Movimientos (Movements)
        const Text(
          'MOVIMIENTOS DE PUNTOS',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 12,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        if (movements.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: _cardDecoration(context),
              child: const Center(
                child: Text(
                  'No hay movimientos de puntos registrados.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
            ),
          )
        else
          ...movements.map((mov) {
            final date = mov['created_at']?.toString().split('T').first ?? '—';
            final qty = (mov['cantidad'] as num?)?.toInt() ?? 0;
            final concept = mov['concepto']?.toString() ?? 'Movimiento';
            final tipo = mov['tipo']?.toString() ?? 'EARN';
            final isEarn = tipo == 'EARN' || tipo == 'ADMIN_ADD' || qty > 0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: _cardDecoration(context),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color:
                            (isEarn
                                    ? const Color(0xFF00B85C)
                                    : Colors.redAccent)
                                .withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isEarn
                            ? Icons.add_circle_outline_rounded
                            : Icons.remove_circle_outline_rounded,
                        color: isEarn
                            ? const Color(0xFF00B85C)
                            : Colors.redAccent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            concept,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            date,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${isEarn ? "+" : ""}$qty pts',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: isEarn
                            ? const Color(0xFF00B85C)
                            : Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildCatalogItemRow(
    BuildContext context,
    GymState state,
    dynamic item,
    String tipo,
    int currentPoints,
  ) {
    final name = item['nombre']?.toString() ?? 'Premio';
    final desc = item['descripcion']?.toString() ?? '';
    final cost = (item['precio_puntos'] as num?)?.toInt() ?? 0;
    final stock = (item['stock'] as num?)?.toInt() ?? 0;
    final bool isOutOfStock = tipo == 'producto' && stock <= 0;
    final bool canAfford = currentPoints >= cost;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(context),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: widget.palette.accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                tipo == 'membresia'
                    ? Icons.card_membership_rounded
                    : Icons.shopping_bag_rounded,
                color: widget.palette.accent,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                    ),
                  ),
                  if (desc.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      desc,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    tipo == 'membresia'
                        ? 'Duración: ${item['duracion_dias']} días'
                        : 'Stock: $stock unid.',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$cost pts',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13.5,
                    color: canAfford
                        ? const Color(0xFF00B85C)
                        : Colors.redAccent,
                  ),
                ),
                const SizedBox(height: 6),
                ElevatedButton(
                  style: roleFilledPillButtonStyle(
                    backgroundColor: isOutOfStock
                        ? Colors.grey
                        : (canAfford
                              ? widget.palette.accent
                              : Colors.grey.shade300),
                    foregroundColor: isOutOfStock
                        ? Colors.white
                        : (canAfford
                              ? widget.palette.accentInk
                              : Colors.grey.shade600),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    minimumHeight: 28,
                  ),
                  onPressed: isOutOfStock || !canAfford
                      ? null
                      : () => _showRedeemConfirmDialog(
                          context,
                          state,
                          item['id'].toString(),
                          name,
                          cost,
                          tipo,
                        ),
                  child: Text(
                    isOutOfStock ? 'Agotado' : 'Canjear',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showRedeemConfirmDialog(
    BuildContext context,
    GymState state,
    String itemId,
    String itemName,
    int cost,
    String tipo,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Confirmar Canje',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          content: Text(
            '¿Deseas canjear "$itemName" por $cost puntos?\n\nEsta acción no se puede deshacer.',
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.palette.accent,
                foregroundColor: widget.palette.accentInk,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              onPressed: () async {
                Navigator.of(dialogContext).pop();

                // Capturar referencias antes del gap asíncrono
                final nav = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);

                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) =>
                      const Center(child: CircularProgressIndicator()),
                );

                try {
                  final result = await state.redeemPoints(
                    tipo: tipo,
                    itemId: itemId,
                    cantidad: 1,
                  );
                  if (!mounted) return;
                  nav.pop();

                  if (result != null && result['success'] == true) {
                    showDialog(
                      context: nav.context,
                      builder: (context) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: const Text(
                          '¡Canje Exitoso!',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                        content: Text(
                          'Has canjeado "$itemName" correctamente.',
                        ),
                        actions: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.palette.accent,
                              foregroundColor: widget.palette.accentInk,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text(
                              'Entendido',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    throw Exception(result?['message'] ?? 'Error desconocido');
                  }
                } catch (e) {
                  if (!mounted) return;
                  nav.pop();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        'Error al procesar el canje: ${e.toString()}',
                      ),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              },
              child: const Text(
                'Confirmar',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPrivateTab(MemberRecord member) {
    final accent = widget.palette.accent;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        const Text(
          'DATOS DE IDENTIDAD',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 12,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: _cardDecoration(context),
          child: Column(
            children: [
              _profileCardRow(
                Icons.badge_rounded,
                'DNI / Identificación',
                member.dni,
                accent,
              ),
              const Divider(color: Color(0xFF2C2C2C), height: 24),
              _profileCardRow(
                Icons.phone_iphone_rounded,
                'Celular',
                member.phone,
                accent,
              ),
              const Divider(color: Color(0xFF2C2C2C), height: 24),
              _profileCardRow(
                Icons.alternate_email_rounded,
                'Correo electrónico',
                member.email,
                accent,
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        const Text(
          'AFILIACIÓN Y ENTRENAMIENTO',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 12,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: _cardDecoration(context),
          child: Column(
            children: [
              _profileCardRow(
                Icons.calendar_month_rounded,
                'Miembro desde',
                member.startDate,
                accent,
              ),
              const Divider(color: Color(0xFF2C2C2C), height: 24),

              // Custom Coach layout
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.fitness_center_rounded,
                      color: accent,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Entrenador Asignado',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          member.assignedTrainer,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF2C2C2C)),
                    ),
                    child: const Text(
                      'Ver Perfil',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        const Text(
          'TEMA Y PERSONALIZACIÓN',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 12,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: _cardDecoration(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Color de Acento',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              const Text(
                'Personaliza el color principal de la interfaz de tu aplicación.',
                style: TextStyle(fontSize: 11.5, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _colorBubble(const Color(0xFFD2FF3A), 'Cyber Lime'),
                  _colorBubble(const Color(0xFF00E5FF), 'Neon Blue'),
                  _colorBubble(const Color(0xFF8E59FF), 'Violet'),
                  _colorBubble(const Color(0xFFFF5722), 'Orange'),
                  _colorBubble(const Color(0xFFFF2D55), 'Magenta'),
                  _colorBubble(const Color(0xFF00E676), 'Emerald'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _profileCardRow(
    IconData icon,
    String label,
    String value,
    Color accent,
  ) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: accent, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _colorBubble(Color color, String name) {
    final isSelected = widget.palette.accent.toARGB32() == color.toARGB32();
    return GestureDetector(
      onTap: () {
        final box = Hive.box('gym_cache');
        box.put('custom_theme_accent', color.toARGB32());
        widget.onThemeChanged();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 2.5,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 10,
                spreadRadius: 2,
              ),
          ],
        ),
        child: isSelected
            ? const Icon(Icons.check, color: Colors.black, size: 18)
            : null,
      ),
    );
  }

  Widget _buildSocialTab(GymState state) {
    final activeInGym = state.allMembersIncludingSoftDeleted
        .where((m) => m.isActiveInGym)
        .toList();
    final accent = widget.palette.accent;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(context),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF0066FF).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.share_location_rounded,
                  color: Color(0xFF0066FF),
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Modo Visible (Social)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Permitir que otros vean que estás entrenando hoy.',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Switch(
                value: true,
                onChanged: (val) {},
                activeThumbColor: accent,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        const Text(
          'MIEMBROS ENTRENANDO AHORA',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 12,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        if (activeInGym.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: _cardDecoration(context),
            child: const Column(
              children: [
                Icon(
                  Icons.people_outline_rounded,
                  color: Colors.white30,
                  size: 36,
                ),
                SizedBox(height: 12),
                Text(
                  'Nadie entrenando en este momento.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activeInGym.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.2,
            ),
            itemBuilder: (context, index) {
              final user = activeInGym[index];
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF2C2C2C)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: accent.withValues(alpha: 0.15),
                      child: Text(
                        user.name.substring(0, 2).toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          color: accent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            user.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF00B85C),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Entrenando',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildPhysicalTab(MemberRecord member) {
    final accent = widget.palette.accent;

    final double weight = member.physicalMeasurements['peso'] ?? 70.0;
    final double height = member.physicalMeasurements['altura'] ?? 170.0;
    final double heightCm = height < 3 ? height * 100 : height;
    final String hText = height > 3
        ? '${(height / 100).toStringAsFixed(2)} m'
        : '$height m';

    // Mifflin-St Jeor BMR estimation (assuming 25yo male standard as baseline)
    final double bmr = (10 * weight) + (6.25 * heightCm) - (5 * 25) + 5;

    double multiplier = 1.55;
    if (_selectedActivity == 'Sedentario') multiplier = 1.2;
    if (_selectedActivity == 'Ligero') multiplier = 1.375;
    if (_selectedActivity == 'Moderado') multiplier = 1.55;
    if (_selectedActivity == 'Activo') multiplier = 1.725;

    final double tdee = bmr * multiplier;

    double goalModifier = 0;
    if (_selectedGoal == 'Definición') goalModifier = -500;
    if (_selectedGoal == 'Volumen') goalModifier = 500;

    final double targetCalories = tdee + goalModifier;
    final double protein = weight * 2.0;
    final double fat = weight * 1.0;
    final double proteinCals = protein * 4;
    final double fatCals = fat * 9;
    final double carbs = (targetCalories - proteinCals - fatCals) / 4;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        const Text(
          'MEDIDAS CORPORALES',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 12,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.35,
          children: [
            _buildMetricCard(
              'Peso Corporal',
              '$weight kg',
              Icons.scale_rounded,
              accent,
              'Objetivo: 72 kg',
            ),
            _buildMetricCard(
              'Altura',
              hText,
              Icons.height_rounded,
              const Color(0xFF00E5FF),
              'Fijo',
            ),
            _buildMetricCard(
              'Cintura',
              '${member.physicalMeasurements['cintura'] ?? 0} cm',
              Icons.line_weight_rounded,
              const Color(0xFF8E59FF),
              'Estable',
            ),
            _buildMetricCard(
              'Pecho',
              '${member.physicalMeasurements['pecho'] ?? 0} cm',
              Icons.accessibility_new_rounded,
              const Color(0xFFFF5722),
              'Estable',
            ),
            _buildMetricCard(
              'Cadera',
              '${member.physicalMeasurements['cadera'] ?? 0} cm',
              Icons.wc_rounded,
              const Color(0xFFFF2D55),
              'En progreso',
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'ESTIMACIÓN DE REQUERIMIENTO DIARIO',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 12,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: _cardDecoration(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.calculate_rounded,
                    color: Colors.white70,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Macros y TDEE Sugerido',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Estimación interactiva mediante fórmula Mifflin-St Jeor.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ACTIVIDAD',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.black38,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF2C2C2C)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedActivity,
                              dropdownColor: const Color(0xFF1E1E1E),
                              isExpanded: true,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              items:
                                  [
                                    'Sedentario',
                                    'Ligero',
                                    'Moderado',
                                    'Activo',
                                  ].map((val) {
                                    return DropdownMenuItem<String>(
                                      value: val,
                                      child: Text(val),
                                    );
                                  }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedActivity = val;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'OBJETIVO DEPORTIVO',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.black38,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF2C2C2C)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedGoal,
                              dropdownColor: const Color(0xFF1E1E1E),
                              isExpanded: true,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              items: ['Definición', 'Mantenimiento', 'Volumen']
                                  .map((val) {
                                    return DropdownMenuItem<String>(
                                      value: val,
                                      child: Text(val),
                                    );
                                  })
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedGoal = val;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Center(
                child: Column(
                  children: [
                    const Text(
                      'Energía Diaria Requerida',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${targetCalories.round()} kcal',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: accent,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _macroDetail(
                    'Proteína',
                    '${protein.round()}g',
                    Colors.redAccent,
                  ),
                  _macroDetail(
                    'Carbohidratos',
                    '${carbs.round()}g',
                    const Color(0xFFD2FF3A),
                  ),
                  _macroDetail('Grasas', '${fat.round()}g', Colors.blueAccent),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'EVOLUCIÓN VISUAL (ANTES / DESPUÉS)',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 12,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildProgressPhotoCard(
                'ENERO',
                '78 kg',
                'Antes',
                Colors.grey[850]!,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildProgressPhotoCard(
                'MAYO',
                '74 kg',
                'Después',
                accent.withValues(alpha: 0.2),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _macroDetail(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.white60,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
    String trend,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2C2C2C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(icon, color: color, size: 18),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                trend,
                style: TextStyle(
                  color: color,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressPhotoCard(
    String month,
    String weight,
    String label,
    Color bgColor,
  ) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2C2C2C)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: bgColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.photo_outlined,
                size: 38,
                color: widget.palette.accent.withValues(alpha: 0.3),
              ),
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            child: Text(
              '$month ($weight)',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
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

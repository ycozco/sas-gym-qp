import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/gym_state.dart';
import '../../../models/gym_models.dart';
import '../../../providers/diet_provider.dart';

class MemberDietView extends ConsumerStatefulWidget {
  const MemberDietView({
    super.key,
    required this.palette,
    required this.onBack,
  });

  final RolePalette palette;
  final VoidCallback onBack;

  @override
  ConsumerState<MemberDietView> createState() => _MemberDietViewState();
}

class _MemberDietViewState extends ConsumerState<MemberDietView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchDiet();
    });
  }

  Future<void> _fetchDiet() async {
    final gymState = GymStateProvider.of(context);
    final isOnline = gymState.isOnline;
    final isBackendMode = gymState.isBackendMode;
    await ref
        .read(activeDietProvider.notifier)
        .loadActiveDiet(isOnline: isOnline, isBackendMode: isBackendMode);
  }

  @override
  Widget build(BuildContext context) {
    final dietState = ref.watch(activeDietProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: widget.onBack,
        ),
        title: const Text(
          'MI PLAN DE DIETA',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        color: widget.palette.accent,
        backgroundColor: const Color(0xFF1E1E1E),
        onRefresh: _fetchDiet,
        child: dietState.when(
          loading: () => const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD2FF3A)),
            ),
          ),
          error: (err, stack) => _buildErrorOrEmptyState(
            'Error al cargar tu plan nutricional.',
            'Inténtalo de nuevo más tarde.',
          ),
          data: (diet) {
            if (diet == null) {
              return _buildErrorOrEmptyState(
                'No tienes una dieta activa.',
                'Solicita a tu entrenador asignar un plan de alimentación personalizado.',
              );
            }
            return _buildDietContent(diet);
          },
        ),
      ),
    );
  }

  Widget _buildErrorOrEmptyState(String title, String subtitle) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
      children: [
        const SizedBox(height: 40),
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.restaurant_rounded,
            size: 36,
            color: Colors.white54,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white54, fontSize: 13),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildDietContent(Map<String, dynamic> diet) {
    final pesoObj = (diet['peso_objetivo_kg'] as num?)?.toDouble() ?? 0.0;
    final caloriasObj = (diet['calorias_objetivo'] as num?)?.toInt() ?? 0;
    final proteinas = (diet['proteinas_g'] as num?)?.toDouble() ?? 0.0;
    final carbohidratos = (diet['carbohidratos_g'] as num?)?.toDouble() ?? 0.0;
    final grasas = (diet['grasas_g'] as num?)?.toDouble() ?? 0.0;

    final List<dynamic> comidasList = (diet['comidas'] as List<dynamic>?) ?? [];
    final sugerencias =
        diet['sugerencias']?.toString() ?? 'Sin sugerencias adicionales.';

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
      children: [
        // Target card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2C2C2C)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Calorías Objetivo',
                        style: TextStyle(color: Colors.white60, fontSize: 11),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$caloriasObj kcal',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: const Color(0xFF2C2C2C),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Peso Objetivo',
                        style: TextStyle(color: Colors.white60, fontSize: 11),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pesoObj > 0 ? '$pesoObj kg' : '—',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: Color(0xFF2C2C2C), height: 1),
              const SizedBox(height: 20),

              // Macronutrients distribution
              Row(
                children: [
                  Expanded(
                    child: _buildMacroPip(
                      'PROTEÍNAS',
                      '${proteinas.round()}g',
                      Colors.redAccent,
                      proteinas / 250,
                    ),
                  ),
                  Expanded(
                    child: _buildMacroPip(
                      'CARBOS',
                      '${carbohidratos.round()}g',
                      const Color(0xFFD2FF3A),
                      carbohidratos / 500,
                    ),
                  ),
                  Expanded(
                    child: _buildMacroPip(
                      'GRASAS',
                      '${grasas.round()}g',
                      Colors.blueAccent,
                      grasas / 150,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Meals List
        const Text(
          'CRONOGRAMA DE COMIDAS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),

        ...comidasList.map((meal) {
          final time = meal['hora']?.toString() ?? '00:00';
          final name = meal['nombre']?.toString() ?? 'Comida';
          final detail = meal['alimentos']?.toString() ?? '';
          final kcal = (meal['calorias'] as num?)?.toInt() ?? 0;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF2C2C2C)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Time tag
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF2C2C2C)),
                  ),
                  child: Text(
                    time,
                    style: const TextStyle(
                      color: Color(0xFFD2FF3A),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (kcal > 0)
                            Text(
                              '$kcal kcal',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        detail,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12.5,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 12),
        // Suggestions Card
        const Text(
          'RECOMENDACIONES GENERALES',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF2C2C2C)),
          ),
          child: Text(
            sugerencias,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMacroPip(
    String label,
    String value,
    Color color,
    double percent,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 60,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: percent.clamp(0.01, 1.0),
              backgroundColor: Colors.black26,
              color: color,
              minHeight: 4,
            ),
          ),
        ),
      ],
    );
  }
}

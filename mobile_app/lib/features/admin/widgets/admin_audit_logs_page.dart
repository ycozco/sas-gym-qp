import 'package:flutter/material.dart';
import '../../../data/gym_state.dart';
import '../../../theme/app_theme_tokens.dart';
import '../../../widgets/app_shell.dart';
import '../../../models/gym_models.dart';

class AdminAuditLogsPage extends StatefulWidget {
  const AdminAuditLogsPage({
    super.key,
    required this.palette,
    required this.state,
    required this.filterActor,
    required this.searchQuery,
    required this.onActorChanged,
    required this.onSearchChanged,
    required this.onBack,
  });

  final RolePalette palette;
  final GymState state;
  final String filterActor;
  final String searchQuery;
  final ValueChanged<String> onActorChanged;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onBack;

  @override
  State<AdminAuditLogsPage> createState() => _AdminAuditLogsPageState();
}

class _AdminAuditLogsPageState extends State<AdminAuditLogsPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Carga inicial (refresh)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.state.loadAuditLogs(refresh: true);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (widget.state.hasMoreAuditLogs && !widget.state.loadingMoreAuditLogs) {
        widget.state.loadAuditLogs(refresh: false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sasColors;
    final filteredLogs = widget.state.auditLogs.where((log) {
      final matchesSearch = log.action.toLowerCase().contains(widget.searchQuery.toLowerCase()) ||
          log.detail.toLowerCase().contains(widget.searchQuery.toLowerCase());
      if (!matchesSearch) return false;

      if (widget.filterActor == 'all') return true;
      return log.actor.toLowerCase().contains(widget.filterActor.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Bitácora de Auditoría', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: widget.onBack),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search & Filter header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                TextField(
                  onChanged: widget.onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Filtrar por acción o detalle...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: colors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: widget.palette.accent, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _actorChip(context, 'Todos', 'all'),
                      const SizedBox(width: 6),
                      _actorChip(context, 'Caja', 'Caja'),
                      const SizedBox(width: 6),
                      _actorChip(context, 'Entrenador', 'Trainer'),
                      const SizedBox(width: 6),
                      _actorChip(context, 'Admin', 'Admin'),
                      const SizedBox(width: 6),
                      _actorChip(context, 'SuperAdmin', 'SuperAdmin'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: filteredLogs.isEmpty
                ? Center(child: Text('No hay logs coincidentes.', style: TextStyle(color: colors.textSecondary)))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    itemCount: filteredLogs.length + (widget.state.hasMoreAuditLogs ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == filteredLogs.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD2FF3A)),
                              ),
                            ),
                          ),
                        );
                      }

                      final log = filteredLogs[index];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: LogTile(
                          icon: log.action.contains('Cobró') || log.action.contains('Venta')
                              ? Icons.point_of_sale_rounded
                              : log.action.contains('Creó') || log.action.contains('Registró')
                                  ? Icons.person_add_alt_1_rounded
                                  : log.action.contains('Baja') || log.action.contains('Eliminó')
                                      ? Icons.delete_outline_rounded
                                      : Icons.list_alt_rounded,
                          title: log.action,
                          detail: '${log.detail} · ${log.actor}',
                          time: log.time,
                          color: log.color,
                          locked: true,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _actorChip(BuildContext context, String label, String value) {
    final colors = context.sasColors;
    final isSelected = widget.filterActor == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) widget.onActorChanged(value);
      },
      selectedColor: widget.palette.accent.withValues(alpha: 0.18),
      labelStyle: TextStyle(
        color: isSelected ? widget.palette.accent : colors.textSecondary,
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        fontSize: 11,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      backgroundColor: colors.surfaceAlt,
    );
  }
}

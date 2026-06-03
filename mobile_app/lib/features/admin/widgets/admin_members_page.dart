import 'package:flutter/material.dart';
import '../../../../models/gym_models.dart';
import '../../../../data/gym_state.dart';
import '../../../../widgets/app_shell.dart';
import 'admin_dashboard_page.dart';

class AdminMembersPage extends StatelessWidget {
  const AdminMembersPage({
    super.key,
    required this.palette,
    required this.state,
    required this.searchQuery,
    required this.filterState,
    required this.onSearchChanged,
    required this.onFilterChanged,
    required this.onSelectMember,
    required this.onCreateMember,
  });

  final RolePalette palette;
  final GymState state;
  final String searchQuery;
  final String filterState;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<MemberRecord> onSelectMember;
  final VoidCallback onCreateMember;

  @override
  Widget build(BuildContext context) {
    // Determine which list to filter
    final rawList = filterState == 'baja_logica'
        ? state.allMembersIncludingSoftDeleted.where((m) => m.state == 'baja_logica').toList()
        : state.members;

    // Filter by state and search text
    final filteredMembers = rawList.where((m) {
      final matchesSearch = m.name.toLowerCase().contains(searchQuery.toLowerCase()) || m.dni.contains(searchQuery);
      if (!matchesSearch) return false;

      if (filterState == 'all' || filterState == 'baja_logica') return true;
      return m.state == filterState;
    }).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(child: SectionHeader(title: 'Socios Registrados', action: 'Gestión total')),
              IconButton(
                onPressed: onCreateMember,
                icon: Icon(Icons.add_circle_rounded, color: palette.accent, size: 28),
                tooltip: 'Crear Socio',
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Search Box
          TextField(
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Buscar por nombre o DNI...',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: const Color(0xFF16161A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF232329)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF232329)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: palette.accent, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('Todos', 'all'),
                const SizedBox(width: 6),
                _filterChip('Activos', 'active'),
                const SizedBox(width: 6),
                _filterChip('Vencidos', 'expired'),
                const SizedBox(width: 6),
                _filterChip('En Gracia', 'grace'),
                const SizedBox(width: 6),
                _filterChip('Bajas Lógicas', 'baja_logica'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Members List
          Expanded(
            child: filteredMembers.isEmpty
                ? Center(
                    child: Text(
                      'No se encontraron socios.',
                      style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredMembers.length,
                    itemBuilder: (context, index) {
                      final m = filteredMembers[index];
                      Color stateColor = const Color(0xFF00B85C);
                      if (m.state == 'expired') stateColor = const Color(0xFFFF3B30);
                      if (m.state == 'grace') stateColor = const Color(0xFFFFB300);
                      if (m.state == 'baja_logica') stateColor = const Color(0xFFFF7A1A);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          onTap: () => onSelectMember(m),
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: adminCardDecoration(),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: palette.accent.withValues(alpha: 0.12),
                                  foregroundColor: palette.accent,
                                  child: Text(
                                    m.name.substring(0, m.name.length >= 2 ? 2 : m.name.length).toUpperCase(),
                                    style: const TextStyle(fontWeight: FontWeight.w800),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        m.name,
                                        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'DNI: ${m.dni} · Plan: ${m.goal}',
                                        style: const TextStyle(fontSize: 12, color: Colors.white60, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: stateColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.chevron_right_rounded, color: Colors.white30, size: 20),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String code) {
    final isSelected = filterState == code;
    return GestureDetector(
      onTap: () => onFilterChanged(code),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? palette.accent : const Color(0xFF16161A),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? Colors.transparent : const Color(0xFF2E2E38),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? palette.accentInk : Colors.white70,
          ),
        ),
      ),
    );
  }
}

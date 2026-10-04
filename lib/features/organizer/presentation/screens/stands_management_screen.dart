import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../events/presentation/providers/events_provider.dart';
import '../../data/models/stand_model.dart';
import '../providers/organizer_provider.dart';

class StandsManagementScreen extends ConsumerStatefulWidget {
  const StandsManagementScreen({super.key});

  @override
  ConsumerState<StandsManagementScreen> createState() =>
      _StandsManagementScreenState();
}

class _StandsManagementScreenState
    extends ConsumerState<StandsManagementScreen> {
  String? _selectedEventId;

  static const List<String> _standCategories = [
    'Comida',
    'Arte',
    'Ropa',
    'Bebidas',
    'Accesorios',
    'Servicios',
    'Manualidades',
    'Tecnología',
    'Salud & Bienestar',
    'Juegos',
    'General',
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(eventsProvider.notifier).fetchOrganizerEvents();
      final events = ref.read(eventsProvider).events;
      if (events.isNotEmpty && mounted) {
        final firstId = events.first.id ?? '';
        setState(() {
          _selectedEventId = firstId;
        });
        if (firstId.isNotEmpty) {
          ref.read(standsProvider.notifier).fetchStands(firstId);
        }
      }
    });
  }

  void _onEventChanged(String? newEventId) {
    if (newEventId != null) {
      setState(() => _selectedEventId = newEventId);
      ref.read(standsProvider.notifier).fetchStands(newEventId);
    }
  }

  void _openStandForm({StandModel? standToEdit}) {
    if (_selectedEventId == null) return;

    final nameController =
        TextEditingController(text: standToEdit != null ? standToEdit.name : '');
    String selectedCategory = standToEdit != null &&
            _standCategories.contains(standToEdit.category)
        ? standToEdit.category
        : _standCategories.first;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.black, width: 2),
          ),
          title: Text(
            standToEdit != null ? 'Editar Stand' : 'Nuevo Stand',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Stand / Emprendimiento',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Categoría',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: selectedCategory,
                    items: _standCategories
                        .map((cat) => DropdownMenuItem(
                              value: cat,
                              child: Text(cat),
                            ))
                        .toList(),
                    onChanged: (cat) {
                      if (cat != null) {
                        setDialogState(() => selectedCategory = cat);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar',
                  style: TextStyle(color: AppColors.black)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryYellow,
                foregroundColor: AppColors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: AppColors.black, width: 2),
                ),
              ),
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;

                Navigator.pop(ctx);
                if (standToEdit != null) {
                  final updated = StandModel(
                    id: standToEdit.id,
                    eventId: _selectedEventId,
                    name: name,
                    category: selectedCategory,
                  );
                  await ref
                      .read(standsProvider.notifier)
                      .updateStand(standToEdit.id, updated);
                } else {
                  final newStand = StandModel(
                    id: '',
                    eventId: _selectedEventId,
                    name: name,
                    category: selectedCategory,
                  );
                  await ref
                      .read(standsProvider.notifier)
                      .createStand(_selectedEventId!, newStand);
                }
              },
              child: Text(
                standToEdit != null ? 'ACTUALIZAR' : 'GUARDAR',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteStand(StandModel stand) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.black, width: 2),
        ),
        title: const Text('¿Eliminar Stand?',
            style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text('¿Deseas eliminar el stand "${stand.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar',
                style: TextStyle(color: AppColors.black)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: AppColors.black, width: 2),
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(standsProvider.notifier).deleteStand(stand.id);
            },
            child: const Text('ELIMINAR',
                style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventsState = ref.watch(eventsProvider);
    final standsState = ref.watch(standsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Gestión de Stands',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: AppColors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.black),
            onPressed: () {
              if (_selectedEventId != null) {
                ref.read(standsProvider.notifier).fetchStands(_selectedEventId!);
              }
            },
          ),
        ],
      ),
      body: eventsState.events.isEmpty
          ? const Center(
              child: Text(
                'No tienes eventos para gestionar stands.',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Seleccionar Evento',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.black, width: 2),
                      boxShadow: const [
                        BoxShadow(color: AppColors.black, offset: Offset(3, 3)),
                      ],
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedEventId,
                        items: eventsState.events.map((event) {
                          return DropdownMenuItem<String>(
                            value: event.id,
                            child: Text(
                              event.title,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: _onEventChanged,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Stands Asignados (${standsState.stands.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.black,
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryYellow,
                          foregroundColor: AppColors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(
                                color: AppColors.black, width: 1.5),
                          ),
                        ),
                        onPressed: _openStandForm,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text(
                          'Nuevo Stand',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: standsState.isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: AppColors.black),
                          )
                        : standsState.stands.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.storefront,
                                          size: 64, color: Colors.grey),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'No hay stands asignados a este evento.',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Agrega emprendimientos y stands para el mapa y directorio del evento.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color:
                                              AppColors.black.withOpacity(0.6),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount: standsState.stands.length,
                                itemBuilder: (context, index) {
                                  final stand = standsState.stands[index];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                          color: AppColors.black, width: 2),
                                      boxShadow: const [
                                        BoxShadow(
                                            color: AppColors.black,
                                            offset: Offset(3, 3)),
                                      ],
                                    ),
                                    child: ListTile(
                                      leading: Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryYellow
                                              .withOpacity(0.3),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color: AppColors.black, width: 1.5),
                                        ),
                                        child: const Icon(Icons.storefront,
                                            color: AppColors.black),
                                      ),
                                      title: Text(
                                        stand.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16),
                                      ),
                                      subtitle: Container(
                                        margin: const EdgeInsets.only(top: 4),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade200,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                border: Border.all(
                                                    color: AppColors.black,
                                                    width: 1),
                                              ),
                                              child: Text(
                                                stand.category,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w800,
                                                  color: AppColors.black,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit,
                                                color: AppColors.black,
                                                size: 20),
                                            onPressed: () => _openStandForm(
                                                standToEdit: stand),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete,
                                                color: AppColors.error,
                                                size: 20),
                                            onPressed: () =>
                                                _confirmDeleteStand(stand),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../events/data/models/event_model.dart';
import '../../../events/presentation/providers/events_provider.dart';
import '../providers/organizer_provider.dart';

class ManageEventsScreen extends ConsumerStatefulWidget {
  const ManageEventsScreen({super.key});

  @override
  ConsumerState<ManageEventsScreen> createState() => _ManageEventsScreenState();
}

class _ManageEventsScreenState extends ConsumerState<ManageEventsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(eventsProvider.notifier).fetchOrganizerEvents());
  }

  void _showEditEventModal(BuildContext context, EventModel event) {
    final titleController = TextEditingController(text: event.title);
    final descriptionController =
        TextEditingController(text: event.description);
    final locationController = TextEditingController(text: event.location);
    final capacityController =
        TextEditingController(text: event.quantity.toString());
    final priceController = TextEditingController(text: event.price.toString());
    bool isPublic = event.isPublic;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: AppColors.black, width: 2),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Editar Evento',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Título del Evento',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: locationController,
                      decoration: const InputDecoration(
                        labelText: 'Ubicación / Lugar',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: capacityController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Capacidad',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: priceController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Precio (S/)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text(
                        'Evento Público',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: const Text('Visible para todos los usuarios'),
                      value: isPublic,
                      activeColor: AppColors.primaryYellow,
                      onChanged: (val) => setModalState(() => isPublic = val),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryYellow,
                          foregroundColor: AppColors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(
                                color: AppColors.black, width: 2),
                          ),
                        ),
                        onPressed: () async {
                          final updated = EventModel(
                            id: event.id,
                            title: titleController.text.trim(),
                            description: descriptionController.text.trim(),
                            location: locationController.text.trim(),
                            address: event.address,
                            category: event.category,
                            startDate: event.startDate,
                            endDate: event.endDate,
                            quantity:
                                int.tryParse(capacityController.text) ??
                                    event.quantity,
                            price: double.tryParse(priceController.text) ??
                                event.price,
                            photos: event.photos,
                            isPublic: isPublic,
                            organizer: event.organizer,
                          );

                          try {
                            if (event.id != null) {
                              await ref
                                  .read(organizerRepositoryProvider)
                                  .updateEvent(event.id!, updated);
                            }
                            if (mounted) {
                              Navigator.pop(context);
                              ref
                                  .read(eventsProvider.notifier)
                                  .fetchOrganizerEvents();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Evento actualizado exitosamente'),
                                  backgroundColor: AppColors.lightGreen,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error al actualizar: $e'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          }
                        },
                        child: const Text(
                          'GUARDAR CAMBIOS',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeleteEvent(BuildContext context, EventModel event) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.black, width: 2),
        ),
        title: const Text(
          '¿Eliminar Evento?',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar "${event.title}"? Esta acción no se puede deshacer.',
        ),
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
              try {
                if (event.id != null) {
                  await ref
                      .read(organizerRepositoryProvider)
                      .deleteEvent(event.id!);
                }
                ref.read(eventsProvider.notifier).fetchOrganizerEvents();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Evento eliminado'),
                      backgroundColor: AppColors.black,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al eliminar: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('ELIMINAR',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventsState = ref.watch(eventsProvider);

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
          'Mis Eventos',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: AppColors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.black),
            onPressed: () =>
                ref.read(eventsProvider.notifier).fetchOrganizerEvents(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(eventsProvider.notifier).fetchOrganizerEvents(),
        child: eventsState.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.black),
              )
            : eventsState.events.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.event_note,
                              size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text(
                            'No tienes eventos creados todavía.',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () =>
                                context.push('/organizer/create-event'),
                            icon: const Icon(Icons.add,
                                color: AppColors.black),
                            label: const Text(
                              'Crear Evento',
                              style: TextStyle(
                                  color: AppColors.black,
                                  fontWeight: FontWeight.w800),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryYellow,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: const BorderSide(
                                    color: AppColors.black, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: eventsState.events.length,
                    itemBuilder: (context, index) {
                      final event = eventsState.events[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.black, width: 2),
                          boxShadow: const [
                            BoxShadow(
                                color: AppColors.black, offset: Offset(4, 4)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: event.isPublic
                                                ? AppColors.lightGreen
                                                : Colors.grey.shade300,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            border: Border.all(
                                                color: AppColors.black,
                                                width: 1.5),
                                          ),
                                          child: Text(
                                            event.isPublic
                                                ? 'PÚBLICO'
                                                : 'PRIVADO',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w900,
                                              color: AppColors.black,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          event.title,
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '📍 ${event.location}',
                                          style: TextStyle(
                                            color: AppColors.black
                                                .withOpacity(0.7),
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '👥 Aforo: ${event.quantity}  |  💰 S/ ${event.price.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            color: AppColors.black
                                                .withOpacity(0.7),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert,
                                        color: AppColors.black),
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _showEditEventModal(context, event);
                                      } else if (value == 'delete') {
                                        _confirmDeleteEvent(context, event);
                                      } else if (value == 'stands') {
                                        context.push('/organizer/stands');
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit, size: 18),
                                            SizedBox(width: 8),
                                            Text('Editar evento'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'stands',
                                        child: Row(
                                          children: [
                                            Icon(Icons.storefront, size: 18),
                                            SizedBox(width: 8),
                                            Text('Gestionar stands'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete,
                                                color: AppColors.error,
                                                size: 18),
                                            SizedBox(width: 8),
                                            Text('Eliminar evento',
                                                style: TextStyle(
                                                    color: AppColors.error)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              decoration: const BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                      color: AppColors.black, width: 1.5),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextButton.icon(
                                      onPressed: () => context
                                          .push('/organizer/validate'),
                                      icon: const Icon(Icons.qr_code_scanner,
                                          size: 18, color: AppColors.black),
                                      label: const Text(
                                        'Validar',
                                        style: TextStyle(
                                          color: AppColors.black,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 1.5,
                                    height: 36,
                                    color: AppColors.black,
                                  ),
                                  Expanded(
                                    child: TextButton.icon(
                                      onPressed: () =>
                                          context.push('/organizer/sales'),
                                      icon: const Icon(Icons.bar_chart,
                                          size: 18, color: AppColors.black),
                                      label: const Text(
                                        'Métricas',
                                        style: TextStyle(
                                          color: AppColors.black,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/organizer/create-event'),
        backgroundColor: AppColors.primaryYellow,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.black, width: 2),
        ),
        child: const Icon(Icons.add, color: AppColors.black),
      ),
    );
  }
}

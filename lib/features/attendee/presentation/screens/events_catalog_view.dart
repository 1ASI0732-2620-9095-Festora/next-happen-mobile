import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../events/presentation/providers/events_provider.dart';
import '../../../engagement/presentation/providers/engagement_provider.dart';
import '../providers/tickets_provider.dart';

class EventsCatalogView extends ConsumerStatefulWidget {
  const EventsCatalogView({super.key});

  @override
  ConsumerState<EventsCatalogView> createState() => _EventsCatalogViewState();
}

class _EventsCatalogViewState extends ConsumerState<EventsCatalogView> {
  String _selectedCategory = 'Todos';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(eventsProvider.notifier).fetchPublicEvents();
      ref.read(engagementProvider.notifier).fetchSavedEvents();
    });
  }
  
  Future<void> _handleBuy(String eventId) async {
    // Para simplificar, compramos 1 entrada.
    final success = await ref.read(ticketsProvider.notifier).checkout(eventId, 1);
    if (!success && mounted) {
      final error = ref.read(ticketsProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'No se pudo iniciar el checkout.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final eventsState = ref.watch(eventsProvider);
    final ticketsState = ref.watch(ticketsProvider);

    final allEvents = eventsState.events;
    final categories = ['Todos', ...allEvents.map((e) => e.category).toSet()];
    
    final filteredEvents = _selectedCategory == 'Todos'
        ? allEvents
        : allEvents.where((e) => e.category == _selectedCategory).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.celebration, size: 32, color: AppColors.primaryYellow),
              const SizedBox(width: 12),
              Text(
                '¡Hola, ${user?.fullName ?? 'asistente'}!',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Eventos Disponibles',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              IconButton(
                onPressed: () => ref.read(eventsProvider.notifier).fetchPublicEvents(),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          if (allEvents.isNotEmpty) ...[
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedCategory = cat);
                        }
                      },
                      selectedColor: AppColors.primaryYellow,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: AppColors.black,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(color: AppColors.black, width: 1.5),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (eventsState.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (eventsState.errorMessage != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red, width: 2),
              ),
              child: Text(
                'Error: ${eventsState.errorMessage}',
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            )
          else if (filteredEvents.isEmpty)
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.grey,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.black, width: 2),
              ),
              alignment: Alignment.center,
              child: Text(
                _selectedCategory == 'Todos'
                    ? 'Aún no hay eventos públicos\ndisponibles.'
                    : 'No hay eventos en la categoría $_selectedCategory.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.black.withOpacity(0.5)),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredEvents.length,
              itemBuilder: (context, index) {
                final event = filteredEvents[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.black, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.black,
                        offset: Offset(4, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 140,
                        width: double.infinity,
                        color: AppColors.grey,
                        child: (event.photos.isNotEmpty) 
                          ? Image.network(event.photos.first, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 50, color: Colors.black26))
                          : const Icon(Icons.image, size: 50, color: Colors.black26),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    event.title,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Consumer(
                                  builder: (context, ref, _) {
                                    final isSaved = ref.watch(engagementProvider).savedEventIds.contains(event.id);
                                    return IconButton(
                                      onPressed: () => ref.read(engagementProvider.notifier).toggleSaved(event),
                                      icon: Icon(
                                        isSaved ? Icons.favorite : Icons.favorite_border,
                                        color: isSaved ? Colors.red : AppColors.black,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${event.startDate.toString().substring(0, 10)} • ${event.location}',
                              style: TextStyle(color: AppColors.black.withOpacity(0.7), fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'S/ ${event.price.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primaryYellow),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    context.push('/event-detail', extra: event);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    minimumSize: const Size(0, 36),
                                    backgroundColor: AppColors.primaryYellow,
                                    foregroundColor: AppColors.black,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: const BorderSide(color: AppColors.black, width: 2),
                                    ),
                                  ),
                                  child: const Text('Ver más'),
                                )
                              ],
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

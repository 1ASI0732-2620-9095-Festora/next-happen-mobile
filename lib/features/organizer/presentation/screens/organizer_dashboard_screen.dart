import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../events/presentation/providers/events_provider.dart';

/// Placeholder del panel del organizador, siguiendo la misma estructura
/// del dashboard web que compartiste (tarjetas de resumen + lista de
/// eventos). Aquí se conectará GET /api/events (filtrado por organizador).
class OrganizerDashboardScreen extends ConsumerStatefulWidget {
  const OrganizerDashboardScreen({super.key});

  @override
  ConsumerState<OrganizerDashboardScreen> createState() => _OrganizerDashboardScreenState();
}

class _OrganizerDashboardScreenState extends ConsumerState<OrganizerDashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(eventsProvider.notifier).fetchOrganizerEvents());
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final eventsState = ref.watch(eventsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Panel del organizador',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.black),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hola, ${user?.fullName ?? 'Organizador'} 👋',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Este es el resumen de tus eventos y ventas en NextHappen.',
              style: TextStyle(color: AppColors.black.withOpacity(0.6)),
            ),
            const SizedBox(height: 20),
            Row(
              children: const [
                Expanded(
                  child: _StatCard(
                    label: 'INGRESOS NETOS',
                    value: 'S/. 0.00',
                    background: AppColors.primaryYellow,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(child: _StatCard(label: 'MIS EVENTOS', value: '—')),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: const [
                Expanded(child: _StatCard(label: 'ENTRADAS VENDIDAS', value: '—')),
                SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'VALIDADAS · ASISTENCIA',
                    value: '—',
                    background: AppColors.lightGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tus eventos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                IconButton(
                  onPressed: () => ref.read(eventsProvider.notifier).fetchOrganizerEvents(),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (eventsState.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (eventsState.events.isEmpty)
              Container(
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.grey,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.black, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Aún no has creado ningún evento.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.black.withOpacity(0.5)),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: eventsState.events.length,
                itemBuilder: (context, index) {
                  final event = eventsState.events[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.black, width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.black,
                          offset: Offset(4, 4),
                        ),
                      ],
                    ),
                    child: ListTile(
                      title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text('${event.startDate.toString().substring(0, 10)} - S/ ${event.price}'),
                      trailing: Icon(
                        event.isPublic ? Icons.public : Icons.lock,
                        color: event.isPublic ? AppColors.lightGreen : AppColors.error,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/organizer/create-event'),
        backgroundColor: AppColors.primaryYellow,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.black, width: 2),
        ),
        child: const Icon(Icons.add, color: AppColors.black),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    this.background = Colors.white,
  });

  final String label;
  final String value;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
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
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: AppColors.black.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

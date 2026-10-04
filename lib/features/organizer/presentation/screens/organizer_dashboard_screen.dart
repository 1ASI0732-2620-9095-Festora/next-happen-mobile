import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../events/presentation/providers/events_provider.dart';

class OrganizerDashboardScreen extends ConsumerStatefulWidget {
  const OrganizerDashboardScreen({super.key});

  @override
  ConsumerState<OrganizerDashboardScreen> createState() =>
      _OrganizerDashboardScreenState();
}

class _OrganizerDashboardScreenState
    extends ConsumerState<OrganizerDashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(eventsProvider.notifier).fetchOrganizerEvents());
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final eventsState = ref.watch(eventsProvider);

    final totalEvents = eventsState.events.length;
    final publicEvents = eventsState.events.where((e) => e.isPublic).length;
    final totalCapacity =
        eventsState.events.fold<int>(0, (sum, e) => sum + e.quantity);
    final potentialGross = eventsState.events
        .fold<double>(0.0, (sum, e) => sum + (e.price * e.quantity));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Panel del Organizador',
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
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.black),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(eventsProvider.notifier).fetchOrganizerEvents(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hola, ${user?.fullName ?? 'Organizador'} 👋',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Gestiona tus eventos, controla accesos y supervisa ventas en tiempo real.',
                style: TextStyle(
                  color: AppColors.black.withOpacity(0.65),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),

              // KPI Stats
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'MIS EVENTOS',
                      value: '$totalEvents',
                      background: AppColors.primaryYellow,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'EVENTOS PÚBLICOS',
                      value: '$publicEvents',
                      background: AppColors.lightGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'AFORO TOTAL',
                      value: '$totalCapacity pers.',
                      background: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'POTENCIAL BRUTO',
                      value: 'S/ ${potentialGross.toStringAsFixed(2)}',
                      background: Colors.white,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              const Text(
                'Accesos directos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 12),

              // Quick Actions Grid
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.5,
                children: [
                  _QuickActionCard(
                    title: 'Validar QR',
                    subtitle: 'Control en puerta',
                    icon: Icons.qr_code_scanner,
                    color: AppColors.primaryYellow,
                    onTap: () => context.push('/organizer/validate'),
                  ),
                  _QuickActionCard(
                    title: 'Mis Eventos',
                    subtitle: 'Editar / Eliminar',
                    icon: Icons.edit_calendar,
                    color: AppColors.lightGreen,
                    onTap: () => context.push('/organizer/events'),
                  ),
                  _QuickActionCard(
                    title: 'Métricas',
                    subtitle: 'Ventas y aforo',
                    icon: Icons.bar_chart,
                    color: Colors.white,
                    onTap: () => context.push('/organizer/sales'),
                  ),
                  _QuickActionCard(
                    title: 'Stands',
                    subtitle: 'Gestionar ferias',
                    icon: Icons.storefront,
                    color: Colors.white,
                    onTap: () => context.push('/organizer/stands'),
                  ),
                ],
              ),

              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Eventos recientes',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.black,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/organizer/events'),
                    child: const Text(
                      'Ver todos',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (eventsState.isLoading)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.black),
                  ),
                )
              else if (eventsState.events.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.black, width: 2),
                    boxShadow: const [
                      BoxShadow(color: AppColors.black, offset: Offset(4, 4)),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.event_busy, size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      const Text(
                        'Aún no has creado ningún evento.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () =>
                            context.push('/organizer/create-event'),
                        icon: const Icon(Icons.add, color: AppColors.black),
                        label: const Text(
                          'Crear mi primer evento',
                          style: TextStyle(
                            color: AppColors.black,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryYellow,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(
                                color: AppColors.black, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: eventsState.events.take(5).length,
                  itemBuilder: (context, index) {
                    final event = eventsState.events[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
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
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.primaryYellow.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                              border:
                                  Border.all(color: AppColors.black, width: 2),
                            ),
                            child: const Icon(Icons.event,
                                color: AppColors.black),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  event.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'S/ ${event.price.toStringAsFixed(2)} • ${event.quantity} capacidad',
                                  style: TextStyle(
                                    color: AppColors.black.withOpacity(0.6),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_forward_ios,
                                size: 16, color: AppColors.black),
                            onPressed: () =>
                                context.push('/events/${event.id}'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/organizer/create-event'),
        backgroundColor: AppColors.primaryYellow,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.black, width: 2),
        ),
        icon: const Icon(Icons.add, color: AppColors.black),
        label: const Text(
          'Nuevo Evento',
          style: TextStyle(
            color: AppColors.black,
            fontWeight: FontWeight.w800,
          ),
        ),
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
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: AppColors.black.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.black,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.black, width: 2),
          boxShadow: const [
            BoxShadow(color: AppColors.black, offset: Offset(4, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: AppColors.black),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                color: AppColors.black,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.black.withOpacity(0.65),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../events/presentation/providers/events_provider.dart';
import '../../../attendee/presentation/providers/tickets_provider.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final List<_NotifItem> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadSmartNotifications);
  }

  Future<void> _loadSmartNotifications() async {
    setState(() => _isLoading = true);

    final events = ref.read(eventsProvider).events;
    final tickets = ref.read(ticketsProvider).tickets;

    final List<_NotifItem> items = [];

    // 1. Notificaciones de compras recientes
    for (final t in tickets.where((t) => t.status == 'Active')) {
      items.add(
        _NotifItem(
          id: 'ticket_${t.id}',
          title: 'Entrada Confirmada',
          body: 'Tu pase para "${t.eventTitle ?? 'Evento'}" está listo. Muestra tu código QR en puerta.',
          icon: Icons.confirmation_number_outlined,
          time: 'Activo',
          route: '/home',
        ),
      );
    }

    // 2. Alertas de eventos próximos
    for (final ev in events.take(3)) {
      items.add(
        _NotifItem(
          id: 'event_${ev.id}',
          title: 'Próxima Feria: ${ev.title}',
          body: 'Encuentra las mejores propuestas gastronómicas y artesanales este ${ev.startDate.toLocal().toString().substring(0, 10)}.',
          icon: Icons.calendar_today,
          time: 'Recomendado',
          route: '/home',
        ),
      );
    }

    setState(() {
      _notifications.clear();
      _notifications.addAll(items);
      _isLoading = false;
    });
  }

  void _markAllRead() {
    setState(() {
      for (final n in _notifications) {
        n.isRead = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Todas las notificaciones marcadas como leídas.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('🔔 Notificaciones', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          if (_notifications.isNotEmpty)
            TextButton.icon(
              onPressed: _markAllRead,
              icon: const Icon(Icons.done_all, color: AppColors.black, size: 18),
              label: const Text('Leídas', style: TextStyle(color: AppColors.black, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🔕', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        const Text(
                          'No tienes notificaciones pendientes',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Aquí recibirás recordatorios de tus ferias y compras.',
                          style: TextStyle(color: Colors.black.withValues(alpha: 0.6)),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: _notifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final item = _notifications[i];
                    return GestureDetector(
                      onTap: () {
                        setState(() => item.isRead = true);
                        if (item.route != null) context.push(item.route!);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: item.isRead ? Colors.white : const Color(0xFFFFFBEA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.black,
                            width: item.isRead ? 1.5 : 2,
                          ),
                          boxShadow: const [
                            BoxShadow(color: AppColors.black, offset: Offset(3, 3)),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primaryYellow,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.black, width: 1.5),
                              ),
                              child: Icon(item.icon, size: 20, color: AppColors.black),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.title,
                                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                                        ),
                                      ),
                                      Text(
                                        item.time,
                                        style: TextStyle(fontSize: 11, color: Colors.black.withValues(alpha: 0.5)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.body,
                                    style: const TextStyle(fontSize: 13, height: 1.4),
                                  ),
                                ],
                              ),
                            ),
                            if (!item.isRead) ...[
                              const SizedBox(width: 8),
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: AppColors.error,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class _NotifItem {
  final String id;
  final String title;
  final String body;
  final IconData icon;
  final String time;
  final String? route;
  bool isRead = false;

  _NotifItem({
    required this.id,
    required this.title,
    required this.body,
    required this.icon,
    required this.time,
    this.route,
  });
}

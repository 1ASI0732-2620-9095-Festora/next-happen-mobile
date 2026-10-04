import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../events/presentation/providers/events_provider.dart';
import '../providers/organizer_provider.dart';

class SalesMetricsScreen extends ConsumerStatefulWidget {
  const SalesMetricsScreen({super.key});

  @override
  ConsumerState<SalesMetricsScreen> createState() => _SalesMetricsScreenState();
}

class _SalesMetricsScreenState extends ConsumerState<SalesMetricsScreen> {
  String? _selectedEventId;

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
          ref.read(salesMetricsProvider.notifier).fetchMetrics(firstId);
        }
      }
    });
  }

  void _onEventChanged(String? newEventId) {
    if (newEventId != null) {
      setState(() {
        _selectedEventId = newEventId;
      });
      ref.read(salesMetricsProvider.notifier).fetchMetrics(newEventId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventsState = ref.watch(eventsProvider);
    final metricsState = ref.watch(salesMetricsProvider);
    final metrics = metricsState.metrics;

    final selectedEvent = eventsState.events.firstWhere(
      (e) => e.id == _selectedEventId,
      orElse: () => eventsState.events.isNotEmpty
          ? eventsState.events.first
          : throw Exception('No event'),
    );

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
          'Métricas de Ventas',
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
                ref
                    .read(salesMetricsProvider.notifier)
                    .fetchMetrics(_selectedEventId!);
              }
            },
          ),
        ],
      ),
      body: eventsState.events.isEmpty
          ? const Center(
              child: Text(
                'No tienes eventos para mostrar métricas.',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
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
                  const SizedBox(height: 24),

                  if (metricsState.isLoading)
                    const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                        child:
                            CircularProgressIndicator(color: AppColors.black),
                      ),
                    )
                  else if (metrics != null) ...[
                    // Revenue summary cards
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primaryYellow,
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
                          const Text(
                            'INGRESOS NETOS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                              color: AppColors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'S/ ${metrics.netRevenue.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: AppColors.black,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Bruto: S/ ${metrics.grossRevenue.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.black.withOpacity(0.7),
                                ),
                              ),
                              Text(
                                'Reembolsos: S/ ${metrics.refundedAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.error,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Grid stats
                    Row(
                      children: [
                        Expanded(
                          child: _MetricCard(
                            label: 'ENTRADAS VENDIDAS',
                            value: '${metrics.ticketsSold}',
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MetricCard(
                            label: 'VALIDADAS EN PUERTA',
                            value: '${metrics.ticketsValidated}',
                            color: AppColors.lightGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _MetricCard(
                            label: 'REEMBOLSADAS',
                            value: '${metrics.ticketsRefunded}',
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MetricCard(
                            label: 'CAPACIDAD MÁXIMA',
                            value: '${selectedEvent.quantity}',
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    const Text(
                      'Ocupación del Evento',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Progress bar
                    Container(
                      padding: const EdgeInsets.all(16),
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${metrics.ticketsSold} de ${selectedEvent.quantity} entradas vendidas',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                              Text(
                                '${selectedEvent.quantity > 0 ? ((metrics.ticketsSold / selectedEvent.quantity) * 100).toStringAsFixed(1) : 0}%',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w900, fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: selectedEvent.quantity > 0
                                  ? (metrics.ticketsSold /
                                          selectedEvent.quantity)
                                      .clamp(0.0, 1.0)
                                  : 0,
                              minHeight: 14,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.primaryYellow),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (metrics.byDay.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'Ventas por día',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: metrics.byDay.length,
                        itemBuilder: (context, index) {
                          final item = metrics.byDay[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: AppColors.black, width: 1.5),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  item.date,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  '${item.tickets} entradas • S/ ${item.revenue.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(24),
                      alignment: Alignment.center,
                      child: const Text('No hay datos disponibles para este evento.'),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.black, width: 2),
        boxShadow: const [
          BoxShadow(color: AppColors.black, offset: Offset(3, 3)),
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
              color: AppColors.black.withOpacity(0.65),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.black,
            ),
          ),
        ],
      ),
    );
  }
}

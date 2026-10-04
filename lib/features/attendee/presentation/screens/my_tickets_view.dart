import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../engagement/presentation/providers/engagement_provider.dart';
import '../providers/tickets_provider.dart';

class MyTicketsView extends ConsumerStatefulWidget {
  const MyTicketsView({super.key});

  @override
  ConsumerState<MyTicketsView> createState() => _MyTicketsViewState();
}

class _MyTicketsViewState extends ConsumerState<MyTicketsView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() => ref.read(ticketsProvider.notifier).fetchMyTickets());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleRefund(String ticketId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.black, width: 2),
        ),
        title: const Text('¿Solicitar Reembolso?', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text(
          'Se cancelará tu entrada y se liberará el cupo en el evento.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No, volver', style: TextStyle(color: AppColors.black)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sí, reembolsar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await ref.read(ticketsProvider.notifier).refund(ticketId);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Entrada reembolsada correctamente.'),
          backgroundColor: AppColors.lightGreen,
        ),
      );
    } else {
      final error = ref.read(ticketsProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Error al procesar el reembolso.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticketsState = ref.watch(ticketsProvider);

    final activeTickets = ticketsState.tickets.where((t) => t.status == 'Active').toList();
    final historyTickets = ticketsState.tickets.where((t) => t.status != 'Active').toList();
    final totalSpent = historyTickets.fold<double>(0.0, (acc, t) => acc + t.price);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          '🎟️ Mis Entradas',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
        ),
        actions: [
          IconButton(
            onPressed: () => ref.read(ticketsProvider.notifier).fetchMyTickets(),
            icon: const Icon(Icons.refresh, color: AppColors.black),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.black,
          indicatorWeight: 3,
          labelColor: AppColors.black,
          unselectedLabelColor: Colors.black.withValues(alpha: 0.5),
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          tabs: [
            Tab(text: 'Vigentes (${activeTickets.length})'),
            Tab(text: 'Historial (${historyTickets.length})'),
          ],
        ),
      ),
      body: ticketsState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Pestaña 1: Entradas Vigentes
                _buildTicketsList(activeTickets, isHistory: false),

                // Pestaña 2: Historial
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Resumen de gasto
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryYellow,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.black, width: 2),
                          boxShadow: const [BoxShadow(color: AppColors.black, offset: Offset(4, 4))],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                const Text('Total invertido', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 4),
                                Text('S/. ${totalSpent.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                              ],
                            ),
                            Column(
                              children: [
                                const Text('Boletos registrados', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 4),
                                Text('${historyTickets.length}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildTicketsList(historyTickets, isHistory: true),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTicketsList(List<dynamic> tickets, {required bool isHistory}) {
    if (tickets.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🎟️', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text(
                isHistory ? 'No tienes compras pasadas.' : 'No tienes entradas vigentes.',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: isHistory,
      physics: isHistory ? const NeverScrollableScrollPhysics() : const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      itemCount: tickets.length,
      itemBuilder: (context, index) {
        final ticket = tickets[index];
        final isUsed = ticket.status == 'Used';
        final isRefunded = ticket.status == 'Refunded';

        return Container(
          margin: const EdgeInsets.only(bottom: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.black, width: 2),
            boxShadow: const [BoxShadow(color: AppColors.black, offset: Offset(4, 4))],
          ),
          child: Column(
            children: [
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
                            ticket.eventTitle ?? 'Ticket #${ticket.id.substring(0, 8)}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isUsed
                                ? AppColors.grey
                                : (isRefunded ? AppColors.error : AppColors.lightGreen),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.black, width: 1.5),
                          ),
                          child: Text(
                            ticket.status,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: isRefunded ? Colors.white : AppColors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Precio: S/. ${ticket.price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                        if (ticket.shortCode != null)
                          Text('Código: ${ticket.shortCode}', style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w800)),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // QR Display
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.black, width: 1.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: QrImageView(
                          data: ticket.shortCode ?? ticket.qrCode,
                          version: QrVersions.auto,
                          size: 140.0,
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (!isHistory) ...[
                const Divider(height: 1, thickness: 2, color: AppColors.black),
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        icon: const Icon(Icons.star_outline, size: 18),
                        label: const Text('Reseña'),
                        onPressed: () => _showReviewDialog(context, ticket.eventId),
                      ),
                    ),
                    Container(width: 1, height: 40, color: AppColors.black),
                    Expanded(
                      child: TextButton.icon(
                        icon: const Icon(Icons.undo, color: AppColors.error, size: 18),
                        label: const Text('Reembolso', style: TextStyle(color: AppColors.error)),
                        onPressed: () => _handleRefund(ticket.id),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showReviewDialog(BuildContext context, String eventId) {
    int rating = 5;
    final commentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.black, width: 2),
              ),
              title: const Text('Calificar Evento', style: TextStyle(fontWeight: FontWeight.w800)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        onPressed: () => setState(() => rating = index + 1),
                        icon: Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: AppColors.primaryYellow,
                          size: 32,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: commentCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Cuéntanos tu opinión...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar', style: TextStyle(color: AppColors.black)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryYellow,
                    foregroundColor: AppColors.black,
                  ),
                  onPressed: () async {
                    final success = await ref
                        .read(engagementProvider.notifier)
                        .leaveReview(eventId, rating, commentCtrl.text.trim());
                    if (context.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success ? '¡Reseña guardada!' : 'Error al enviar reseña.'),
                          backgroundColor: success ? AppColors.lightGreen : AppColors.error,
                        ),
                      );
                    }
                  },
                  child: const Text('Publicar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

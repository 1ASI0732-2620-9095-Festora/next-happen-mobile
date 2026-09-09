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

class _MyTicketsViewState extends ConsumerState<MyTicketsView> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(ticketsProvider.notifier).fetchMyTickets());
  }

  @override
  Widget build(BuildContext context) {
    final ticketsState = ref.watch(ticketsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Mis Entradas',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              IconButton(
                onPressed: () => ref.read(ticketsProvider.notifier).fetchMyTickets(),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (ticketsState.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (ticketsState.tickets.isEmpty)
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
                'Aún no tienes entradas.\n¡Compra una en el catálogo!',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.black.withOpacity(0.5)),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: ticketsState.tickets.length,
              itemBuilder: (context, index) {
                final ticket = ticketsState.tickets[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
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
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Ticket #${ticket.id.substring(0, 8)}',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: ticket.status == 'Valid' ? AppColors.lightGreen : AppColors.grey,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                ticket.status,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: QrImageView(
                            data: ticket.qrCode,
                            version: QrVersions.auto,
                            size: 150.0,
                            backgroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Muestra este código al ingreso del evento.',
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _showReviewDialog(context, ticket.eventId),
                            icon: const Icon(Icons.star_outline, color: AppColors.black),
                            label: const Text('Dejar Reseña', style: TextStyle(color: AppColors.black)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.black, width: 2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  void _showReviewDialog(BuildContext context, String eventId) {
    int rating = 5;
    String comment = '';

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
              title: const Text('Dejar una Reseña', style: TextStyle(fontWeight: FontWeight.w800)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('¿Qué te pareció el evento?'),
                  const SizedBox(height: 16),
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
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Comentario',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    onChanged: (val) => comment = val,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar', style: TextStyle(color: AppColors.black)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final success = await ref.read(engagementProvider.notifier).leaveReview(eventId, rating, comment);
                    if (success && mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('¡Reseña enviada!'), backgroundColor: AppColors.lightGreen),
                      );
                    } else if (mounted) {
                      final error = ref.read(engagementProvider).errorMessage;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(error ?? 'Error'), backgroundColor: AppColors.error),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryYellow,
                    foregroundColor: AppColors.black,
                  ),
                  child: const Text('Enviar'),
                ),
              ],
            );
          }
        );
      },
    );
  }
}

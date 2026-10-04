import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../events/data/models/event_model.dart';
import '../../../engagement/presentation/providers/engagement_provider.dart';
import '../../../engagement/data/models/review_model.dart';
import '../providers/tickets_provider.dart';

class EventDetailView extends ConsumerStatefulWidget {
  const EventDetailView({super.key, required this.event});

  final EventModel event;

  @override
  ConsumerState<EventDetailView> createState() => _EventDetailViewState();
}

class _EventDetailViewState extends ConsumerState<EventDetailView> {
  int _quantity = 1;
  int _rating = 5;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmittingReview = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(engagementProvider.notifier).fetchReviews(widget.event.id);
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  double get _totalPrice => widget.event.price * _quantity;

  Future<void> _handleCheckout() async {
    final success = await ref.read(ticketsProvider.notifier).checkout(widget.event.id, _quantity);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Redirigiendo a la pasarela de pago...')),
      );
    } else {
      final error = ref.read(ticketsProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'No se pudo iniciar el pago.')),
      );
    }
  }

  Future<void> _submitReview() async {
    if (_commentController.text.trim().isEmpty) return;
    setState(() => _isSubmittingReview = true);

    try {
      await ref.read(engagementProvider.notifier).addReview(
        widget.event.id,
        _rating,
        _commentController.text.trim(),
      );
      _commentController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Gracias por tu reseña!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar la reseña: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmittingReview = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authUser = ref.watch(authProvider).user;
    final isSaved = ref.watch(engagementProvider.select((s) => s.isEventSaved(widget.event.id)));
    final engagementState = ref.watch(engagementProvider);
    final isCheckoutLoading = ref.watch(ticketsProvider.select((s) => s.isCheckoutLoading));

    final reviews = engagementState.reviewsByEvent[widget.event.id] ?? [];
    final avgRating = reviews.isEmpty
        ? 0.0
        : reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;

    final image = widget.event.photos.isNotEmpty
        ? widget.event.photos.first
        : 'https://placehold.co/600x400?text=NextHappen';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.event.title,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: Icon(
              isSaved ? Icons.favorite : Icons.favorite_border,
              color: isSaved ? AppColors.error : AppColors.black,
            ),
            onPressed: () {
              if (authUser != null) {
                ref.read(engagementProvider.notifier).toggleSaveEvent(widget.event.id);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen de cabecera
            Container(
              height: 220,
              width: double.infinity,
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.black, width: 2)),
              ),
              child: Image.network(
                image,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.grey,
                  child: const Center(child: Icon(Icons.image_not_supported, size: 50)),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Categoría pill
                  if (widget.event.category.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryYellow,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.black, width: 1.5),
                      ),
                      child: Text(
                        widget.event.category,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                    ),
                  const SizedBox(height: 10),

                  // Título
                  Text(
                    widget.event.title,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 12),

                  // Descripción
                  Text(
                    widget.event.description,
                    style: const TextStyle(fontSize: 15, height: 1.5),
                  ),
                  const SizedBox(height: 20),

                  // Especificaciones
                  _buildSpecRow(Icons.calendar_today, 'Fecha',
                      '${widget.event.startDate.toLocal().toString().substring(0, 10)} - ${widget.event.endDate.toLocal().toString().substring(0, 10)}'),
                  const SizedBox(height: 8),
                  _buildSpecRow(Icons.location_on, 'Ubicación', widget.event.address),
                  const SizedBox(height: 8),
                  _buildSpecRow(Icons.confirmation_number_outlined, 'Disponibilidad',
                      '${widget.event.quantity} entradas'),
                  const SizedBox(height: 8),
                  _buildSpecRow(Icons.attach_money, 'Precio unitario',
                      'S/. ${widget.event.price.toStringAsFixed(2)}'),

                  const SizedBox(height: 24),

                  // Tarjeta de Compra
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.black, width: 2),
                      boxShadow: const [BoxShadow(color: AppColors.black, offset: Offset(4, 4))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Comprar Entradas',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Cantidad:', style: TextStyle(fontWeight: FontWeight.w700)),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                                ),
                                Text(
                                  '$_quantity',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: _quantity < widget.event.quantity
                                      ? () => setState(() => _quantity++)
                                      : null,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Divider(thickness: 1.5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total a pagar:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                            Text(
                              'S/. ${_totalPrice.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryYellow,
                              foregroundColor: AppColors.black,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: const BorderSide(color: AppColors.black, width: 2),
                              ),
                              elevation: 0,
                            ),
                            icon: isCheckoutLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.black),
                                  )
                                : const Icon(Icons.credit_card),
                            label: Text(
                              isCheckoutLoading ? 'Procesando…' : 'Comprar Entrada',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                            ),
                            onPressed: (isCheckoutLoading || widget.event.quantity <= 0)
                                ? null
                                : _handleCheckout,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Reseñas y Calificaciones
                  const Text(
                    '⭐ Reseñas y calificaciones',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),

                  // Promedio
                  Row(
                    children: [
                      Text(
                        avgRating.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: List.generate(
                              5,
                              (i) => Icon(
                                i < avgRating.round() ? Icons.star : Icons.star_border,
                                color: AppColors.primaryYellow,
                                size: 20,
                              ),
                            ),
                          ),
                          Text('${reviews.length} reseña(s)', style: TextStyle(color: Colors.black.withValues(alpha: 0.6))),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Formulario de Reseña
                  if (authUser != null)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.black, width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Deja tu reseña', style: TextStyle(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          Row(
                            children: List.generate(5, (index) {
                              final starNum = index + 1;
                              return IconButton(
                                icon: Icon(
                                  starNum <= _rating ? Icons.star : Icons.star_border,
                                  color: AppColors.primaryYellow,
                                ),
                                onPressed: () => setState(() => _rating = starNum),
                              );
                            }),
                          ),
                          TextField(
                            controller: _commentController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText: 'Cuéntanos tu experiencia...',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.black,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: _isSubmittingReview ? null : _submitReview,
                              child: Text(_isSubmittingReview ? 'Enviando…' : 'Publicar reseña'),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Lista de Reseñas
                  if (reviews.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: Text('Aún no hay reseñas. ¡Sé el primero!')),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: reviews.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final r = reviews[i];
                        return _buildReviewTile(r);
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.black),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildReviewTile(ReviewModel r) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.black, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(r.userName, style: const TextStyle(fontWeight: FontWeight.w800)),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < r.rating ? Icons.star : Icons.star_border,
                    color: AppColors.primaryYellow,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          if (r.comment.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(r.comment, style: const TextStyle(fontSize: 14)),
          ],
        ],
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/ticket_repository.dart';
import '../providers/tickets_provider.dart';
import '../screens/attendee_home_screen.dart';

class StripePaymentPendingDialog extends ConsumerStatefulWidget {
  const StripePaymentPendingDialog({
    super.key,
    required this.checkoutResult,
    required this.initialTicketCount,
    required this.eventTitle,
  });

  final CheckoutResult checkoutResult;
  final int initialTicketCount;
  final String eventTitle;

  static Future<bool?> show(
    BuildContext context, {
    required CheckoutResult checkoutResult,
    required int initialTicketCount,
    required String eventTitle,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StripePaymentPendingDialog(
        checkoutResult: checkoutResult,
        initialTicketCount: initialTicketCount,
        eventTitle: eventTitle,
      ),
    );
  }

  @override
  ConsumerState<StripePaymentPendingDialog> createState() =>
      _StripePaymentPendingDialogState();
}

class _StripePaymentPendingDialogState
    extends ConsumerState<StripePaymentPendingDialog> {
  Timer? _pollingTimer;
  bool _isManualChecking = false;
  String? _feedbackMessage;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      _checkPaymentStatus(isAuto: true);
    });
  }

  Future<void> _checkPaymentStatus({bool isAuto = false}) async {
    if (!mounted || _isSuccess) return;

    if (!isAuto) {
      setState(() {
        _isManualChecking = true;
        _feedbackMessage = null;
      });
    }

    try {
      final sessionId = widget.checkoutResult.sessionId;
      bool confirmedByApi = false;

      if (sessionId != null && sessionId.isNotEmpty) {
        confirmedByApi = await ref
            .read(ticketRepositoryProvider)
            .confirmPayment(sessionId);
      }

      await ref.read(ticketsProvider.notifier).fetchMyTickets();

      if (!mounted) return;

      final currentTickets = ref.read(ticketsProvider).tickets;
      final hasNewTicket = currentTickets.length > widget.initialTicketCount;

      if (confirmedByApi || hasNewTicket) {
        _handleSuccess();
        return;
      }

      if (!isAuto && mounted) {
        setState(() {
          _isManualChecking = false;
          _feedbackMessage =
              'Aún no detectamos la confirmación de Stripe. Si ya completaste el pago, espera unos segundos e intenta nuevamente.';
        });
      }
    } catch (_) {
      if (!isAuto && mounted) {
        setState(() {
          _isManualChecking = false;
          _feedbackMessage =
              'No se pudo verificar el estado en este momento. Reintentando automáticamente...';
        });
      }
    }
  }

  void _handleSuccess() {
    _isSuccess = true;
    _pollingTimer?.cancel();

    // Switch tab to Entradas (index 2)
    ref.read(attendeeTabProvider.notifier).state = 2;

    // Pop the dialog
    Navigator.of(context).pop(true);

    // Navigate to /home to guarantee we are on the Home screen with Entradas tab
    context.go('/home');

    // Show celebration snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.black),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                '¡Pago completado con éxito! Tu entrada ya está lista.',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primaryYellow,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColors.black, width: 2),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.black, width: 2.5),
          boxShadow: const [
            BoxShadow(
              color: AppColors.black,
              offset: Offset(5, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Badge / Icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryYellow,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.black, width: 2),
                  ),
                  child: const Icon(
                    Icons.credit_card,
                    color: AppColors.black,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pago con Stripe',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.black,
                        ),
                      ),
                      Text(
                        'Completando tu orden segura',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Event info banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.black, width: 1.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.confirmation_number,
                      size: 20, color: AppColors.black),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.eventTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: AppColors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Status Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.lightGreen,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.black, width: 2),
              ),
              child: Column(
                children: [
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.black),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Esperando confirmación...',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: AppColors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Se abrió Stripe en tu navegador para realizar el pago. Una vez pagado, tu entrada aparecerá aquí automáticamente.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            if (_feedbackMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F0),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error, width: 1.5),
                ),
                child: Text(
                  _feedbackMessage!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Action: "¡Ya completé mi pago!"
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryYellow,
                foregroundColor: AppColors.black,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: AppColors.black, width: 2),
                ),
              ),
              onPressed: _isManualChecking ? null : () => _checkPaymentStatus(),
              child: _isManualChecking
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.black),
                      ),
                    )
                  : const Text(
                      '¡Ya completé mi pago!',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
            ),
            const SizedBox(height: 10),

            // Secondary: Reopen Stripe checkout URL
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.black,
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: AppColors.black, width: 2),
                ),
              ),
              onPressed: () {
                ref
                    .read(ticketRepositoryProvider)
                    .launchCheckoutUrl(widget.checkoutResult.checkoutUrl);
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.open_in_new, size: 16, color: AppColors.black),
                  SizedBox(width: 6),
                  Text(
                    'Reabrir pasarela Stripe',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // Cancel button
            TextButton(
              onPressed: () {
                _pollingTimer?.cancel();
                Navigator.of(context).pop(false);
              },
              child: const Text(
                'Volver al evento (Cancelar)',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

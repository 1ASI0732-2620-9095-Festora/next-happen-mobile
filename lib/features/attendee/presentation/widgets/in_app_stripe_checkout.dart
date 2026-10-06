import 'dart:io';
import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/ticket_repository.dart';
import '../providers/tickets_provider.dart';
import '../screens/attendee_home_screen.dart';
import 'stripe_payment_pending_dialog.dart';

class InAppStripeCheckout {
  InAppStripeCheckout._();

  static Future<void> open({
    required BuildContext context,
    required WidgetRef ref,
    required String checkoutUrl,
    required String eventTitle,
    String? sessionId,
  }) async {
    if (checkoutUrl.isEmpty) return;

    final initialTicketCount = ref.read(ticketsProvider).tickets.length;

    // 1. MODO SIMULACIÓN:
    // Si el backend no tiene Stripe activo, devuelve session_id que empieza con 'sim_'
    // o checkoutUrl ya apunta a /user/checkout/success. En este caso no hay formulario que llenar.
    final isSimulation = (sessionId != null && sessionId.startsWith('sim_')) ||
        checkoutUrl.contains('/user/checkout/success') ||
        checkoutUrl.contains('checkout-success');

    if (isSimulation) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Confirmando orden y emitiendo tu entrada...',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.primaryYellow,
            duration: Duration(seconds: 2),
          ),
        );
      }
      await _handleCheckoutSuccess(context, ref, sessionId);
      return;
    }

    // 2. MODO REAL EN DESKTOP (Windows, macOS, Linux)
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      final isAvailable = await WebviewWindow.isWebviewAvailable();
      if (isAvailable) {
        await _openDesktopCheckout(
          context: context,
          ref: ref,
          checkoutUrl: checkoutUrl,
          eventTitle: eventTitle,
          sessionId: sessionId,
          initialTicketCount: initialTicketCount,
        );
        return;
      }
    }

    // 3. MODO REAL EN MOBILE (Android, iOS)
    if (Platform.isAndroid || Platform.isIOS) {
      final result = await Navigator.of(context).push<dynamic>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (ctx) => _InAppMobileCheckoutScreen(
            checkoutUrl: checkoutUrl,
            eventTitle: eventTitle,
            sessionId: sessionId,
          ),
        ),
      );

      if (result != null && result != false && context.mounted) {
        final confirmedSession = result is String ? result : sessionId;
        await _handleCheckoutSuccess(context, ref, confirmedSession);
      }
      return;
    }

    // 4. FALLBACK: Si no hay WebView disponible
    final uri = Uri.tryParse(checkoutUrl);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (context.mounted) {
        await StripePaymentPendingDialog.show(
          context,
          checkoutResult: CheckoutResult(
            orderId: '',
            checkoutUrl: checkoutUrl,
            sessionId: sessionId,
          ),
          initialTicketCount: initialTicketCount,
          eventTitle: eventTitle,
        );
      }
    }
  }

  static Future<void> _openDesktopCheckout({
    required BuildContext context,
    required WidgetRef ref,
    required String checkoutUrl,
    required String eventTitle,
    required String? sessionId,
    required int initialTicketCount,
  }) async {
    final webview = await WebviewWindow.create(
      configuration: CreateConfiguration(
        title: 'NextHappen - Pago Seguro Stripe',
        windowWidth: 500,
        windowHeight: 760,
        titleBarTopPadding: Platform.isMacOS ? 20 : 0,
      ),
    );

    bool handled = false;

    Future<void> onDetectedSuccess(String? session) async {
      if (handled) return;
      handled = true;
      webview.close();
      await _handleCheckoutSuccess(context, ref, session);
    }

    webview.setOnUrlRequestCallback((url) {
      if (!handled &&
          url != checkoutUrl &&
          (url.contains('/user/checkout/success') ||
              url.contains('checkout-success') ||
              (url.contains('session_id=') && !url.contains('checkout.stripe.com')))) {
        final uri = Uri.tryParse(url);
        final extractedSession = uri?.queryParameters['session_id'] ?? sessionId;
        onDetectedSuccess(extractedSession);
        return true;
      }
      if (!handled &&
          (url.contains('/user/checkout/cancel') || url.contains('checkout-cancel'))) {
        handled = true;
        webview.close();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pago cancelado.')),
          );
        }
        return true;
      }
      return false;
    });

    webview.onClose.then((_) async {
      if (!handled) {
        try {
          if (sessionId != null && sessionId.isNotEmpty) {
            await ref.read(ticketRepositoryProvider).confirmPayment(sessionId);
          }
          await ref.read(ticketsProvider.notifier).fetchMyTickets();
          final ticketsNow = ref.read(ticketsProvider).tickets.length;
          if (ticketsNow > initialTicketCount) {
            await onDetectedSuccess(sessionId);
          }
        } catch (_) {}
      }
    });

    webview.launch(checkoutUrl);
  }

  static Future<void> _handleCheckoutSuccess(
    BuildContext context,
    WidgetRef ref,
    String? sessionId,
  ) async {
    try {
      if (sessionId != null && sessionId.isNotEmpty) {
        await ref.read(ticketRepositoryProvider).confirmPayment(sessionId);
      }
      await ref.read(ticketsProvider.notifier).fetchMyTickets();
    } catch (_) {}

    // Cambiar a la pestaña de Entradas
    ref.read(attendeeTabProvider.notifier).state = AttendeeTabs.tickets;

    if (context.mounted) {
      context.go('/home');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.black),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  '¡Pago completado con éxito! Tu entrada ya está lista 🎟️',
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
  }
}

class _InAppMobileCheckoutScreen extends StatefulWidget {
  const _InAppMobileCheckoutScreen({
    required this.checkoutUrl,
    required this.eventTitle,
    required this.sessionId,
  });

  final String checkoutUrl;
  final String eventTitle;
  final String? sessionId;

  @override
  State<_InAppMobileCheckoutScreen> createState() =>
      _InAppMobileCheckoutScreenState();
}

class _InAppMobileCheckoutScreenState
    extends State<_InAppMobileCheckoutScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _isHandled = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initWebViewController();
  }

  void _initWebViewController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            _checkUrl(url);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (error) {
            if (mounted && error.isForMainFrame == true) {
              setState(() {
                _hasError = true;
                _isLoading = false;
              });
            }
          },
          onNavigationRequest: (request) {
            if (_checkUrl(request.url)) {
              return NavigationDecision.prevent;
            }
            if (!request.url.startsWith('http://') &&
                !request.url.startsWith('https://')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );

    try {
      _controller.loadRequest(Uri.parse(widget.checkoutUrl));
    } catch (_) {
      setState(() => _hasError = true);
    }
  }

  bool _checkUrl(String url) {
    if (_isHandled) return true;

    // Solo interceptar redirección de éxito final
    if (url != widget.checkoutUrl &&
        (url.contains('/user/checkout/success') ||
            url.contains('checkout-success') ||
            (url.contains('session_id=') &&
                !url.contains('checkout.stripe.com')))) {
      _isHandled = true;
      final uri = Uri.tryParse(url);
      final extractedSession =
          uri?.queryParameters['session_id'] ?? widget.sessionId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pop(extractedSession ?? true);
        }
      });
      return true;
    }

    if (url.contains('/user/checkout/cancel') ||
        url.contains('checkout-cancel')) {
      _isHandled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pop(false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pago cancelado.')),
          );
        }
      });
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryYellow,
        elevation: 0,
        shape: const Border(
          bottom: BorderSide(color: AppColors.black, width: 2),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pago Seguro Stripe 💳',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.black,
              ),
            ),
            Text(
              widget.eventTitle,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.black),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        bottom: _isLoading
            ? const PreferredSize(
                preferredSize: Size.fromHeight(3),
                child: LinearProgressIndicator(
                  backgroundColor: AppColors.grey,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.black),
                ),
              )
            : null,
      ),
      body: _hasError
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off, size: 48, color: AppColors.error),
                    const SizedBox(height: 12),
                    const Text(
                      'No se pudo conectar a la pasarela',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Verifica tu conexión a internet o intenta nuevamente.',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryYellow,
                        foregroundColor: AppColors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: AppColors.black, width: 2),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _hasError = false;
                          _isLoading = true;
                        });
                        _controller.loadRequest(Uri.parse(widget.checkoutUrl));
                      },
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            )
          : WebViewWidget(controller: _controller),
    );
  }
}

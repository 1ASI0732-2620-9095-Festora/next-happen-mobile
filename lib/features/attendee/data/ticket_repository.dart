import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import 'models/ticket_model.dart';

class CheckoutResult {
  final String orderId;
  final String checkoutUrl;
  final String? sessionId;

  const CheckoutResult({
    required this.orderId,
    required this.checkoutUrl,
    this.sessionId,
  });
}

class TicketRepository {
  TicketRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<TicketModel>> getUserTickets(String userId) async {
    try {
      final response = await _apiClient.dio.get<List<dynamic>>(
        ApiConstants.userTickets(userId),
      );
      return response.data!
          .map((e) => TicketModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  Future<CheckoutResult> checkoutEvent(String eventId, int quantity) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        ApiConstants.checkout,
        data: {
          'eventId': eventId,
          'quantity': quantity,
        },
      );
      
      final data = response.data ?? {};
      final checkoutUrl = data['checkoutUrl'] as String? ?? '';
      final orderId = data['orderId']?.toString() ?? '';
      var sessionId = data['sessionId'] as String?;

      if ((sessionId == null || sessionId.isEmpty) && checkoutUrl.isNotEmpty) {
        final uri = Uri.tryParse(checkoutUrl);
        if (uri != null) {
          sessionId = uri.queryParameters['session_id'];
          if (sessionId == null && uri.pathSegments.isNotEmpty) {
            final csSegment = uri.pathSegments.firstWhere(
              (s) => s.startsWith('cs_'),
              orElse: () => '',
            );
            if (csSegment.isNotEmpty) sessionId = csSegment;
          }
        }
      }

      return CheckoutResult(
        orderId: orderId,
        checkoutUrl: checkoutUrl,
        sessionId: sessionId,
      );
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  Future<bool> launchCheckoutUrl(String checkoutUrl) async {
    if (checkoutUrl.isEmpty) return false;
    final uri = Uri.tryParse(checkoutUrl);
    if (uri == null) return false;
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (launched) return true;
    } catch (_) {}
    try {
      return await launchUrl(uri);
    } catch (_) {
      return false;
    }
  }

  Future<bool> confirmPayment(String sessionId) async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        ApiConstants.confirmPayment(sessionId),
      );
      final data = response.data ?? {};
      final status = data['status']?.toString();
      return data['paid'] == true || status == 'Paid';
    } catch (_) {
      return false;
    }
  }

  Future<void> refundTicket(String ticketId) async {
    try {
      await _apiClient.dio.post<dynamic>(
        ApiConstants.refundTicket(ticketId),
      );
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  ApiException _asApiException(DioException e) {
    if (e.error is ApiException) return e.error as ApiException;
    return ApiException(
      message: e.message ?? 'Ocurrió un error con la operación de tickets.',
      statusCode: e.response?.statusCode,
    );
  }
}

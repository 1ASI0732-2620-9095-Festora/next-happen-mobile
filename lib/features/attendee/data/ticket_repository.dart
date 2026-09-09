import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import 'models/ticket_model.dart';

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

  Future<bool> checkoutEvent(String eventId, int quantity) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        ApiConstants.checkout,
        data: {
          'eventId': eventId,
          'quantity': quantity,
        },
      );
      
      final checkoutUrl = response.data!['checkoutUrl'] as String?;
      if (checkoutUrl != null) {
        final uri = Uri.parse(checkoutUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return true;
        }
      }
      return false;
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  ApiException _asApiException(DioException e) {
    if (e.error is ApiException) return e.error as ApiException;
    return ApiException(
      message: e.message ?? 'Ocurrió un error con la compra.',
      statusCode: e.response?.statusCode,
    );
  }
}

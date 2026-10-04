import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../events/data/models/event_model.dart';
import 'models/event_attendee_model.dart';
import 'models/sales_metrics_model.dart';
import 'models/stand_model.dart';
import 'models/validate_response_model.dart';

class OrganizerRepository {
  OrganizerRepository(this._apiClient);

  final ApiClient _apiClient;

  // -- Events --

  Future<EventModel> updateEvent(String eventId, EventModel event) async {
    try {
      final data = event.toJson();
      data.remove('id');
      data.remove('organizer');

      final response = await _apiClient.dio.put<Map<String, dynamic>>(
        ApiConstants.eventDetail(eventId),
        data: data,
      );
      return EventModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  Future<void> deleteEvent(String eventId) async {
    try {
      await _apiClient.dio.delete<dynamic>(
        ApiConstants.eventDetail(eventId),
      );
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  // -- Tickets & Door Control --

  Future<List<EventAttendeeModel>> getEventAttendees(String eventId) async {
    try {
      final response = await _apiClient.dio.get<List<dynamic>>(
        ApiConstants.eventTickets(eventId),
      );
      return response.data!
          .map((e) => EventAttendeeModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  Future<ValidateResponseModel> validateTicket(String qrCode) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        ApiConstants.validateTicket,
        data: {'qrCode': qrCode},
      );
      return ValidateResponseModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  // -- Sales Dashboard --

  Future<SalesMetricsModel> getEventSales(String eventId) async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        ApiConstants.eventSales(eventId),
      );
      return SalesMetricsModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  // -- Stands --

  Future<List<StandModel>> getStands(String eventId) async {
    try {
      final response = await _apiClient.dio.get<List<dynamic>>(
        ApiConstants.eventStands(eventId),
      );
      return response.data!
          .map((e) => StandModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  Future<StandModel> createStand(String eventId, StandModel stand) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        ApiConstants.eventStands(eventId),
        data: stand.toJson(),
      );
      return StandModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  Future<StandModel> updateStand(String standId, StandModel stand) async {
    try {
      final response = await _apiClient.dio.put<Map<String, dynamic>>(
        ApiConstants.standDetail(standId),
        data: stand.toJson(),
      );
      return StandModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  Future<void> deleteStand(String standId) async {
    try {
      await _apiClient.dio.delete<dynamic>(
        ApiConstants.standDetail(standId),
      );
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  ApiException _asApiException(DioException e) {
    if (e.response?.statusCode == 403) {
      return ApiException(
        message: 'No tienes permiso para modificar este evento.',
        statusCode: 403,
      );
    }
    if (e.error is ApiException) return e.error as ApiException;
    return ApiException(
      message: e.message ?? 'Ocurrió un error en el panel de administrador.',
      statusCode: e.response?.statusCode,
    );
  }
}

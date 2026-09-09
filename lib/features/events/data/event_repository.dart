import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import 'models/event_model.dart';

class EventRepository {
  EventRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<EventModel>> getPublicEvents() async {
    try {
      final response = await _apiClient.dio.get<List<dynamic>>(ApiConstants.eventsPublic);
      return response.data!
          .map((e) => EventModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  Future<List<EventModel>> getOrganizerEvents() async {
    try {
      final response = await _apiClient.dio.get<List<dynamic>>(ApiConstants.events);
      return response.data!
          .map((e) => EventModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  Future<EventModel> createEvent(EventModel event) async {
    try {
      // Create JSON omitting id and organizer, handled by backend
      final data = event.toJson();
      data.remove('id');
      data.remove('organizer');

      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        ApiConstants.events,
        data: data,
      );
      return EventModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  ApiException _asApiException(DioException e) {
    if (e.error is ApiException) return e.error as ApiException;
    return ApiException(
      message: e.message ?? 'Ocurrió un error inesperado con los eventos.',
      statusCode: e.response?.statusCode,
    );
  }
}

import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../events/data/models/event_model.dart';
import 'models/review_model.dart';

class EngagementRepository {
  EngagementRepository(this._apiClient);

  final ApiClient _apiClient;

  // -- Favoritos (Saved Events) --

  Future<void> saveEvent(String userId, String eventId) async {
    try {
      await _apiClient.dio.post<dynamic>(
        ApiConstants.savedEvent(userId, eventId),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        // Ya estaba guardado, podemos ignorar o manejar si se desea
        return;
      }
      throw _asApiException(e);
    }
  }

  Future<void> removeSavedEvent(String userId, String eventId) async {
    try {
      await _apiClient.dio.delete<dynamic>(
        ApiConstants.savedEvent(userId, eventId),
      );
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  Future<List<EventModel>> getSavedEvents(String userId) async {
    try {
      final response = await _apiClient.dio.get<List<dynamic>>(
        ApiConstants.savedEventsList(userId),
      );
      return response.data!
          .map((e) => EventModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  // -- Reseñas (Reviews) --

  Future<ReviewModel> createReview(String eventId, int rating, String comment) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        ApiConstants.eventReviews(eventId),
        data: {
          'rating': rating,
          'comment': comment,
        },
      );
      return ReviewModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  ApiException _asApiException(DioException e) {
    if (e.error is ApiException) return e.error as ApiException;
    return ApiException(
      message: e.message ?? 'Ocurrió un error en engagement.',
      statusCode: e.response?.statusCode,
    );
  }
}

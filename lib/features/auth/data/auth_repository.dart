import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'models/auth_response_model.dart';
import 'models/user_role.dart';

class AuthRepository {
  AuthRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<AuthResponseModel> login({
    required String email,
    required String password,
    UserRole role = UserRole.user,
  }) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        ApiConstants.login,
        data: {
          'email': email,
          'password': password,
          'role': role.apiValue,
        },
      );
      return AuthResponseModel.fromJson(response.data!, fallbackRole: role);
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    UserRole role = UserRole.user,
  }) async {
    try {
      await _apiClient.dio.post<Map<String, dynamic>>(
        ApiConstants.register,
        data: {
          'fullName': fullName,
          'email': email,
          'password': password,
          'role': role.apiValue,
        },
      );
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  ApiException _asApiException(DioException e) {
    if (e.error is ApiException) return e.error as ApiException;
    return ApiException(
      message: e.message ?? 'Ocurrió un error inesperado.',
      statusCode: e.response?.statusCode,
    );
  }
}

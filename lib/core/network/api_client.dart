import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../storage/secure_storage_service.dart';
import 'api_exception.dart';


class ApiClient {
  ApiClient(this._storage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.readToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (DioException error, handler) {
          handler.next(_mapError(error));
        },
      ),
    );
  }

  late final Dio _dio;
  final SecureStorageService _storage;

  Dio get dio => _dio;

  DioException _mapError(DioException error) {
    final data = error.response?.data;
    final statusCode = error.response?.statusCode;

    // Si es un 403 Forbidden (no tiene permisos)
    if (statusCode == 403) {
      return error.copyWith(
        error: ApiException(
          message: 'No tienes permisos de Organizador para crear eventos. Asegúrate de haberte registrado como Organizador.',
          statusCode: statusCode,
        ),
      );
    }

    // Si el backend devolvió nuestro propio formato {"error": "..."}
    if (data is Map && data['error'] != null) {
      return error.copyWith(
        error: ApiException(
          message: data['error'].toString(),
          statusCode: statusCode,
        ),
      );
    }

    // Si es un error de validación automático de ASP.NET (ej. {"errors": {"Title": ["..."]}})
    if (data is Map && data['errors'] != null) {
      final errors = data['errors'] as Map;
      final firstError = errors.values.first;
      final errorMessage = firstError is List ? firstError.first.toString() : firstError.toString();
      return error.copyWith(
        error: ApiException(
          message: 'Error de formato: $errorMessage',
          statusCode: statusCode,
        ),
      );
    }

    final isConnectionIssue = error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout;

    // Agregamos el contenido de "data" al mensaje para saber exactamente qué responde el servidor
    final serverResponse = data != null ? data.toString() : statusCode.toString();

    return error.copyWith(
      error: ApiException(
        message: isConnectionIssue
            ? 'No se pudo conectar con el servidor. Verifica que el backend esté corriendo.'
            : 'Error del servidor ($serverResponse). Intenta de nuevo.',
        statusCode: statusCode,
      ),
    );
  }
}

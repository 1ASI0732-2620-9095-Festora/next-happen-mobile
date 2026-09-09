
class ApiException implements Exception {
  const ApiException({required this.message, this.statusCode});

  final String message;
  final int? statusCode;

  bool get isUnauthorized => statusCode == 401;
  bool get isBadRequest => statusCode == 400;

  @override
  String toString() => message;
}

import 'package:nexthappen/features/auth/data/models/user_role.dart';

import 'user_model.dart';

/// Modelo de la respuesta de POST /api/auth/login y /api/auth/register.
///
/// ⚠️ IMPORTANTE: tu documentación confirma que el endpoint "devolverá los
/// datos del usuario junto con el Token JWT", pero no el nombre exacto del
/// campo del token ni si el usuario viene anidado. Prueba el endpoint real
/// (Postman/Swagger) y ajusta este modelo si hace falta — ya cubre los
/// nombres más comunes (`token`/`accessToken`/`jwt`) como primer intento.
class AuthResponseModel {
  const AuthResponseModel({required this.token, required this.user});

  final String token;
  final UserModel user;

  factory AuthResponseModel.fromJson(Map<String, dynamic> json, {UserRole? fallbackRole}) {
    final token = (json['token'] ?? json['accessToken'] ?? json['jwt'] ?? '')
        .toString();

    // Algunos backends anidan el usuario en "user", otros devuelven
    // sus campos al mismo nivel que el token. Soportamos ambos casos.
    final userJson = json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : json;

    return AuthResponseModel(
      token: token,
      user: UserModel.fromJson(userJson, fallbackRole: fallbackRole),
    );
  }
}

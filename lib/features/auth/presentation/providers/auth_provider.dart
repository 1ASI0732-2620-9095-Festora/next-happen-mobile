import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../data/auth_repository.dart';
import '../../data/models/user_model.dart';
import '../../data/models/user_role.dart';

// ---- Dependencias (inyección simple vía Riverpod) ----

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.watch(secureStorageProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(apiClientProvider));
});

// ---- Estado de autenticación ----

enum AuthStatus { checking, authenticated, unauthenticated }

class AuthState {
  const AuthState({
    this.status = AuthStatus.checking,
    this.user,
    this.isSubmitting = false,
    this.errorMessage,
  });

  final AuthStatus status;
  final UserModel? user;
  final bool isSubmitting;
  final String? errorMessage;

  bool get isOrganizer => user?.role.isOrganizer ?? false;

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    bool? isSubmitting,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repository, this._storage) : super(const AuthState()) {
    _restoreSession();
  }

  final AuthRepository _repository;
  final SecureStorageService _storage;

  /// Al abrir la app, revisa si ya hay un token guardado para no pedir
  /// login de nuevo. Nota: esto solo verifica que exista un token; para
  /// producción conviene agregar un endpoint tipo /api/auth/me que valide
  /// el token contra el backend y refresque los datos del usuario.
  Future<void> _restoreSession() async {
    final hasSession = await _storage.hasSession();
    if (hasSession) {
      final roleStr = await _storage.readRole();
      final idStr = await _storage.readUserId();
      final role = UserRoleX.fromApiValue(roleStr);
      
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: UserModel(id: idStr ?? '', fullName: 'Usuario', email: '', role: role),
      );
    } else {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login({
    required String email,
    required String password,
    UserRole role = UserRole.user,
  }) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      final response = await _repository.login(
        email: email,
        password: password,
        role: role,
      );
      await _storage.saveSession(
        token: response.token,
        role: response.user.role.apiValue,
        userId: response.user.id,
      );
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: response.user,
        isSubmitting: false,
      );
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: e.toString());
    }
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    UserRole role = UserRole.user,
  }) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      await _repository.register(
        fullName: fullName,
        email: email,
        password: password,
        role: role,
      );
      
      // El registro solo devuelve "User created successfully". No devuelve Token.
      // Así que iniciamos sesión automáticamente para obtener el JWT y los datos reales.
      await login(email: email, password: password, role: role);
      
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: e.toString());
    }
  }

  Future<void> logout() async {
    await _storage.clearSession();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.watch(authRepositoryProvider),
    ref.watch(secureStorageProvider),
  );
});

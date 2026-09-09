/// Roles según tu backend: el controlador de eventos espera "Organizer"
/// o "Admin" para poder crear eventos; "User" es el rol por defecto.
enum UserRole { user, organizer, admin }

extension UserRoleX on UserRole {
  /// Valor exacto que espera el backend en el campo "role".
  String get apiValue {
    switch (this) {
      case UserRole.user:
        return 'User';
      case UserRole.organizer:
        return 'Organizer';
      case UserRole.admin:
        return 'Admin';
    }
  }

  static UserRole fromApiValue(String? value) {
    if (value == null) return UserRole.user;
    final lower = value.toLowerCase();
    switch (lower) {
      case 'organizer':
        return UserRole.organizer;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.user;
    }
  }

  /// Organizadores y Admins ven el panel de organizador.
  bool get isOrganizer => this == UserRole.organizer || this == UserRole.admin;
}

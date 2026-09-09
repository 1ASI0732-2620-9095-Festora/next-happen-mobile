import 'user_role.dart';

class UserModel {
  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
  });

  final String id;
  final String fullName;
  final String email;
  final UserRole role;

  factory UserModel.fromJson(Map<String, dynamic> json, {UserRole? fallbackRole}) {
    final name = (json['fullName'] ?? json['name'] ?? '').toString();
    final emailStr = (json['email'] ?? '').toString();
    
    return UserModel(
      id: (json['userId'] ?? json['id'] ?? json['_id'] ?? '').toString(),
      fullName: name.isNotEmpty ? name : (emailStr.isNotEmpty ? emailStr.split('@')[0] : 'Usuario'),
      email: emailStr,
      role: json['role'] != null 
          ? UserRoleX.fromApiValue(json['role']?.toString())
          : (fallbackRole ?? UserRole.user),
    );
  }
}

import 'package:ornek_flutter_web/models/user_profile_model.dart';
import 'package:ornek_flutter_web/models/role_model.dart';

class UserWithRole {
  final UserProfile user;
  final Role? role;

  UserWithRole({
    required this.user,
    this.role,
  });
} 
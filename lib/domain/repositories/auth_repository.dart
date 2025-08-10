import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity?> signUp(String email, String password, UserType userType);
  Future<UserEntity?> login(String email, String password);
  Future<void> logout();
  Future<UserEntity?> getCurrentUser();
}

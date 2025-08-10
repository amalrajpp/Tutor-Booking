enum UserType { student, tutor }

class UserEntity {
  final String uid;
  final String email;
  final UserType userType;

  UserEntity({required this.uid, required this.email, required this.userType});
}

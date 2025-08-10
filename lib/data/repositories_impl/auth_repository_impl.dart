import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Future<UserEntity?> signUp(
    String email,
    String password,
    UserType userType,
  ) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = userCredential.user!.uid;

    final firestore = FirebaseFirestore.instance;

    final baseData = {
      'email': email,
      'userType': userType.name, // optional for debugging
      'isProfileComplete': false,
      'createdAt': FieldValue.serverTimestamp(),
    };

    if (userType == UserType.student) {
      await firestore.collection('students').doc(uid).set(baseData);
    } else {
      await firestore.collection('tutors').doc(uid).set(baseData);
    }

    return UserEntity(uid: uid, email: email, userType: userType);
  }

  @override
  Future<UserEntity?> login(String email, String password) async {
    final userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    // Assume you have stored userType in Firestore or SharedPrefs
    return UserEntity(
      uid: userCredential.user!.uid,
      email: email,
      userType: UserType.student,
    ); // TEMP
  }

  @override
  Future<void> logout() => _auth.signOut();

  @override
  Future<UserEntity?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return UserEntity(
      uid: user.uid,
      email: user.email ?? '',
      userType: UserType.student,
    ); // TEMP
  }
}

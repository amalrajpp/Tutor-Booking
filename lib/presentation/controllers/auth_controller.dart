import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthController extends GetxController {
  final AuthRepository authRepository;

  var user = Rxn<UserEntity>();
  // In your AuthController
  final isLoading = false.obs;

  AuthController(this.authRepository);

  @override
  void onInit() {
    super.onInit();
    autoLogin();
  }

  Future<void> signUp(String email, String password, UserType type) async {
    user.value = await authRepository.signUp(email, password, type);
  }

  Future<void> login(String email, String password) async {
    user.value = await authRepository.login(email, password);
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid != null) {
      final firestore = FirebaseFirestore.instance;

      final studentDoc = await firestore.collection('students').doc(uid).get();
      if (studentDoc.exists) {
        final isComplete = studentDoc.data()?['isProfileComplete'] ?? false;
        if (!isComplete) {
          Get.offAllNamed('/studentDetails');
        } else {
          Get.offAllNamed('/studentHome');
        }
        return;
      }

      final tutorDoc = await firestore.collection('tutors').doc(uid).get();
      if (tutorDoc.exists) {
        final isComplete = tutorDoc.data()?['isProfileComplete'] ?? false;
        if (!isComplete) {
          Get.offAllNamed('/tutorDetails');
        } else {
          Get.offAllNamed('/tutorHome');
        }
        return;
      }

      // If neither doc exists — should never happen unless something failed
      Get.snackbar('Error', 'User not found in student or tutor collection');
    }
  }

  Future<void> logout() async {
    await authRepository.logout();
    user.value = null;
    Get.offAllNamed('/login'); // or replace with Get.offAll() if needed
  }

  Future<void> autoLogin() async {
    final current = await authRepository.getCurrentUser();
    if (current != null) {
      user.value = current;
      // Firestore logic to check profile completion and route user
      final uid = current.uid;
      final firestore = FirebaseFirestore.instance;

      final studentDoc = await firestore.collection('students').doc(uid).get();
      if (studentDoc.exists) {
        final isComplete = studentDoc.data()?['isProfileComplete'] ?? false;
        if (!isComplete) {
          Get.offAllNamed('/studentDetails');
        } else {
          Get.offAllNamed('/studentHome');
        }
        return;
      }

      final tutorDoc = await firestore.collection('tutors').doc(uid).get();
      if (tutorDoc.exists) {
        final isComplete = tutorDoc.data()?['isProfileComplete'] ?? false;
        if (!isComplete) {
          Get.offAllNamed('/tutorDetails');
        } else {
          Get.offAllNamed('/tutorHome');
        }
        return;
      }
      Get.offAllNamed('/login');
    } else {
      Get.offAllNamed('/login');
    }
  }

  // ... rest of your AuthController (signUp, login, logout) ...
}

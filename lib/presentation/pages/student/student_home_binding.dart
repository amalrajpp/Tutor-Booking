// In a new file, e.g., lib/presentation/bindings/tutor_home_binding.dart

import 'package:get/get.dart';
import 'package:karreoapp/presentation/controllers/student_home_controller.dart';

class StudentHomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => StudentHomeController());
  }
}

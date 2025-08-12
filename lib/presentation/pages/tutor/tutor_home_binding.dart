// In a new file, e.g., lib/presentation/bindings/tutor_home_binding.dart

import 'package:get/get.dart';
import 'package:karreoapp/presentation/controllers/tutor_home_controller.dart';

class TutorHomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => TutorHomeController());
  }
}

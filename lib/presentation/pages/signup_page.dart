import 'dart:ui';

import 'package:animate_do/animate_do.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../domain/entities/user_entity.dart';
import '../controllers/auth_controller.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  // --- STATE AND CONTROLLERS (LOGIC UNCHANGED) ---
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final confirmPassCtrl = TextEditingController();

  final isStudent = true.obs;
  final isObscured = true.obs;
  final isConfirmObscured = true.obs;
  final isLoading = false.obs;

  final formKey = GlobalKey<FormState>();

  // --- UNIFIED COLOR PALETTE FROM LOGIN PAGE ---
  final Color primaryColor = const Color(0xFF37A93C);
  final Color backgroundColor = const Color(0xFFEDF7EE);
  final Color textColor = const Color(0xFF0A3622);
  final Color subtleTextColor = const Color(0xFF556B61);

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    confirmPassCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check if the keyboard is visible
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            // LAYER 1: Header (Conditionally rendered)
            // The header is only visible if the keyboard is not.
            if (!isKeyboardVisible)
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(top: 40.0),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: _buildHeader(),
                  ),
                ),
              ),

            // LAYER 2: The Floating Glassmorphic Panel
            Align(
              alignment: Alignment.bottomCenter,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // If keyboard is up, panel can take more space.
                  // Otherwise, reserve space for the header.
                  final double topClearance = isKeyboardVisible ? 0 : 180.0;
                  final maxPanelHeight = constraints.maxHeight - topClearance;

                  return _buildFloatingPanel(maxPanelHeight);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- HEADER WIDGET ---
  Widget _buildHeader() {
    return FadeInDown(
      duration: const Duration(milliseconds: 600),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/images/title.png', height: 45),
          const SizedBox(height: 16),
          Text(
            "Create Your Account",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  // --- FLOATING PANEL WIDGET (WITH MAX HEIGHT CONSTRAINT) ---
  Widget _buildFloatingPanel(double maxPanelHeight) {
    final controller = Get.find<AuthController>();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: SlideInUp(
        duration: const Duration(milliseconds: 800),
        delay: const Duration(milliseconds: 200),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
            child: Container(
              constraints: BoxConstraints(maxHeight: maxPanelHeight),
              padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.55),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(35),
                ),
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
              ),
              child: Form(
                key: formKey,
                autovalidateMode: AutovalidateMode.disabled,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        "Join the Community!",
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      Text(
                        "Let's get you started on your path.",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: subtleTextColor,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildInputField(
                        controller: emailCtrl,
                        hintText: "Email address",
                        validator: (v) => v != null && GetUtils.isEmail(v)
                            ? null
                            : "Please enter a valid email",
                      ),
                      const SizedBox(height: 16),
                      Obx(
                        () => _buildInputField(
                          controller: passCtrl,
                          hintText: "Password",
                          isPassword: true,
                          isObscured: isObscured,
                          validator: (v) => v != null && v.length >= 6
                              ? null
                              : "Password must be at least 6 characters",
                        ),
                      ),
                      const SizedBox(height: 16),
                      Obx(
                        () => _buildInputField(
                          controller: confirmPassCtrl,
                          hintText: "Confirm Password",
                          isPassword: true,
                          isObscured: isConfirmObscured,
                          validator: (v) => v == passCtrl.text
                              ? null
                              : "Passwords do not match",
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildRoleSwitch(),
                      const SizedBox(height: 32),
                      _buildSignUpButton(controller),
                      const SizedBox(height: 24),
                      _buildSignInRedirect(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- FORM COMPONENTS & WIDGETS ---
  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    bool isPassword = false,
    RxBool? isObscured,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && (isObscured?.value ?? true),
      validator: validator,
      style: GoogleFonts.poppins(fontSize: 16, color: textColor),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(
          vertical: 18,
          horizontal: 20,
        ),
        filled: true,
        fillColor: backgroundColor.withOpacity(0.8),
        hintText: hintText,
        hintStyle: GoogleFonts.poppins(color: subtleTextColor),
        suffixIcon: isPassword && isObscured != null
            ? IconButton(
                icon: Icon(
                  isObscured.value
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: subtleTextColor,
                ),
                onPressed: () => isObscured.value = !isObscured.value,
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400, width: 2.5),
        ),
      ),
    );
  }

  Widget _buildRoleSwitch() {
    return Obx(
      () => Row(
        children: [
          Expanded(
            child: _buildRoleOption(
              title: "Student",
              icon: Icons.school_outlined,
              isSelected: isStudent.value,
              onTap: () => isStudent.value = true,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildRoleOption(
              title: "Tutor",
              icon: Icons.history_edu_outlined,
              isSelected: !isStudent.value,
              onTap: () => isStudent.value = false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleOption({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withOpacity(0.15)
              : backgroundColor.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.white.withOpacity(0.5),
            width: isSelected ? 2 : 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? primaryColor : subtleTextColor,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? primaryColor : textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignUpButton(AuthController controller) {
    return Obx(
      () => SizedBox(
        height: 54,
        child: ElevatedButton(
          onPressed: isLoading.value
              ? null
              : () async {
                  if (!formKey.currentState!.validate()) return;
                  FocusScope.of(context).unfocus();
                  isLoading.value = true;
                  try {
                    // This is your existing call to the controller
                    await controller.signUp(
                      emailCtrl.text.trim(),
                      passCtrl.text.trim(),
                      isStudent.value ? UserType.student : UserType.tutor,
                    );

                    // --- SUCCESS HANDLING STARTS HERE ---

                    // 1. Show a success Snackbar
                    Get.snackbar(
                      "Account Created!",
                      "Welcome! You can now log in.",
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor:
                          primaryColor, // Use your theme's success color
                      colorText: Colors.white,
                      borderRadius: 12,
                      margin: const EdgeInsets.all(12),
                    );

                    // 2. Wait for 2 seconds to let the user read the message
                    await Future.delayed(const Duration(seconds: 2));

                    // 3. Navigate to the login page, replacing the sign-up page
                    Get.offNamed('/login');

                    // --- SUCCESS HANDLING ENDS HERE ---
                  } catch (e) {
                    // This is your EXISTING error handling, which is great.
                    // It already lets the user know if registration was NOT successful.
                    Get.snackbar(
                      "Signup Failed",
                      e.toString().replaceAll("Exception: ", ""),
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.red.shade600,
                      colorText: Colors.white,
                      borderRadius: 12,
                      margin: const EdgeInsets.all(12),
                    );
                  } finally {
                    // It's good practice to check if the widget is still mounted
                    // before trying to update its state, especially after async gaps.
                    if (mounted) {
                      isLoading.value = false;
                    }
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            elevation: 8,
            shadowColor: primaryColor.withOpacity(0.6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: isLoading.value
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(
                  'Sign Up',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSignInRedirect() {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: GoogleFonts.poppins(color: subtleTextColor, fontSize: 16),
        children: [
          const TextSpan(text: "Already have an account? "),
          TextSpan(
            text: "Log In",
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
            recognizer: TapGestureRecognizer()
              ..onTap = () => Get.offNamed('/login'),
          ),
        ],
      ),
    );
  }
}

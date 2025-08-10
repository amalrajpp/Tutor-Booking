import 'dart:ui';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/auth_controller.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  final isObscured = true.obs;
  final formKey = GlobalKey<FormState>();

  final Color primaryColor = const Color(0xFF37A93C);
  final Color backgroundColor = const Color(0xFFEDF7EE);
  final Color textColor = const Color(0xFF0A3622);
  final Color subtleTextColor = const Color(0xFF556B61);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // LAYER 1: Dynamic Background Shapes
          //_buildBackgroundShapes(),

          // LAYER 2: Header (Logo & Tagline)
          // Positioned freely in the top section of the screen
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 40.0),
              child: Align(
                alignment: Alignment.topCenter,
                child: _buildHeader(),
              ),
            ),
          ),

          // LAYER 3: The Floating Glassmorphic Panel
          // Aligned to the bottom and slides up
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildFloatingPanel(),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS FOR THE NEW LAYOUT ---

  Widget _buildHeader() {
    return FadeInDown(
      duration: const Duration(milliseconds: 600),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/images/title.png', height: 45),
          const SizedBox(height: 16),
          Text(
            "Syllabus To Success",
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

  Widget _buildFloatingPanel() {
    final controller = Get.find<AuthController>();

    // This panel slides up, containing all the interactive elements
    return SlideInUp(
      duration: const Duration(milliseconds: 800),
      delay: const Duration(milliseconds: 200),
      child: ClipRRect(
        // Rounded corners only on the top
        borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 30.0,
            ),
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
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "Welcome Back!",
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    Text(
                      "Sign in to continue your journey.",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: subtleTextColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildInputField(
                      controller: emailCtrl,
                      hintText: "Email address",
                    ),
                    const SizedBox(height: 16),
                    Obx(
                      () => _buildInputField(
                        controller: passCtrl,
                        hintText: "Password",
                        isPassword: true,
                        isObscured: isObscured,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        child: Text(
                          "Forgot Password?",
                          style: GoogleFonts.poppins(
                            color: textColor.withOpacity(0.8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildLoginButton(controller),
                    const SizedBox(height: 24),
                    _buildSignUpRedirect(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- UPDATED INPUT FIELD AND BUTTONS ---

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    bool isPassword = false,
    RxBool? isObscured,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && (isObscured?.value ?? true),
      style: GoogleFonts.poppins(fontSize: 16, color: textColor),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(
          vertical: 18,
          horizontal: 20,
        ),
        filled: true,
        fillColor: backgroundColor.withOpacity(0.8), // Subtle fill color
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
      ),
    );
  }

  Widget _buildLoginButton(AuthController controller) {
    return Obx(
      () => SizedBox(
        height: 54,
        child: ElevatedButton(
          onPressed: controller.isLoading.value
              ? null
              : () async {
                  if (!formKey.currentState!.validate()) return;
                  controller.isLoading.value = true;
                  try {
                    await controller.login(
                      emailCtrl.text.trim(),
                      passCtrl.text.trim(),
                    );
                  } catch (e) {
                    Get.snackbar(
                      "Login Failed",
                      e.toString().replaceAll("Exception: ", ""),
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.red.withOpacity(0.9),
                      colorText: Colors.white,
                      borderRadius: 12,
                      margin: const EdgeInsets.all(12),
                    );
                  } finally {
                    controller.isLoading.value = false;
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
          child: controller.isLoading.value
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(
                  'Login',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSignUpRedirect(BuildContext context) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: GoogleFonts.poppins(color: subtleTextColor, fontSize: 16),
        children: [
          const TextSpan(text: "Don't have an account? "),
          TextSpan(
            text: "Sign Up",
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
            recognizer: TapGestureRecognizer()
              ..onTap = () => Get.toNamed('/signup'),
          ),
        ],
      ),
    );
  }
}

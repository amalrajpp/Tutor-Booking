import 'dart:ui';
import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class TutorDetailsPage extends StatefulWidget {
  const TutorDetailsPage({super.key});

  @override
  State<TutorDetailsPage> createState() => _TutorDetailsPageState();
}

class _TutorDetailsPageState extends State<TutorDetailsPage> {
  // --- CHANGE: Added controller for city and renamed experience controller ---
  final nameCtrl = TextEditingController();
  final qualificationCtrl = TextEditingController();
  final yearOfPassingCtrl = TextEditingController(); // Was experienceCtrl
  final phoneCtrl = TextEditingController();
  final cityCtrl = TextEditingController(); // New controller

  final List<String> classes = ['7-8', '9-10', '11-12'];
  final List<String> mediums = ['English', 'Malayalam', 'Hindi'];
  final List<String> subjects = [
    'Maths',
    'Science',
    'English',
    'Social Science',
    'Computer',
    'Physics',
    'Chemistry',
    'Biology',
  ];

  List<String> selectedSubjects = [];
  String? selectedClass;
  String? selectedMedium;

  bool isLoading = false;

  void showError(String message) {
    Get.snackbar(
      'Validation Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade400,
      colorText: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      borderRadius: 12,
    );
  }

  Future<void> handleSubmit() async {
    // --- CHANGE: Updated validation logic ---
    if (nameCtrl.text.trim().isEmpty) return showError('Name is required.');
    if (phoneCtrl.text.trim().isEmpty || phoneCtrl.text.length != 10)
      return showError('Valid phone number is required.');
    if (cityCtrl.text.trim().isEmpty)
      return showError('City is required.'); // New validation
    if (qualificationCtrl.text.trim().isEmpty)
      return showError('Qualification is required.');
    if (yearOfPassingCtrl.text.trim().isEmpty)
      return showError('Year of Passing is required.'); // Updated validation
    if (selectedClass == null) return showError('Please select a class group.');
    if (selectedMedium == null) return showError('Please select a medium.');
    if (selectedSubjects.isEmpty)
      return showError('Please select at least one subject.');

    setState(() => isLoading = true);

    final uid = FirebaseAuth.instance.currentUser!.uid;
    FirebaseAuth.instance.currentUser!.updateDisplayName(nameCtrl.text);
    // --- CHANGE: Updated Firestore data structure ---
    await FirebaseFirestore.instance.collection('tutors').doc(uid).set({
      'name': nameCtrl.text.trim(),
      'phone': phoneCtrl.text.trim(),
      'city': cityCtrl.text.trim(), // Added city
      'qualification': qualificationCtrl.text.trim(),
      'yearOfPassing': yearOfPassingCtrl.text
          .trim(), // Changed from 'experience'
      'class': selectedClass,
      'medium': selectedMedium,
      'subjects': selectedSubjects,
      'isProfileComplete': true,
    }, SetOptions(merge: true));

    if (mounted) {
      setState(() => isLoading = false);
    }
    Get.offAllNamed('/tutorHome');
  }

  // --- UI Color Palette (Matches StudentDetailsPage) ---
  final Color primaryColor = const Color(0xFF32A055);
  final Color backgroundColor = const Color(0xFFF0F9F3);
  final Color textColor = const Color(0xFF002333);
  final Color subtleTextColor = Colors.grey.shade600;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          _buildAuroraBackground(),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                // --- Header with Illustration (Unchanged) ---
                FadeInDown(
                  duration: const Duration(milliseconds: 500),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/images/tutor_illustration.png',
                          height: 150,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.history_edu_rounded,
                                size: 120,
                                color: Color(0xFF32A055),
                              ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Complete Your Tutor Profile",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "This helps students find and connect with you.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: subtleTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // --- Section 1: Personal Info ---
                FadeInUp(
                  duration: const Duration(milliseconds: 500),
                  delay: const Duration(milliseconds: 200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('Personal Information'),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: nameCtrl,
                        name: 'Full Name',
                        prefixIcon: Icons.person_outline_rounded,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: phoneCtrl,
                        name: 'Phone Number',
                        prefixIcon: Icons.phone_outlined,
                        inputType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      // --- CHANGE: Added City text field ---
                      CustomTextField(
                        controller: cityCtrl,
                        name: 'City',
                        prefixIcon: Icons.location_city_rounded,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // --- Section 2: Professional Details ---
                FadeInUp(
                  duration: const Duration(milliseconds: 500),
                  delay: const Duration(milliseconds: 300),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('Professional Details'),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: qualificationCtrl,
                        name: 'Highest Qualification',
                        prefixIcon: Icons.school_outlined,
                      ),
                      const SizedBox(height: 16),
                      // --- CHANGE: Updated Experience field to Year of Passing ---
                      CustomTextField(
                        controller: yearOfPassingCtrl,
                        name: 'Year of Passing',
                        prefixIcon: Icons.calendar_today_outlined,
                        inputType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // --- Section 3: Teaching Details (Unchanged) ---
                FadeInUp(
                  duration: const Duration(milliseconds: 500),
                  delay: const Duration(milliseconds: 400),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('Teaching Details'),
                      const SizedBox(height: 16),
                      CustomDropdown<String>(
                        hintText: 'Select Class Group to Teach',
                        items: classes,
                        onChanged: (value) =>
                            setState(() => selectedClass = value),
                        decoration: _customDropdownDecoration(),
                      ),
                      const SizedBox(height: 16),
                      CustomDropdown<String>(
                        hintText: 'Select Medium',
                        items: mediums,
                        onChanged: (value) =>
                            setState(() => selectedMedium = value),
                        decoration: _customDropdownDecoration(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // --- Section 4: Subjects (Unchanged) ---
                FadeInUp(
                  duration: const Duration(milliseconds: 500),
                  delay: const Duration(milliseconds: 500),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('Subjects You Can Teach'),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: subjects.map((subject) {
                          final selected = selectedSubjects.contains(subject);
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (selected) {
                                  selectedSubjects.remove(subject);
                                } else {
                                  selectedSubjects.add(subject);
                                }
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: selected
                                    ? primaryColor
                                    : Colors.white.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: selected
                                      ? primaryColor
                                      : Colors.grey.shade300,
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                subject,
                                style: GoogleFonts.poppins(
                                  color: selected ? Colors.white : textColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                // --- Submit Button (Unchanged) ---
                FadeInUp(
                  duration: const Duration(milliseconds: 500),
                  delay: const Duration(milliseconds: 600),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 5,
                          shadowColor: primaryColor.withOpacity(0.4),
                        ),
                        onPressed: isLoading ? null : handleSubmit,
                        child: isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                'Save & Continue',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets (Unchanged) ---
  Widget _buildAuroraBackground() {
    return Stack(
      children: [
        Positioned(
          top: -100,
          left: -150,
          child: CircleAvatar(
            radius: 200,
            backgroundColor: primaryColor.withOpacity(0.15),
          ),
        ),
        Positioned(
          bottom: -150,
          right: -200,
          child: CircleAvatar(
            radius: 250,
            backgroundColor: Colors.lightBlue.shade200.withOpacity(0.15),
          ),
        ),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 80.0, sigmaY: 80.0),
          child: Container(color: Colors.transparent),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
    );
  }

  CustomDropdownDecoration _customDropdownDecoration() {
    return CustomDropdownDecoration(
      closedFillColor: Colors.white.withOpacity(0.7),
      expandedFillColor: Colors.white,
      closedBorder: Border.all(color: Colors.grey.shade300, width: 1.5),
      expandedBorder: Border.all(color: primaryColor, width: 2),
      closedBorderRadius: BorderRadius.circular(12),
      expandedBorderRadius: BorderRadius.circular(12),
      hintStyle: GoogleFonts.poppins(color: subtleTextColor, fontSize: 16),
      headerStyle: GoogleFonts.poppins(
        color: textColor,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      listItemStyle: GoogleFonts.poppins(color: textColor, fontSize: 16),
    );
  }
}

// --- CustomTextField Widget (Unchanged) ---
class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String name;
  final IconData prefixIcon;
  final TextInputType inputType;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.name,
    required this.prefixIcon,
    this.inputType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF32A055);
    final Color subtleTextColor = Colors.grey.shade600;

    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withOpacity(0.7),
        labelText: name,
        labelStyle: GoogleFonts.poppins(color: subtleTextColor),
        prefixIcon: Icon(prefixIcon, color: subtleTextColor),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
      ),
    );
  }
}

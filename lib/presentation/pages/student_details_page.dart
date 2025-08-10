import 'dart:ui';
import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class StudentDetailsPage extends StatefulWidget {
  const StudentDetailsPage({super.key});

  @override
  State<StudentDetailsPage> createState() => _StudentDetailsPageState();
}

class _StudentDetailsPageState extends State<StudentDetailsPage> {
  // --- All logic and state variables ---
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final cityCtrl = TextEditingController();
  final schoolCtrl = TextEditingController();

  final List<String> grades = ['8', '9', '10', '11', '12'];
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
  String? selectedGrade;
  String? selectedMedium;

  // --- UI Color Palette ---
  final Color primaryColor = const Color(0xFF32A055);
  final Color backgroundColor = const Color(0xFFF0F9F3);
  final Color textColor = const Color(0xFF002333);
  final Color subtleTextColor = Colors.grey.shade600;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // LAYER 1: The visually rich background
          _buildAuroraBackground(),

          // LAYER 2: The Form Content
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                // --- Header with Illustration ---
                FadeInDown(
                  duration: const Duration(milliseconds: 500),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/images/profile_illustration.png',
                          height: 150,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.school_rounded,
                                size: 120,
                                color: Color(0xFF32A055),
                              ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Let's Complete Your Profile",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "This helps us find the best resources for you.",
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
                      CustomTextField(
                        controller: cityCtrl,
                        name: 'City',
                        prefixIcon: Icons.location_city_rounded,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // --- Section 2: Academic Details ---
                FadeInUp(
                  duration: const Duration(milliseconds: 500),
                  delay: const Duration(milliseconds: 300),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('Academic Details'),
                      const SizedBox(height: 16),
                      CustomDropdown<String>(
                        hintText: 'Select Grade/Class',
                        items: grades,
                        onChanged: (value) =>
                            setState(() => selectedGrade = value),
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
                      const SizedBox(height: 16),
                      // --- SCHOOL NAME FIELD MOVED HERE ---
                      CustomTextField(
                        controller: schoolCtrl,
                        name: 'School Name',
                        prefixIcon: Icons.school_rounded,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // --- Section 3: Subjects ---
                FadeInUp(
                  duration: const Duration(milliseconds: 500),
                  delay: const Duration(milliseconds: 400),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('Subjects You Need Help With'),
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

                // --- Submit Button ---
                FadeInUp(
                  duration: const Duration(milliseconds: 500),
                  delay: const Duration(milliseconds: 500),
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
                        onPressed: () async {
                          // Logic for saving remains unchanged
                          if (nameCtrl.text.isEmpty ||
                              phoneCtrl.text.isEmpty ||
                              cityCtrl.text.isEmpty ||
                              schoolCtrl.text.isEmpty ||
                              selectedGrade == null ||
                              selectedMedium == null ||
                              selectedSubjects.isEmpty) {
                            Get.snackbar(
                              'Incomplete Profile',
                              'Please fill all the required fields.',
                              backgroundColor: Colors.red.shade400,
                              colorText: Colors.white,
                              snackPosition: SnackPosition.BOTTOM,
                            );
                            return;
                          }
                          FirebaseAuth.instance.currentUser!.updateDisplayName(
                            nameCtrl.text,
                          );
                          await FirebaseFirestore.instance
                              .collection('students')
                              .doc(uid)
                              .set({
                                'name': nameCtrl.text,
                                'phone': phoneCtrl.text,
                                'city': cityCtrl.text,
                                'school': schoolCtrl.text,
                                'grade': selectedGrade,
                                'medium': selectedMedium,
                                'subjectsNeeded': selectedSubjects,
                                'isProfileComplete': true,
                              }, SetOptions(merge: true));
                          Get.offAllNamed('/studentHome');
                        },
                        child: Text(
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

  // --- HELPER WIDGETS (UNCHANGED) ---

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
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
      ),
    );
  }
}

import 'dart:ui';
import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

// Assuming a named route '/studentDetails' is set up for editing the profile.

class StudentProfilePage extends StatefulWidget {
  const StudentProfilePage({super.key});

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  // --- UI Color Palette (Matches TutorProfilePage) ---
  final Color primaryColor = const Color(0xFF32A055);
  final Color backgroundColor = const Color(0xFFF0F9F3);
  final Color textColor = const Color(0xFF002333);
  final Color subtleTextColor = Colors.grey.shade600;
  final Color cardColor = Colors.white.withOpacity(0.8);

  // Future to fetch student data
  late Future<DocumentSnapshot> studentDataFuture;

  @override
  void initState() {
    super.initState();
    _fetchStudentData();
  }

  void _fetchStudentData() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    studentDataFuture = FirebaseFirestore.instance
        .collection('students')
        .doc(uid)
        .get();
  }

  Future<void> _refreshData() async {
    setState(() {
      _fetchStudentData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'My Profile',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          IconButton(
            icon: Icon(Icons.edit_rounded, color: primaryColor),
            onPressed: () {
              // Navigate to the details page to edit
              // Ensure you have a named route '/studentDetails' configured
              Get.toNamed('/studentDetails');
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildAuroraBackground(),
          FutureBuilder<DocumentSnapshot>(
            future: studentDataFuture,
            builder: (context, snapshot) {
              // --- Handle Loading State ---
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(color: primaryColor),
                );
              }

              // --- Handle Error State ---
              if (snapshot.hasError) {
                return Center(
                  child: Text('An error occurred: ${snapshot.error}'),
                );
              }

              // --- Handle No Data State ---
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Profile not found.'),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () => Get.toNamed('/studentDetails'),
                        child: const Text('Complete Profile'),
                      ),
                    ],
                  ),
                );
              }

              // --- Display Data ---
              final data = snapshot.data!.data() as Map<String, dynamic>;
              final subjects = data['subjectsNeeded'] as List<dynamic>? ?? [];

              return RefreshIndicator(
                onRefresh: _refreshData,
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  children: [
                    // --- Profile Header ---
                    FadeInDown(
                      child: _buildProfileHeader(
                        data['name'] ?? 'N/A',
                        "Grade: ${data['grade'] ?? 'N/A'}", // Using grade as the subtitle
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- Personal Details Card ---
                    FadeInUp(
                      delay: const Duration(milliseconds: 100),
                      child: _buildSectionCard(
                        title: 'Personal Details',
                        children: [
                          _buildInfoRow(
                            Icons.phone_outlined,
                            'Phone Number',
                            data['phone'] ?? 'N/A',
                          ),
                          _buildInfoRow(
                            Icons.location_city_outlined,
                            'City',
                            data['city'] ?? 'N/A',
                          ),
                          _buildInfoRow(
                            Icons.school_outlined,
                            'School/College',
                            data['school'] ?? 'N/A',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- Academic & Subjects Card ---
                    FadeInUp(
                      delay: const Duration(milliseconds: 200),
                      child: _buildSectionCard(
                        title: 'Academic Details',
                        children: [
                          _buildInfoRow(
                            Icons.class_outlined,
                            'Grade / Class',
                            data['grade'] ?? 'N/A',
                          ),
                          _buildInfoRow(
                            Icons.translate_outlined,
                            'Medium of Instruction',
                            data['medium'] ?? 'N/A',
                          ),
                          const SizedBox(height: 10),
                          // --- Subjects Chips ---
                          if (subjects.isNotEmpty) ...[
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Subjects of Interest',
                                style: GoogleFonts.poppins(
                                  color: subtleTextColor,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: subjects
                                  .map(
                                    (subject) => Chip(
                                      label: Text(subject.toString()),
                                      backgroundColor: primaryColor.withOpacity(
                                        0.1,
                                      ),
                                      labelStyle: GoogleFonts.poppins(
                                        color: primaryColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      side: BorderSide(
                                        color: primaryColor.withOpacity(0.3),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // --- Logout Button ---
                    FadeInUp(
                      delay: const Duration(milliseconds: 300),
                      child: _buildLogoutButton(),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets (Identical to TutorProfilePage for consistency) ---

  Widget _buildProfileHeader(String name, String subtitle) {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: primaryColor.withOpacity(0.2),
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : 'S',
            style: GoogleFonts.poppins(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          name,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: subtleTextColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const Divider(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: primaryColor, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: subtleTextColor,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return ElevatedButton.icon(
      onPressed: () async {
        // You can add a confirmation dialog here if you want
        await FirebaseAuth.instance.signOut();
        // Navigate to login/welcome screen
        Get.offAllNamed('/login');
      },
      icon: const Icon(Icons.logout, color: Colors.redAccent),
      label: Text(
        "Logout",
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.redAccent,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red.withOpacity(0.1),
        elevation: 0,
        fixedSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

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
}

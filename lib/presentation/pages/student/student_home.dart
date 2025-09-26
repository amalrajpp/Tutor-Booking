import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:karreoapp/presentation/controllers/student_home_controller.dart';
import 'package:karreoapp/presentation/pages/student/student_profile.dart';
import 'package:karreoapp/presentation/pages/tutor/tutor_home.dart';

// Model for Course Data
class Course {
  final IconData icon;
  final String title;
  final int lessonCount;
  final double rating;

  const Course({
    required this.icon,
    required this.title,
    required this.lessonCount,
    required this.rating,
  });
}

class StudentHomePage extends GetView<StudentHomeController> {
  const StudentHomePage({super.key});

  // --- Constants ---
  static const Color _primaryGreen = Color(0xFF3AB54A);
  static const Color _darkText = Color(0xFF231F20);
  static const Color _backgroundColor = Color(0xFFEBF6EC);

  // --- Static Data ---
  final List<Course> popularCourses = const [
    Course(
      icon: Icons.computer,
      title: 'Computer Course',
      lessonCount: 15,
      rating: 4.9,
    ),
    Course(
      icon: Icons.spellcheck,
      title: 'English Course',
      lessonCount: 13,
      rating: 4.8,
    ),
    Course(
      icon: Icons.design_services,
      title: 'Design Course',
      lessonCount: 18,
      rating: 5.0,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Instantiate the controller. GetX will manage its lifecycle.
    Get.put(StudentHomeController());

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeaderAndSearch(context),
            _buildPopularCourses(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderAndSearch(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Column(
          children: [
            Container(
              height: 320,
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
              decoration: const BoxDecoration(
                color: _darkText,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Column(
                children: [
                  _buildCustomAppBar(),
                  const SizedBox(height: 25),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Book your\nclasses!",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 260),
          ],
        ),
        Positioned(top: 220, child: _buildSearchCard(context)),
      ],
    );
  }

  Widget _buildCustomAppBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.menu, color: Colors.white, size: 30),
          onPressed: () => Get.to(() => const TutorHomePage()),
        ),
        GestureDetector(
          onTap: () => Get.to(() => const StudentProfilePage()),
          child: const CircleAvatar(
            radius: 20,
            backgroundImage: AssetImage('assets/images/avatar.png'),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchCard(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSessionTypeSelector(),
          const SizedBox(height: 16),
          _buildSearchInputFields(context),
          const SizedBox(height: 12),
          _buildDateTimeFields(context),
          const SizedBox(height: 16),
          _buildSearchTutorsButton(),
        ],
      ),
    );
  }

  Widget _buildSessionTypeSelector() {
    return Obx(
      () => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildSessionTypeOption("Single Hour", 0),
          _buildSessionTypeOption("Custom", 1),
          _buildSessionTypeOption("Flexible", 2),
        ],
      ),
    );
  }

  Widget _buildSessionTypeOption(String title, int index) {
    final bool isSelected = controller.selectedSessionType.value == index;
    return GestureDetector(
      onTap: () => controller.setSessionType(index),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: isSelected ? _darkText : Colors.grey[600],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 16,
            ),
          ),
          if (isSelected)
            Container(
              margin: const EdgeInsets.only(top: 4),
              height: 2,
              width: 40,
              color: _primaryGreen,
            ),
        ],
      ),
    );
  }

  Widget _buildSearchInputFields(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return const Iterable<String>.empty();
              }
              return StudentHomeController.subjectSuggestions.where((option) {
                return option.toLowerCase().contains(
                  textEditingValue.text.toLowerCase(),
                );
              });
            },
            fieldViewBuilder:
                (
                  BuildContext context,
                  TextEditingController fieldTextEditingController,
                  FocusNode fieldFocusNode,
                  VoidCallback onFieldSubmitted,
                ) {
                  // Sync state controller with the Autocomplete's internal controller
                  controller.subjectController.value =
                      fieldTextEditingController.value;
                  return _buildTextField(
                    controller: fieldTextEditingController,
                    focusNode: fieldFocusNode,
                    icon: Icons.search,
                    label: "Subject (e.g., Math)",
                  );
                },
            onSelected: (String selection) {
              controller.subjectController.text = selection;
              controller.subjectFocusNode.unfocus();
            },
          ),
          Divider(height: 1, color: Colors.grey[300]),
          GestureDetector(
            onTap: controller.handleLocationTap,
            child: AbsorbPointer(
              child: _buildTextField(
                controller: controller.locationController,
                icon: Icons.location_on,
                label: "Location (Your Area)",
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeFields(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => controller.selectDate(context),
            child: AbsorbPointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: _backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _buildTextField(
                  controller: controller.dateController,
                  icon: Icons.calendar_today,
                  label: "Date",
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => controller.selectTime(context),
            child: AbsorbPointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: _backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _buildTextField(
                  controller: controller.timeController,
                  icon: Icons.access_time,
                  label: "Time",
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required IconData icon,
    required String label,
    TextEditingController? controller,
    FocusNode? focusNode,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        decoration: InputDecoration(
          icon: Icon(icon, color: Colors.grey[500], size: 20),
          hintText: label,
          hintStyle: TextStyle(color: Colors.grey[500]),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildSearchTutorsButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: controller.searchForTutors,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryGreen,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          "Search Tutors",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildPopularCourses() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            "Popular Course",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _darkText,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 210,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: popularCourses.length,
            padding: const EdgeInsets.only(left: 20, right: 10),
            itemBuilder: (context, index) {
              return _buildCourseCard(popularCourses[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCourseCard(Course course) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 10, bottom: 5, top: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: _backgroundColor,
                ),
                child: Center(
                  child: Icon(course.icon, color: _darkText, size: 60),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              course.title,
              style: const TextStyle(
                color: _darkText,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 5),
            Text(
              '${course.lessonCount} Lessons',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Text(
                  course.rating.toString(),
                  style: const TextStyle(
                    color: _darkText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.star, color: Colors.amber, size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void showLocationOptionsDialog(GeoPoint savedPoint) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: Get.theme.canvasColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Choose Location',
              style: Get.theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: _darkText,
              ),
            ),
            const SizedBox(height: 25),
            _buildLocationOptionTile(
              context: Get.context!,
              icon: Icons.bookmark_added_rounded,
              title: 'Use Saved Location',
              subtitle: 'Select the location stored in your profile.',
              onTap: () => controller.useSavedLocation(savedPoint),
            ),
            const SizedBox(height: 15),
            _buildLocationOptionTile(
              context: Get.context!,
              icon: Icons.my_location_rounded,
              title: 'Fetch New Location',
              subtitle: 'Get your precise current position now.',
              onTap: controller.useNewLocation,
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
  }

  Widget _buildLocationOptionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: _backgroundColor,
      borderRadius: BorderRadius.circular(16.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.0),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Row(
            children: [
              Icon(icon, color: _primaryGreen, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _darkText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: _darkText,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

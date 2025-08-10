import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:karreoapp/presentation/pages/book_tutor.dart';
import 'package:karreoapp/presentation/pages/custom.dart';
import 'package:karreoapp/presentation/pages/student_profile.dart';
import 'package:karreoapp/presentation/pages/tutor_home.dart';

// Imports from the provided logic
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';

// Import for reverse geocoding to get address from coordinates
import 'package:geocoding/geocoding.dart' as geocoding;

class StudentHome extends StatefulWidget {
  const StudentHome({super.key});

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

// Model for Course Data
class Course {
  final IconData icon;
  final String title;
  final int lessonCount;
  final double rating;

  Course({
    required this.icon,
    required this.title,
    required this.lessonCount,
    required this.rating,
  });
}

class _StudentHomeState extends State<StudentHome> {
  // --- Variables from StudentHome UI ---
  int _selectedSessionType = 0;
  static const Color _primaryGreen = Color(0xFF3AB54A);
  static const Color _darkText = Color(0xFF231F20);
  static const Color _backgroundColor = Color(0xFFEBF6EC);
  final FocusNode _subjectFocusNode = FocusNode();

  // MODIFIED: Added controller for the subject field
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final List<Course> popularCourses = [
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
  static const List<String> _subjectSuggestions = <String>[
    'Mathematics',
    'Physics',
    'Chemistry',
    'Biology',
    'History',
    'Geography',
    'English',
    'Computer Science',
    'Art',
    'Music',
    'Physical Education',
  ];

  // --- Variables from HomeScreen Logic ---
  final user = FirebaseAuth.instance.currentUser;
  Position? _currentPosition;
  String? _locationStatus;

  // IMPORTANT: Replace with your actual OpenRouteService API key
  final String orsApiKey =
      'eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6ImJiNzJiZGFmOTY0ZDQ3YmM5YjQzM2VjYjNhMmNmOWNiIiwiaCI6Im11cm11cjY0In0=';

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();
  }

  // --- All logic methods are here ---

  Future<void> _fetchCurrentLocation() async {
    setState(() => _locationStatus = "Fetching location...");

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _locationStatus = "Location services disabled.");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _locationStatus = "Location permission denied.");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(
        () => _locationStatus = "Location permission permanently denied.",
      );
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _locationStatus = "Location fetched ✅";
      });

      if (mounted) {
        await _getAddressFromCoordinates(position.latitude, position.longitude);
      }

      if (user != null) {
        final GeoFirePoint geoFirePoint = GeoFirePoint(
          GeoPoint(position.latitude, position.longitude),
        );

        await FirebaseFirestore.instance
            .collection("students")
            .doc(user!.uid)
            .set({
              "location": {
                'geo': geoFirePoint.data,
                "timestamp": Timestamp.now(),
              },
            }, SetOptions(merge: true));
        debugPrint("Location updated in Firestore.");
      }
    } catch (e) {
      setState(() => _locationStatus = "Error fetching location: $e");
    }
  }

  // MODIFIED: This function now checks for all fields, calculates duration,
  // and passes all required data to the results page.
  Future<void> _searchForTutors() async {
    // 1. VALIDATION: Check if all required fields are filled.
    if (_subjectController.text.isEmpty ||
        _dateController.text.isEmpty ||
        _timeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill in subject, date, and time to search."),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return; // Stop the function if fields are not filled
    }

    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Your location is not available. Please enable location services.",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 2. DURATION CALCULATION: Determine duration based on session type.
    int duration;
    switch (_selectedSessionType) {
      case 0: // Single Hour
        duration = 1;
        break;
      case 1: // Custom
        duration = 2;
        break;
      case 2: // Flexible
        duration = 4;
        break;
      default:
        duration = 1; // Default to 1 hour
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(color: _primaryGreen),
        );
      },
    );

    try {
      final center = GeoFirePoint(
        GeoPoint(_currentPosition!.latitude, _currentPosition!.longitude),
      );
      final collection = FirebaseFirestore.instance.collection("tutors");

      final stream = GeoCollectionReference<Map<String, dynamic>>(collection)
          .subscribeWithin(
            center: center,
            radiusInKm: 50,
            field: 'location.geo',
            geopointFrom: (data) =>
                (data['location']['geo']['geopoint']) as GeoPoint,
          );

      final docs = await stream.first;

      final sortedTutors =
          docs
              .where((doc) => doc.id != user?.uid)
              .map((doc) {
                final data = doc.data();
                if (data == null ||
                    data['location']?['geo']?['geopoint'] == null) {
                  return null;
                }
                final geoPoint =
                    data['location']['geo']['geopoint'] as GeoPoint;

                // This is the straight-line distance, good for initial sorting
                final straightLineDistance =
                    Geolocator.distanceBetween(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                      geoPoint.latitude,
                      geoPoint.longitude,
                    ) /
                    1000.0;

                return {
                  "id": doc.id,
                  "name": data["name"],
                  "email": data["email"],
                  "distance": straightLineDistance,
                  "medium": data["medium"],
                  "class": data["class"],
                  "geoPoint": geoPoint,
                  "rating": (data["rating"] as num? ?? 0.0).toDouble(),
                };
              })
              .whereType<Map<String, dynamic>>()
              .toList()
            ..sort(
              (a, b) =>
                  (a["distance"] as double).compareTo(b["distance"] as double),
            );

      final topFiveTutors = sortedTutors.take(5).toList();

      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        // 3. NAVIGATION: Pass all the new data to the next page.
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TutorSearchResultsPage(
              tutors: topFiveTutors,
              studentPosition: _currentPosition!,
              orsApiKey: orsApiKey,
              // --- PASSING NEW DATA ---
              subject: _subjectController.text,
              date: _dateController.text,
              time: _timeController.text,
              duration: duration,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("An error occurred while searching: $e"),
          backgroundColor: Colors.red,
        ),
      );
      debugPrint("Error fetching nearby tutors: $e");
    }
  }

  Future<void> _handleLocationTap() async {
    if (user == null) {
      _fetchCurrentLocation();
      return;
    }
    final docRef = FirebaseFirestore.instance
        .collection('students')
        .doc(user!.uid);
    final docSnap = await docRef.get();

    if (docSnap.exists && docSnap.data()?['location'] != null) {
      final geoPoint =
          docSnap.data()!['location']['geo']['geopoint'] as GeoPoint;
      _showLocationOptionsDialog(geoPoint);
    } else {
      await _fetchCurrentLocation();
    }
  }

  void _showLocationOptionsDialog(GeoPoint savedPoint) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: BoxDecoration(
            color: Theme.of(context).canvasColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24.0),
            ),
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
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _darkText,
                ),
              ),
              const SizedBox(height: 25),
              _buildLocationOptionTile(
                context: context,
                icon: Icons.bookmark_added_rounded,
                title: 'Use Saved Location',
                subtitle: 'Select the location stored in your profile.',
                onTap: () {
                  Navigator.of(context).pop();
                  _getAddressFromCoordinates(
                    savedPoint.latitude,
                    savedPoint.longitude,
                  );
                },
              ),
              const SizedBox(height: 15),
              _buildLocationOptionTile(
                context: context,
                icon: Icons.my_location_rounded,
                title: 'Fetch New Location',
                subtitle: 'Get your precise current position now.',
                onTap: () {
                  Navigator.of(context).pop();
                  _fetchCurrentLocation();
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
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

  Future<void> _getAddressFromCoordinates(double lat, double lon) async {
    try {
      List<geocoding.Placemark> placemarks = await geocoding
          .placemarkFromCoordinates(lat, lon);
      geocoding.Placemark place = placemarks[0];
      final address = '${place.street}, ${place.locality}, ${place.postalCode}';
      if (mounted) {
        setState(() {
          _locationController.text = address;
        });
      }
    } catch (e) {
      debugPrint("Error getting address: $e");
      if (mounted) {
        setState(() {
          _locationController.text = "Could not find address";
        });
      }
    }
  }

  @override
  void dispose() {
    _subjectFocusNode.dispose();
    _subjectController.dispose(); // MODIFIED: Dispose the new controller
    _dateController.dispose();
    _timeController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate && mounted) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat.yMMMd().format(_selectedDate!);
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime && mounted) {
      setState(() {
        _selectedTime = picked;
        _timeController.text = _selectedTime!.format(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeaderAndSearch(),
            _buildPopularCourses(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderAndSearch() {
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
        Positioned(top: 220, child: _buildSearchCard()),
      ],
    );
  }

  Widget _buildCustomAppBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.menu, color: Colors.white, size: 30),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TutorHome()),
            );
          },
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const StudentProfilePage(),
              ),
            );
          },
          child: const CircleAvatar(
            radius: 20,
            backgroundImage: AssetImage('assets/images/avatar.png'),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchCard() {
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
          _buildSearchInputFields(),
          const SizedBox(height: 12),
          _buildDateTimeFields(),
          const SizedBox(height: 16),
          _buildSearchTutorsButton(),
        ],
      ),
    );
  }

  Widget _buildSessionTypeSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildSessionTypeOption("Single Hour", 0),
        _buildSessionTypeOption("Custom", 1),
        _buildSessionTypeOption("Flexible", 2),
      ],
    );
  }

  Widget _buildSessionTypeOption(String title, int index) {
    final bool isSelected = _selectedSessionType == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedSessionType = index),
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

  Widget _buildSearchInputFields() {
    return Container(
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text == '') {
                return const Iterable<String>.empty();
              }
              return _subjectSuggestions.where((String option) {
                return option.toLowerCase().contains(
                  textEditingValue.text.toLowerCase(),
                );
              });
            },
            // MODIFIED: This builder now uses our state's _subjectController
            // to ensure the typed text is captured for the search function.
            fieldViewBuilder:
                (
                  BuildContext context,
                  TextEditingController fieldTextEditingController,
                  FocusNode fieldFocusNode,
                  VoidCallback onFieldSubmitted,
                ) {
                  // Sync the state controller with the field's controller
                  _subjectController.value = fieldTextEditingController.value;
                  return _buildTextField(
                    controller: fieldTextEditingController,
                    focusNode: fieldFocusNode,
                    icon: Icons.search,
                    label: "Subject (e.g., Math)",
                  );
                },
            optionsViewBuilder:
                (
                  BuildContext context,
                  AutocompleteOnSelected<String> onSelected,
                  Iterable<String> options,
                ) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4.0,
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.8,
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (BuildContext context, int index) {
                            final String option = options.elementAt(index);
                            return InkWell(
                              onTap: () {
                                onSelected(option);
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(option),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
            // MODIFIED: Also update our state controller on selection.
            onSelected: (String selection) {
              debugPrint('You just selected $selection');
              _subjectController.text = selection;
              _subjectFocusNode.unfocus();
            },
          ),
          Divider(height: 1, color: Colors.grey[300]),
          GestureDetector(
            onTap: _handleLocationTap,
            child: AbsorbPointer(
              child: _buildTextField(
                controller: _locationController,
                icon: Icons.location_on,
                label: "Location (Your Area)",
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeFields() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _selectDate(context),
            child: AbsorbPointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: _backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _buildTextField(
                  controller: _dateController,
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
            onTap: () => _selectTime(context),
            child: AbsorbPointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: _backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _buildTextField(
                  controller: _timeController,
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
        onPressed: _searchForTutors,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    course.title,
                    style: const TextStyle(
                      color: _darkText,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
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
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:karreoapp/presentation/pages/student/book_tutor.dart';
import 'package:karreoapp/presentation/pages/student/student_home.dart';

class StudentHomeController extends GetxController {
  // --- STATE VARIABLES ---
  final selectedSessionType = 0.obs;
  final currentPosition = Rxn<Position>(); // For nullable reactive types
  final locationStatus = "Initializing...".obs;
  final user = FirebaseAuth.instance.currentUser;

  // --- TEXT EDITING CONTROLLERS ---
  late TextEditingController subjectController;
  late TextEditingController dateController;
  late TextEditingController timeController;
  late TextEditingController locationController;
  late FocusNode subjectFocusNode;

  // --- PRIVATE VARIABLES ---
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  // IMPORTANT: Replace with your actual OpenRouteService API key
  final String _orsApiKey =
      'eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6ImJiNzJiZGFmOTY0ZDQ3YmM5YjQzM2VjYjNhMmNmOWNiIiwiaCI6Im11cm11cjY0In0=';

  // --- STATIC DATA ---
  static const List<String> subjectSuggestions = <String>[
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

  // --- LIFECYCLE METHODS ---
  @override
  void onInit() {
    super.onInit();
    subjectController = TextEditingController();
    dateController = TextEditingController();
    timeController = TextEditingController();
    locationController = TextEditingController();
    subjectFocusNode = FocusNode();
    fetchCurrentLocation();
  }

  @override
  void onClose() {
    subjectController.dispose();
    dateController.dispose();
    timeController.dispose();
    locationController.dispose();
    subjectFocusNode.dispose();
    super.onClose();
  }

  // --- LOGIC METHODS ---
  Future<void> fetchCurrentLocation() async {
    locationStatus.value = "Fetching location...";

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      locationStatus.value = "Location services disabled.";
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        locationStatus.value = "Location permission denied.";
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      locationStatus.value = "Location permission permanently denied.";
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      currentPosition.value = position;
      locationStatus.value = "Location fetched ✅";
      await _getAddressFromCoordinates(position.latitude, position.longitude);

      if (user != null) {
        final geoFirePoint = GeoFirePoint(
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
      locationStatus.value = "Error fetching location: $e";
    }
  }

  Future<void> searchForTutors() async {
    // 1. VALIDATION
    if (subjectController.text.isEmpty ||
        dateController.text.isEmpty ||
        timeController.text.isEmpty) {
      Get.snackbar(
        "Input Required",
        "Please fill in subject, date, and time to search.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orangeAccent,
        colorText: Colors.white,
      );
      return;
    }

    if (currentPosition.value == null) {
      Get.snackbar(
        "Location Error",
        "Your location is not available. Please enable location services.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // 2. DURATION CALCULATION
    final int duration = switch (selectedSessionType.value) {
      1 => 2,
      2 => 4,
      _ => 1,
    };

    Get.dialog(
      const Center(child: CircularProgressIndicator(color: Color(0xFF3AB54A))),
      barrierDismissible: false,
    );

    try {
      final center = GeoFirePoint(
        GeoPoint(
          currentPosition.value!.latitude,
          currentPosition.value!.longitude,
        ),
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
                final geoData = data!['location']?['geo']?['geopoint'];
                if (geoData == null) return null;

                final geoPoint = geoData as GeoPoint;
                final straightLineDistance =
                    Geolocator.distanceBetween(
                      currentPosition.value!.latitude,
                      currentPosition.value!.longitude,
                      geoPoint.latitude,
                      geoPoint.longitude,
                    ) /
                    1000.0; // in km

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

      if (Get.isDialogOpen!) Get.back(); // Dismiss loading indicator

      Get.to(
        () => TutorSearchResultsPage(
          tutors: topFiveTutors,
          studentPosition: currentPosition.value!,
          orsApiKey: _orsApiKey,
          subject: subjectController.text,
          date: dateController.text,
          time: timeController.text,
          duration: duration,
        ),
      );
    } catch (e) {
      if (Get.isDialogOpen!) Get.back();
      Get.snackbar(
        "Search Failed",
        "An error occurred while searching: $e",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      debugPrint("Error fetching nearby tutors: $e");
    }
  }

  Future<void> handleLocationTap() async {
    if (user == null) {
      fetchCurrentLocation();
      return;
    }
    final docRef = FirebaseFirestore.instance
        .collection('students')
        .doc(user!.uid);
    final docSnap = await docRef.get();
    final data = docSnap.data();

    if (docSnap.exists &&
        data != null &&
        data['location']?['geo']?['geopoint'] != null) {
      final geoPoint = data['location']['geo']['geopoint'] as GeoPoint;
      // The dialog widget is built in the View file.
      // We use Get.find() to access the view instance and call its method.
      Get.find<StudentHomePage>().showLocationOptionsDialog(geoPoint);
    } else {
      await fetchCurrentLocation();
    }
  }

  Future<void> useSavedLocation(GeoPoint savedPoint) async {
    if (Get.isBottomSheetOpen!) Get.back(); // Close the modal sheet
    currentPosition.value = Position(
      latitude: savedPoint.latitude,
      longitude: savedPoint.longitude,
      timestamp: DateTime.now(),
      accuracy: 0.0,
      altitude: 0.0,
      altitudeAccuracy: 0,
      heading: 0.0,
      headingAccuracy: 0,
      speed: 0.0,
      speedAccuracy: 0.0,
    );
    await _getAddressFromCoordinates(savedPoint.latitude, savedPoint.longitude);
  }

  Future<void> useNewLocation() async {
    if (Get.isBottomSheetOpen!) Get.back(); // Close the modal sheet
    await fetchCurrentLocation();
  }

  Future<void> _getAddressFromCoordinates(double lat, double lon) async {
    try {
      List<geocoding.Placemark> placemarks = await geocoding
          .placemarkFromCoordinates(lat, lon);
      geocoding.Placemark place = placemarks[0];
      final address = '${place.street}, ${place.locality}, ${place.postalCode}';
      locationController.text = address;
    } catch (e) {
      debugPrint("Error getting address: $e");
      locationController.text = "Could not find address";
    }
  }

  Future<void> selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      _selectedDate = picked;
      dateController.text = DateFormat.yMMMd().format(_selectedDate!);
    }
  }

  Future<void> selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      _selectedTime = picked;
      timeController.text = _selectedTime!.format(context);
    }
  }

  void setSessionType(int index) {
    selectedSessionType.value = index;
  }
}

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:karreoapp/presentation/pages/tutor/tutor_home.dart';

// FIX 1: Import rxdart with a prefix to resolve naming conflicts with GetX.
import 'package:rxdart/rxdart.dart' as rx;

class TutorHomeController extends GetxController {
  // --- STATE & VARIABLES ---
  late Stream<TutorStats> tutorStatsStream;

  // FIX 2: Added reactive properties for the user's name and avatar URL,
  // which the view (TutorHomePage) now expects.
  final userName = 'Tutor'.obs;
  final userAvatarUrl = ''.obs;

  // --- FALLBACK & STATIC DATA ---
  final TutorStats fallbackStats = const TutorStats(
    upcomingSessions: 0,
    pendingRequests: 0,
    monthlyEarnings: 0.00,
  );

  // FIX 3: Converted the lists to RxList to make them reactive.
  // The Obx widgets in the view will now automatically update when these lists change.
  final RxList<TutorAppointment> upcomingAppointments = <TutorAppointment>[
    TutorAppointment(
      studentName: 'Riya Sharma',
      studentAvatarUrl: 'assets/images/avatar.png',
      subject: 'Physics - Grade 12',
      dateTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
    ),
    TutorAppointment(
      studentName: 'Aarav Singh',
      studentAvatarUrl: 'assets/images/avatar.png',
      subject: 'Mathematics',
      dateTime: DateTime.now().add(const Duration(days: 2, hours: 5)),
    ),
  ].obs;

  final RxList<BookingRequest> pendingRequests = <BookingRequest>[
    BookingRequest(
      studentName: 'Priya Patel',
      studentAvatarUrl: 'assets/images/avatar.png',
      subject: 'Chemistry',
      requestedDateTime: DateTime.now().add(const Duration(days: 4)),
      durationType: 'Single Hour',
    ),
  ].obs;

  // --- LIFECYCLE METHODS ---
  @override
  void onInit() {
    super.onInit();
    _loadUserData();
    // FIX 4: Made the stream a broadcast stream to prevent potential
    // "stream has already been listened to" errors if the widget rebuilds.
    tutorStatsStream = _getTutorStatsStream().asBroadcastStream();
    _fetchCurrentLocation();
  }

  // --- LOGIC & DATA STREAMS ---

  /// Loads user data from Firebase Auth and updates reactive properties.
  void _loadUserData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Provide a fallback for the display name.
      userName.value = user.displayName ?? 'Tutor';
      userAvatarUrl.value = user.photoURL ?? '';
    }
  }

  Stream<TutorStats> _getTutorStatsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value(fallbackStats);
    }

    final pendingStream = FirebaseFirestore.instance
        .collection('bookings')
        .where('tutorId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'pending')
        .snapshots();

    final upcomingStream = FirebaseFirestore.instance
        .collection('bookings')
        .where('tutorId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'confirmed')
        .where('sessionTimestamp', isGreaterThanOrEqualTo: Timestamp.now())
        .snapshots();

    // FIX 5: Use the 'rx' prefix for combineLatest2 from the rxdart package.
    return rx.Rx.combineLatest2(
      pendingStream,
      upcomingStream,
      (QuerySnapshot pending, QuerySnapshot upcoming) => TutorStats(
        pendingRequests: pending.docs.length,
        upcomingSessions: upcoming.docs.length,
        monthlyEarnings: 0.00, // This can be updated with a real stream later
      ),
    );
  }

  /// Fetches the tutor's current location and updates it in Firestore.
  Future<void> _fetchCurrentLocation() async {
    debugPrint("TutorHome: Starting location fetch...");

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint("TutorHome: Location services are disabled.");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint("TutorHome: Location permission denied by user.");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint("TutorHome: Location permission permanently denied.");
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      debugPrint("TutorHome: Location fetched successfully.");

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final geoFirePoint = GeoFirePoint(
          GeoPoint(position.latitude, position.longitude),
        );

        // Using .set with merge:true is safer than .update as it creates the
        // document if it doesn't exist, preventing crashes.
        await FirebaseFirestore.instance.collection("tutors").doc(user.uid).set(
          {
            "location": {
              'geo': geoFirePoint.data,
              "timestamp": Timestamp.now(),
            },
          },
          SetOptions(merge: true),
        );

        debugPrint(
          "TutorHome: Location updated in Firestore for user ${user.uid}",
        );
      }
    } catch (e) {
      debugPrint("TutorHome: Error fetching location: $e");
    }
  }
}

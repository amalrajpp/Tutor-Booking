import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart'
    hide Rx; // ✅ FIX 1: Hiding Rx from GetX to prevent conflicts.
import 'package:karreoapp/presentation/pages/tutor/tutor_home.dart';

import 'package:rxdart/rxdart.dart';

class TutorHomeController extends GetxController {
  // --- STATE & VARIABLES ---
  // ✅ FIX 2: Removed instance variable for user. It's safer to get the
  // current user inside the methods to ensure you always have the latest auth state.
  late Stream<TutorStats> tutorStatsStream;

  // --- FALLBACK & STATIC DATA ---
  final TutorStats fallbackStats = const TutorStats(
    upcomingSessions: 0,
    pendingRequests: 0,
    monthlyEarnings: 0.00,
  );

  // You can later replace this static data with streams from Firestore
  final List<TutorAppointment> upcomingAppointments = [
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
  ];

  final List<BookingRequest> pendingRequests = [
    BookingRequest(
      studentName: 'Priya Patel',
      studentAvatarUrl: 'assets/images/avatar.png',
      subject: 'Chemistry',
      requestedDateTime: DateTime.now().add(const Duration(days: 4)),
      durationType: 'Single Hour',
    ),
  ];

  // --- LIFECYCLE METHODS ---
  @override
  void onInit() {
    super.onInit();
    tutorStatsStream = _getTutorStatsStream();
    _fetchCurrentLocation();
  }

  // --- LOGIC & DATA STREAMS ---
  Stream<TutorStats> _getTutorStatsStream() {
    final user = FirebaseAuth.instance.currentUser; // Get current user here
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

    return Rx.combineLatest2(
      pendingStream,
      upcomingStream,
      (QuerySnapshot pending, QuerySnapshot upcoming) => TutorStats(
        pendingRequests: pending.docs.length,
        upcomingSessions: upcoming.docs.length,
        monthlyEarnings: 0.00, // Static for now
      ),
    );
  }

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

      final user = FirebaseAuth.instance.currentUser; // Get current user here
      if (user != null) {
        final geoFirePoint = GeoFirePoint(
          GeoPoint(position.latitude, position.longitude),
        );

        await FirebaseFirestore.instance
            .collection("tutors")
            .doc(user.uid)
            .update({
              "location": {
                'geo': geoFirePoint.data,
                "timestamp": Timestamp.now(),
              },
            });
        debugPrint(
          "TutorHome: Location updated in Firestore for user ${user.uid}",
        );
      }
    } catch (e) {
      debugPrint("TutorHome: Error fetching location: $e");
    }
  }
}

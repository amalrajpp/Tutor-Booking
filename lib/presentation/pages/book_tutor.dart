import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class TutorSearchResultsPage extends StatefulWidget {
  final List<Map<String, dynamic>> tutors;
  final Position studentPosition;
  final String orsApiKey;
  final String subject;
  final String date;
  final String time;
  final int duration;

  const TutorSearchResultsPage({
    Key? key,
    required this.tutors,
    required this.studentPosition,
    required this.orsApiKey,
    required this.subject,
    required this.date,
    required this.time,
    required this.duration,
  }) : super(key: key);

  @override
  State<TutorSearchResultsPage> createState() => _TutorSearchResultsPageState();
}

class _TutorSearchResultsPageState extends State<TutorSearchResultsPage> {
  late List<Map<String, dynamic>?> _drivingRoutes;

  static const Color _primaryGreen = Color(0xFF3AB54A);
  static const Color _darkText = Color(0xFF231F20);
  static const Color _backgroundColor = Color(0xFFEBF6EC);
  static const Color _starColor = Color(0xFFFFC107);

  @override
  void initState() {
    super.initState();
    _drivingRoutes = List.filled(widget.tutors.length, null);
    _calculateAllDrivingRoutes();
  }

  // --- NEW BOOKING LOGIC ---

  Future<void> _handleBooking(Map<String, dynamic> tutorData) async {
    // Show a loading dialog to the user
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const Center(child: CircularProgressIndicator(color: _primaryGreen)),
    );

    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      Navigator.of(context).pop(); // Dismiss loading
      _showErrorDialog("You must be logged in to book a session.");
      return;
    }

    // Prepare data for Firestore
    final studentId = currentUser.uid;
    final studentName = currentUser.displayName ?? "Student";
    final tutorId =
        tutorData['id']; // Assumes the tutor's UID is passed as 'id'
    final tutorName = tutorData['name'];

    // Convert date and time strings to the required formats
    final DateTime sessionDate = DateFormat('yMMMd').parse(widget.date);
    final String availabilityDocId =
        "${tutorId}_${DateFormat('yyyy-MM-dd').format(sessionDate)}";
    final DateTime sessionTime = DateFormat('h:mm a').parse(widget.time);
    final String timeSlotKey = DateFormat('HH:mm').format(sessionTime);

    // Get references to Firestore documents
    final availabilityDocRef = FirebaseFirestore.instance
        .collection('tutorAvailabilities')
        .doc(availabilityDocId);
    final newBookingRef = FirebaseFirestore.instance
        .collection('bookings')
        .doc();

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // 1. Read the tutor's availability for the given day
        final availabilitySnapshot = await transaction.get(availabilityDocRef);

        if (!availabilitySnapshot.exists) {
          throw ('Tutor has not set their availability for this day.');
        }

        final availabilityData = availabilitySnapshot.data()!;
        final timeSlots = availabilityData['timeSlots'] as Map<String, dynamic>;
        final slotData = timeSlots[timeSlotKey];

        // 2. Verify the slot is available
        if (slotData == null || slotData['status'] != 'available') {
          throw ('This time slot is no longer available. Please select another.');
        }

        // 3. Create the booking document data
        final Timestamp sessionTimestamp = Timestamp.fromDate(
          DateTime(
            sessionDate.year,
            sessionDate.month,
            sessionDate.day,
            sessionTime.hour,
            sessionTime.minute,
          ),
        );

        final bookingData = {
          'studentId': studentId,
          'studentName': studentName,
          'tutorId': tutorId,
          'tutorName': tutorName,
          'subject': widget.subject,
          'sessionTimestamp': sessionTimestamp,
          'duration': widget.duration,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        };

        // 4. Perform the writes: create booking and update availability
        transaction.set(newBookingRef, bookingData);
        transaction.update(availabilityDocRef, {
          'timeSlots.$timeSlotKey': {
            'status': 'booked',
            'bookingId': newBookingRef.id,
            'studentId': studentId,
          },
        });
      });

      // If transaction completes successfully
      Navigator.of(context).pop(); // Dismiss loading
      _showSuccessDialog();
    } catch (e) {
      Navigator.of(context).pop(); // Dismiss loading
      _showErrorDialog(e.toString());
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Booking Successful!'),
        content: const Text(
          'Your request has been sent to the tutor. You will be notified upon confirmation.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Pop twice to dismiss the dialog and go back from the results page
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Booking Failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // --- UNCHANGED LOGIC ---
  Future<Map<String, dynamic>?> _fetchDrivingRoute(
    GeoPoint tutorGeoPoint,
  ) async {
    final url = Uri.parse(
      "https://api.openrouteservice.org/v2/directions/driving-car",
    );
    final headers = {
      "Authorization": widget.orsApiKey,
      "Content-Type": "application/json",
    };
    final body = jsonEncode({
      "coordinates": [
        [widget.studentPosition.longitude, widget.studentPosition.latitude],
        [tutorGeoPoint.longitude, tutorGeoPoint.latitude],
      ],
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 &&
          data["routes"] != null &&
          data["routes"].isNotEmpty) {
        final summary = data["routes"][0]["summary"];
        return {
          "distance": summary["distance"] / 1000.0, // in km
          "duration": summary["duration"] / 60.0, // in minutes
        };
      } else {
        debugPrint(
          "ORS Error: ${data['error']?['message'] ?? 'No route found.'}",
        );
        return null;
      }
    } catch (e) {
      debugPrint("ORS request failed: $e");
      return null;
    }
  }

  Future<void> _calculateAllDrivingRoutes() async {
    for (int i = 0; i < widget.tutors.length; i++) {
      final tutorData = widget.tutors[i];
      final route = await _fetchDrivingRoute(tutorData['geoPoint'] as GeoPoint);
      if (mounted) {
        setState(() {
          _drivingRoutes[i] =
              route ?? {'error': true}; // Use a special map for errors
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text("Tutors for ${widget.subject}"),
        backgroundColor: _darkText,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: AnimationLimiter(
        child: widget.tutors.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
                itemCount: widget.tutors.length,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 20.0,
                ),
                itemBuilder: (context, index) {
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 400),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: _buildTutorCard(context, index),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 100, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              "No Tutors Found",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _darkText.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "There are no available tutors within a 50km radius. Try checking back later.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTutorCard(BuildContext context, int index) {
    final tutor = widget.tutors[index];
    final routeInfo = _drivingRoutes[index];
    final name = tutor['name'] as String? ?? 'Unnamed Tutor';
    final rating = (tutor["rating"] as num? ?? 0.0).toDouble();

    return Card(
      margin: const EdgeInsets.only(bottom: 20.0),
      elevation: 5,
      shadowColor: _darkText.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, const Color(0xFFF8FDF8)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: _primaryGreen,
                    child: CircleAvatar(
                      radius: 26,
                      backgroundColor: _backgroundColor,
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'T',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _primaryGreen,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 19,
                            color: _darkText,
                          ),
                        ),
                        const SizedBox(height: 5),
                        _buildRating(rating),
                      ],
                    ),
                  ),
                  _buildTrailingWidget(routeInfo),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // TODO: Implement navigation to tutor's full profile page
                      },
                      child: const Text('View Profile'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _darkText.withOpacity(0.8),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      // MODIFIED: onPressed now calls the booking logic
                      onPressed: () => _handleBooking(tutor),
                      child: const Text('Book Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRating(double rating) {
    return Row(
      children: [
        Icon(Icons.star_rounded, color: _starColor, size: 22),
        const SizedBox(width: 5),
        Text(
          rating.toStringAsFixed(1), // e.g., 4.5
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _darkText,
          ),
        ),
        Text(
          " rating",
          style: TextStyle(fontSize: 15, color: Colors.grey[700]),
        ),
      ],
    );
  }

  Widget _buildTrailingWidget(Map<String, dynamic>? routeInfo) {
    if (routeInfo == null) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: _primaryGreen,
        ),
      );
    } else if (routeInfo.containsKey('error')) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
          SizedBox(height: 2),
          Text(
            "Route N/A",
            style: TextStyle(color: Colors.redAccent, fontSize: 10),
          ),
        ],
      );
    } else {
      final distance = routeInfo['distance'] as double;
      final duration = routeInfo['duration'] as double;
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            "${distance.toStringAsFixed(1)} km",
            style: const TextStyle(
              color: _primaryGreen,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            "~${duration.toStringAsFixed(0)} min",
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      );
    }
  }
}

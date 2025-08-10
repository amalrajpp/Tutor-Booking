import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:karreoapp/presentation/pages/custom.dart';
import 'package:karreoapp/presentation/pages/earning.dart';
import 'package:karreoapp/presentation/pages/request.dart';
import 'package:karreoapp/presentation/pages/student_profile.dart';
import 'package:karreoapp/presentation/pages/tutor_availability.dart';
import 'package:karreoapp/presentation/pages/tutor_profile.dart';
import 'package:karreoapp/presentation/pages/upcoming.dart';
import 'package:rxdart/rxdart.dart'; // Required for combining streams

// Imports required for location fetching
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';

// --- Data Models (Optimized with const constructors) ---

class TutorStats {
  final int upcomingSessions;
  final int pendingRequests;
  final double monthlyEarnings;

  const TutorStats({
    required this.upcomingSessions,
    required this.pendingRequests,
    required this.monthlyEarnings,
  });
}

class TutorAppointment {
  final String studentName;
  final String studentAvatarUrl;
  final String subject;
  final DateTime dateTime;

  const TutorAppointment({
    required this.studentName,
    required this.studentAvatarUrl,
    required this.subject,
    required this.dateTime,
  });
}

class BookingRequest {
  final String studentName;
  final String studentAvatarUrl;
  final String subject;
  final DateTime requestedDateTime;
  final String durationType; // e.g., "Single Hour", "Flexible"

  const BookingRequest({
    required this.studentName,
    required this.studentAvatarUrl,
    required this.subject,
    required this.requestedDateTime,
    required this.durationType,
  });
}

// --- Tutor Home Page Widget ---

class TutorHome extends StatefulWidget {
  const TutorHome({super.key});

  @override
  State<TutorHome> createState() => _TutorHomeState();
}

class _TutorHomeState extends State<TutorHome> {
  // --- State & Variables ---
  static const Color _primaryGreen = Color(0xFF3AB54A);
  static const Color _darkText = Color(0xFF231F20);
  static const Color _backgroundColor = Color(0xFFEBF6EC);

  // Fallback data is now const.
  final TutorStats _fallbackStats = const TutorStats(
    upcomingSessions: 0,
    pendingRequests: 0,
    monthlyEarnings: 0.00,
  );

  final List<TutorAppointment> _upcomingAppointments = [
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

  final List<BookingRequest> _pendingRequests = [
    BookingRequest(
      studentName: 'Priya Patel',
      studentAvatarUrl: 'assets/images/avatar.png',
      subject: 'Chemistry',
      requestedDateTime: DateTime.now().add(const Duration(days: 4)),
      durationType: 'Single Hour',
    ),
  ];

  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();
  }

  // --- Logic & Data Streams ---

  Stream<TutorStats> _getTutorStatsStream() {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return Stream.value(
        const TutorStats(
          upcomingSessions: 0,
          pendingRequests: 0,
          monthlyEarnings: 0,
        ),
      );
    }

    final pendingStream = FirebaseFirestore.instance
        .collection('bookings')
        .where('tutorId', isEqualTo: currentUser.uid)
        .where('status', isEqualTo: 'pending')
        .snapshots();

    final upcomingStream = FirebaseFirestore.instance
        .collection('bookings')
        .where('tutorId', isEqualTo: currentUser.uid)
        .where('status', isEqualTo: 'confirmed')
        .where('sessionTimestamp', isGreaterThanOrEqualTo: Timestamp.now())
        .snapshots();

    return Rx.combineLatest2(
      pendingStream,
      upcomingStream,
      (QuerySnapshot pending, QuerySnapshot upcoming) => TutorStats(
        pendingRequests: pending.docs.length,
        upcomingSessions: upcoming.docs.length,
        monthlyEarnings:
            0.00, // Static for now, can be replaced with real data later
      ),
    );
  }

  // OPTIMIZED: Removed setState calls as _locationStatus is not used in the UI.
  // This prevents unnecessary widget rebuilds.
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

      if (user != null) {
        final geoFirePoint = GeoFirePoint(
          GeoPoint(position.latitude, position.longitude),
        );

        await FirebaseFirestore.instance
            .collection("tutors")
            .doc(user!.uid)
            .update({
              "location": {
                'geo': geoFirePoint.data,
                "timestamp": Timestamp.now(),
              },
            });
        debugPrint(
          "TutorHome: Location updated in Firestore for user ${user!.uid}",
        );
      }
    } catch (e) {
      debugPrint("TutorHome: Error fetching location: $e");
    }
  }

  // --- UI Builder Methods ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeaderAndDashboard(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  _buildSectionHeader('Upcoming Appointments', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UpcomingBookingsPage(),
                      ),
                    );
                  }),
                  const SizedBox(height: 10),
                  _buildUpcomingAppointmentsList(),
                  const SizedBox(height: 30),
                  _buildSectionHeader('Pending Requests', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BookingRequestsPage(),
                      ),
                    );
                  }),
                  const SizedBox(height: 10),
                  _buildPendingRequestsList(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderAndDashboard() {
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
                      "Hello, Amal!\nHere's your dashboard.",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
        Positioned(
          top: 260,
          child: StreamBuilder<TutorStats>(
            stream: _getTutorStatsStream(),
            builder: (context, snapshot) {
              final stats = snapshot.data ?? _fallbackStats;
              return _buildDashboardCard(stats);
            },
          ),
        ),
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
              MaterialPageRoute(
                builder: (context) => const SetAvailabilityPage(),
              ),
            );
          },
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TutorProfilePage()),
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

  Widget _buildDashboardCard(TutorStats stats) {
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
      child: _buildStatsSection(stats),
    );
  }

  Widget _buildStatsSection(TutorStats stats) {
    final formatCurrency = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatColumn(
          stats.upcomingSessions.toString(),
          'Upcoming',
          Icons.event_note,
          Colors.blue,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const UpcomingBookingsPage(),
              ),
            );
          },
        ),
        _buildStatColumn(
          stats.pendingRequests.toString(),
          'Requests',
          Icons.hourglass_top,
          Colors.orange,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const BookingRequestsPage(),
              ),
            );
          },
        ),
        _buildStatColumn(
          formatCurrency.format(stats.monthlyEarnings),
          'Earnings',
          Icons.account_balance_wallet,
          _primaryGreen,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const EarningsPage()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatColumn(
    String value,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: _darkText,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(color: _darkText.withOpacity(0.7), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onViewAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _darkText,
          ),
        ),
        TextButton(
          onPressed: onViewAll,
          child: const Text('View All', style: TextStyle(color: _primaryGreen)),
        ),
      ],
    );
  }

  Widget _buildUpcomingAppointmentsList() {
    return ListView.separated(
      itemCount: _upcomingAppointments.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildAppointmentCard(_upcomingAppointments[index]);
      },
    );
  }

  Widget _buildAppointmentCard(TutorAppointment appointment) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 25,
          backgroundImage: AssetImage(appointment.studentAvatarUrl),
        ),
        title: Text(
          appointment.studentName,
          style: const TextStyle(fontWeight: FontWeight.bold, color: _darkText),
        ),
        subtitle: Text(
          '${appointment.subject}\n${DateFormat.yMMMd().add_jm().format(appointment.dateTime)}',
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildPendingRequestsList() {
    return ListView.separated(
      itemCount: _pendingRequests.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildRequestCard(_pendingRequests[index]);
      },
    );
  }

  Widget _buildRequestCard(BookingRequest request) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              radius: 25,
              backgroundImage: AssetImage(request.studentAvatarUrl),
            ),
            title: Text(
              request.studentName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: _darkText,
              ),
            ),
            subtitle: Text('${request.subject} - ${request.durationType}'),
          ),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(onPressed: () {}, child: const Text('Decline')),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(backgroundColor: _primaryGreen),
                child: const Text(
                  'Accept',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

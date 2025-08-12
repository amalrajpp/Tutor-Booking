import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:karreoapp/presentation/controllers/tutor_home_controller.dart';
import 'package:karreoapp/presentation/pages/tutor/earning.dart';
import 'package:karreoapp/presentation/pages/tutor/request.dart';
import 'package:karreoapp/presentation/pages/tutor/tutor_availability.dart';
import 'package:karreoapp/presentation/pages/tutor/tutor_profile.dart';
import 'package:karreoapp/presentation/pages/tutor/upcoming.dart';

// --- Data Models (Can be moved to separate files for larger projects) ---
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
  final String durationType;

  const BookingRequest({
    required this.studentName,
    required this.studentAvatarUrl,
    required this.subject,
    required this.requestedDateTime,
    required this.durationType,
  });
}

// --- Tutor Home Page Widget (View) ---
class TutorHomePage extends GetView<TutorHomeController> {
  const TutorHomePage({super.key});

  // --- UI Constants ---
  static const Color _primaryGreen = Color(0xFF3AB54A);
  static const Color _darkText = Color(0xFF231F20);
  static const Color _backgroundColor = Color(0xFFEBF6EC);

  @override
  Widget build(BuildContext context) {
    // Initialize the controller. GetX handles the lifecycle automatically.
    Get.put(TutorHomeController());

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeaderAndDashboard(context),
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

  Widget _buildHeaderAndDashboard(BuildContext context) {
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
                  _buildCustomAppBar(context),
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
            stream: controller.tutorStatsStream, // Get stream from controller
            builder: (context, snapshot) {
              final stats =
                  snapshot.data ??
                  controller.fallbackStats; // Use fallback from controller
              return _buildDashboardCard(context, stats);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCustomAppBar(BuildContext context) {
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

  Widget _buildDashboardCard(BuildContext context, TutorStats stats) {
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
      child: _buildStatsSection(context, stats),
    );
  }

  Widget _buildStatsSection(BuildContext context, TutorStats stats) {
    final formatCurrency = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatColumn(
          context,
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
          context,
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
          context,
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
    BuildContext context,
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
      itemCount:
          controller.upcomingAppointments.length, // Get list from controller
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildAppointmentCard(controller.upcomingAppointments[index]);
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
      itemCount: controller.pendingRequests.length, // Get list from controller
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildRequestCard(controller.pendingRequests[index]);
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

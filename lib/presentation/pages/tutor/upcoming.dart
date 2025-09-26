import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// Data model for an upcoming booking
class UpcomingBooking {
  final String id; // Document ID of the booking
  final String studentName;
  final String subject;
  final DateTime sessionDateTime;
  final int duration;

  UpcomingBooking({
    required this.id,
    required this.studentName,
    required this.subject,
    required this.sessionDateTime,
    required this.duration,
  });

  // Factory constructor to create an UpcomingBooking from a Firestore document
  factory UpcomingBooking.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UpcomingBooking(
      id: doc.id,
      studentName: data['studentName'] ?? 'Unknown Student',
      subject: data['subject'] ?? 'No Subject',
      sessionDateTime: (data['sessionTimestamp'] as Timestamp).toDate(),
      duration: data['duration'] ?? 1,
    );
  }
}

class UpcomingBookingsPage extends StatefulWidget {
  const UpcomingBookingsPage({Key? key}) : super(key: key);

  @override
  State<UpcomingBookingsPage> createState() => _UpcomingBookingsPageState();
}

class _UpcomingBookingsPageState extends State<UpcomingBookingsPage> {
  // --- UI Constants ---
  static const Color _primaryGreen = Color(0xFF3AB54A);
  static const Color _darkText = Color(0xFF231F20);
  static const Color _backgroundColor = Color(0xFFF7F7F7);

  // --- Firestore Logic ---

  Stream<List<UpcomingBooking>> _getUpcomingBookings() {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return Stream.value([]); // Return empty stream if user is not logged in
    }

    return FirebaseFirestore.instance
        .collection('bookings')
        .where('tutorId', isEqualTo: currentUser.uid)
        .where('status', isEqualTo: 'confirmed')
        .where('sessionTimestamp', isGreaterThanOrEqualTo: Timestamp.now())
        .orderBy('sessionTimestamp', descending: false) // Show soonest first
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => UpcomingBooking.fromFirestore(doc))
              .toList(),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text('Upcoming Bookings'),
        backgroundColor: _darkText,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<List<UpcomingBooking>>(
        stream: _getUpcomingBookings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _primaryGreen),
            );
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final bookings = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              return _buildBookingCard(bookings[index]);
            },
          );
        },
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
            Icon(
              Icons.event_available_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'No Upcoming Bookings',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'You have no confirmed sessions in the future.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(UpcomingBooking booking) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: _primaryGreen.withOpacity(0.1),
                  child: Text(
                    booking.studentName.isNotEmpty
                        ? booking.studentName[0].toUpperCase()
                        : 'S',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _primaryGreen,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.studentName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: _darkText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        booking.subject,
                        style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(
              Icons.calendar_today_rounded,
              DateFormat.yMMMMd('en_US').format(booking.sessionDateTime),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.access_time_rounded,
              DateFormat.jm().format(booking.sessionDateTime),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.timelapse_rounded,
              '${booking.duration} Hour${booking.duration > 1 ? 's' : ''}',
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Implement logic to join a virtual meeting or view details
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.video_call_rounded),
                label: const Text('Join Session'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        const SizedBox(width: 12),
        Text(text, style: const TextStyle(fontSize: 15, color: _darkText)),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// Data model for a booking request
class BookingRequest {
  final String id; // Document ID of the booking
  final String studentName;
  final String subject;
  final DateTime sessionDateTime;
  final int duration;
  final String studentId;
  final String tutorId;

  BookingRequest({
    required this.id,
    required this.studentName,
    required this.subject,
    required this.sessionDateTime,
    required this.duration,
    required this.studentId,
    required this.tutorId,
  });

  // Factory constructor to create a BookingRequest from a Firestore document
  factory BookingRequest.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return BookingRequest(
      id: doc.id,
      studentName: data['studentName'] ?? 'Unknown Student',
      subject: data['subject'] ?? 'No Subject',
      sessionDateTime: (data['sessionTimestamp'] as Timestamp).toDate(),
      duration: data['duration'] ?? 1,
      studentId: data['studentId'] ?? '',
      tutorId: data['tutorId'] ?? '',
    );
  }
}

class BookingRequestsPage extends StatefulWidget {
  const BookingRequestsPage({Key? key}) : super(key: key);

  @override
  State<BookingRequestsPage> createState() => _BookingRequestsPageState();
}

class _BookingRequestsPageState extends State<BookingRequestsPage> {
  // --- UI Constants ---
  static const Color _primaryGreen = Color(0xFF3AB54A);
  static const Color _darkText = Color(0xFF231F20);
  static const Color _backgroundColor = Color(0xFFF7F7F7);

  // --- Firestore Logic ---

  Stream<List<BookingRequest>> _getBookingRequests() {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return Stream.value([]); // Return empty stream if user is not logged in
    }

    return FirebaseFirestore.instance
        .collection('bookings')
        .where('tutorId', isEqualTo: currentUser.uid)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => BookingRequest.fromFirestore(doc))
              .toList(),
        );
  }

  Future<void> _acceptRequest(BookingRequest request) async {
    final bookingRef = FirebaseFirestore.instance
        .collection('bookings')
        .doc(request.id);

    try {
      await bookingRef.update({'status': 'confirmed'});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking confirmed successfully!'),
          backgroundColor: _primaryGreen,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error confirming booking: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _declineRequest(BookingRequest request) async {
    final bookingRef = FirebaseFirestore.instance
        .collection('bookings')
        .doc(request.id);
    final availabilityDocId =
        "${request.tutorId}_${DateFormat('yyyy-MM-dd').format(request.sessionDateTime)}";
    final availabilityRef = FirebaseFirestore.instance
        .collection('tutorAvailabilities')
        .doc(availabilityDocId);
    final timeSlotKey = DateFormat('HH:mm').format(request.sessionDateTime);

    // Use a batch write to ensure both operations succeed or fail together
    WriteBatch batch = FirebaseFirestore.instance.batch();

    // 1. Update the booking status to 'declined'
    batch.update(bookingRef, {'status': 'declined'});

    // 2. Reset the availability slot to 'available'
    batch.update(availabilityRef, {
      'timeSlots.$timeSlotKey': {'status': 'available'},
    });

    try {
      await batch.commit();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking has been declined.'),
          backgroundColor: Colors.grey,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error declining booking: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text('Booking Requests'),
        backgroundColor: _darkText,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<List<BookingRequest>>(
        stream: _getBookingRequests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _primaryGreen),
            );
          }
          if (snapshot.hasError) {
            print(snapshot.error);
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final requests = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              return _buildRequestCard(requests[index]);
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
              Icons.notifications_off_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'No Pending Requests',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'You have no new booking requests at the moment.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(BookingRequest request) {
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
                    request.studentName.isNotEmpty
                        ? request.studentName[0].toUpperCase()
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
                        request.studentName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: _darkText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        request.subject,
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
              DateFormat.yMMMMd('en_US').format(request.sessionDateTime),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.access_time_rounded,
              DateFormat.jm().format(request.sessionDateTime),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.timelapse_rounded,
              '${request.duration} Hour${request.duration > 1 ? 's' : ''}',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _declineRequest(request),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _acceptRequest(request),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Accept'),
                  ),
                ),
              ],
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

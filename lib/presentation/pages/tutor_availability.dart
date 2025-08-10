import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class SetAvailabilityPage extends StatefulWidget {
  const SetAvailabilityPage({Key? key}) : super(key: key);

  @override
  State<SetAvailabilityPage> createState() => _SetAvailabilityPageState();
}

class _SetAvailabilityPageState extends State<SetAvailabilityPage> {
  // --- UI Constants ---
  static const Color _primaryGreen = Color(0xFF3AB54A);
  static const Color _darkText = Color(0xFF231F20);
  static const Color _backgroundColor = Color(0xFFF7F7F7);
  static const Color _lightGrey = Color(0xFFE8E8E8);

  // --- State Variables ---
  DateTime _selectedDate = DateTime.now();
  Map<String, String> _timeSlots = {};
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _generateInitialTimeSlots();
    _fetchAvailabilityForSelectedDate();
  }

  // --- Logic ---

  void _generateInitialTimeSlots() {
    // Generate hourly slots from 8 AM to 8 PM
    for (int i = 8; i <= 20; i++) {
      final time = TimeOfDay(hour: i, minute: 0);
      final formattedTime =
          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      _timeSlots[formattedTime] = 'unavailable';
    }
  }

  Future<void> _fetchAvailabilityForSelectedDate() async {
    setState(() => _isLoading = true);

    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      // Handle user not logged in
      return;
    }

    final String docId =
        "${user.uid}_${DateFormat('yyyy-MM-dd').format(_selectedDate)}";
    final docRef = FirebaseFirestore.instance
        .collection('tutorAvailabilities')
        .doc(docId);

    try {
      final doc = await docRef.get();
      // Reset all slots to unavailable before loading saved data
      _generateInitialTimeSlots();

      if (doc.exists && doc.data()?['timeSlots'] != null) {
        final savedSlots = doc.data()!['timeSlots'] as Map<String, dynamic>;
        savedSlots.forEach((key, value) {
          if (_timeSlots.containsKey(key)) {
            _timeSlots[key] = value['status'] ?? 'unavailable';
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching availability: $e");
      // Handle error, maybe show a snackbar
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveAvailability() async {
    setState(() => _isSaving = true);

    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isSaving = false);
      // Handle user not logged in
      return;
    }

    final String docId =
        "${user.uid}_${DateFormat('yyyy-MM-dd').format(_selectedDate)}";
    final docRef = FirebaseFirestore.instance
        .collection('tutorAvailabilities')
        .doc(docId);

    final Map<String, dynamic> dataToSave = {};
    _timeSlots.forEach((key, value) {
      dataToSave[key] = {'status': value};
    });

    try {
      await docRef.set({
        'tutorId': user.uid,
        'date': Timestamp.fromDate(_selectedDate),
        'timeSlots': dataToSave,
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Availability saved successfully!'),
          backgroundColor: _primaryGreen,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving availability: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    _fetchAvailabilityForSelectedDate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Set Your Availability',
          style: TextStyle(color: _darkText),
        ),
        backgroundColor: Colors.white,
        foregroundColor: _darkText,
        elevation: 1,
      ),
      body: Column(
        children: [
          _buildDateSelector(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: _primaryGreen),
                  )
                : _buildTimeSlotList(),
          ),
        ],
      ),
      floatingActionButton: _isSaving
          ? const FloatingActionButton(
              onPressed: null,
              backgroundColor: _primaryGreen,
              child: CircularProgressIndicator(color: Colors.white),
            )
          : FloatingActionButton.extended(
              onPressed: _saveAvailability,
              backgroundColor: _primaryGreen,
              icon: const Icon(Icons.save, color: Colors.white),
              label: const Text(
                'Save Changes',
                style: TextStyle(color: Colors.white),
              ),
            ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      color: Colors.white,
      child: SizedBox(
        height: 70,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 30, // Show next 30 days
          itemBuilder: (context, index) {
            final date = DateTime.now().add(Duration(days: index));
            final isSelected = DateUtils.isSameDay(_selectedDate, date);
            return _buildDateChip(date, isSelected);
          },
        ),
      ),
    );
  }

  Widget _buildDateChip(DateTime date, bool isSelected) {
    return GestureDetector(
      onTap: () => _onDateSelected(date),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _primaryGreen : _lightGrey,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _primaryGreen.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              DateFormat('d').format(date), // Day number
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : _darkText,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              DateFormat('E').format(date), // Day of week (e.g., Mon)
              style: TextStyle(
                fontSize: 14,
                color: isSelected ? Colors.white70 : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlotList() {
    final sortedKeys = _timeSlots.keys.toList()..sort();

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: sortedKeys.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final timeKey = sortedKeys[index];
        final status = _timeSlots[timeKey]!;
        final isAvailable = status == 'available';

        // Cannot change status if already booked
        final isBooked = status == 'booked';

        final time = DateFormat('HH:mm').parse(timeKey);
        final formattedTime = DateFormat('h:mm a').format(time);

        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: isBooked
                ? null
                : () {
                    setState(() {
                      _timeSlots[timeKey] = isAvailable
                          ? 'unavailable'
                          : 'available';
                    });
                  },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Text(
                    formattedTime,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _darkText,
                    ),
                  ),
                  const Spacer(),
                  if (isBooked)
                    const Text(
                      'Booked',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  else
                    Switch(
                      value: isAvailable,
                      onChanged: (value) {
                        setState(() {
                          _timeSlots[timeKey] = value
                              ? 'available'
                              : 'unavailable';
                        });
                      },
                      activeColor: _primaryGreen,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

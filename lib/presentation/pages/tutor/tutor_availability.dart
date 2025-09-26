import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
// A superior calendar view, add `table_calendar: ^3.0.9` to your pubspec.yaml
import 'package:table_calendar/table_calendar.dart';

// --- ENUM & Data Class for Availability Structure (No Changes) ---
enum AvailabilityType { fullDay, morning, afternoon, custom }

class TimeRange {
  TimeOfDay start;
  TimeOfDay end;
  TimeRange({required this.start, required this.end});
  double get startAsDouble => start.hour + start.minute / 60.0;
  double get endAsDouble => end.hour + end.minute / 60.0;
}

// --- Main Widget ---
class SetAvailabilityPage extends StatefulWidget {
  const SetAvailabilityPage({Key? key}) : super(key: key);

  @override
  State<SetAvailabilityPage> createState() => _SetAvailabilityPageState();
}

class _SetAvailabilityPageState extends State<SetAvailabilityPage> {
  // --- UI Constants & Theme ---
  static const Color _primaryGreen = Color(0xFF3AB54A);
  static const Color _darkText = Color(0xFF231F20);
  static const Color _backgroundColor = Color(
    0xFFF7F9FC,
  ); // Lighter, cleaner background

  // --- State Variables ---
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDate = DateTime.now();
  bool _isLoading = true;
  bool _isSaving = false;
  AvailabilityType _selectedType = AvailabilityType.custom;
  List<TimeRange> _customRanges = [];

  //<editor-fold desc="Data Logic & State Management (unchanged)">
  @override
  void initState() {
    super.initState();
    _fetchAvailabilityForSelectedDate();
  }

  Future<void> _fetchAvailabilityForSelectedDate() async {
    setState(() {
      _isLoading = true;
      _selectedType = AvailabilityType.custom;
      _customRanges = [];
    });

    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final String docId =
        "${user.uid}_${DateFormat('yyyy-MM-dd').format(_selectedDate)}";
    final docRef = FirebaseFirestore.instance
        .collection('tutorAvailabilities')
        .doc(docId);

    try {
      final doc = await docRef.get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final typeString = data['type'] as String?;
        _selectedType = AvailabilityType.values.firstWhere(
          (e) => e.toString().split('.').last == typeString,
          orElse: () => AvailabilityType.custom,
        );

        if (_selectedType == AvailabilityType.custom &&
            data['ranges'] != null) {
          final rangesData = data['ranges'] as List<dynamic>;
          _customRanges = rangesData.map((range) {
            final start = TimeOfDay.fromDateTime(
              DateFormat('HH:mm').parse(range['start']),
            );
            final end = TimeOfDay.fromDateTime(
              DateFormat('HH:mm').parse(range['end']),
            );
            return TimeRange(start: start, end: end);
          }).toList();
        }
      }
    } catch (e) {
      debugPrint("Error fetching availability: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load availability: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAvailability() async {
    setState(() => _isSaving = true);

    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isSaving = false);
      return;
    }

    final String docId =
        "${user.uid}_${DateFormat('yyyy-MM-dd').format(_selectedDate)}";
    final docRef = FirebaseFirestore.instance
        .collection('tutorAvailabilities')
        .doc(docId);

    final Map<String, dynamic> dataToSave = {
      'tutorId': user.uid,
      'date': Timestamp.fromDate(_selectedDate),
      'type': _selectedType.toString().split('.').last,
      'ranges': [],
    };

    if (_selectedType == AvailabilityType.custom) {
      dataToSave['ranges'] = _customRanges.map((range) {
        return {
          'start':
              '${range.start.hour.toString().padLeft(2, '0')}:${range.start.minute.toString().padLeft(2, '0')}',
          'end':
              '${range.end.hour.toString().padLeft(2, '0')}:${range.end.minute.toString().padLeft(2, '0')}',
        };
      }).toList();
    }

    try {
      await docRef.set(dataToSave);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Availability saved successfully!'),
          backgroundColor: _primaryGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving availability: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _addCustomRange(TimeRange newRange) {
    if (newRange.startAsDouble >= newRange.endAsDouble) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: End time must be after start time.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    for (final existingRange in _customRanges) {
      if (newRange.startAsDouble < existingRange.endAsDouble &&
          newRange.endAsDouble > existingRange.startAsDouble) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: This time overlaps with an existing slot.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    setState(() {
      _customRanges.add(newRange);
      _customRanges.sort((a, b) => a.startAsDouble.compareTo(b.startAsDouble));
    });
  }

  void _removeCustomRange(TimeRange rangeToRemove) {
    setState(() {
      _customRanges.remove(rangeToRemove);
    });
  }
  //</editor-fold>

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Set Your Availability',
          style: TextStyle(fontWeight: FontWeight.bold, color: _darkText),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 1,
      ),
      body: Column(
        children: [
          _buildCalendar(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: _primaryGreen),
                  )
                : _buildAvailabilitySelector(),
          ),
        ],
      ),
      floatingActionButton: _buildSaveFAB(),
    );
  }

  // --- UI Builder Methods ---

  Widget _buildCalendar() {
    return Material(
      color: Colors.white,
      elevation: 1,
      child: TableCalendar(
        firstDay: DateTime.now(),
        lastDay: DateTime.now().add(const Duration(days: 365)),
        focusedDay: _focusedDate,
        selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
        onDaySelected: (selectedDay, focusedDay) {
          if (!isSameDay(_selectedDate, selectedDay)) {
            setState(() {
              _selectedDate = selectedDay;
              _focusedDate = focusedDay;
            });
            _fetchAvailabilityForSelectedDate();
          }
        },
        onPageChanged: (focusedDay) {
          _focusedDate = focusedDay;
        },
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: _primaryGreen.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          selectedDecoration: const BoxDecoration(
            color: _primaryGreen,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildAvailabilitySelector() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Set availability for ${DateFormat('MMMM d, yyyy').format(_selectedDate)}",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _darkText,
            ),
          ),
          const SizedBox(height: 16),
          SegmentedButton<AvailabilityType>(
            style: SegmentedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: _primaryGreen,
              selectedForegroundColor: Colors.white,
              selectedBackgroundColor: _primaryGreen,
            ),
            segments: const [
              ButtonSegment(
                value: AvailabilityType.fullDay,
                label: Text('Full Day'),
                icon: Icon(Icons.wb_sunny_outlined),
              ),
              ButtonSegment(
                value: AvailabilityType.morning,
                label: Text('Morning'),
                icon: Icon(Icons.light_mode_outlined),
              ),
              ButtonSegment(
                value: AvailabilityType.afternoon,
                label: Text('Afternoon'),
                icon: Icon(Icons.dark_mode_outlined),
              ),
              ButtonSegment(
                value: AvailabilityType.custom,
                label: Text('Custom'),
                icon: Icon(Icons.tune_outlined),
              ),
            ],
            selected: {_selectedType},
            onSelectionChanged: (Set<AvailabilityType> newSelection) {
              setState(() {
                _selectedType = newSelection.first;
              });
            },
          ),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SizeTransition(sizeFactor: animation, child: child),
              );
            },
            child: _selectedType == AvailabilityType.custom
                ? _buildCustomRangesSection()
                : const SizedBox.shrink(),
          ),

          // *** FIX ADDED HERE ***
          // This SizedBox acts as a spacer to prevent the FAB from overlapping the last item.
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildCustomRangesSection() {
    return Container(
      key: const ValueKey('custom_section'),
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_customRanges.isEmpty)
            _buildEmptyState()
          else
            ..._customRanges.map((range) => _buildCustomRangeTag(range)),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            icon: const Icon(Icons.add_alarm_outlined),
            label: const Text('Add a Time Slot'),
            style: FilledButton.styleFrom(
              foregroundColor: _primaryGreen,
              backgroundColor: _primaryGreen.withOpacity(0.1),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () async {
              final newRange = await _showAddTimeRangeBottomSheet(context);
              if (newRange != null) {
                _addCustomRange(newRange);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24.0),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.hourglass_empty_rounded, size: 40, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              'No custom slots added.',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            Text(
              'Click below to add your first time slot.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomRangeTag(TimeRange range) {
    String formatTime(TimeOfDay time) {
      final dt = DateTime(2025, 1, 1, time.hour, time.minute);
      return DateFormat('h:mm a').format(dt);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _primaryGreen.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _primaryGreen.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.timelapse_rounded, color: _primaryGreen, size: 20),
          const SizedBox(width: 8),
          Text(
            '${formatTime(range.start)} - ${formatTime(range.end)}',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: _darkText,
              fontSize: 16,
            ),
          ),
          const Spacer(),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(
              Icons.close_rounded,
              color: Colors.red.shade300,
              size: 20,
            ),
            onPressed: () => _removeCustomRange(range),
          ),
        ],
      ),
    );
  }

  Future<TimeRange?> _showAddTimeRangeBottomSheet(BuildContext context) {
    TimeOfDay? startTime;
    TimeOfDay? endTime;

    return showModalBottomSheet<TimeRange>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Add Time Slot',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Select a start and end time for your availability.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTimePickerTile(
                          'Start Time',
                          startTime,
                          (newTime) =>
                              setDialogState(() => startTime = newTime),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTimePickerTile(
                          'End Time',
                          endTime,
                          (newTime) => setDialogState(() => endTime = newTime),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: (startTime != null && endTime != null)
                        ? () => Navigator.of(
                            context,
                          ).pop(TimeRange(start: startTime!, end: endTime!))
                        : null,
                    child: const Text('Save Slot'),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTimePickerTile(
    String label,
    TimeOfDay? time,
    Function(TimeOfDay) onTimeSelected,
  ) {
    return InkWell(
      onTap: () async {
        final pickedTime = await showTimePicker(
          context: context,
          initialTime: time ?? TimeOfDay.now(),
        );
        if (pickedTime != null) onTimeSelected(pickedTime);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              time == null
                  ? 'Not Set'
                  : DateFormat(
                      'h:mm a',
                    ).format(DateTime(2025, 1, 1, time.hour, time.minute)),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveFAB() {
    return _isSaving
        ? const FloatingActionButton(
            onPressed: null,
            backgroundColor: _primaryGreen,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        : FloatingActionButton.extended(
            onPressed: _saveAvailability,
            backgroundColor: _primaryGreen,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.save_alt_rounded),
            label: const Text('Save Changes'),
          );
  }
}

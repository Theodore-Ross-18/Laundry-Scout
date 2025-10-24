import 'package:flutter/material.dart';

class ScheduleSelectionScreen extends StatefulWidget {
  final Map<String, String>? selectedSchedule;
  final List<String> availablePickupTimeSlots; 
  final List<String> availableDropoffTimeSlots;
  final List<String> selectedServices;

  const ScheduleSelectionScreen({
    super.key,
    this.selectedSchedule,
    this.availablePickupTimeSlots = const [], 
    this.availableDropoffTimeSlots = const [],
    this.selectedServices = const [],
  });

  @override
  State<ScheduleSelectionScreen> createState() => _ScheduleSelectionScreenState();
}

class _ScheduleSelectionScreenState extends State<ScheduleSelectionScreen> {
  String? _selectedPickupTime;
  String? _selectedDropoffTime;

  List<String> get _pickupTimes => widget.availablePickupTimeSlots;
  List<String> get _dropoffTimes => widget.availableDropoffTimeSlots;

  @override
  void initState() {
    super.initState();
    if (widget.selectedSchedule != null) {
      _selectedPickupTime = widget.selectedSchedule!['pickup'];
      _selectedDropoffTime = widget.selectedSchedule!['dropoff'];
    }
    print('initState: _selectedPickupTime = $_selectedPickupTime, _selectedDropoffTime = $_selectedDropoffTime');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF5A35E3),
      appBar: AppBar(
        backgroundColor: const Color(0xFF5A35E3),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Laundry Scout',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pick-Up Schedule',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ..._pickupTimes.map((time) => _buildTimeSlot(
                              time,
                              _selectedPickupTime == time,
                              true, // isPickup
                              () {
                                setState(() {
                                  if (_selectedPickupTime == time) {
                                    _selectedPickupTime = null;
                                    print('Pickup time unselected: $time');
                                  } else {
                                    _selectedPickupTime = time;
                                    print('Pickup time selected: $time');
                                  }
                                });
                              },
                            )),
                            const SizedBox(height: 32),
                            
                            const Text(
                              'Drop-Off Schedule',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ..._dropoffTimes.map((time) => _buildTimeSlot(
                              time,
                              _selectedDropoffTime == time,
                              false, // isPickup
                              () {
                                setState(() {
                                  if (_selectedDropoffTime == time) {
                                    _selectedDropoffTime = null;
                                    print('Dropoff time unselected: $time');
                                  } else {
                                    _selectedDropoffTime = time;
                                    print('Dropoff time selected: $time');
                                  }
                                });
                              },
                            )),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (_selectedPickupTime != null || _selectedDropoffTime != null)
                            ? () {
                                print('Done button pressed: _selectedPickupTime = $_selectedPickupTime, _selectedDropoffTime = $_selectedDropoffTime');
                                Navigator.pop(context, {
                                  'pickup': _selectedPickupTime,
                                  'dropoff': _selectedDropoffTime,
                                });
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5A35E3),
                          disabledBackgroundColor: Colors.grey[300],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Done',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlot(String time, bool isSelected, bool isPickup, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          if (isPickup && !widget.selectedServices.contains('Pick Up')) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Select a Pick Up service first.')),
            );
            return;
          }
          if (!isPickup && !widget.selectedServices.contains('Drop Off')) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Select a Drop Off service first.')),
            );
            return;
          }
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF5A35E3).withOpacity(0.1) : Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF5A35E3) : Colors.grey[200]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  time,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? const Color(0xFF5A35E3) : Colors.black87,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF5A35E3),
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
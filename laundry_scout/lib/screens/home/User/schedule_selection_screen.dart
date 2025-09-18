import 'package:flutter/material.dart';

class ScheduleSelectionScreen extends StatefulWidget {
  final Map<String, String>? selectedSchedule;

  const ScheduleSelectionScreen({super.key, this.selectedSchedule});

  @override
  State<ScheduleSelectionScreen> createState() => _ScheduleSelectionScreenState();
}

class _ScheduleSelectionScreenState extends State<ScheduleSelectionScreen> {
  String? _selectedPickupTime;
  String? _selectedDropoffTime;

  final List<String> _pickupTimes = [
    '8:00 AM - 10:00 AM',
    '11:00 AM - 1:00 PM',
    '3:00 PM - 5:00 PM',
  ];

  final List<String> _dropoffTimes = [
    '1:00 PM - 3:00 PM',
    '4:00 PM - 6:00 PM',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.selectedSchedule != null) {
      _selectedPickupTime = widget.selectedSchedule!['pickup'];
      _selectedDropoffTime = widget.selectedSchedule!['dropoff'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6F5ADC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6F5ADC),
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
                            // Pick-Up Schedule Section
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
                              () {
                                setState(() {
                                  _selectedPickupTime = time;
                                });
                              },
                            )),
                            const SizedBox(height: 32),
                            
                            // Drop-Off Schedule Section
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
                              () {
                                setState(() {
                                  _selectedDropoffTime = time;
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
                        onPressed: (_selectedPickupTime != null && _selectedDropoffTime != null)
                            ? () {
                                Navigator.pop(context, {
                                  'pickup': _selectedPickupTime!,
                                  'dropoff': _selectedDropoffTime!,
                                });
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6F5ADC),
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

  Widget _buildTimeSlot(String time, bool isSelected, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6F5ADC).withOpacity(0.1) : Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF6F5ADC) : Colors.grey[200]!,
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
                    color: isSelected ? const Color(0xFF6F5ADC) : Colors.black87,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF6F5ADC),
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
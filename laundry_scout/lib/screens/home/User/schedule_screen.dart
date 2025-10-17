import 'package:flutter/material.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF5A35E3),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Laundry Scout',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // Content
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      const Text(
                        'Pick-Up Schedule',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...(_pickupTimes.map((time) => _buildTimeSlot(
                        time,
                        _selectedPickupTime == time,
                        () {
                          setState(() {
                            _selectedPickupTime = time;
                          });
                        },
                      )).toList()),
                      const SizedBox(height: 30),
                      const Text(
                        'Drop-Off Schedule',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Choose your area',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...(_dropoffTimes.map((time) => _buildTimeSlot(
                        time,
                        _selectedDropoffTime == time,
                        () {
                          setState(() {
                            _selectedDropoffTime = time;
                          });
                        },
                      )).toList()),
                      const Spacer(),
                      // Done button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _canProceed() ? _saveSchedule : null,
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
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlot(String time, bool isSelected, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
              Icon(
                Icons.access_time,
                color: isSelected ? const Color(0xFF5A35E3) : Colors.grey[600],
                size: 20,
              ),
              const SizedBox(width: 12),
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
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  bool _canProceed() {
    return _selectedPickupTime != null && _selectedDropoffTime != null;
  }

  void _saveSchedule() {
    final schedule = {
      'pickupTime': _selectedPickupTime,
      'dropoffTime': _selectedDropoffTime,
    };
    
    Navigator.pop(context, schedule);
  }
}
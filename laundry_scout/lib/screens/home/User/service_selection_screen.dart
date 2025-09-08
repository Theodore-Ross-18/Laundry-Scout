import 'package:flutter/material.dart';

class ServiceSelectionScreen extends StatefulWidget {
  final List<String> selectedServices;

  const ServiceSelectionScreen({super.key, required this.selectedServices});

  @override
  State<ServiceSelectionScreen> createState() => _ServiceSelectionScreenState();
}

class _ServiceSelectionScreenState extends State<ServiceSelectionScreen> {
  late List<String> _selectedServices;

  final List<Map<String, dynamic>> _services = [
    {
      'name': 'Iron Only',
      'icon': Icons.iron,
      'color': Colors.red,
      'price': 50,
    },
    {
      'name': 'Clean & Iron',
      'icon': Icons.local_laundry_service,
      'color': Colors.orange,
      'price': 120,
    },
    {
      'name': 'Wash & Fold',
      'icon': Icons.checkroom,
      'color': Colors.blue,
      'price': 180,
    },
    {
      'name': 'Carpets',
      'icon': Icons.cleaning_services,
      'color': Colors.purple,
      'price': 200,
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedServices = List.from(widget.selectedServices);
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Choose Your Services',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6F5ADC),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _services.length,
                        itemBuilder: (context, index) {
                          final service = _services[index];
                          final isSelected = _selectedServices.contains(service['name']);
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected 
                                    ? const Color(0xFF6F5ADC) 
                                    : Colors.grey[200]!,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: service['color'].withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  service['icon'],
                                  color: service['color'],
                                  size: 28,
                                ),
                              ),
                              title: Text(
                                service['name'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              subtitle: Text(
                                'Starting from ₱${service['price']}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              trailing: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.rectangle,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: isSelected 
                                        ? const Color(0xFF6F5ADC) 
                                        : Colors.grey[400]!,
                                    width: 2,
                                  ),
                                  color: isSelected 
                                      ? const Color(0xFF6F5ADC) 
                                      : Colors.transparent,
                                ),
                                child: isSelected
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 16,
                                      )
                                    : null,
                              ),
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedServices.remove(service['name']);
                                  } else {
                                    _selectedServices.add(service['name']);
                                  }
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _selectedServices.isNotEmpty 
                            ? () => Navigator.pop(context, _selectedServices)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6F5ADC),
                          disabledBackgroundColor: Colors.grey[300],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _selectedServices.isEmpty 
                              ? 'Select at least one service'
                              : 'Done (${_selectedServices.length} selected)',
                          style: const TextStyle(
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
}
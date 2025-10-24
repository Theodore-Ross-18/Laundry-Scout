import 'package:flutter/material.dart';

class ServiceSelectionScreen extends StatefulWidget {
  final Map<String, int> selectedServices;
  final List<Map<String, dynamic>> pricelist;

  const ServiceSelectionScreen({
    super.key, 
    required this.selectedServices,
    required this.pricelist,
  });

  @override
  State<ServiceSelectionScreen> createState() => _ServiceSelectionScreenState();
}

class _ServiceSelectionScreenState extends State<ServiceSelectionScreen> {
  late Map<String, int> _selectedServicesWithQuantity;

  List<Map<String, dynamic>> get _services => widget.pricelist
      .where((item) => (double.tryParse(item['price']?.toString() ?? '0') ?? 0) > 0.0)
      .map((item) => {
        'name': item['service_name'] ?? 'Unknown Service',
        'icon': _getServiceIcon(item['service_name']),
        'color': _getServiceColor(item['service_name']),
        'price': (double.tryParse(item['price']?.toString() ?? '0') ?? 0).toStringAsFixed(2),
      }).toList();

  @override
  void initState() {
    super.initState();
    _selectedServicesWithQuantity = Map<String, int>.from(widget.selectedServices);
  }

  IconData _getServiceIcon(String? serviceName) {
    switch (serviceName?.toLowerCase()) {
      case 'iron only':
      case 'ironing':
        return Icons.iron;
      case 'clean & iron':
      case 'clean and iron':
        return Icons.local_laundry_service;
      case 'wash & fold':
      case 'wash and fold':
        return Icons.checkroom;
      case 'carpets':
      case 'carpet cleaning':
        return Icons.cleaning_services;
      case 'dry cleaning':
        return Icons.dry_cleaning;
      case 'pressing':
        return Icons.content_cut;
      case 'deliver':
      case 'delivery':
        return Icons.delivery_dining;
      default:
        return Icons.local_laundry_service;
    }
  }

  Color _getServiceColor(String? serviceName) {
    switch (serviceName?.toLowerCase()) {
      case 'iron only':
      case 'ironing':
        return Colors.red;
      case 'clean & iron':
      case 'clean and iron':
        return Colors.orange;
      case 'wash & fold':
      case 'wash and fold':
        return Colors.blue;
      case 'carpets':
      case 'carpet cleaning':
        return Colors.purple;
      case 'dry cleaning':
        return Colors.green;
      case 'pressing':
        return Colors.teal;
      case 'deliver':
      case 'delivery':
        return Colors.brown;
      default:
        return Color(0xFF5A35E3);
    }
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Choose Your Services',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5A35E3),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _services.length,
                        itemBuilder: (context, index) {
                          final service = _services[index];
                          final isSelected = _selectedServicesWithQuantity.containsKey(service['name']);
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected 
                                    ? const Color(0xFF5A35E3) 
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
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_selectedServicesWithQuantity.containsKey(service['name']))
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, color: Color(0xFF5A35E3)),
                                      onPressed: () {
                                        setState(() {
                                          int currentQuantity = _selectedServicesWithQuantity[service['name']]!;
                                          if (currentQuantity > 1) {
                                            _selectedServicesWithQuantity[service['name']] = currentQuantity - 1;
                                          } else {
                                            _selectedServicesWithQuantity.remove(service['name']);
                                          }
                                        });
                                      },
                                    ),
                                  if (_selectedServicesWithQuantity.containsKey(service['name']))
                                    Text(
                                      '${_selectedServicesWithQuantity[service['name']]} kg',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  if (_selectedServicesWithQuantity.containsKey(service['name']))
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline, color: Color(0xFF5A35E3)),
                                      onPressed: () {
                                        setState(() {
                                          int currentQuantity = _selectedServicesWithQuantity[service['name']]!;
                                          _selectedServicesWithQuantity[service['name']] = currentQuantity + 1;
                                        });
                                      },
                                    ),
                                  if (!_selectedServicesWithQuantity.containsKey(service['name']))
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.rectangle,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: Colors.grey[400]!,
                                          width: 2,
                                        ),
                                        color: Colors.transparent,
                                      ),
                                      child: null,
                                    ),
                                ],
                              ),
                              onTap: () {
                                setState(() {
                                  if (_selectedServicesWithQuantity.containsKey(service['name'])) {
                                    _selectedServicesWithQuantity.remove(service['name']);
                                  } else {
                                    _selectedServicesWithQuantity[service['name']] = 1;
                                  }
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: const Text(
                        'This is an estimation only and may change.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _selectedServicesWithQuantity.isNotEmpty
                            ? () => Navigator.pop(context, _selectedServicesWithQuantity)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5A35E3),
                          disabledBackgroundColor: Colors.grey[300],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _selectedServicesWithQuantity.isEmpty
                              ? 'Select at least one service'
                              : 'Done (${_selectedServicesWithQuantity.length} selected)',
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
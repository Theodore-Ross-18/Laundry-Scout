import 'package:flutter/material.dart';

class OwnerReportsScreen extends StatefulWidget {
  final Map<String, int> orderStats;
  final List<Map<String, dynamic>> allOrders;
  const OwnerReportsScreen({super.key, required this.orderStats, required this.allOrders});

  @override
  State<OwnerReportsScreen> createState() => _OwnerReportsScreenState();
}

class _OwnerReportsScreenState extends State<OwnerReportsScreen> {
  String? _selectedMonthYear;
  late List<String> _monthYears;
  double _totalEarnings = 0.0;
  String _topUsedService = 'N/A';

  @override
  void initState() {
    super.initState();
    _monthYears = _generateMonthYears();
    _selectedMonthYear = _monthYears.first;
    _calculateTotalEarnings();
    _calculateTopUsedService();
  }

  void _calculateTotalEarnings() {
    for (var order in widget.allOrders) {
      _totalEarnings += (order['total_amount'] as num? ?? 0.0).toDouble();
    }
  }

  void _calculateTopUsedService() {
    Map<String, double> serviceQuantities = {};

    for (var order in widget.allOrders) {
      if (order['items'] != null) {
        Map<String, dynamic> items = Map<String, dynamic>.from(order['items']);
        items.forEach((serviceName, quantity) {
          serviceQuantities.update(
            serviceName,
            (value) => value + (quantity as num).toDouble(),
            ifAbsent: () => (quantity as num).toDouble(),
          );
        });
      }
    }

    if (serviceQuantities.isNotEmpty) {
      var sortedServices = serviceQuantities.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      _topUsedService = sortedServices.first.key;
    }
  }

  List<String> _generateMonthYears() {
    List<String> monthYears = [];
    DateTime now = DateTime.now();
    DateTime nextYear = DateTime(now.year + 1, now.month, now.day);

    for (DateTime date = now; date.isBefore(nextYear); date = DateTime(date.year, date.month + 1, date.day)) {
      monthYears.add('${_getMonthName(date.month)} ${date.year}');
    }
    return monthYears;
  }

  String _getMonthName(int month) {
    switch (month) {
      case 1: return 'January';
      case 2: return 'February';
      case 3: return 'March';
      case 4: return 'April';
      case 5: return 'May';
      case 6: return 'June';
      case 7: return 'July';
      case 8: return 'August';
      case 9: return 'September';
      case 10: return 'October';
      case 11: return 'November';
      case 12: return 'December';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          DropdownButton<String>(
            value: _selectedMonthYear,
            onChanged: (String? newValue) {
              setState(() {
                _selectedMonthYear = newValue;
              });
            },
            items: _monthYears.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  style: TextStyle(color: Colors.black),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          'Total Bookings',
                          style: TextStyle(color: Colors.black),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '${widget.orderStats['total']}',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          'Total Estimate Earnings',
                          style: TextStyle(color: Colors.black),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '${_totalEarnings.toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          'Top Used Service',
                          style: TextStyle(color: Colors.black),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '$_topUsedService',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
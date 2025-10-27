import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

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
  List<MapEntry<String, double>> _serviceData = [];
  List<Map<String, dynamic>> _filteredOrders = [];
  Map<String, int> _filteredOrderStats = {};

  @override
  void initState() {
    super.initState();
    _monthYears = _generateMonthYears();
    _selectedMonthYear = _monthYears.first;
    _filterDataByMonth();
  }

  void _filterDataByMonth() {
    if (_selectedMonthYear == null) return;
    
    // Parse selected month and year
    final parts = _selectedMonthYear!.split(' ');
    final selectedMonth = _getMonthNumber(parts[0]);
    final selectedYear = int.parse(parts[1]);
    
    // Filter orders by selected month/year
    _filteredOrders = widget.allOrders.where((order) {
      if (order['created_at'] == null) return false;
      
      try {
        final orderDate = DateTime.parse(order['created_at']);
        return orderDate.month == selectedMonth && orderDate.year == selectedYear;
      } catch (e) {
        return false;
      }
    }).toList();
    
    // Calculate filtered order stats
    _filteredOrderStats = {
      'total': _filteredOrders.length,
      'pending': _filteredOrders.where((order) => order['status'] == 'pending').length,
      'confirmed': _filteredOrders.where((order) => order['status'] == 'confirmed').length,
      'completed': _filteredOrders.where((order) => order['status'] == 'completed').length,
      'cancelled': _filteredOrders.where((order) => order['status'] == 'cancelled').length,
    };
    
    // Recalculate all data based on filtered orders
    _calculateTotalEarnings();
    _calculateTopUsedService();
  }

  int _getMonthNumber(String monthName) {
    switch (monthName) {
      case 'January': return 1;
      case 'February': return 2;
      case 'March': return 3;
      case 'April': return 4;
      case 'May': return 5;
      case 'June': return 6;
      case 'July': return 7;
      case 'August': return 8;
      case 'September': return 9;
      case 'October': return 10;
      case 'November': return 11;
      case 'December': return 12;
      default: return 0;
    }
  }

  void _calculateTotalEarnings() {
    _totalEarnings = 0.0;
    for (var order in _filteredOrders) {
      _totalEarnings += (order['total_amount'] as num? ?? 0.0).toDouble();
    }
  }

  void _calculateTopUsedService() {
    Map<String, double> serviceOrderCounts = {};

    for (var order in _filteredOrders) {
      if (order['items'] != null) {
        Map<String, dynamic> items = Map<String, dynamic>.from(order['items']);
        // Count each service type once per order (order-based, not quantity-based)
        items.forEach((serviceName, quantity) {
          serviceOrderCounts.update(
            serviceName,
            (value) => value + 1.0, // Count orders, not quantities
            ifAbsent: () => 1.0,
          );
        });
      }
    }

    if (serviceOrderCounts.isNotEmpty) {
      var sortedServices = serviceOrderCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      _topUsedService = sortedServices.first.key;
      _serviceData = sortedServices.take(5).toList(); // Top 5 services for pie chart
    } else {
      _topUsedService = 'N/A';
      _serviceData = [];
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

  List<Color> _getPieChartColors() {
    return [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.amber,
      Colors.indigo,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
          DropdownButton<String>(
            value: _selectedMonthYear,
            onChanged: (String? newValue) {
              setState(() {
                _selectedMonthYear = newValue;
                _filterDataByMonth();
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
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        Text(
                          'Total Bookings',
                          style: TextStyle(color: Colors.black, fontSize: 12),
                        ),
                        SizedBox(height: 6),
                        Text(
                          '${_filteredOrderStats['total'] ?? 0}',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        Text(
                          'Total Estimate Earnings',
                          style: TextStyle(color: Colors.black, fontSize: 12),
                        ),
                        SizedBox(height: 6),
                        Text(
                          '${_totalEarnings.toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        Text(
                          'Top Used Service',
                          style: TextStyle(color: Colors.black, fontSize: 12),
                        ),
                        SizedBox(height: 6),
                        Text(
                          '$_topUsedService',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Text(
                    'Transactions',
                    style: TextStyle(color: Colors.black, fontSize: 16),
                  ),
                  SizedBox(height: 6),
                  Container(
                    height: 150,
                    child: ListView.builder(
                      shrinkWrap: false,
                      physics: ClampingScrollPhysics(), // Allow scrolling within the card
                      itemCount: _filteredOrders.length,
                      itemBuilder: (context, index) {
                        final order = _filteredOrders[index];
                        final customerName = order['user_profiles']?['first_name'] != null && order['user_profiles']?['last_name'] != null
                            ? '${order['user_profiles']['first_name']} ${order['user_profiles']['last_name']}'
                            : order['customer_name'] != null
                                ? order['customer_name']
                                : 'N/A';
                        final services = (order['items'] as Map<String, dynamic>?)?.keys.join(', ') ?? 'N/A';
                        final totalAmount = order['total_amount']?.toStringAsFixed(2) ?? '0.00';
                        final createdAt = order['created_at'] != null
                            ? DateFormat('MMM d').format(DateTime.parse(order['created_at']))
                            : 'N/A';

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    customerName,
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                                  ),
                                  Text(
                                    services,
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Php $totalAmount',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                                  ),
                                  Text(
                                    createdAt,
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          // Pie Chart for Service Usage
          if (_serviceData.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Text(
                      'Most Ordered Services',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        // Pie Chart
                        Container(
                          height: 180,
                          width: 180,
                          child: PieChart(
                            PieChartData(
                              sections: _serviceData.asMap().entries.map((entry) {
                                int index = entry.key;
                                MapEntry<String, double> service = entry.value;
                                final colors = _getPieChartColors();
                                return PieChartSectionData(
                                  color: colors[index % colors.length],
                                  value: service.value,
                                  title: '${service.value.toStringAsFixed(0)}',
                                  radius: 60,
                                  titleStyle: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                );
                              }).toList(),
                              sectionsSpace: 1,
                              centerSpaceRadius: 30,
                              pieTouchData: PieTouchData(
                                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                  // Handle touch interactions if needed
                                },
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        // Legend
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _serviceData.asMap().entries.map((entry) {
                              int index = entry.key;
                              MapEntry<String, double> service = entry.value;
                              final colors = _getPieChartColors();
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      color: colors[index % colors.length],
                                    ),
                                    SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        '${service.key} (${service.value.toStringAsFixed(0)} orders)',
                                        style: TextStyle(fontSize: 11, color: Colors.black),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
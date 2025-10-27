import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  DateTime? _businessCreationDate; // Store business creation date

  @override
  void initState() {
    super.initState();
    _monthYears = _generateMonthYears(); // Initialize with default before async call
    _selectedMonthYear = _monthYears.first;
    _filterDataByMonth();
    _loadBusinessProfileCreationDate().then((_) {
      // After business creation date is loaded, regenerate month years and filter data
      setState(() {
        _monthYears = _generateMonthYears();
        _selectedMonthYear = _monthYears.first;
        _filterDataByMonth();
      });
    });
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

  Future<void> _loadBusinessProfileCreationDate() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final response = await Supabase.instance.client
          .from('business_profiles')
          .select('created_at')
          .eq('owner_id', user.id);

      if (response.isNotEmpty && response[0]['created_at'] != null) {
        setState(() {
          _businessCreationDate = DateTime.parse(response[0]['created_at']);
        });
      } else {
        // No business profile found, default to current date
        setState(() {
          _businessCreationDate = DateTime.now();
        });
      }
    } catch (e) {
      print('Error loading business profile creation date: $e');
      // Default to current date if error occurs
      setState(() {
        _businessCreationDate = DateTime.now();
      });
    }
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
    
    // Start from business creation date or current date if not available
    DateTime startDate = _businessCreationDate ?? now;
    
    // Ensure we don't go beyond the current date
    DateTime endDate = DateTime(now.year + 1, now.month, now.day);
    
    // Generate months from start date to end date
    for (DateTime date = DateTime(startDate.year, startDate.month, 1); 
         date.isBefore(endDate) || date.isAtSameMomentAs(endDate); 
         date = DateTime(date.year, date.month + 1, 1)) {
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

  Widget _buildStatusChip(String label, int count, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          SizedBox(height: 4),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generatePDF() async {
    final pdf = pw.Document();
    
    // Get laundry shop name from the first order, or use a default
    String laundryShopName = 'Your Laundry Shop';
    if (_filteredOrders.isNotEmpty && _filteredOrders.first['laundry_shop_name'] != null) {
      laundryShopName = _filteredOrders.first['laundry_shop_name'];
    }
    
    // Create PDF content
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text(
                'Laundry Scout - Owner Report',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Shop: $laundryShopName',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Text(
              'Report Date: ${DateFormat('MMMM d, yyyy').format(DateTime.now())}',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Text(
              'Report Period: $_selectedMonthYear',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 20),
            
            // Summary Cards
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildPDFCard('Total Bookings', '${_filteredOrderStats['total'] ?? 0}'),
                _buildPDFCard('Total Earnings', 'Php ${_totalEarnings.toStringAsFixed(2)}'),
                _buildPDFCard('Top Service', _topUsedService),
              ],
            ),
            pw.SizedBox(height: 20),
            
            // Order Status Breakdown
            pw.Text(
              'Order Status Breakdown',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                pw.TableRow(
                  children: [
                    _buildPDFTableCell('Status', isHeader: true),
                    _buildPDFTableCell('Count', isHeader: true),
                  ],
                ),
                pw.TableRow(
                  children: [
                    _buildPDFTableCell('Pending'),
                    _buildPDFTableCell('${_filteredOrderStats['pending'] ?? 0}'),
                  ],
                ),
                pw.TableRow(
                  children: [
                    _buildPDFTableCell('Confirmed'),
                    _buildPDFTableCell('${_filteredOrderStats['confirmed'] ?? 0}'),
                  ],
                ),
                pw.TableRow(
                  children: [
                    _buildPDFTableCell('Completed'),
                    _buildPDFTableCell('${_filteredOrderStats['completed'] ?? 0}'),
                  ],
                ),
                pw.TableRow(
                  children: [
                    _buildPDFTableCell('Cancelled'),
                    _buildPDFTableCell('${_filteredOrderStats['cancelled'] ?? 0}'),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            
            // Service Usage
            if (_serviceData.isNotEmpty) ...[
              pw.Text(
                'Most Ordered Services',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    children: [
                      _buildPDFTableCell('Service', isHeader: true),
                      _buildPDFTableCell('Orders', isHeader: true),
                    ],
                  ),
                  ..._serviceData.map((service) => pw.TableRow(
                    children: [
                      _buildPDFTableCell(service.key),
                      _buildPDFTableCell(service.value.toStringAsFixed(0)),
                    ],
                  )).toList(),
                ],
              ),
              pw.SizedBox(height: 20),
            ],
            
            // Recent Transactions
            pw.Text(
              'Recent Transactions',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                pw.TableRow(
                  children: [
                    _buildPDFTableCell('Customer', isHeader: true),
                    _buildPDFTableCell('Services', isHeader: true),
                    _buildPDFTableCell('Amount', isHeader: true),
                    _buildPDFTableCell('Date', isHeader: true),
                  ],
                ),
                ..._filteredOrders.take(10).map((order) {
                  final customerName = order['user_profiles']?['first_name'] != null && order['user_profiles']?['last_name'] != null
                      ? '${order['user_profiles']['first_name']} ${order['user_profiles']['last_name']}'
                      : order['customer_name'] != null
                          ? order['customer_name']
                          : 'N/A';
                  final services = (order['items'] as Map<String, dynamic>?)?.keys.join(', ') ?? 'N/A';
                  final totalAmount = order['total_amount']?.toStringAsFixed(2) ?? '0.00';
                  final createdAt = order['created_at'] != null
                      ? DateFormat('MMM d, yyyy').format(DateTime.parse(order['created_at']))
                      : 'N/A';

                  return pw.TableRow(
                    children: [
                      _buildPDFTableCell(customerName),
                      _buildPDFTableCell(services),
                      _buildPDFTableCell('Php $totalAmount'),
                      _buildPDFTableCell(createdAt),
                    ],
                  );
                }).toList(),
              ],
            ),
            if (_filteredOrders.length > 10)
              pw.Text(
                '... and ${_filteredOrders.length - 10} more transactions',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
          ];
        },
      ),
    );

    // Print or share the PDF
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'laundry_scout_report_${_selectedMonthYear!.replaceAll(' ', '_')}.pdf',
    );
  }

  pw.Widget _buildPDFCard(String title, String value) {
    return pw.Container(
      width: 150,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#5A35E3'), // Purple background color
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.white,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPDFTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Remove the back button
        title: const Text('General Report'),
        centerTitle: false,
        backgroundColor: const Color(0xFF5A35E3), // Set AppBar background to purple
        foregroundColor: Colors.white, // Set AppBar text/icon color to white
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Poppins'), // Set title text color to white and font to Poppins
      ),
      backgroundColor: Colors.white, // Set Scaffold background to white
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Only show previous button if not at the first month
                    if (_monthYears.indexOf(_selectedMonthYear!) > 0)
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios, color: const Color(0xFF5A35E3)),
                        onPressed: () {
                          final currentIndex = _monthYears.indexOf(_selectedMonthYear!);
                          if (currentIndex > 0) {
                            setState(() {
                              _selectedMonthYear = _monthYears[currentIndex - 1];
                              _filterDataByMonth();
                            });
                          }
                        },
                      )
                    else
                      SizedBox(width: 48), // Placeholder to maintain alignment
                    Text(
                      _selectedMonthYear!,
                      style: TextStyle(
                        color: const Color(0xFF5A35E3),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.arrow_forward_ios, color: const Color(0xFF5A35E3)),
                      onPressed: () {
                        final currentIndex = _monthYears.indexOf(_selectedMonthYear!);
                        if (currentIndex < _monthYears.length - 1) {
                          setState(() {
                            _selectedMonthYear = _monthYears[currentIndex + 1];
                            _filterDataByMonth();
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              // Summary Cards Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      color: const Color(0xFF5A35E3),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.shopping_bag,
                              color: Colors.white.withOpacity(0.8),
                              size: 24,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Total Bookings',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9), 
                                fontSize: 11,
                                fontWeight: FontWeight.w500
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '${_filteredOrderStats['total'] ?? 0}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold, 
                                color: Colors.white
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      color: const Color(0xFF5A35E3),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.attach_money,
                              color: Colors.white.withOpacity(0.8),
                              size: 24,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Total Earnings',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9), 
                                fontSize: 11,
                                fontWeight: FontWeight.w500
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '₱${_totalEarnings.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold, 
                                color: Colors.white
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      color: const Color(0xFF5A35E3),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.star,
                              color: Colors.white.withOpacity(0.8),
                              size: 24,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Top Service',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9), 
                                fontSize: 11,
                                fontWeight: FontWeight.w500
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              _topUsedService.length > 8 ? '${_topUsedService.substring(0, 8)}...' : _topUsedService,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold, 
                                color: Colors.white
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              // Order Status Breakdown Section
              Card(
                color: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order Status Overview',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF5A35E3),
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatusChip(
                            'Pending',
                            _filteredOrderStats['pending'] ?? 0,
                            Colors.orange,
                            Icons.schedule,
                          ),
                          _buildStatusChip(
                            'Confirmed',
                            _filteredOrderStats['confirmed'] ?? 0,
                            Colors.blue,
                            Icons.check_circle,
                          ),
                          _buildStatusChip(
                            'Completed',
                            _filteredOrderStats['completed'] ?? 0,
                            Colors.green,
                            Icons.done_all,
                          ),
                          _buildStatusChip(
                            'Cancelled',
                            _filteredOrderStats['cancelled'] ?? 0,
                            Colors.red,
                            Icons.cancel,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              // Charts and Analytics Section
              if (_serviceData.isNotEmpty)
                Card(
                  color: const Color.fromARGB(255, 255, 255, 255),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          'Service Analytics',
                          style: TextStyle(
                            fontSize: 18, 
                            fontWeight: FontWeight.bold, 
                            color: const Color(0xFF5A35E3)
                          ),
                        ),
                        SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Pie Chart
                            Expanded(
                              flex: 2,
                              child: Container(
                                height: 200,
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
                                        radius: 70,
                                        titleStyle: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      );
                                    }).toList(),
                                    sectionsSpace: 2,
                                    centerSpaceRadius: 40,
                                    pieTouchData: PieTouchData(
                                      touchCallback: (FlTouchEvent event, pieTouchResponse) {},
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 20),
                            // Legend and Details
                            Expanded(
                              flex: 1,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Top Services',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF5A35E3)
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  ..._serviceData.asMap().entries.map((entry) {
                                    int index = entry.key;
                                    MapEntry<String, double> service = entry.value;
                                    final colors = _getPieChartColors();
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 16,
                                            height: 16,
                                            decoration: BoxDecoration(
                                              color: colors[index % colors.length],
                                              borderRadius: BorderRadius.circular(3),
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  service.key,
                                                  style: TextStyle(
                                                    fontSize: 12, 
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.black87
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                Text(
                                                  '${service.value.toStringAsFixed(0)} orders',
                                                  style: TextStyle(
                                                    fontSize: 10, 
                                                    color: Colors.grey[600]
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              SizedBox(height: 16),
              // Recent Transactions Section
              Card(
                color: const Color.fromARGB(255, 255, 255, 255),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Transactions',
                            style: TextStyle(
                              fontSize: 18, 
                              fontWeight: FontWeight.bold, 
                              color: const Color(0xFF5A35E3)
                            ),
                          ),
                          Text(
                            '${_filteredOrders.length} total',
                            style: TextStyle(
                              fontSize: 12, 
                              color: Colors.grey[600]
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      if (_filteredOrders.isEmpty)
                        Container(
                          height: 100,
                          child: Center(
                            child: Text(
                              'No transactions for this period',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          height: 200,
                          child: ListView.separated(
                            shrinkWrap: false,
                            physics: ClampingScrollPhysics(),
                            itemCount: _filteredOrders.length > 5 ? 5 : _filteredOrders.length,
                            separatorBuilder: (context, index) => Divider(
                              height: 1,
                              color: Colors.grey[200],
                            ),
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
                                  ? DateFormat('MMM d, yyyy').format(DateTime.parse(order['created_at']))
                                  : 'N/A';
                              final status = order['status']?.toString().toUpperCase() ?? 'UNKNOWN';
                              
                              Color statusColor;
                              switch (order['status']) {
                                case 'completed':
                                  statusColor = Colors.green;
                                  break;
                                case 'confirmed':
                                  statusColor = Colors.blue;
                                  break;
                                case 'pending':
                                  statusColor = Colors.orange;
                                  break;
                                case 'cancelled':
                                  statusColor = Colors.red;
                                  break;
                                default:
                                  statusColor = Colors.grey;
                              }

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            customerName,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold, 
                                              color: Colors.black87,
                                              fontSize: 13
                                            ),
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            services,
                                            style: TextStyle(
                                              color: Colors.grey[600], 
                                              fontSize: 11
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            createdAt,
                                            style: TextStyle(
                                              color: Colors.grey[500], 
                                              fontSize: 10
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: statusColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            status,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: statusColor,
                                              fontWeight: FontWeight.bold
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Php $totalAmount',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold, 
                                            color: const Color(0xFF5A35E3),
                                            fontSize: 13
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        if (_filteredOrders.length > 5)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Showing 5 of ${_filteredOrders.length} transactions',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _generatePDF,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF5A35E3),
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'Generate Report',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
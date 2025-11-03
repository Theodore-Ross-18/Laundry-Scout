// ignore_for_file: unused_element, unused_field

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
    // Default selection to the current month
    final now = DateTime.now();
    final currentLabel = '${_getMonthName(now.month)} ${now.year}';
    _selectedMonthYear = _monthYears.contains(currentLabel)
        ? currentLabel
        : (_monthYears.isNotEmpty ? _monthYears.last : null);
    _filterDataByMonth();
    _loadBusinessProfileCreationDate().then((_) {
      // After business creation date is loaded, regenerate month years and filter data
      setState(() {
        _monthYears = _generateMonthYears();
        final now2 = DateTime.now();
        final currentLabel2 = '${_getMonthName(now2.month)} ${now2.year}';
        _selectedMonthYear = _monthYears.contains(currentLabel2)
            ? currentLabel2
            : (_monthYears.isNotEmpty ? _monthYears.last : null);
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

  // Determine earliest order date from all orders to build month range
  DateTime? _getEarliestOrderDate() {
    DateTime? earliest;
    for (var order in widget.allOrders) {
      final createdAt = order['created_at'];
      if (createdAt == null) continue;
      try {
        final date = DateTime.parse(createdAt);
        if (earliest == null || date.isBefore(earliest)) {
          earliest = date;
        }
      } catch (_) {
        // Ignore parse errors
      }
    }
    return earliest;
  }

  List<String> _generateMonthYears() {
    List<String> monthYears = [];
    DateTime now = DateTime.now();
    // Always include 12 months before and 12 months after the current month
    DateTime startDate = DateTime(now.year, now.month - 12, 1);
    DateTime endDate = DateTime(now.year, now.month + 12, 1);

    for (DateTime date = startDate;
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
      const Color(0xFF5A35E3), // Color for the top service
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
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
                ..._filteredOrders.map((order) {
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

  Widget _buildSummaryCard( {required String label, required String value, required IconData icon, required Color color, bool alignLeft = false, bool whiteBackgroundIcon = false, double valueFontSize = 18}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: color,
      child: Container(
        height: 125,
        padding: const EdgeInsets.all(14.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: alignLeft ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: whiteBackgroundIcon ? BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ) : null,
              child: Icon(
                icon,
                color: whiteBackgroundIcon ? const Color(0xFF5A35E3) : Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8), 
                fontSize: 12,
                fontWeight: FontWeight.w500
              ),
              textAlign: alignLeft ? TextAlign.left : TextAlign.center,
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: TextStyle(
                fontSize: valueFontSize,
                fontWeight: FontWeight.bold, 
                color: Colors.white
              ),
              textAlign: alignLeft ? TextAlign.left : TextAlign.center,
            ),
          ],
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
      backgroundColor: const Color(0xFF5A35E3), // Set Scaffold background to purple
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Only show previous button if not at the first month
                    if (_monthYears.indexOf(_selectedMonthYear!) > 0)
                      GestureDetector(
                        onTap: () {
                          final currentIndex = _monthYears.indexOf(_selectedMonthYear!); 
                          if (currentIndex > 0) {
                            setState(() {
                              _selectedMonthYear = _monthYears[currentIndex - 1];
                              _filterDataByMonth();
                            });
                          }
                        },
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: Color(0xFF5A35E3),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.chevron_left,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 48), // Placeholder to maintain alignment
                    const SizedBox(width: 8),
                    Text(
                      _selectedMonthYear!,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Only show next button if not at the last month
                    if (_monthYears.indexOf(_selectedMonthYear!) < _monthYears.length - 1)
                      GestureDetector(
                        onTap: () {
                          final currentIndex = _monthYears.indexOf(_selectedMonthYear!); 
                          if (currentIndex < _monthYears.length - 1) {
                            setState(() {
                              _selectedMonthYear = _monthYears[currentIndex + 1];
                              _filterDataByMonth();
                            });
                          }
                        },
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: Color(0xFF5A35E3),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.chevron_right,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 48),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 2, // Bookings card takes less space
                      child: _buildSummaryCard(
                        label: 'Bookings',
                        value: '${_filteredOrderStats['total'] ?? 0}',
                        icon: Icons.shopping_bag,
                        color: const Color(0xFF5A35E3),
                        valueFontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 1),
                    Expanded(
                      flex: 2, // Top Service card takes less space
                      child: _buildSummaryCard(
                        label: 'Top Service',
                        value: _topUsedService.length > 10 ? '${_topUsedService.substring(0, 10)}...' : _topUsedService,
                        icon: Icons.star,
                        color: const Color(0xFF5A35E3),
                        valueFontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 1),
                    Expanded(
                      flex: 3, // Total Earnings card takes more space (50% longer)
                      child: _buildSummaryCard(
                        label: 'Total Earnings',
                        value: 'P${_totalEarnings.toStringAsFixed(2)}',
                        icon: Icons.attach_money,
                        color: const Color(0xFF5A35E3),
                        alignLeft: true,
                        whiteBackgroundIcon: true,
                        valueFontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 1),
              // Order Status Breakdown Section
              Card(
                color: Colors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Color(0xFFE3E3E3), width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          'Order Status Overview',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color.fromARGB(255, 2, 2, 2),
                          ),
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
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFFE3E3E3), width: 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                    child: Column(
                      children: [
                        Text(
                          'Service Analytics',
                          style: TextStyle(
                            fontSize: 18, 
                            fontWeight: FontWeight.bold, 
                            color: Colors.black,
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
                                height: 150,
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
                                        radius: 40,
                                        titleStyle: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      );
                                    }).toList(),
                                    sectionsSpace: 2,
                                    centerSpaceRadius: 30,
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
                                  ..._serviceData.asMap().entries.map((entry) {
                                    int index = entry.key;
                                    MapEntry<String, double> service = entry.value;
                                    final colors = _getPieChartColors();
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 2.0),
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
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFE3E3E3), width: 1),
                ),
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
                              color: Colors.black
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
                        SizedBox(height: 16),
                        // Generate Report Button moved to end of Transactions section
                        SizedBox(
                          width: double.infinity,
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
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

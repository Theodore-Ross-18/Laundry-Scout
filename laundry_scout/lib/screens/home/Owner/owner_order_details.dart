import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

import 'package:universal_html/html.dart'
    if (dart.library.io) '../../web_html_stub.dart' as html;

class OwnerOrderDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const OwnerOrderDetailsScreen({super.key, required this.order});

  @override
  State<OwnerOrderDetailsScreen> createState() => _OwnerOrderDetailsScreenState();
}

class _OwnerOrderDetailsScreenState extends State<OwnerOrderDetailsScreen> {
  final GlobalKey _receiptKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5), 
      appBar: AppBar(
        backgroundColor: const Color(0xFFF0F2F5),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color:  Color(0xFF5A35E3)),
          onPressed: () {
            Navigator.of(context).pop();
          },
          style: IconButton.styleFrom(
            backgroundColor: Colors.transparent, 
          ),
        ),
        title: const Text(
          "Order Details",
          style: TextStyle(color:  Color(0xFF5A35E3), fontWeight: FontWeight.bold), 
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            RepaintBoundary(
              key: _receiptKey,
              child: Container(
                color: Colors.white,
                margin: const EdgeInsets.all(16.0),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          ColorFiltered(
                            colorFilter: ColorFilter.mode(Colors.black, BlendMode.srcIn),
                            child: Image.asset(
                              'lib/assets/lslogo.png',
                              height: 50,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Payment Receipt',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            DateFormat('MMMM dd, yyyy hh:mm a').format(DateTime.now()),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 30, thickness: 1),
                    _buildDetailRow(
                      'Order ID',
                      '#${widget.order['order_number']}',
                      isBold: true,
                      valueColor: Colors.black,
                    ),
                    _buildDetailRow(
                      'Customer Name',
                      widget.order['customer_name'],
                    ),
                    _buildDetailRow(
                      'Customer Number',
                      widget.order['mobile_number'],
                    ),
                    _buildDetailRow(
                      'Service Type',
                      (widget.order['items'] as Map<String, dynamic>).keys.join(', '),
                    ),
                    _buildDetailRow(
                      'Delivery Address',
                      widget.order['delivery_address'],
                    ),
                    _buildDetailRow(
                      'Order Date',
                      DateFormat('MMMM dd, yyyy hh:mm a').format(DateTime.parse(widget.order['created_at'])),
                    ),
                    _buildDetailRow(
                      'Note',
                      widget.order['special_instructions'] ?? '',
                    ),
                    const Divider(height: 30, thickness: 1),
                    _buildDetailRow(
                      'Total Amount',
                      '₱${widget.order['total_amount'] ?? '0.00'}',
                      isBold: true,
                      valueColor: const Color(0xFF5A35E3),
                    ),
                    const Divider(height: 30, thickness: 1),
                    const SizedBox(height: 20),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        widget.order['laundry_shop_name'] ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: TextButton(
                onPressed: _captureAndSaveReceipt,
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF6F5ADC),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text(
                  'Download Receipt',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 20), // Added space below the button
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value, {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              label == 'Note' && (value == null || value.isEmpty) ? 'No Request' : value ?? 'N/A',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: valueColor ?? Colors.black,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _captureAndSaveReceipt() async {
    if (kIsWeb) {
      try {
        final RenderRepaintBoundary boundary = _receiptKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
        final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        final Uint8List rgbaBytes = byteData!.buffer.asUint8List();

        final img.Image image_ = img.Image.fromBytes(
          width: image.width,
          height: image.height,
          bytes: rgbaBytes.buffer,
          order: img.ChannelOrder.rgba
        );
        final Uint8List jpegBytes = img.encodeJpg(image_);

        final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
        final orderNumber = widget.order['order_number'] ?? 'unknown';
        final fileName = 'Laundry-Scout_${orderNumber}_$timestamp.jpeg';

        final blob = html.Blob([jpegBytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.document.body!.append(html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..click());
        html.document.body!.children.removeLast();
        html.Url.revokeObjectUrl(url);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Receipt downloaded as $fileName')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error downloading receipt: $e')),
          );
        }
      }
      return;
    }
    try {
      
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Storage permission required to save receipt')),
          );
        }
        return;
      }

      final RenderRepaintBoundary boundary = _receiptKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final Uint8List rgbaBytes = byteData!.buffer.asUint8List();

      final img.Image imageJpg = img.Image.fromBytes(
        width: image.width,
        height: image.height,
        bytes: rgbaBytes.buffer,
        format: img.Format.uint8,
      );
      final Uint8List jpegBytes = img.encodeJpg(imageJpg);

      final directory = await getDownloadsDirectory();
      if (directory == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not access downloads directory')),
          );
        }
        return;
      }

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final orderNumber = widget.order['order_number'] ?? 'unknown';
      final fileName = 'Laundry-Scout_${orderNumber}_$timestamp.jpeg';
      final filePath = '${directory.path}/$fileName';

      final file = File(filePath);
      await file.writeAsBytes(jpegBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Receipt saved to Downloads as $fileName')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving receipt: $e')),
        );
      }
    }
  }
}
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.of(context).pop();
          },
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFF8A2BE2), // Purple color
          ),
        ),
        title: const Text(
          "Order Details",
          style: TextStyle(color: Colors.black), // Black color for title
        ),
      ),
      body: RepaintBoundary(
        key: _receiptKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Order ID',
                          style: TextStyle(fontSize: 16, color: Colors.black),
                        ),
                        Text(
                          '#${widget.order['order_number']}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Builder(
                        builder: (context) {
                          Color statusColor;
                          switch (widget.order['status']) {
                            case 'pending':
                              statusColor = Colors.orange;
                              break;
                            case 'in_progress':
                              statusColor = Colors.blue;
                              break;
                            case 'completed':
                              statusColor = Colors.green;
                              break;
                            case 'cancelled':
                              statusColor = Colors.red;
                              break;
                            default:
                              statusColor = Colors.grey;
                          }

                          Color statusBgColor;
                          switch (widget.order['status']) {
                            case 'pending':
                              statusBgColor = Colors.orange.withValues(alpha: 0.15);
                              break;
                            case 'in_progress':
                              statusBgColor = Colors.blue.withValues(alpha: 0.15);
                              break;
                            case 'completed':
                              statusBgColor = Colors.green.withValues(alpha: 0.15);
                              break;
                            case 'cancelled':
                              statusBgColor = Colors.red.withValues(alpha: 0.15);
                              break;
                            default:
                              statusBgColor = Colors.grey.withValues(alpha: 0.15);
                          }

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusBgColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              (widget.order['status'] ?? 'N/A').replaceAll('_', ' ').toUpperCase(),
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        },
                      ),
                      const Text(
                        'Status',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Customer Name',
                          style: TextStyle(fontSize: 16, color: Colors.black),
                        ),
                        Text(
                          widget.order['customer_name'] ?? 'N/A',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Type of Service',
                          style: TextStyle(fontSize: 16, color: Colors.black),
                        ),
                        Text(
                          widget.order['service_type'] ?? 'N/A',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Delivery Address',
                          style: TextStyle(fontSize: 16, color: Colors.black),
                        ),
                        Text(
                          widget.order['delivery_address'] ?? 'N/A',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Order Date',
                          style: TextStyle(fontSize: 16, color: Colors.black),
                        ),
                        Text(
                          widget.order['created_at'] ?? 'N/A',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Note:',
                          style: TextStyle(fontSize: 16, color: Colors.black),
                        ),
                        Text(
                          widget.order['special_instructions'] ?? '...',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Paid via',
                          style: TextStyle(fontSize: 16, color: Colors.black),
                        ),
                        Text(
                          widget.order['payment_method'] ?? 'N/A',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Payment balance',
                          style: TextStyle(fontSize: 16, color: Colors.black),
                        ),
                        Text(
                          '₱${widget.order['total_amount'] ?? '0.00'}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.order['laundry_shop_name'] ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: _captureAndSaveReceipt,
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.grey[200], // Light grey background
                      foregroundColor: Colors.black, // Dark text
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8), // Rounded corners
                      ),
                    ),
                    child: const Text('Download Receipt'),
                  ),
                ],
              ),
            ],
          ),
        ),
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
      // Request storage permission
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Storage permission required to save receipt')),
          );
        }
        return;
      }

      // Capture the widget as an image
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

      // Get the downloads directory
      final directory = await getDownloadsDirectory();
      if (directory == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not access downloads directory')),
          );
        }
        return;
      }

      // Create filename with order number and timestamp
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final orderNumber = widget.order['order_number'] ?? 'unknown';
      final fileName = 'Laundry-Scout_${orderNumber}_$timestamp.jpeg';
      final filePath = '${directory.path}/$fileName';

      // Save the file
      final file = File(filePath);
      await file.writeAsBytes(jpegBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Receipt saved to Downloads as $fileName')),
        );
      }
    } catch (e) {
      // debugPrint('Error saving receipt: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving receipt: $e')),
        );
      }
    }
  }
}
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../widgets/optimized_image.dart';

class BusinessProfilePreview extends StatefulWidget {
  final String businessName;
  final String location;
  final String aboutBusiness;
  final String? coverPhotoUrl;
  final PlatformFile? coverPhotoFile;
  final bool doesDelivery;
  final List<String> services;
  final String? phoneNumber;
  final String? email;
  final String? website;
  final String? openHours;
  final Map<String, double>? servicePrices;
  final double? rating;
  final int? reviewCount;
  final List<Map<String, dynamic>>? reviews;

  const BusinessProfilePreview({
    super.key,
    required this.businessName,
    required this.location,
    required this.aboutBusiness,
    this.coverPhotoUrl,
    this.coverPhotoFile,
    required this.doesDelivery,
    required this.services,
    this.phoneNumber,
    this.email,
    this.website,
    this.openHours,
    this.servicePrices,
    this.rating,
    this.reviewCount,
    this.reviews,
  });

  @override
  State<BusinessProfilePreview> createState() => _BusinessProfilePreviewState();
}

class _BusinessProfilePreviewState extends State<BusinessProfilePreview>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Map<String, TextEditingController> _priceControllers = {};
  bool _isEditingPrices = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializePriceControllers();
  }

  void _initializePriceControllers() {
    if (widget.servicePrices != null) {
      for (var entry in widget.servicePrices!.entries) {
        _priceControllers[entry.key] = TextEditingController(
          text: entry.value.toStringAsFixed(2),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (var controller in _priceControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider<Object>? imageProvider;

    // Prioritize the local file if available
    if (widget.coverPhotoFile != null) {
      if (kIsWeb) {
        if (widget.coverPhotoFile!.bytes != null) {
          imageProvider = MemoryImage(widget.coverPhotoFile!.bytes!);
        }
      } else {
        if (widget.coverPhotoFile!.path != null) {
          imageProvider = FileImage(File(widget.coverPhotoFile!.path!));
        }
      }
    }

    // If no local file image is set, try the URL
    if (imageProvider == null && widget.coverPhotoUrl != null) {
      imageProvider = NetworkImage(widget.coverPhotoUrl!);
    }

    return Scaffold(
      backgroundColor: const Color(0xFF6F5ADC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6F5ADC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Laundry Scout',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Open Now',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Cover Photo
          SizedBox(
            height: 200,
            child: widget.coverPhotoFile != null
                ? Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      image: imageProvider != null
                          ? DecorationImage(
                              image: imageProvider,
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: imageProvider == null
                        ? const Center(
                            child: Icon(Icons.business, size: 64, color: Colors.grey),
                          )
                        : null,
                  )
                : OptimizedImage(
                    imageUrl: widget.coverPhotoUrl,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorWidget: Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(Icons.business, size: 64, color: Colors.grey),
                      ),
                    ),
                  ),
          ),
          // Business Name and Rating
          Container(
            color: const Color(0xFF6F5ADC),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.businessName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.white70, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.location,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
                if (widget.rating != null) ...[

                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ...List.generate(5, (index) => Icon(
                        index < (widget.rating ?? 0).floor()
                            ? Icons.star
                            : Icons.star_border,
                        color: Colors.amber,
                        size: 16,
                      )),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.rating?.toStringAsFixed(1)} (${widget.reviewCount ?? 0} reviews)',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Tab Bar
          Container(
            color: const Color(0xFF6F5ADC),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(text: 'About'),
                Tab(text: 'Deliver'),
                Tab(text: 'Price only'),
                Tab(text: 'Reviews'),
              ],
            ),
          ),
          // Tab Content
          Expanded(
            child: Container(
              color: Colors.white,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAboutTab(),
                  _buildDeliverTab(),
                  _buildPricelistTab(),
                  _buildReviewsTab(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.aboutBusiness,
            style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black),
          ),
          const SizedBox(height: 24),
          const Text(
            'Services Offered',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.services.map((service) => Chip(
              label: Text(service),
              backgroundColor: const Color(0xFF6F5ADC),
              labelStyle: const TextStyle(color: Colors.white),
            )).toList(),
          ),
          if (widget.phoneNumber != null) ...[
            const SizedBox(height: 24),
            const Text(
              'Contact Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.phone, color: Color(0xFF6F5ADC), size: 20),
                const SizedBox(width: 8),
                Text(
                  widget.phoneNumber!,
                  style: const TextStyle(fontSize: 16, color: Colors.black),
                ),
              ],
            ),
          ],
          if (widget.email != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.email, color: Color(0xFF6F5ADC), size: 20),
                const SizedBox(width: 8),
                Text(
                  widget.email!,
                  style: const TextStyle(fontSize: 16, color: Colors.black),
                ),
              ],
            ),
          ],
          if (widget.openHours != null) ...[
            const SizedBox(height: 24),
            const SizedBox(height: 24),
            const Text(
              'Open Hours',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, color: Color(0xFF6F5ADC), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.openHours!,
                    style: const TextStyle(fontSize: 16, color: Colors.black),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDeliverTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: widget.doesDelivery ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.doesDelivery ? Colors.green : Colors.red,
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  widget.doesDelivery ? Icons.local_shipping : Icons.not_interested,
                  size: 48,
                  color: widget.doesDelivery ? Colors.green : Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  widget.doesDelivery ? 'Delivery Available' : 'No Delivery Service',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                if (widget.doesDelivery) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'We offer convenient delivery services to your location.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.black),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6F5ADC).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.schedule, color: Color(0xFF6F5ADC), size: 32),
                      SizedBox(height: 8),
                      Text(
                        'Washing',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6F5ADC).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.local_shipping, color: Color(0xFF6F5ADC), size: 32),
                      SizedBox(height: 8),
                      Text(
                        'Deliver',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6F5ADC).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.iron, color: Color(0xFF6F5ADC), size: 32),
                      SizedBox(height: 8),
                      Text(
                        'Wash & Fold',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPricelistTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Service Pricing',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _isEditingPrices = !_isEditingPrices;
                  });
                },
                icon: Icon(
                  _isEditingPrices ? Icons.check : Icons.edit,
                  color: const Color(0xFF6F5ADC),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (widget.servicePrices != null && widget.servicePrices!.isNotEmpty) ...[
            ...widget.servicePrices!.entries.map((entry) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      entry.key,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black),
                    ),
                  ),
                  const SizedBox(width: 16),
                  _isEditingPrices
                      ? SizedBox(
                          width: 100,
                          child: TextFormField(
                            controller: _priceControllers[entry.key],
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              prefixText: '\$',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            ),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6F5ADC),
                            ),
                          ),
                        )
                      : Text(
                          '\$${entry.value.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6F5ADC),
                          ),
                        ),
                ],
              ),
            )),
            if (_isEditingPrices) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _savePriceChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6F5ADC),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Save Price Changes',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ] else ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.price_check, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No pricing information available',
                      style: TextStyle(fontSize: 16, color: Colors.black),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _savePriceChanges() {
    // Update the service prices with new values
    final updatedPrices = <String, double>{};
    for (var entry in _priceControllers.entries) {
      final price = double.tryParse(entry.value.text) ?? 0.0;
      updatedPrices[entry.key] = price;
    }
    
    // Here you would typically save to database or call a callback
    // For now, we'll just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Price changes saved successfully!'),
        backgroundColor: Color(0xFF6F5ADC),
      ),
    );
    
    setState(() {
      _isEditingPrices = false;
    });
  }

  Widget _buildReviewsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (widget.rating != null) ...[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF6F5ADC).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Review',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.rating!.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6F5ADC),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) => Icon(
                      index < widget.rating!.floor()
                          ? Icons.star
                          : Icons.star_border,
                      color: Colors.amber,
                      size: 24,
                    )),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Based on ${widget.reviewCount ?? 0} reviews',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          if (widget.reviews != null && widget.reviews!.isNotEmpty) ...[
            ...widget.reviews!.map((review) => Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFF6F5ADC),
                        child: Text(
                          (review['name'] as String? ?? 'U')[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              review['name'] as String? ?? 'Anonymous',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                            ),
                            Row(
                              children: [
                                ...List.generate(5, (index) => Icon(
                                  index < (review['rating'] as double? ?? 0).floor()
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.amber,
                                  size: 16,
                                )),
                                const SizedBox(width: 8),
                                Text(
                                  (review['rating'] as double? ?? 0).toStringAsFixed(1),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Text(
                        review['date'] as String? ?? '',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    review['comment'] as String? ?? '',
                    style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.black),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Handle make a review
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6F5ADC),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Make a Review',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ] else ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.rate_review, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No reviews yet',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
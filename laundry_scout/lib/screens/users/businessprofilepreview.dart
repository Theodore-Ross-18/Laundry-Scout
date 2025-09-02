import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart'; // Add this import
import 'dart:io'; // Add this import
import 'package:flutter/foundation.dart' show kIsWeb; // Add this import
import '../../widgets/optimized_image.dart';

class BusinessProfilePreview extends StatelessWidget {
  final String businessName;
  final String location;
  final String aboutBusiness;
  final String? coverPhotoUrl;
  final PlatformFile? coverPhotoFile; // Declare coverPhotoFile field
  final bool doesDelivery;
  final List<String> services;

  const BusinessProfilePreview({
    Key? key,
    required this.businessName,
    required this.location,
    required this.aboutBusiness,
    this.coverPhotoUrl,
    this.coverPhotoFile, // Add coverPhotoFile to the constructor
    required this.doesDelivery,
    required this.services,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ImageProvider<Object>? imageProvider;

    // Prioritize the local file if available
    if (coverPhotoFile != null) {
      if (kIsWeb) {
        if (coverPhotoFile!.bytes != null) {
          imageProvider = MemoryImage(coverPhotoFile!.bytes!);
        }
      } else { // Mobile
        if (coverPhotoFile!.path != null) {
          imageProvider = FileImage(File(coverPhotoFile!.path!));
        }
      }
    }

    // If no local file image is set, try the URL
    if (imageProvider == null && coverPhotoUrl != null) {
      imageProvider = NetworkImage(coverPhotoUrl!);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Preview'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cover Photo
            SizedBox(
              height: 200,
              child: coverPhotoFile != null
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
                      imageUrl: coverPhotoUrl,
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
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Business Name
                  Text(
                    businessName,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),

                  // Location
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.white70),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          location,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.white70,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // About Business
                  Text(
                    'About',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    aboutBusiness,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                  const SizedBox(height: 24),

                  // Services
                  Text(
                    'Services Offered',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: services.map((service) => Chip(
                      label: Text(service),
                      backgroundColor: const Color(0xFF6F5ADC),
                      labelStyle: const TextStyle(color: Colors.white),
                    )).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Delivery Status
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          doesDelivery ? Icons.local_shipping : Icons.not_interested,
                          color: doesDelivery ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          doesDelivery ? 'Delivery Available' : 'No Delivery Service',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.white,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:mime/mime.dart';

class BusinessDocsScreen extends StatefulWidget {
  const BusinessDocsScreen({super.key});

  @override
  State<BusinessDocsScreen> createState() => _BusinessDocsScreenState();
}

class _BusinessDocsScreenState extends State<BusinessDocsScreen> {
  PlatformFile? _birFile;
  PlatformFile? _certificateFile;
  PlatformFile? _permitFile;
  String? _birImageUrl;
  String? _certificateImageUrl;
  String? _permitImageUrl;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadExistingDocuments();
  }

  Future<void> _loadExistingDocuments() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final response = await Supabase.instance.client
          .from('business_profiles')
          .select('bir_registration_url, business_certificate_url, mayors_permit_url')
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) {
        return;
      }

      if (mounted) {
        setState(() {
          if (response['bir_registration_url'] != null) {
            _birImageUrl = response['bir_registration_url'] as String;
          }
          if (response['business_certificate_url'] != null) {
            _certificateImageUrl = response['business_certificate_url'] as String;
          }
          if (response['mayors_permit_url'] != null) {
            _permitImageUrl = response['mayors_permit_url'] as String;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading existing documents: $e')),
        );
      }
    }
  }

  Future<void> _pickFile(Function(PlatformFile) onFilePicked, String fileTypeLabel) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        withData: kIsWeb,
      );
      if (result != null && result.files.isNotEmpty) {
        final pickedFile = result.files.single;

        if (kIsWeb && pickedFile.bytes == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to load file bytes for $fileTypeLabel on web.')),
            );
          }
          return;
        }
        if (!kIsWeb && pickedFile.path == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('File path is invalid for $fileTypeLabel.')),
            );
          }
          return;
        }
        onFilePicked(pickedFile);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No $fileTypeLabel selected.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking $fileTypeLabel: ${e.toString()}')),
        );
      }
    }
  }

  Future<String?> _uploadDocument(PlatformFile? file, String docType, String businessName) async {
    if (file == null) return null;
    final String fileExtension = file.extension ?? 'bin';
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return null;
    final String fileName = '${businessName}/${docType}_${user.id}_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';

    if (kIsWeb) {
      if (file.bytes == null) {
        throw Exception('File bytes are null for $docType on web.');
      }
      await Supabase.instance.client.storage.from('businessdocuments').uploadBinary(
            fileName,
            file.bytes!,
            fileOptions: FileOptions(
              contentType: lookupMimeType(file.name) ?? 'application/octet-stream'
            ),
          );
    } else {
      if (file.path == null) {
        throw Exception('File path is null for $docType on mobile.');
      }
      await Supabase.instance.client.storage.from('businessdocuments').upload(
            fileName,
            File(file.path!),
          );
    }
    return Supabase.instance.client.storage.from('businessdocuments').getPublicUrl(fileName);
  }

  Future<void> _submitDocuments() async {
    setState(() { _isSubmitting = true; });
    String? birUrl, certificateUrl, permitUrl;

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User not logged in')),
          );
        }
        setState(() { _isSubmitting = false; });
        return;
      }

      final businessProfile = await Supabase.instance.client
          .from('business_profiles')
          .select('business_name')
          .eq('id', user.id)
          .maybeSingle();
      
      if (businessProfile == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Business profile not found.')),
          );
        }
        setState(() { _isSubmitting = false; });
        return;
      }

      final String businessName = businessProfile['business_name'] ?? 'unknown_business';

      birUrl = await _uploadDocument(_birFile, 'bir', businessName);
      certificateUrl = await _uploadDocument(_certificateFile, 'certificate', businessName);
      permitUrl = await _uploadDocument(_permitFile, 'permit', businessName);

      await Supabase.instance.client
          .from('business_profiles')
          .update({
            'bir_registration_url': birUrl,
            'business_certificate_url': certificateUrl,
            'mayors_permit_url': permitUrl,
            'status': 'pending', 
          })
          .eq('id', user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Documents updated successfully!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting documents: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isSubmitting = false; });
      }
    }
  }


  void _onBirFilePicked(PlatformFile file) {
    setState(() {
      _birFile = file;
    });
  }

  void _onCertificateFilePicked(PlatformFile file) {
    setState(() {
      _certificateFile = file;
    });
  }

  void _onPermitFilePicked(PlatformFile file) {
    setState(() {
      _permitFile = file;
    });
  }

  Widget _buildFileUploadField({
    required String label,
    PlatformFile? file,
    String? imageUrl,
    required VoidCallback onTap,
    required TextTheme textTheme,
    required VoidCallback onClear,
  }) {
    bool isImage =
        (file?.extension?.toLowerCase() == 'jpg' ||
         file?.extension?.toLowerCase() == 'jpeg' ||
         file?.extension?.toLowerCase() == 'png');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.bodyMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: Colors.grey[700]!),
              image: (isImage && file != null)
                  ? DecorationImage(
                      image: kIsWeb
                          ? MemoryImage(file.bytes!) as ImageProvider<Object>
                          : FileImage(File(file.path!)) as ImageProvider<Object>,
                      fit: BoxFit.cover,
                    )
                  : (imageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(imageUrl),
                          fit: BoxFit.cover,
                        )
                      : null),
            ),
            child: (file == null && imageUrl == null)
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_upload, size: 40, color: Colors.white),
                        const SizedBox(height: 8),
                        Text('Click to upload', style: textTheme.bodySmall?.copyWith(color: Colors.white)),
                      ],
                    ),
                  )
                : (isImage || imageUrl != null)
                    ? Stack(
                        children: [
                          Positioned.fill(
                            child: (isImage && file != null)
                                ? Image(
                                    image: kIsWeb
                                        ? MemoryImage(file.bytes!) as ImageProvider<Object>
                                        : FileImage(File(file.path!)) as ImageProvider<Object>,
                                    fit: BoxFit.cover,
                                  )
                                : Image(
                                    image: NetworkImage(imageUrl!),
                                    fit: BoxFit.cover,
                                  ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: onClear,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.all(4),
                                child: const Icon(Icons.close, color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Text(
                              file!.name,
                              style: textTheme.bodySmall?.copyWith(color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: onClear,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
          ),
        ),
        const SizedBox(height: 8),
        if (file != null && !isImage)
          Text(
            file.name,
            style: textTheme.bodySmall?.copyWith(color: Colors.white),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Documents'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildFileUploadField(
              label: 'Attach BIR Registration',
              file: _birFile,
              imageUrl: _birImageUrl,
              onTap: () => _pickFile(_onBirFilePicked, 'BIR Registration'),
              onClear: () => setState(() {
                _birFile = null;
                _birImageUrl = null;
              }),
              textTheme: textTheme,
            ),
            const SizedBox(height: 20),
            _buildFileUploadField(
              label: 'Business Certificate',
              file: _certificateFile,
              imageUrl: _certificateImageUrl,
              onTap: () => _pickFile(_onCertificateFilePicked, 'Business Certificate'),
              onClear: () => setState(() {
                _certificateFile = null;
                _certificateImageUrl = null;
              }),
              textTheme: textTheme,
            ),
            const SizedBox(height: 20),
            _buildFileUploadField(
              label: 'Mayor\'s Permit',
              file: _permitFile,
              imageUrl: _permitImageUrl,
              onTap: () => _pickFile(_onPermitFilePicked, 'Mayor\'s Permit'),
              onClear: () => setState(() {
                _permitFile = null;
                _permitImageUrl = null;
              }),
              textTheme: textTheme,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitDocuments,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5A35E3),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              child: _isSubmitting
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                  : const Text('Update Documents'),
            ),
          ],
        ),
      ),
    );
  }
}
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
            _birFile = PlatformFile(name: 'BIR_Registration.pdf', size: 0); 
          }
          if (response['business_certificate_url'] != null) {
            _certificateFile = PlatformFile(name: 'Business_Certificate.pdf', size: 0); 
          }
          if (response['mayors_permit_url'] != null) {
            _permitFile = PlatformFile(name: 'Mayors_Permit.pdf', size: 0); 
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
    required PlatformFile? file,
    required VoidCallback onTap,
    required TextTheme textTheme,
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
          style: textTheme.bodyMedium?.copyWith(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: Colors.grey[300]!),
              image: isImage && file != null
                  ? DecorationImage(
                      image: kIsWeb
                          ? MemoryImage(file.bytes!) as ImageProvider<Object>
                          : FileImage(File(file.path!)) as ImageProvider<Object>,
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: file == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_upload, size: 40, color: Colors.grey[600]),
                        const SizedBox(height: 8),
                        Text('Click to upload', style: textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
                      ],
                    ),
                  )
                : isImage
                    ? null
                    : Center(
                        child: Text(
                          file.name,
                          style: textTheme.bodySmall?.copyWith(color: Colors.black87),
                          textAlign: TextAlign.center,
                        ),
                      ),
          ),
        ),
        const SizedBox(height: 8),
        if (file != null && !isImage)
          Text(
            file.name,
            style: textTheme.bodySmall?.copyWith(color: Colors.black54),
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
              onTap: () => _pickFile(_onBirFilePicked, 'BIR Registration'),
              textTheme: textTheme,
            ),
            const SizedBox(height: 20),
            _buildFileUploadField(
              label: 'Business Certificate',
              file: _certificateFile,
              onTap: () => _pickFile(_onCertificateFilePicked, 'Business Certificate'),
              textTheme: textTheme,
            ),
            const SizedBox(height: 20),
            _buildFileUploadField(
              label: 'Mayor\'s Permit',
              file: _permitFile,
              onTap: () => _pickFile(_onPermitFilePicked, 'Mayor\'s Permit'),
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
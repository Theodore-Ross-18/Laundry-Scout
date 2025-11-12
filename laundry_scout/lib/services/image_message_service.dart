import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:mime/mime.dart';
import 'image_service.dart';

class ImageMessageService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static final ImagePicker _imagePicker = ImagePicker();

  /// Take a photo using the device camera
  static Future<XFile?> takePhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      return photo;
    } catch (e) {
      print('Error taking photo: $e');
      return null;
    }
  }

  /// Pick an image from device gallery
  static Future<XFile?> pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      return image;
    } catch (e) {
      print('Error picking image from gallery: $e');
      return null;
    }
  }

  /// Upload image to Supabase storage and return the public URL
  static Future<String?> uploadImageToStorage({
    required XFile imageFile,
    required String conversationId,
    required String senderId,
  }) async {
    try {
      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileExtension = path.extension(imageFile.path).toLowerCase();
      final fileName = '${conversationId}_${senderId}_${timestamp}$fileExtension';
      final filePath = 'message_images/$fileName';

      // Get file bytes
      Uint8List fileBytes;
      if (kIsWeb) {
        fileBytes = await imageFile.readAsBytes();
      } else {
        fileBytes = await File(imageFile.path).readAsBytes();
      }

      // Compress image
      final compressedBytes = await ImageService.compressImage(fileBytes);

      // Upload to Supabase storage
      await _supabase.storage
          .from('message_images')
          .uploadBinary(filePath, compressedBytes);

      // Get public URL
      final publicUrl = _supabase.storage
          .from('message_images')
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      print('Error uploading image to storage: $e');
      return null;
    }
  }

  /// Upload PlatformFile to Supabase storage (for file picker compatibility)
  static Future<String?> uploadPlatformFileToStorage({
    required PlatformFile platformFile,
    required String conversationId,
    required String senderId,
  }) async {
    try {
      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileExtension = platformFile.extension != null 
          ? '.${platformFile.extension}' 
          : '.jpg';
      final fileName = '${conversationId}_${senderId}_${timestamp}$fileExtension';
      final filePath = 'message_images/$fileName';

      // Get file bytes
      Uint8List fileBytes;
      if (kIsWeb) {
        if (platformFile.bytes == null) {
          throw Exception('File bytes are null for web platform');
        }
        fileBytes = platformFile.bytes!;
      } else {
        if (platformFile.path == null) {
          throw Exception('File path is null for mobile platform');
        }
        fileBytes = await File(platformFile.path!).readAsBytes();
      }

      // Compress image
      final compressedBytes = await ImageService.compressImage(fileBytes);

      // Upload to Supabase storage
      await _supabase.storage
          .from('message_images')
          .uploadBinary(filePath, compressedBytes);

      // Get public URL
      final publicUrl = _supabase.storage
          .from('message_images')
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      print('Error uploading platform file to storage: $e');
      return null;
    }
  }

  /// Delete an image from Supabase storage
  static Future<bool> deleteImageFromStorage(String imageUrl) async {
    try {
      // Extract file path from URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      
      // Find the file path after 'message_images/'
      final messageImagesIndex = pathSegments.indexOf('message_images');
      if (messageImagesIndex == -1 || messageImagesIndex + 1 >= pathSegments.length) {
        print('Invalid image URL format');
        return false;
      }
      
      final filePath = pathSegments.sublist(messageImagesIndex + 1).join('/');
      final fullPath = 'message_images/$filePath';

      // Delete from storage
      await _supabase.storage.from('message_images').remove([fullPath]);
      return true;
    } catch (e) {
      print('Error deleting image from storage: $e');
      return false;
    }
  }

  /// Validate if a file is an image
  static bool isImageFile(String filePath) {
    final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'];
    final extension = path.extension(filePath).toLowerCase();
    return imageExtensions.contains(extension);
  }

  /// Get mime type for a file
  static String? getMimeType(String filePath) {
    return lookupMimeType(filePath);
  }
}
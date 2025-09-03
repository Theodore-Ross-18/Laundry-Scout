import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';

class FormPersistenceService {
  static const String _userInfoPrefix = 'user_info_form_';
  static const String _businessInfoPrefix = 'business_info_form_';
  static const String _businessProfilePrefix = 'business_profile_form_';

  // Save form data
  static Future<void> saveFormData(String formType, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getKey(formType);
    await prefs.setString(key, jsonEncode(data));
  }

  // Save image file data
  static Future<void> saveImageData(String formType, String fieldName, PlatformFile? imageFile) async {
    if (imageFile == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    final imageKey = '${_getKey(formType)}_${fieldName}_image';
    
    if (kIsWeb) {
      if (imageFile.bytes != null) {
        await prefs.setString(imageKey, base64Encode(imageFile.bytes!));
        await prefs.setString('${imageKey}_name', imageFile.name);
      }
    } else {
      if (imageFile.path != null) {
        final file = File(imageFile.path!);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          await prefs.setString(imageKey, base64Encode(bytes));
          await prefs.setString('${imageKey}_name', imageFile.name);
        }
      }
    }
  }

  // Load image file data
  static Future<PlatformFile?> loadImageData(String formType, String fieldName) async {
    final prefs = await SharedPreferences.getInstance();
    final imageKey = '${_getKey(formType)}_${fieldName}_image';
    final nameKey = '${imageKey}_name';
    
    final imageData = prefs.getString(imageKey);
    final imageName = prefs.getString(nameKey);
    
    if (imageData != null && imageName != null) {
      try {
        final bytes = base64Decode(imageData);
        return PlatformFile(
          name: imageName,
          size: bytes.length,
          bytes: bytes,
        );
      } catch (e) {
        // If data is corrupted, remove it
        await prefs.remove(imageKey);
        await prefs.remove(nameKey);
        return null;
      }
    }
    return null;
  }

  // Clear image data
  static Future<void> clearImageData(String formType, String fieldName) async {
    final prefs = await SharedPreferences.getInstance();
    final imageKey = '${_getKey(formType)}_${fieldName}_image';
    final nameKey = '${imageKey}_name';
    await prefs.remove(imageKey);
    await prefs.remove(nameKey);
  }

  // Load form data
  static Future<Map<String, dynamic>?> loadFormData(String formType) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getKey(formType);
    final data = prefs.getString(key);
    if (data != null) {
      try {
        return jsonDecode(data) as Map<String, dynamic>;
      } catch (e) {
        // If data is corrupted, remove it
        await clearFormData(formType);
        return null;
      }
    }
    return null;
  }

  // Clear form data
  static Future<void> clearFormData(String formType) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getKey(formType);
    await prefs.remove(key);
  }

  // Save individual field
  static Future<void> saveField(String formType, String fieldName, dynamic value) async {
    final existingData = await loadFormData(formType) ?? {};
    existingData[fieldName] = value;
    await saveFormData(formType, existingData);
  }

  // Get storage key based on form type
  static String _getKey(String formType) {
    switch (formType) {
      case 'user_info':
        return '${_userInfoPrefix}data';
      case 'business_info':
        return '${_businessInfoPrefix}data';
      case 'business_profile':
        return '${_businessProfilePrefix}data';
      default:
        return '${formType}_form_data';
    }
  }

  // Form type constants
  static const String userInfoForm = 'user_info';
  static const String businessInfoForm = 'business_info';
  static const String businessProfileForm = 'business_profile';

  // Helper methods for specific forms
  static Future<void> saveUserInfoData(Map<String, dynamic> data) async {
    await saveFormData(userInfoForm, data);
  }

  static Future<Map<String, dynamic>?> loadUserInfoData() async {
    return await loadFormData(userInfoForm);
  }

  static Future<void> clearUserInfoData() async {
    await clearFormData(userInfoForm);
  }

  static Future<void> saveBusinessInfoData(Map<String, dynamic> data) async {
    await saveFormData(businessInfoForm, data);
  }

  static Future<Map<String, dynamic>?> loadBusinessInfoData() async {
    return await loadFormData(businessInfoForm);
  }

  static Future<void> clearBusinessInfoData() async {
    await clearFormData(businessInfoForm);
  }

  static Future<void> saveBusinessProfileData(Map<String, dynamic> data) async {
    await saveFormData(businessProfileForm, data);
  }

  static Future<Map<String, dynamic>?> loadBusinessProfileData() async {
    return await loadFormData(businessProfileForm);
  }

  static Future<void> clearBusinessProfileData() async {
    await clearFormData(businessProfileForm);
    await clearImageData(businessProfileForm, 'cover_photo');
  }

  // Helper methods for image persistence
  static Future<void> saveBusinessProfileImage(PlatformFile? imageFile) async {
    await saveImageData(businessProfileForm, 'cover_photo', imageFile);
  }

  static Future<PlatformFile?> loadBusinessProfileImage() async {
    return await loadImageData(businessProfileForm, 'cover_photo');
  }
}
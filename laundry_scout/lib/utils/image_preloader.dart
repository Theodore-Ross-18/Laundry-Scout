import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ImagePreloader {
  static final ImagePreloader _instance = ImagePreloader._internal();
  factory ImagePreloader() => _instance;
  ImagePreloader._internal();

  final Set<String> _preloadedImages = {};

  /// Preload critical images for better user experience
  Future<void> preloadCriticalImages(BuildContext context, List<String> imageUrls) async {
    final List<Future<void>> preloadTasks = [];
    
    for (String url in imageUrls) {
      if (!_preloadedImages.contains(url) && url.isNotEmpty) {
        preloadTasks.add(_preloadSingleImage(context, url));
      }
    }
    
    if (preloadTasks.isNotEmpty) {
      await Future.wait(preloadTasks, eagerError: false);
    }
  }

  Future<void> _preloadSingleImage(BuildContext context, String url) async {
    try {
      await precacheImage(
        CachedNetworkImageProvider(url),
        context,
      );
      _preloadedImages.add(url);
      debugPrint('Successfully preloaded image: $url');
    } catch (e) {
      debugPrint('Failed to preload image $url: $e');
    }
  }

  /// Check if an image has been preloaded
  bool isPreloaded(String url) {
    return _preloadedImages.contains(url);
  }

  /// Clear preloaded images cache
  void clearPreloadedCache() {
    _preloadedImages.clear();
  }

  /// Get count of preloaded images
  int get preloadedCount => _preloadedImages.length;
}
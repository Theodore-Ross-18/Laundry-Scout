import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:file_picker/file_picker.dart';

class ImageService {
  static final ImageService _instance = ImageService._internal();
  factory ImageService() => _instance;
  ImageService._internal();

  // Cache for network connectivity status
  ConnectivityResult? _lastConnectivityResult;
  
  // Image quality settings based on network speed
  static const Map<ConnectivityResult, int> _qualitySettings = {
    ConnectivityResult.wifi: 90,
    ConnectivityResult.ethernet: 95,
    ConnectivityResult.mobile: 70,
    ConnectivityResult.other: 60,
    ConnectivityResult.none: 50,
  };

  // Get current network connectivity
  Future<ConnectivityResult> _getConnectivity() async {
    if (_lastConnectivityResult == null) {
      final List<ConnectivityResult> results = await Connectivity().checkConnectivity();
      _lastConnectivityResult = results.isNotEmpty ? results.first : ConnectivityResult.none;
      
      // Listen for connectivity changes
      Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
        _lastConnectivityResult = results.isNotEmpty ? results.first : ConnectivityResult.none;
      });
    }
    return _lastConnectivityResult!;
  }

  // Get image quality based on network speed
  Future<int> _getImageQuality() async {
    final connectivity = await _getConnectivity();
    return _qualitySettings[connectivity] ?? 70;
  }

  // Static method for simple image compression
  static Future<Uint8List> compressImage(Uint8List imageBytes) async {
    try {
      final compressedBytes = await FlutterImageCompress.compressWithList(
        imageBytes,
        quality: 85,
        minWidth: 800,
        minHeight: 600,
      );
      return compressedBytes;
    } catch (e) {
      // If compression fails, return original bytes
      return imageBytes;
    }
  }

  // Compress image based on network conditions (instance method)
  Future<Uint8List?> compressImageWithNetworkOptimization({
    required Uint8List imageBytes,
    String? filePath,
    int? customQuality,
  }) async {
    try {
      final quality = customQuality ?? await _getImageQuality();
      
      if (kIsWeb) {
        // For web, use basic compression
        return await FlutterImageCompress.compressWithList(
          imageBytes,
          quality: quality,
          format: CompressFormat.jpeg,
        );
      } else {
        // For mobile, use file-based compression if path is available
        if (filePath != null) {
          final result = await FlutterImageCompress.compressWithFile(
            filePath,
            quality: quality,
            format: CompressFormat.jpeg,
          );
          return result;
        } else {
          return await FlutterImageCompress.compressWithList(
            imageBytes,
            quality: quality,
            format: CompressFormat.jpeg,
          );
        }
      }
    } catch (e) {
      debugPrint('Error compressing image: $e');
      return imageBytes; // Return original if compression fails
    }
  }

  // Compress picked file
  Future<PlatformFile?> compressPickedFile(PlatformFile file) async {
    try {
      Uint8List? compressedBytes;
      
      if (kIsWeb && file.bytes != null) {
        compressedBytes = await compressImage(file.bytes!);
      } else if (!kIsWeb && file.path != null) {
        compressedBytes = await compressImage(
          file.bytes ?? Uint8List(0),
        );
      }

      if (compressedBytes != null) {
        return PlatformFile(
          name: file.name,
          size: compressedBytes.length,
          bytes: compressedBytes,
          path: file.path,
        );
      }
    } catch (e) {
      debugPrint('Error compressing picked file: $e');
    }
    return file; // Return original if compression fails
  }

  // Create optimized cached network image widget
  Widget buildCachedNetworkImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
    BorderRadius? borderRadius,
  }) {
    // Safe conversion to int, avoiding infinity values
    int? memCacheWidth;
    int? memCacheHeight;
    
    if (width != null && width.isFinite && width > 0) {
      memCacheWidth = width.toInt();
    }
    
    if (height != null && height.isFinite && height > 0) {
      memCacheHeight = height.toInt();
    }
    
    Widget imageWidget = CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => placeholder ?? _buildDefaultPlaceholder(),
      errorWidget: (context, url, error) {
        debugPrint('Image loading error for $url: $error');
        return errorWidget ?? _buildDefaultErrorWidget();
      },
      fadeInDuration: const Duration(milliseconds: 200),
      fadeOutDuration: const Duration(milliseconds: 100),
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      maxWidthDiskCache: 800, // Reduced for better performance
      maxHeightDiskCache: 800,
      cacheManager: CacheManager(
        Config(
          'customCacheKey',
          stalePeriod: const Duration(days: 7),
          maxNrOfCacheObjects: 200,
          repo: JsonCacheInfoRepository(databaseName: 'customCacheKey'),
          fileService: HttpFileService(),
        ),
      ),
    );

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  // Create optimized circular avatar with cached image
  Widget buildCachedCircleAvatar({
    required String? imageUrl,
    required double radius,
    Widget? child,
    Color? backgroundColor,
  }) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? Colors.grey[300],
        child: child ?? Icon(Icons.person, size: radius, color: Colors.grey[600]),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? Colors.grey[300],
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          placeholder: (context, url) => _buildCircularPlaceholder(radius),
          errorWidget: (context, url, error) {
            debugPrint('Avatar image loading error for $url: $error');
            return child ?? Icon(
              Icons.person,
              size: radius,
              color: Colors.grey[600],
            );
          },
          memCacheWidth: (radius * 2).isFinite ? (radius * 2).toInt() : null,
          memCacheHeight: (radius * 2).isFinite ? (radius * 2).toInt() : null,
          cacheManager: CacheManager(
            Config(
              'avatarCacheKey',
              stalePeriod: const Duration(days: 7),
              maxNrOfCacheObjects: 100,
              repo: JsonCacheInfoRepository(databaseName: 'avatarCacheKey'),
              fileService: HttpFileService(),
            ),
          ),
        ),
      ),
    );
  }

  // Default placeholder widget
  Widget _buildDefaultPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6F5ADC)),
        ),
      ),
    );
  }

  // Default error widget
  Widget _buildDefaultErrorWidget() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(
          Icons.error_outline,
          color: Colors.grey,
          size: 32,
        ),
      ),
    );
  }

  // Circular placeholder for avatars
  Widget _buildCircularPlaceholder(double radius) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey[200],
      ),
      child: Center(
        child: SizedBox(
          width: radius * 0.6,
          height: radius * 0.6,
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6F5ADC)),
          ),
        ),
      ),
    );
  }

  // Preload images for better performance
  Future<void> preloadImages(List<String> imageUrls, BuildContext context) async {
    for (String url in imageUrls) {
      try {
        await precacheImage(CachedNetworkImageProvider(url), context);
      } catch (e) {
        debugPrint('Error preloading image $url: $e');
      }
    }
  }

  // Clear image cache
  Future<void> clearCache() async {
    await CachedNetworkImage.evictFromCache('');
  }

  // Get cache size info
  Future<String> getCacheInfo() async {
    try {
      final cacheManager = DefaultCacheManager();
      await cacheManager.getFileFromCache('');
      return 'Cache info available';
    } catch (e) {
      return 'Cache info unavailable';
    }
  }
}
import 'dart:async';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

enum NetworkSpeed {
  slow,    // < 1 Mbps
  medium,  // 1-5 Mbps
  fast,    // > 5 Mbps
  unknown
}

class NetworkSpeedDetector {
  static NetworkSpeedDetector? _instance;
  static NetworkSpeedDetector get instance => _instance ??= NetworkSpeedDetector._();
  
  NetworkSpeedDetector._();
  
  NetworkSpeed _currentSpeed = NetworkSpeed.unknown;
  final StreamController<NetworkSpeed> _speedController = StreamController<NetworkSpeed>.broadcast();
  
  NetworkSpeed get currentSpeed => _currentSpeed;
  Stream<NetworkSpeed> get speedStream => _speedController.stream;
  
  /// Detect network speed using multiple methods
  Future<NetworkSpeed> detectSpeed() async {
    if (kIsWeb) {
      return await _detectWebSpeed();
    } else {
      // For mobile apps, use a different approach
      return await _detectMobileSpeed();
    }
  }
  
  /// Web-specific speed detection using Navigator API
  Future<NetworkSpeed> _detectWebSpeed() async {
    try {
      // Method 1: Use Navigator.connection API if available
      if (html.window.navigator.connection != null) {
        final connection = html.window.navigator.connection!;
        final effectiveType = connection.effectiveType;
        
        switch (effectiveType) {
          case 'slow-2g':
          case '2g':
            _currentSpeed = NetworkSpeed.slow;
            break;
          case '3g':
            _currentSpeed = NetworkSpeed.medium;
            break;
          case '4g':
            _currentSpeed = NetworkSpeed.fast;
            break;
          default:
            _currentSpeed = NetworkSpeed.medium;
        }
        
        _speedController.add(_currentSpeed);
        return _currentSpeed;
      }
      
      // Method 2: Fallback to download speed test
      return await _performSpeedTest();
    } catch (e) {
      debugPrint('Error detecting network speed: $e');
      _currentSpeed = NetworkSpeed.medium;
      _speedController.add(_currentSpeed);
      return _currentSpeed;
    }
  }
  
  /// Mobile-specific speed detection
  Future<NetworkSpeed> _detectMobileSpeed() async {
    // For mobile, we'll use a simple speed test
    return await _performSpeedTest();
  }
  
  /// Perform a simple speed test by downloading a small resource
  Future<NetworkSpeed> _performSpeedTest() async {
    try {
      final stopwatch = Stopwatch()..start();
      
      // Use a small image or API endpoint for speed testing
      // This is a lightweight test - you can adjust the URL
      final testUrl = 'https://httpbin.org/bytes/1024'; // 1KB test
      
      final response = await html.HttpRequest.request(
        testUrl,
        method: 'GET',
        requestHeaders: {
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
        },
      );
      
      stopwatch.stop();
      
      if (response.status == 200) {
        final timeMs = stopwatch.elapsedMilliseconds;
        final bytesDownloaded = 1024; // 1KB
        final speedKbps = (bytesDownloaded * 8) / (timeMs / 1000) / 1024; // Kbps
        
        if (speedKbps < 1000) { // < 1 Mbps
          _currentSpeed = NetworkSpeed.slow;
        } else if (speedKbps < 5000) { // 1-5 Mbps
          _currentSpeed = NetworkSpeed.medium;
        } else { // > 5 Mbps
          _currentSpeed = NetworkSpeed.fast;
        }
      } else {
        _currentSpeed = NetworkSpeed.medium; // Default fallback
      }
    } catch (e) {
      debugPrint('Speed test failed: $e');
      _currentSpeed = NetworkSpeed.medium; // Default fallback
    }
    
    _speedController.add(_currentSpeed);
    return _currentSpeed;
  }
  
  /// Get loading strategy based on network speed
  LoadingStrategy getLoadingStrategy() {
    switch (_currentSpeed) {
      case NetworkSpeed.slow:
        return LoadingStrategy(
          gpsAccuracy: 'low',
          enableCaching: true,
          lazyLoadMarkers: true,
          maxMarkersInitial: 5,
          enableProgressiveLoading: true,
          timeoutMs: 15000,
        );
      case NetworkSpeed.medium:
        return LoadingStrategy(
          gpsAccuracy: 'medium',
          enableCaching: true,
          lazyLoadMarkers: false,
          maxMarkersInitial: 15,
          enableProgressiveLoading: true,
          timeoutMs: 10000,
        );
      case NetworkSpeed.fast:
        return LoadingStrategy(
          gpsAccuracy: 'high',
          enableCaching: false,
          lazyLoadMarkers: false,
          maxMarkersInitial: -1, // Load all
          enableProgressiveLoading: false,
          timeoutMs: 5000,
        );
      case NetworkSpeed.unknown:
        return LoadingStrategy(
          gpsAccuracy: 'medium',
          enableCaching: true,
          lazyLoadMarkers: true,
          maxMarkersInitial: 10,
          enableProgressiveLoading: true,
          timeoutMs: 10000,
        );
    }
  }
  
  void dispose() {
    _speedController.close();
  }
}

class LoadingStrategy {
  final String gpsAccuracy;
  final bool enableCaching;
  final bool lazyLoadMarkers;
  final int maxMarkersInitial;
  final bool enableProgressiveLoading;
  final int timeoutMs;
  
  LoadingStrategy({
    required this.gpsAccuracy,
    required this.enableCaching,
    required this.lazyLoadMarkers,
    required this.maxMarkersInitial,
    required this.enableProgressiveLoading,
    required this.timeoutMs,
  });
}
import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum ConnectionQuality { excellent, good, fair, poor, offline }

class ConnectionService {
  static final ConnectionService _instance = ConnectionService._internal();
  factory ConnectionService() => _instance;
  ConnectionService._internal();

  ConnectionQuality _currentQuality = ConnectionQuality.good;
  final StreamController<ConnectionQuality> _qualityController = StreamController.broadcast();
  Timer? _qualityCheckTimer;
  int _consecutiveFailures = 0;
  
  ConnectionQuality get currentQuality => _currentQuality;
  Stream<ConnectionQuality> get qualityStream => _qualityController.stream;

  void startMonitoring() {
    // More frequent monitoring for better responsiveness
    _qualityCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkConnectionQuality();
    });
    _checkConnectionQuality(); // Initial check
  }

  void stopMonitoring() {
    _qualityCheckTimer?.cancel();
  }

  Future<void> _checkConnectionQuality() async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      
      if (connectivity == ConnectivityResult.none) {
        _updateQuality(ConnectionQuality.offline);
        return;
      }

      // Test with Supabase endpoint for more accurate results
      final stopwatch = Stopwatch()..start();
      
      try {
        // Ping Supabase directly for more relevant latency
        await Supabase.instance.client
            .from('messages')
            .select('id')
            .limit(1)
            .timeout(const Duration(seconds: 3));
        
        stopwatch.stop();
        final responseTime = stopwatch.elapsedMilliseconds;
        
        ConnectionQuality quality;
        if (responseTime < 150) {
          quality = ConnectionQuality.excellent;
        } else if (responseTime < 400) {
          quality = ConnectionQuality.good;
        } else if (responseTime < 1000) {
          quality = ConnectionQuality.fair;
        } else {
          quality = ConnectionQuality.poor;
        }
        
        _consecutiveFailures = 0;
        _updateQuality(quality);
      } catch (e) {
        // Fallback to DNS lookup if Supabase fails
        await _fallbackConnectionTest();
      }
    } catch (e) {
      _consecutiveFailures++;
      if (_consecutiveFailures >= 3) {
        _updateQuality(ConnectionQuality.offline);
      } else {
        _updateQuality(ConnectionQuality.poor);
      }
    }
  }

  Future<void> _fallbackConnectionTest() async {
    try {
      final stopwatch = Stopwatch()..start();
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      stopwatch.stop();

      if (result.isNotEmpty) {
        final responseTime = stopwatch.elapsedMilliseconds;
        
        ConnectionQuality quality;
        if (responseTime < 200) {
          quality = ConnectionQuality.good;
        } else if (responseTime < 500) {
          quality = ConnectionQuality.fair;
        } else {
          quality = ConnectionQuality.poor;
        }
        
        _updateQuality(quality);
      } else {
        _updateQuality(ConnectionQuality.offline);
      }
    } catch (e) {
      _updateQuality(ConnectionQuality.poor);
    }
  }

  void _updateQuality(ConnectionQuality quality) {
    if (_currentQuality != quality) {
      _currentQuality = quality;
      _qualityController.add(quality);
      print('🌐 Connection quality changed to: $quality');
    }
  }

  void dispose() {
    _qualityCheckTimer?.cancel();
    _qualityController.close();
  }
}
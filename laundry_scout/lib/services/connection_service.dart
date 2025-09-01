import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

enum ConnectionQuality { excellent, good, fair, poor, offline }

class ConnectionService {
  static final ConnectionService _instance = ConnectionService._internal();
  factory ConnectionService() => _instance;
  ConnectionService._internal();

  ConnectionQuality _currentQuality = ConnectionQuality.good;
  final StreamController<ConnectionQuality> _qualityController = StreamController.broadcast();
  Timer? _qualityCheckTimer;
  
  ConnectionQuality get currentQuality => _currentQuality;
  Stream<ConnectionQuality> get qualityStream => _qualityController.stream;

  void startMonitoring() {
    _qualityCheckTimer = Timer.periodic(const Duration(seconds: 10), (_) {
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

      // Measure connection speed with a small test
      final stopwatch = Stopwatch()..start();
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      stopwatch.stop();

      if (result.isNotEmpty) {
        final responseTime = stopwatch.elapsedMilliseconds;
        
        ConnectionQuality quality;
        if (responseTime < 100) {
          quality = ConnectionQuality.excellent;
        } else if (responseTime < 300) {
          quality = ConnectionQuality.good;
        } else if (responseTime < 1000) {
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
    }
  }

  void dispose() {
    _qualityCheckTimer?.cancel();
    _qualityController.close();
  }
}
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:no_screenshot/no_screenshot.dart';

/// Service to prevent screenshots and screen recording across the app.
/// Uses the `no_screenshot` package for native platform protection.
class ScreenProtectionService {
  static final ScreenProtectionService _instance = ScreenProtectionService._();
  factory ScreenProtectionService() => _instance;
  ScreenProtectionService._();

  final _noScreenshot = NoScreenshot.instance;
  StreamSubscription? _streamSubscription;
  bool _isProtectionActive = false;

  bool get isProtectionActive => _isProtectionActive;

  /// Initialize screen protection — call once at app startup.
  /// Blocks screenshots and screen recording on Android & iOS.
  Future<void> enableProtection() async {
    try {
      final result = await _noScreenshot.screenshotOff();
      _isProtectionActive = result;
      debugPrint('🛡️ Screen protection enabled: $result');
    } catch (e) {
      debugPrint('⚠️ Failed to enable screen protection: $e');
    }
  }

  /// Disable screen protection (e.g. for non-sensitive screens).
  Future<void> disableProtection() async {
    try {
      final result = await _noScreenshot.screenshotOn();
      _isProtectionActive = !result;
      debugPrint('🔓 Screen protection disabled: $result');
    } catch (e) {
      debugPrint('⚠️ Failed to disable screen protection: $e');
    }
  }

  /// Start listening for screenshot attempts and screen recording.
  Future<void> startMonitoring() async {
    try {
      // Listen for screenshot/recording events
      _streamSubscription = _noScreenshot.screenshotStream.listen((snapshot) {
        if (snapshot.wasScreenshotTaken) {
          debugPrint('📸 Screenshot detected!');
        }
        if (snapshot.isScreenRecording) {
          debugPrint('🔴 Screen recording detected!');
        }
      });

      // Start screenshot & recording detection
      await _noScreenshot.startScreenshotListening();
      await _noScreenshot.startScreenRecordingListening();
      debugPrint('👁️ Screen monitoring started');
    } catch (e) {
      debugPrint('⚠️ Failed to start screen monitoring: $e');
    }
  }

  /// Stop all monitoring.
  Future<void> stopMonitoring() async {
    try {
      await _streamSubscription?.cancel();
      _streamSubscription = null;
      await _noScreenshot.stopScreenshotListening();
      await _noScreenshot.stopScreenRecordingListening();
      debugPrint('👁️ Screen monitoring stopped');
    } catch (e) {
      debugPrint('⚠️ Failed to stop screen monitoring: $e');
    }
  }

  /// Dispose all resources.
  Future<void> dispose() async {
    await stopMonitoring();
    await disableProtection();
  }
}

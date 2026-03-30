import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';
import 'token_service.dart';

class FcmService {
  static const String _fcmTokenKey = 'fcm_token';
  static FirebaseMessaging? _messaging;
  static bool _isInitialized = false;
  static bool _isTokenRefreshListenerActive = false;

  /// Check if Firebase is initialized
  static bool get isFirebaseInitialized {
    try {
      Firebase.app();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Initialize Firebase Messaging
  static Future<void> initialize() async {
    if (!isFirebaseInitialized) {
      print('FCM: Firebase not initialized, skipping FCM setup');
      return;
    }

    try {
      _messaging = FirebaseMessaging.instance;

      // Permission is requested in NotificationService to avoid duplication
      // await _messaging!.requestPermission(
      //   alert: true,
      //   badge: true,
      //   sound: true,
      //   provisional: false,
      // );

      _isInitialized = true;

      // Set up token refresh listener
      _setupTokenRefreshListener();

      print('FCM: Initialized successfully');
    } catch (e) {
      print('FCM: Initialization error: $e');
      _isInitialized = false;
    }
  }

  /// Set up listener for token refresh
  static void _setupTokenRefreshListener() {
    if (_isTokenRefreshListenerActive) return;

    _messaging?.onTokenRefresh.listen((newToken) async {
      print('🔄 FCM Token refreshed!');
      print('New token: $newToken');

      // Save new token locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_fcmTokenKey, newToken);

      // Update token on backend
      await _updateTokenOnBackend(newToken);
    });

    _isTokenRefreshListenerActive = true;
  }

  /// Update FCM token on the backend — disabled (no endpoint on backend)
  static Future<void> _updateTokenOnBackend(String fcmToken) async {
    // Backend does not have a separate update-fcm-token endpoint.
    // The FCM token is sent during signin — no action needed here.
    print('ℹ️ FCM token refresh noted locally (no backend update needed)');
  }

  /// Get FCM token for push notifications.
  static Future<String?> getFcmToken() async {
    if (!isFirebaseInitialized) {
      print('⚠️ FCM: Firebase not available, returning cached token if exists');
      return getCachedFcmToken();
    }

    try {
      _messaging ??= FirebaseMessaging.instance;

      // On iOS, APNS token MUST be available before we can get FCM token
      if (Platform.isIOS) {
        print('🍎 FCM: iOS — checking APNS token...');

        // Wait up to 10 seconds for APNS token
        String? apnsToken;
        for (int i = 0; i < 10; i++) {
          apnsToken = await _messaging!.getAPNSToken();
          if (apnsToken != null) break;
          print('🔄 FCM: APNS token not ready, retrying (${i + 1}/10)...');
          await Future.delayed(const Duration(seconds: 1));
        }

        if (apnsToken == null) {
          print('❌ FCM: APNS token still null after 10s — notifications won\'t work on iOS!');
          print('   Possible causes:');
          print('   1. Push Notifications capability not enabled in Xcode');
          print('   2. No valid provisioning profile with push entitlement');
          print('   3. Running on iOS Simulator (APNS not supported)');
          return getCachedFcmToken();
        }
        print('✅ FCM: APNS token ready: $apnsToken');
      }

      print('🔄 FCM: Getting FCM token from Firebase...');
      final token = await _messaging!.getToken();

      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_fcmTokenKey, token);
        print('✅ FCM: Token cached successfully');
      }

      print('🔑 ======= FCM TOKEN =======');
      print(token ?? 'NULL — token not received!');
      print('🔑 ===========================');

      return token;
    } catch (e) {
      print('❌ FCM: Error getting token: $e');
      return getCachedFcmToken();
    }
  }

  /// Get cached FCM token from local storage
  static Future<String?> getCachedFcmToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_fcmTokenKey);
    } catch (e) {
      return null;
    }
  }

  /// Refresh FCM token locally (no backend update — token is sent during signin)
  static Future<void> refreshAndUpdateToken() async {
    try {
      final newToken = await getFcmToken();
      if (newToken != null) {
        print('✅ FCM token refreshed locally: ${newToken.substring(0, 20)}...');
      }
    } catch (e) {
      print('Error refreshing FCM token: $e');
    }
  }

  /// Clear FCM token from local storage
  static Future<void> clearFcmToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_fcmTokenKey);
    } catch (e) {
      print('Error clearing FCM token: $e');
    }
  }

  /// Delete FCM token (useful for logout)
  static Future<void> deleteToken() async {
    try {
      if (_isInitialized) {
        await _messaging?.deleteToken();
      }
      await clearFcmToken();
    } catch (e) {
      print('Error deleting FCM token: $e');
    }
  }
}
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'auth_service.dart';
// import 'token_service.dart';
//
// class FcmService {
//   static const String _fcmTokenKey = 'fcm_token';
//   static FirebaseMessaging? _messaging;
//   static bool _isInitialized = false;
//   static bool _isTokenRefreshListenerActive = false;
//
//   // 🔥 ADDED: callback لتوجيه التطبيق
//   static Function(Map<String, dynamic>)? onNotificationTap;
//
//   /// Check if Firebase is initialized
//   static bool get isFirebaseInitialized {
//     try {
//       Firebase.app();
//       return true;
//     } catch (e) {
//       return false;
//     }
//   }
//
//   /// Initialize Firebase Messaging
//   static Future<void> initialize() async {
//     if (!isFirebaseInitialized) {
//       print('FCM: Firebase not initialized, skipping FCM setup');
//       return;
//     }
//
//     try {
//       _messaging = FirebaseMessaging.instance;
//
//       _isInitialized = true;
//
//       // 🔥 ADDED: طلب الإذن
//       await _requestPermission();
//
//       // 🔥 ADDED: استقبال الإشعار
//       _setupMessageListeners();
//
//       // Token refresh
//       _setupTokenRefreshListener();
//
//       print('FCM: Initialized successfully');
//     } catch (e) {
//       print('FCM: Initialization error: $e');
//       _isInitialized = false;
//     }
//   }
//
//   // 🔥 ADDED: طلب Permission
//   static Future<void> _requestPermission() async {
//     await _messaging?.requestPermission(
//       alert: true,
//       badge: true,
//       sound: true,
//     );
//   }
//
//   /// 🔥 ADDED: استقبال الإشعارات
//   static void _setupMessageListeners() {
//     // Foreground
//     FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//       print('📩 Notification received (foreground)');
//       print('Title: ${message.notification?.title}');
//       print('Body: ${message.notification?.body}');
//       print('Data: ${message.data}');
//     });
//
//     // Background (app opened from notification)
//     FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
//       print('📬 Notification clicked (background)');
//       _handleNotificationTap(message.data);
//     });
//   }
//
//   /// 🔥 ADDED: لما التطبيق يكون مقفول خالص
//   static Future<void> handleInitialMessage() async {
//     final RemoteMessage? message =
//     await FirebaseMessaging.instance.getInitialMessage();
//
//     if (message != null) {
//       print('📦 Notification opened from terminated state');
//       _handleNotificationTap(message.data);
//     }
//   }
//
//   // 🔥 ADDED: handler موحد
//   static void _handleNotificationTap(Map<String, dynamic> data) {
//     if (onNotificationTap != null) {
//       onNotificationTap!(data);
//     }
//   }
//
//   /// Set up listener for token refresh
//   static void _setupTokenRefreshListener() {
//     if (_isTokenRefreshListenerActive) return;
//
//     _messaging?.onTokenRefresh.listen((newToken) async {
//       print('🔄 FCM Token refreshed!');
//       print('New token: $newToken');
//
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.setString(_fcmTokenKey, newToken);
//
//       await _updateTokenOnBackend(newToken);
//     });
//
//     _isTokenRefreshListenerActive = true;
//   }
//
//   /// Update FCM token on the backend
//   static Future<void> _updateTokenOnBackend(String fcmToken) async {
//     try {
//       final tokenService = TokenService();
//       final authToken = await tokenService.getToken();
//
//       if (authToken != null) {
//         final authService = AuthService();
//         final response = await authService.updateFcmToken(fcmToken);
//
//         if (response.succeeded) {
//           print('✅ FCM token updated on backend');
//         } else {
//           print('❌ Failed to update FCM token: ${response.message}');
//         }
//       }
//     } catch (e) {
//       print('Error updating FCM token on backend: $e');
//     }
//   }
//
//   /// Get FCM token
//   static Future<String?> getFcmToken() async {
//     if (!isFirebaseInitialized) {
//       return getCachedFcmToken();
//     }
//
//     try {
//       _messaging ??= FirebaseMessaging.instance;
//       final token = await _messaging!.getToken();
//
//       if (token != null) {
//         final prefs = await SharedPreferences.getInstance();
//         await prefs.setString(_fcmTokenKey, token);
//       }
//
//       print('--- FCM Token ---');
//       print(token);
//       print('-----------------');
//
//       return token;
//     } catch (e) {
//       return getCachedFcmToken();
//     }
//   }
//
//   static Future<String?> getCachedFcmToken() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getString(_fcmTokenKey);
//   }
//
//   static Future<void> refreshAndUpdateToken() async {
//     final newToken = await getFcmToken();
//     if (newToken != null) {
//       await _updateTokenOnBackend(newToken);
//     }
//   }
//
//   static Future<void> clearFcmToken() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.remove(_fcmTokenKey);
//   }
//
//   static Future<void> deleteToken() async {
//     if (_isInitialized) {
//       await _messaging?.deleteToken();
//     }
//     await clearFcmToken();
//   }
// }

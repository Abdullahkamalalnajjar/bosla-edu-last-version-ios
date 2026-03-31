import Flutter
import UIKit
import FirebaseCore
import FirebaseMessaging
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {

  override var window: UIWindow? {
    get {
      if let scene = UIApplication.shared.connectedScenes
        .compactMap({ $0 as? UIWindowScene })
        .first {
        return scene.windows.first
      }
      return super.window
    }
    set {
      super.window = newValue
    }
  }

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // 1️⃣ Configure Firebase FIRST
    FirebaseApp.configure()
    print("✅ [AppDelegate] FirebaseApp.configure() done")

    // 2️⃣ Set FCM delegate
    Messaging.messaging().delegate = self

    // 3️⃣ Set notification delegate
    UNUserNotificationCenter.current().delegate = self

    // 4️⃣ Request notification permission
    UNUserNotificationCenter.current().requestAuthorization(
      options: [.alert, .badge, .sound]
    ) { granted, error in
      print("🔔 [AppDelegate] Notification permission granted: \(granted)")
      if let error = error {
        print("❌ [AppDelegate] Permission error: \(error)")
      }
    }

    // 5️⃣ Register for remote notifications (triggers APNS registration)
    application.registerForRemoteNotifications()
    print("📡 [AppDelegate] Registered for remote notifications")

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  // ──────────────────────────────────────────
  // APNS token callbacks
  // ──────────────────────────────────────────

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    print("✅ [AppDelegate] APNS Token received!")
    print("📱 [AppDelegate] APNS Token: \(tokenString)")

    // Forward APNS token to Firebase Messaging (required when swizzling is disabled)
    Messaging.messaging().apnsToken = deviceToken
    print("✅ [AppDelegate] APNS token forwarded to FCM")

    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    print("❌ [AppDelegate] FAILED to register for remote notifications!")
    print("❌ [AppDelegate] Error: \(error.localizedDescription)")
  }

  // ──────────────────────────────────────────
  // Remote notification received (CRITICAL for FCM delivery)
  // This is called by APNs when a push notification arrives.
  // Without this, notifications won't be delivered when
  // FirebaseAppDelegateProxyEnabled is NO.
  // ──────────────────────────────────────────

  override func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    print("📩 [AppDelegate] didReceiveRemoteNotification called!")
    print("📩 [AppDelegate] userInfo: \(userInfo)")

    // Forward to Firebase Messaging (required when swizzling is disabled)
    Messaging.messaging().appDidReceiveMessage(userInfo)

    // Forward to Flutter (FlutterAppDelegate handles this for firebase_messaging plugin)
    super.application(application, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: completionHandler)
  }
}

// ──────────────────────────────────────────
// UNUserNotificationCenter Delegate
// Shows notifications in FOREGROUND with sound
// ──────────────────────────────────────────
extension AppDelegate {
  // Called when notification arrives while app is in FOREGROUND
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    let userInfo = notification.request.content.userInfo
    print("🔔 [AppDelegate] willPresent notification in foreground!")
    print("🔔 [AppDelegate] userInfo: \(userInfo)")

    // Forward to Firebase Messaging (required when swizzling is disabled)
    Messaging.messaging().appDidReceiveMessage(userInfo)

    // Show banner + sound + badge even when app is open
    completionHandler([.alert, .badge, .sound])
  }

  // Called when user taps the notification
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let userInfo = response.notification.request.content.userInfo
    print("🔔 [AppDelegate] Notification tapped!")
    print("🔔 [AppDelegate] tapped userInfo: \(userInfo)")

    // Forward to Firebase Messaging (required when swizzling is disabled)
    Messaging.messaging().appDidReceiveMessage(userInfo)

    super.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
  }
}

// ──────────────────────────────────────────
// FCM Delegate — gets FCM token after APNS
// ──────────────────────────────────────────
extension AppDelegate: MessagingDelegate {
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    print("🔥 [FCM] FCM Token received natively!")
    print("🔑 [FCM] FCM Token: \(fcmToken ?? "nil")")

    // Notify Flutter side via notification
    let dataDict: [String: String] = ["token": fcmToken ?? ""]
    NotificationCenter.default.post(
      name: Notification.Name("FCMToken"),
      object: nil,
      userInfo: dataDict
    )
  }
}

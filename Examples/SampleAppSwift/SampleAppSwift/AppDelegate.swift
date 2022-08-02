//
//  AppDelegate.swift
//  ExampleSwift
//
//  Created by Arnab Pal on 09/05/20.
//  Copyright © 2020 RudderStack. All rights reserved.
//

import UIKit
import Rudder
import RudderBraze

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var client: RSClient?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        let config: RSConfig = RSConfig(writeKey: "1wvsoF3Kx2SczQNlx1dvcqW9ODW")
            .dataPlaneURL("https://rudderstacz.dataplane.rudderstack.com")
            .loglevel(.debug)
            .trackLifecycleEvents(true)
            .recordScreenViews(true)
        
        client = RSClient.sharedInstance()
        RSClient.sharedInstance().configure(with: config)

        client?.addDestination(RudderBrazeDestination())
        
        client?.track(RSEvents.Ecommerce.orderCompleted, properties: [
            "key-1": "value-1",
            "key-2": 2,
            RSKeys.Ecommerce.revenue: 5007,
            "products": [
                [
                    RSKeys.Ecommerce.productId: "Pro-1001",
                    RSKeys.Ecommerce.quantity: 1,
                    RSKeys.Ecommerce.price: 1001.11
                ],
                [
                    RSKeys.Ecommerce.productId: "Pro-2002",
                    RSKeys.Ecommerce.quantity: 2,
                    RSKeys.Ecommerce.price: 2002.22,
                    "pro-key-1": "pro-value-1"
                ]
            ]
        ])
        
        // Register for push notifications: https://www.braze.com/docs/developer_guide/platform_integration_guides/ios/push_notifications/integration/#step-3-register-for-push-notifications
        setupPushCategories()
        return true
    }
    
    func setupPushCategories() {
        if #available(iOS 10, *) {
          let center = UNUserNotificationCenter.current()
          center.delegate = self
          var options: UNAuthorizationOptions = [.alert, .sound, .badge]
          if #available(iOS 12.0, *) {
            options = UNAuthorizationOptions(rawValue: options.rawValue | UNAuthorizationOptions.provisional.rawValue)
          }
          center.requestAuthorization(options: options) { (granted, error) in
              RSClient.sharedInstance().pushAuthorizationFromUserNotificationCenter(granted)
          }
          UIApplication.shared.registerForRemoteNotifications()
        } else {
          let types : UIUserNotificationType = [.alert, .badge, .sound]
          let setting : UIUserNotificationSettings = UIUserNotificationSettings(types:types, categories:nil)
          UIApplication.shared.registerUserNotificationSettings(setting)
          UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
    // MARK: Push Notification call
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        RSClient.sharedInstance().application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        RSClient.sharedInstance().application(application, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: completionHandler)
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        RSClient.sharedInstance().userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
    }
    

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}

extension UIApplicationDelegate {
    var client: RSClient? {
        if let appDelegate = self as? AppDelegate {
            return appDelegate.client
        }
        return nil
    }
}

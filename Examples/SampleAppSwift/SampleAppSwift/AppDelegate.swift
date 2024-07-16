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
        
        let config: RSConfig = RSConfig(writeKey: "<WRITE KEY>")
            .dataPlaneURL("<DATA PLANE URL>")
            .loglevel(.debug)
            .trackLifecycleEvents(false)
            .recordScreenViews(false)
        
        client = RSClient.sharedInstance()
        RSClient.sharedInstance().configure(with: config)

        client?.addDestination(RudderBrazeDestination())
        
//        setupPushCategories()
//        sendEvents()
        return true
    }
    
    func sendEvents() {
        let client = RSClient.sharedInstance()
        
        identify()
        func identify() {
            let option = RSOption()
            option.putExternalId("brazeExternalId", withId: "ID-1")
            client.identify("User swift iOS 1", traits: [
                RSKeys.Identify.Traits.firstName: "firstName",
                RSKeys.Identify.Traits.lastName: "lastName",
                RSKeys.Identify.Traits.email: "test@mail.com",
                RSKeys.Identify.Traits.birthday: "2016-12-14T13:32:31.601",
                RSKeys.Identify.Traits.gender: "MaLe",
                RSKeys.Identify.Traits.phone: "0123456789",
                RSKeys.Identify.Traits.address: [
                    RSKeys.Identify.Traits.Address.city: "City value",
                    RSKeys.Identify.Traits.Address.country: "India"
                ],
                "Traits key-1": "Traits value-1"
            ], option: option)
        }
        
        let emptyProducts: [String: Any] = [
            RSKeys.Ecommerce.products: [[:]]
        ]
        let products: [[String: Any]] = [
            [
                RSKeys.Ecommerce.productId: "1003",
                RSKeys.Ecommerce.quantity: 13,
                RSKeys.Ecommerce.price: 100.33,
                "Product-Key-13": "Product-Value-13"
            ]
        ]
        let twoProducts: [[String: Any]] = [
            [
                RSKeys.Ecommerce.productId: "1006",
                RSKeys.Ecommerce.quantity: 16,
                RSKeys.Ecommerce.price: 100.66,
                "Product-Key-16": "Product-Value-16"
            ],
            [
                RSKeys.Ecommerce.productId: "2006",
                RSKeys.Ecommerce.quantity: 26,
                RSKeys.Ecommerce.price: 200.66,
                "Product-Key-26": "Product-Value-26"
            ]
        ]
        let propertiesWithProductsAndWithoutCustomProperty: [String: Any] = [
            RSKeys.Ecommerce.products: [[
                RSKeys.Ecommerce.productId: "1004",
                RSKeys.Ecommerce.quantity: 14,
                RSKeys.Ecommerce.price: 100.44
            ]],
            RSKeys.Ecommerce.currency: "INR"
        ]
        let propertiesWithTwoProductsAndCustomProperty: [String: Any] = [
            RSKeys.Ecommerce.products: twoProducts,
            RSKeys.Ecommerce.revenue: 126,
            RSKeys.Ecommerce.currency: "INR",
            "Key-16": "Value-16"
        ]
        let propertiesWithProductsAndCustomProperty: [String: Any] = [
            RSKeys.Ecommerce.products: products,
            RSKeys.Ecommerce.revenue: 1233,
            RSKeys.Ecommerce.currency: "INR",
            "Key-13": "Value-13"
        ]
        let propertiesWithoutProducts: [String: Any] = [
            RSKeys.Ecommerce.productId: "1007",
            RSKeys.Ecommerce.quantity: 17,
            RSKeys.Ecommerce.price: 100.77,
            RSKeys.Ecommerce.revenue: 127,
            RSKeys.Ecommerce.currency: "INR",
            "Key-17": "Value-17"
        ]
        let customProperties: [String: Any] = [
            "Key-1": emptyProducts,
            "Key-2": 123,
            "Key-3": "INR",
            "Key-4": 10005.1,
            "Key-5": "Value-1"
        ]
        track()
        func track() {
            // Without Campaign properties
            client.track("Install Attributed")
            // With Campaign properties
            client.track("Install Attributed", properties: [
                "campaign": [
                    "source": "Source value",
                    "name": "Name value",
                    "ad_group": "ad_group value",
                    "ad_creative": "ad_creative value"
                ]
            ])
            
            // Revenue event
            client.track("Random Revenue event", properties: [
                RSKeys.Ecommerce.revenue: 123
            ])
            client.track(RSEvents.Ecommerce.orderCompleted)   // No event will be sent as property is empty
            // With only empty Products
            client.track(RSEvents.Ecommerce.orderCompleted, properties: emptyProducts)    // No event should be made
            
            // With Products
            client.track(RSEvents.Ecommerce.orderCompleted, properties: propertiesWithProductsAndCustomProperty)
            client.track(RSEvents.Ecommerce.orderCompleted, properties: propertiesWithProductsAndWithoutCustomProperty)
            client.track("Ecomm track events", properties: propertiesWithProductsAndCustomProperty)
            client.track("Ecomm track events without revenue", properties: propertiesWithProductsAndWithoutCustomProperty)  // Custom event
            
            client.track(RSEvents.Ecommerce.orderCompleted, properties: propertiesWithTwoProductsAndCustomProperty)
            client.track("With two products", properties: propertiesWithTwoProductsAndCustomProperty)
            // Without Products
            client.track(RSEvents.Ecommerce.orderCompleted, properties: propertiesWithoutProducts)
            // Custom events with properties
            client.track("Custom track event_1", properties: customProperties)
            // Custom events without properties
            client.track("Custom track event_3")
            
        }
    }
    
    func setupPushCategories() {
        // Register for push notifications: https://www.braze.com/docs/developer_guide/platform_integration_guides/ios/push_notifications/integration/#step-3-register-for-push-notifications
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
          let types: UIUserNotificationType = [.alert, .badge, .sound]
          let setting: UIUserNotificationSettings = UIUserNotificationSettings(types: types, categories: nil)
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

//
//  RSAdjustDestination.swift
//  RudderBraze
//
//  Created by Pallab Maiti on 24/03/22.
//

import Foundation
import Rudder
import Appboy_iOS_SDK

class RSBrazeDestination: RSDestinationPlugin {
    let type = PluginType.destination
    let key = "Braze"
    var client: RSClient?
    var controller = RSController()
        
    func update(serverConfig: RSServerConfig, type: UpdateType) { // swiftlint:disable:this cyclomatic_complexity
        guard type == .initial else { return }
        guard let brazeConfig: RudderBrazeConfig = serverConfig.getConfig(forPlugin: self) else {
            client?.log(message: "Failed to Initialize Braze", logLevel: .warning)
            return
        }
        if !brazeConfig.appKey.isEmpty {
            var appboyOptions = [String: String]()
            let customEndpoint = brazeConfig.dataCenter.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            switch customEndpoint {
            case "US-01":
                appboyOptions[ABKEndpointKey] = "sdk.iad-01.braze.com"
            case "US-02":
                appboyOptions[ABKEndpointKey] = "sdk.iad-02.braze.com"
            case "US-03":
                appboyOptions[ABKEndpointKey] = "sdk.iad-03.braze.com"
            case "US-04":
                appboyOptions[ABKEndpointKey] = "sdk.iad-04.braze.com"
            case "US-05":
                appboyOptions[ABKEndpointKey] = "sdk.iad-05.braze.com"
            case "US-06":
                appboyOptions[ABKEndpointKey] = "sdk.iad-06.braze.com"
            case "US-08":
                appboyOptions[ABKEndpointKey] = "sdk.iad-08.braze.com"
            case "EU-01":
                appboyOptions[ABKEndpointKey] = "sdk.fra-01.braze.com"
            case "EU-02":
                appboyOptions[ABKEndpointKey] = "sdk.fra-02.braze.com"
            default: break
            }
            Appboy.start(withApiKey: brazeConfig.appKey, in: UIApplication.shared, withLaunchOptions: nil, withAppboyOptions: appboyOptions)
            client?.log(message: "Initializing Braze SDK.", logLevel: .debug)
        }
    }
    
    func identify(message: IdentifyMessage) -> IdentifyMessage? { // swiftlint:disable:this cyclomatic_complexity function_body_length
        if let userId = message.userId, !userId.isEmpty {
            Appboy.sharedInstance()?.changeUser(userId)
        } else {
            if let externalIds = message.context?[RSKeys.Other.externalId] as? [[String: String]] {
                if let externalIdDict = externalIds.first(where: { dict in
                    return dict["type"] == "brazeExternalId"
                }), let id = externalIdDict["id"] {
                    Appboy.sharedInstance()?.changeUser(id)
                }
            }
        }
        if let traits = message.traits {
            if let lastName = traits[RSKeys.Identify.Traits.lastName] as? String {
                Appboy.sharedInstance()?.user.lastName = lastName
            }
            if let email = traits[RSKeys.Identify.Traits.email] as? String {
                Appboy.sharedInstance()?.user.email = email
            }
            if let firstName = traits[RSKeys.Identify.Traits.firstName] as? String {
                Appboy.sharedInstance()?.user.firstName = firstName
            }
            if let birthday = traits[RSKeys.Identify.Traits.birthday] as? String, let date: Date = dateFrom(isoDateString: birthday) {
                Appboy.sharedInstance()?.user.dateOfBirth = date
            }
//            if let birthday = traits[RSKeys.Identify.Traits.birthday] as? String {
//                let dateFormatter = DateFormatter()
//                dateFormatter.locale = Locale(identifier: "en_US_POSIX")
//                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
//                print(dateFormatter.date(from: birthday))
//                Appboy.sharedInstance()?.user.dateOfBirth = dateFormatter.date(from: birthday)
//            }
            if let gender = traits[RSKeys.Identify.Traits.gender] as? String {
                switch gender.lowercased() {
                case "m", "male":
                    Appboy.sharedInstance()?.user.setGender(.male)
                case "f", "female":
                    Appboy.sharedInstance()?.user.setGender(.female)
                case "other":
                    Appboy.sharedInstance()?.user.setGender(.other)
                default:
                    Appboy.sharedInstance()?.user.setGender(.unknown)
                }
            }
            if let phone = traits[RSKeys.Identify.Traits.phone] as? String {
                Appboy.sharedInstance()?.user.phone = phone
            }
            if let address = traits[RSKeys.Identify.Traits.address] as? [String: Any] {
                if let city = address[RSKeys.Identify.Traits.Address.city] as? String {
                    Appboy.sharedInstance()?.user.homeCity = city
                }
                if let country = address[RSKeys.Identify.Traits.Address.country] as? String {
                    Appboy.sharedInstance()?.user.country = country
                }
            }
            let appboyTraits = [
                RSKeys.Identify.Traits.birthday,
                RSKeys.Identify.Traits.gender,
                RSKeys.Identify.Traits.phone,
                RSKeys.Identify.Traits.address,
                RSKeys.Identify.Traits.firstName,
                RSKeys.Identify.Traits.lastName,
                RSKeys.Identify.Traits.email,
                RSKeys.Identify.Traits.anonymousId
            ]
            for (key, value) in traits {
                if appboyTraits.contains(key) {
                    continue
                }
                switch value {
                case let v as String:
                    Appboy.sharedInstance()?.user.setCustomAttributeWithKey(key, andStringValue: v)
                case let v as Int:
                    Appboy.sharedInstance()?.user.setCustomAttributeWithKey(key, andIntegerValue: v)
                case let v as Double:
                    Appboy.sharedInstance()?.user.setCustomAttributeWithKey(key, andDoubleValue: v)
                case let v as Bool:
                    Appboy.sharedInstance()?.user.setCustomAttributeWithKey(key, andBOOLValue: v)
                case let v as [Any]:
                    Appboy.sharedInstance()?.user.setCustomAttributeArrayWithKey(key, array: v)
                case let v as Date:
                    Appboy.sharedInstance()?.user.setCustomAttributeWithKey(key, andDateValue: v)
                default:
                    break
                }
            }
        }
        return message
    }
    
    func track(message: TrackMessage) -> TrackMessage? {
        if message.event == "Install Attributed" {
            if let campaign = message.properties?["campaign"] as? [String: Any] {
                let attributionData: ABKAttributionData = ABKAttributionData(
                    network: campaign["source"] as? String,
                    campaign: campaign["name"] as? String,
                    adGroup: campaign["ad_group"] as? String,
                    creative: campaign["ad_creative"] as? String
                )
                Appboy.sharedInstance()?.user.attributionData = attributionData
            }
            return message
        }
        if message.event == RSEvents.Ecommerce.orderCompleted || message.properties?[RSKeys.Ecommerce.revenue] != nil {
            if let properties = message.properties {
                if let productList = getProductList(properties: properties) {
                    for product in productList {
                        guard let productId = product.productId, let price = product.price else {
                            continue
                        }
                        /// For `logPurchase` API refer to the Braze document: https://www.braze.com/docs/developer_guide/platform_integration_guides/ios/analytics/logging_purchases/#tracking-purchases-and-revenue
                        Appboy.sharedInstance()?.logPurchase(productId, inCurrency: product.currency, atPrice: NSDecimalNumber(value: price), withQuantity: UInt(product.quantity), andProperties: product.properties)
                    }
                    return message
                }
                else if let brazeList = getPurchase(from: properties),
                            let revenue = brazeList.revenue {
                    Appboy.sharedInstance()?.logPurchase(message.event, inCurrency: brazeList.currency, atPrice: NSDecimalNumber(value: revenue), withQuantity: 1, andProperties: brazeList.properties)
                    return message
                }
            }
        }
        // Custom event
        else {
            Appboy.sharedInstance()?.logCustomEvent(message.event, withProperties: message.properties)
        }
        return message
    }
    
    func flush() {
        Appboy.sharedInstance()?.requestImmediateDataFlush()
    }
}

#if os(iOS) || targetEnvironment(macCatalyst)
extension RSBrazeDestination: RSPushNotifications {
    // Refer: https://www.braze.com/docs/developer_guide/platform_integration_guides/ios/push_notifications/integration/
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Appboy.sharedInstance()?.registerDeviceToken(deviceToken)
    }
        
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        Appboy.sharedInstance()?.register(application, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: completionHandler)
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        Appboy.sharedInstance()?.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
    }
    
    func pushAuthorizationFromUserNotificationCenter(_ granted: Bool) {
        Appboy.sharedInstance()?.pushAuthorization(fromUserNotificationCenter: granted)
    }
}
#endif

// MARK: - Support methods

extension RSBrazeDestination {
    var TRACK_RESERVED_KEYWORDS: [String] {
        // Refer: https://www.braze.com/docs/developer_guide/platform_integration_guides/ios/analytics/logging_purchases/#reserved-keys
        return [RSKeys.Ecommerce.productId, RSKeys.Ecommerce.quantity, RSKeys.Ecommerce.price, RSKeys.Ecommerce.products, RSKeys.Ecommerce.currency]
    }
    
    func dateFrom(isoDateString: String?) -> Date? {
        if let date = isoDateString, !date.isEmpty {
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
            dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            return dateFormatter.date(from: date)
        }
        return nil
    }
        
    func getProductList(properties: [String: Any]) -> [BrazePurchase]? {
        var brazePurchaseList = [BrazePurchase]()
        if let products = properties[RSKeys.Ecommerce.products] as? [[String: Any]], !products.isEmpty {
            for product in products {
                if !product.isEmpty {
                    var tempProductProperties = [String: Any]()
                    var brazePurchase = BrazePurchase()
                    for (key, value) in product {
                        switch key {
                        case RSKeys.Ecommerce.productId:
                            brazePurchase.productId = "\(value)"
                        case RSKeys.Ecommerce.quantity:
                            brazePurchase.quantity = Int("\(value)") ?? 1
                        case RSKeys.Ecommerce.price:
                            brazePurchase.price = Double("\(value)")
                        default:
                            tempProductProperties[key] = value
                        }
                    }
                    brazePurchase.properties = tempProductProperties
                    brazePurchaseList.append(brazePurchase)
                }
            }
        }
        
        // If no product array is present then return
        if brazePurchaseList.isEmpty {
            return nil
        }
        
        var tempProperties = [String: Any]()
        for (key, value) in properties {
            if TRACK_RESERVED_KEYWORDS.contains(key) {
                continue
            }
            switch key {
            case RSKeys.Ecommerce.revenue, RSKeys.Ecommerce.value, RSKeys.Ecommerce.total:
                tempProperties[RSKeys.Ecommerce.revenue] = Double("\(value)")
            default:
                tempProperties[key] = value
            }
        }
        
        // Update the properties for each product in the products array.
        for (index, _) in brazePurchaseList.enumerated() {
            brazePurchaseList[index].properties = brazePurchaseList[index].properties?
                .merging(tempProperties, uniquingKeysWith: { (_, last) in last }) ?? tempProperties
            // Currency should be an ISO 4217 currency code.
            if let currency = properties[RSKeys.Ecommerce.currency] as? String, currency.count == 3 {
                brazePurchaseList[index].currency = currency
            }
        }
        return brazePurchaseList.isEmpty ? nil : brazePurchaseList
    }
    
    func getPurchase(from properties: [String: Any]) -> BrazePurchase? {
        var brazePurchaseList = BrazePurchase()
        var tempProperties = [String: Any]()
        for (key, value) in properties {
            if !(key == RSKeys.Ecommerce.currency || key == RSKeys.Ecommerce.revenue) {
                tempProperties[key] = value
            }
        }
        if let currency = properties[RSKeys.Ecommerce.currency] as? String {
            brazePurchaseList.currency = currency
        }
        if let revenue = properties[RSKeys.Ecommerce.revenue] {
            brazePurchaseList.revenue = Double("\(revenue)")
        }
        brazePurchaseList.properties = tempProperties
        return brazePurchaseList
    }
}

struct BrazePurchase {
    var productId: String?
    var price: Double?
    var quantity: Int = 1
    var revenue: Double?
    var currency: String = "USD"
    var properties: [String: Any]?
}

struct RudderBrazeConfig: Codable {
    private let _appKey: String?
    var appKey: String {
        return _appKey ?? ""
    }
    
    private let _dataCenter: String?
    var dataCenter: String {
        return _dataCenter ?? ""
    }
    
    enum CodingKeys: String, CodingKey {
        case _appKey = "appKey"
        case _dataCenter = "dataCenter"
    }
}

@objc
public class RudderBrazeDestination: RudderDestination {
    
    public override init() {
        super.init()
        plugin = RSBrazeDestination()
    }
}

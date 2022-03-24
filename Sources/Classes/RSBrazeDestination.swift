//
//  RSAdjustDestination.swift
//  RudderBraze
//
//  Created by Pallab Maiti on 24/03/22.
//

import Foundation
import RudderStack
import Appboy_iOS_SDK

class RSBrazeDestination: RSDestinationPlugin {
    let type = PluginType.destination
    let key = "Braze"
    var client: RSClient?
    var controller = RSController()
        
    func update(serverConfig: RSServerConfig, type: UpdateType) {
        guard type == .initial else { return }
        if let destinations = serverConfig.destinations {
            if let destination = destinations.first(where: { $0.destinationDefinition?.displayName == self.key }), let config = destination.config?.dictionaryValue {
                if let appKey = config["appKey"] as? String {
                    var appboyOptions = [String: String]()
                    if let dataCenter = config["dataCenter"] as? String {
                        switch dataCenter {
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
                    }
                    Appboy.start(withApiKey: appKey, in: UIApplication.shared, withLaunchOptions: nil, withAppboyOptions: appboyOptions)
                }
            }
        }
    }
    
    func identify(message: IdentifyMessage) -> IdentifyMessage? {
        if let userId = message.userId {
            Appboy.sharedInstance()?.changeUser(userId)
        } else {
            if let externalIds = message.context?["externalId"] as? [[String: String]] {
                if let externalIdDict = externalIds.first(where: { dict in
                    return dict["type"] == "brazeExternalId"
                }), let id = externalIdDict["id"] {
                    Appboy.sharedInstance()?.changeUser(id)
                }
            }
        }
        if let traits = message.traits {
            if let lastName = traits["lastName"] as? String {
                Appboy.sharedInstance()?.user.lastName = lastName
            }
            if let email = traits["email"] as? String {
                Appboy.sharedInstance()?.user.email = email
            }
            if let firstName = traits["firstName"] as? String {
                Appboy.sharedInstance()?.user.firstName = firstName
            }
            if let birthday = traits["birthday"] as? String {
                let dateFormatter = DateFormatter()
                dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
                Appboy.sharedInstance()?.user.dateOfBirth = dateFormatter.date(from: birthday)
            }
            if let gender = traits["gender"] as? String {
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
            if let phone = traits["phone"] as? String {
                Appboy.sharedInstance()?.user.phone = phone
            }
            if let address = traits["address"] as? [String: Any] {
                if let city = address["city"] as? String {
                    Appboy.sharedInstance()?.user.homeCity = city
                }
                if let country = address["country"] as? String {
                    Appboy.sharedInstance()?.user.country = country
                }
            }
            let appboyTraits = [
                "birthday",
                "anonymousId",
                "gender",
                "phone",
                "address",
                "firstName",
                "lastName",
                "email"
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
        switch message.event {
        case "Install Attributed":
            var attributionData: ABKAttributionData?
            if let campaign = message.properties?["campaign"] as? [String: Any] {
                attributionData = ABKAttributionData(network: campaign["source"] as? String, campaign: campaign["name"] as? String, adGroup: campaign["ad_group"] as? String, creative: campaign["ad_creative"] as? String)
            }
            Appboy.sharedInstance()?.user.attributionData = attributionData
        case RSECommerceConstants.ECommOrderCompleted:
            if let properties = message.properties, let brazePurchaseList = getBrazePurchaseList(properties: properties) {
                for brazePurchase in brazePurchaseList {
                    guard let productId = brazePurchase.productId, let price = brazePurchase.price else {
                        continue
                    }
                    if let quantity = brazePurchase.quatity {
                        Appboy.sharedInstance()?.logPurchase(productId, inCurrency: brazePurchase.currency, atPrice: NSDecimalNumber(value: price), withQuantity: UInt(quantity), andProperties: brazePurchase.properties)
                    } else {
                        Appboy.sharedInstance()?.logPurchase(productId, inCurrency: brazePurchase.currency, atPrice: NSDecimalNumber(value: price), withProperties: brazePurchase.properties)
                    }
                }
            }
        default:
            Appboy.sharedInstance()?.logCustomEvent(message.event, withProperties: message.properties)
        }
        return message
    }
    
    func screen(message: ScreenMessage) -> ScreenMessage? {
        client?.log(message: "MessageType is not supported", logLevel: .warning)
        return message
    }
    
    func group(message: GroupMessage) -> GroupMessage? {
        client?.log(message: "MessageType is not supported", logLevel: .warning)
        return message
    }
    
    func alias(message: AliasMessage) -> AliasMessage? {
        client?.log(message: "MessageType is not supported", logLevel: .warning)
        return message
    }
}

// MARK: - Support methods

extension RSBrazeDestination {
    var TRACK_RESERVED_KEYWORDS: [String] {
        return ["product_id", "quantity", "price", "products"]
    }
        
    func getBrazePurchaseList(properties: [String: Any]) -> [BrazePurchase]? {
        var brazePurchaseList = [BrazePurchase]()
        
        if let products = properties["products"] as? [[String: Any]] {
            for product in products {
                handleProductData(brazePurchaseList: &brazePurchaseList, productDict: product, propertiesDict: properties)
            }
        }
                
        func handleProductData(brazePurchaseList: inout [BrazePurchase], productDict: [String: Any], propertiesDict: [String: Any]) {
            var properties = [String: Any]()
            var brazePurchase = BrazePurchase()
            for (key, value) in productDict {
                switch key {
                case "product_id":
                    brazePurchase.productId = "\(value)"
                case "quantity":
                    brazePurchase.quatity = Int("\(value)")
                case "price":
                    brazePurchase.price = Double("\(value)")
                default:
                    properties[key] = value
                }
            }
            for (key, value) in propertiesDict {
                if TRACK_RESERVED_KEYWORDS.contains(key) {
                    continue
                }
                switch key {
                case "revenue", "value", "total":
                    properties["revenue"] = Double("\(value)")
                default:
                    properties[key] = value
                }
            }
            brazePurchase.currency = properties["currency"] as? String ?? "USD"
            brazePurchase.properties = properties.isEmpty ? nil : properties
            brazePurchaseList.append(brazePurchase)
        }
        return brazePurchaseList.isEmpty ? nil : brazePurchaseList
    }
}

struct BrazePurchase {
    var productId: String?
    var price: Double?
    var quatity: Int?
    var currency: String = "USD"
    var properties: [String: Any]?
}

@objc
public class RudderBrazeDestination: RudderDestination {
    
    public override init() {
        super.init()
        plugin = RSBrazeDestination()
    }
}

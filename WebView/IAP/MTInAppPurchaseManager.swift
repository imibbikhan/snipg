//
//  MTInAppPurchaseManager.swift
//  FitnessFunctional
//
//  Created by Tayyab Ali on 13/05/2020.
//  Copyright © 2020 Fantech Labs. All rights reserved.
//

import Foundation
import SwiftyStoreKit
import StoreKit

enum IAP: String, CaseIterable {
    
    case monthlyWithTrial = "com.snipg.us.monthly.trialsubscription"
    case monthly = "com.snipg.us.monthlysubscription"
    case oneTimePayment = "com.snipg.us.consumble.one.time"

    static let IAP_BUY_APP = IAP.allCases.compactMap({$0.rawValue})
    static let SHARED_SECRETE = "366835758b35408285656fdb92d9e7f8"
}

protocol MTInAppPurchaseDelegate {
    func inAppPurchase(didVerifyPurchaseFor products: [ReceiptItem], expiryDate: Date?, type: MTInAppPurchaseManager.PurchaseType)
    func inAppPurchase(didCompletePurchaseFor product: PurchaseDetails)
    func inAppPurchase(didCompleteWithError error: String)
    func inAppPurchase(didRetriveProductsWith products: [SKProduct])
    func inAppPurchase(didRestored products: [Purchase])
    func inAppPurchase(isExpired products: [ReceiptItem])

}

extension MTInAppPurchaseDelegate {
    func inAppPurchase(didCompletePurchaseFor product: PurchaseDetails) {}
    func inAppPurchase(didRetriveProductsWith products: [SKProduct]) {}
    func inAppPurchase(didRestored products: [Purchase]) {}
}

class MTInAppPurchaseManager: NSObject {

    static let shared = MTInAppPurchaseManager()
    
    fileprivate var productIds = [String]()
    fileprivate var sharedSecret = ""
    var delegate: MTInAppPurchaseDelegate?
    
    enum PurchaseType: String {
        case consumableOrNonConsumable
        case autoRenewable
        case nonRenewable
    }
}

// MARK: - Class Methods
extension MTInAppPurchaseManager {
    
    func setProductIds(productIds: [String]) {
        self.productIds = productIds
    }
    
    func setSharedSecret(secretId: String) {
        self.sharedSecret = secretId
    }
    
    func completeAnyPendingTransections() {
        SwiftyStoreKit.completeTransactions(atomically: true) { purchases in
            for purchase in purchases {
                switch purchase.transaction.transactionState {
                case .purchased, .restored:
                    if purchase.needsFinishTransaction {
                        // Deliver content from server, then:
                        SwiftyStoreKit.finishTransaction(purchase.transaction)
                    }
                // Unlock content
                case .failed, .purchasing, .deferred:
                    break // do nothing
                @unknown default:
                    break
                }
            }
        }
    }
    
    func fetchAvailableSubscriptions() {
        SwiftyStoreKit.retrieveProductsInfo(Set(productIds)) { result in
            self.resultForProductRetrievalInfo(result)
        }
    }
    
    func verifyPurchase(with productId: [String], type: PurchaseType, validDuration: TimeInterval? = nil) {
        let appleValidator = AppleReceiptValidator(service: .production, sharedSecret: sharedSecret)

        SwiftyStoreKit.verifyReceipt(using: appleValidator) { [weak self] result in
            guard let `self` = self else {
                return
            }
            
            switch result {
            case .success(let receipt):
                // Verify the purchase of a Subscription
                
                switch type {
                case .consumableOrNonConsumable:
                    // Verify the purchase of Consumable or NonConsumable
                    let purchaseResult = SwiftyStoreKit.verifyPurchase(
                        productId: productId.first!,
                        inReceipt: receipt)
                    
                    self.resultForSubscriptionType(type, of: productId.first!, result: purchaseResult)
                case .autoRenewable:
                    
                    let purchaseResult = SwiftyStoreKit.verifySubscriptions(
                        ofType: .autoRenewable,
                        productIds: Set(productId),
                        inReceipt: receipt)
                    self.resultForSubscriptionType(type, of: Set(productId), result: purchaseResult)

//                    let verifySubscriptionResults = productId.map({ SwiftyStoreKit.verifySubscription(ofType: .autoRenewable, productId: $0, inReceipt: receipt) })
////
//                    for result in verifySubscriptionResults {
//                        switch result {
//                        case .purchased(let expiryDate, let items):
//                            self.delegate?.inAppPurchase(didVerifyPurchaseFor: items, expiryDate: expiryDate, type: type)
//                            print("\(productId) is valid until \(expiryDate)\n\(items)\n")
//                        case .expired(let expiryDate, let items):
//                            self.delegate?.inAppPurchase(isExpired: items)
//                            print("\(productId) is expired since \(expiryDate)\n\(items)\n")
//                        case .notPurchased:
//                            print("The user has never purchased \(productId)")
//                        }
//                    }

//                    for productId in productId {
//                        let purchaseResult = SwiftyStoreKit.verifySubscription(
//                            ofType: .autoRenewable, // or .nonRenewing (see below)
//                            productId: productId,
//                            inReceipt: receipt)
//
//                        self.resultForSubscriptionType(type, of: productId, result: purchaseResult)
//                    }
                case .nonRenewable:
                    guard let validDuration = validDuration else {
                        return
                    }
                    let purchaseResult = SwiftyStoreKit.verifySubscription(
                        ofType: .nonRenewing(validDuration: validDuration),
                        productId: productId.first!,
                        inReceipt: receipt)
                    self.resultForSubscriptionType(type, of: Set(productId), result: purchaseResult)
                }
                
            case .error(let error):
                self.delegate?.inAppPurchase(didCompleteWithError: "Receipt verification failed: \(error.localizedDescription)")
                print("Receipt verification failed: \(error)")
            }
        }
    }
    
    func purchaseProduct(with productId: String, type: PurchaseType, validDuration: TimeInterval? = nil) {
        
        if type == .consumableOrNonConsumable {
            SwiftyStoreKit.retrieveProductsInfo([productId]) { result in
                
                if let error = result.error {
                    self.delegate?.inAppPurchase(didCompleteWithError: error.localizedDescription)
                    return
                }
                
                if result.invalidProductIDs.count > 0 {
                    self.delegate?.inAppPurchase(didCompleteWithError: "Invalid Product Ids=> \(result.invalidProductIDs)")
                    return
                }

                if let product = result.retrievedProducts.first {
                    SwiftyStoreKit.purchaseProduct(product, quantity: 1, atomically: true) { result in
                        // handle result (same as above)
                        self.purchaseResultHandler(result)
                    }
                }
            }
            return
        }
        
        SwiftyStoreKit.purchaseProduct(productId, atomically: true) { result in
            
            switch result {
            case .success(let product):
                // Deliver content from server, then:
                if product.needsFinishTransaction {
                    SwiftyStoreKit.finishTransaction(product.transaction)
                }
                self.delegate?.inAppPurchase(didCompletePurchaseFor: product)

                self.verifyPurchase(with: [productId], type: type, validDuration: validDuration)
            case .error(let error):
                self.delegate?.inAppPurchase(didCompleteWithError: error.localizedDescription)
            }
        }
    }
    
    func restorePurchase() {
        SwiftyStoreKit.restorePurchases(atomically: true) { results in
            if results.restoreFailedPurchases.count > 0 {
                self.delegate?.inAppPurchase(didCompleteWithError: "Restore Failed: \(results.restoreFailedPurchases)")
                print("Restore Failed: \(results.restoreFailedPurchases)")
            }
            else if results.restoredPurchases.count > 0 {
                self.delegate?.inAppPurchase(didRestored: results.restoredPurchases)
                print("Restore Success: \(results.restoredPurchases)")
            }
            else {
                print("Nothing to Restore")
            }
        }
    }
}

// MARK: - Class Methods
extension MTInAppPurchaseManager {
    fileprivate func resultForProductRetrievalInfo(_ result: RetrieveResults) {
        if let error = result.error {
            self.delegate?.inAppPurchase(didCompleteWithError: error.localizedDescription)
            return
        }
        
        if result.invalidProductIDs.count > 0 {
            self.delegate?.inAppPurchase(didCompleteWithError: "Invalid Product Ids=> \(result.invalidProductIDs)")
            return
        }
        self.delegate?.inAppPurchase(didRetriveProductsWith: Array(result.retrievedProducts))
    }
    
    fileprivate func resultForSubscriptionType(_ type: PurchaseType, of productId: Set<String>, result: VerifySubscriptionResult) {
        switch result {
        case .purchased(let expiryDate, let items):
            self.delegate?.inAppPurchase(didVerifyPurchaseFor: items, expiryDate: expiryDate, type: type)
            print("\(productId) is valid until \(expiryDate)\n\(items)\n")
        case .expired(let expiryDate, let items):
            self.delegate?.inAppPurchase(isExpired: items)
            print("\(productId) is expired since \(expiryDate)\n\(items)\n")
        case .notPurchased:
            print("The user has never purchased \(productId)")
        }
    }
    
    fileprivate func resultForSubscriptionType(_ type: PurchaseType, of productId: String, result purchaseResult: VerifyPurchaseResult) {
        switch purchaseResult {
        case .purchased(let receiptItem):
            self.delegate?.inAppPurchase(didVerifyPurchaseFor: [receiptItem], expiryDate: nil, type: type)
            print("\(productId) is purchased: \(receiptItem)")
        case .notPurchased:
//            self.delegate?.inAppPurchase(didCompleteWithError: "The user has never purchased \(productId)")
            print("The user has never purchased \(productId)")
        }
    }
    
    fileprivate func purchaseResultHandler(_ result: PurchaseResult) {
        switch result {
        case .success(let product):
            // fetch content from your server, then:
            if product.needsFinishTransaction {
                SwiftyStoreKit.finishTransaction(product.transaction)
            }
            self.delegate?.inAppPurchase(didCompletePurchaseFor: product)
            self.verifyPurchase(with: [product.productId], type: .consumableOrNonConsumable)
            print("Purchase Success: \(product.productId)")
        case .error(let error):
            var customError = ""
            
            switch error.code {
            case .unknown:
                customError = "Unknown error. Please contact support"
                print(error.localizedDescription)
            case .clientInvalid:
                customError = "Not allowed to make the payment"
                print("Not allowed to make the payment")
            case .paymentCancelled: break
            case .paymentInvalid:
                customError = "Not allowed to make the payment"
                print("The purchase identifier was invalid")
            case .paymentNotAllowed:
                customError = "The device is not allowed to make the payment"
                print("The device is not allowed to make the payment")
            case .storeProductNotAvailable:
                customError = "The product is not available in the current storefront"
                print("The product is not available in the current storefront")
            case .cloudServicePermissionDenied:
                customError = "Access to cloud service information is not allowed"
                print("Access to cloud service information is not allowed")
            case .cloudServiceNetworkConnectionFailed:
                customError = "Could not connect to the network"
                print("Could not connect to the network")
            case .cloudServiceRevoked:
                customError = "User has revoked permission to use this cloud service"
                print("User has revoked permission to use this cloud service")
            default:
                customError = error.localizedDescription
                print((error as NSError).localizedDescription)
            }
            self.delegate?.inAppPurchase(didCompleteWithError: customError)
        }
    }
}

//
//  IAPManager.swift
//  IAPSample1
//
//  Created by Davide D'Andrea on 17/09/2020.
//  Copyright © 2020 IdeaSolutions. All rights reserved.
//

import Foundation
import StoreKit


public typealias ProductIdentifier = String
public typealias ProductsRequestCompletionHandler = (_ success: Bool, _ products: [SKProduct]?) -> Void

extension Notification.Name {
    static let IAPManagerPurchaseNotification = Notification.Name("IAPManagerPurchaseNotification")
    static let IAPManagerPurchasesReceivedNotification = Notification.Name("IAPManagerPurchasesReceivedNotification")
}



class Product: Codable {
    let identifier: String
    let purchasedTimes: Int
    
    var isPurchased: Bool {
        return purchasedTimes > 0
    }
    
    init(identifier: String, purchasedTimes: Int) {
        self.identifier = identifier
        self.purchasedTimes = purchasedTimes
    }
}



class IAPManager: NSObject {
    let productIdentifiers: Set<ProductIdentifier> = ["purchase1","purchase2","subscription1"]
    var purchasedProductIdentifiers: Set<ProductIdentifier> = []
    private var productsRequest: SKProductsRequest?
    private var productsRequestCompletionHandler: ProductsRequestCompletionHandler?
    
    private let defaults = UserDefaults(suiteName: "iapManager")
    
    static let shared = IAPManager()
    
    private override init() {
        
        for identifier in productIdentifiers {
            let purchased = UserDefaults.standard.bool(forKey: identifier)
            if purchased {
                purchasedProductIdentifiers.insert(identifier)
                print("Previously purchased: \(identifier)")
            } else {
                print("Not purchased: \(identifier)")
            }
        }
        
        super.init()
        
        SKPaymentQueue.default().add(self)
    }
    
    
    public func requestProducts(_ completionHandler: @escaping ProductsRequestCompletionHandler) {
        productsRequest?.cancel()
        productsRequestCompletionHandler = completionHandler
        
        productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
        productsRequest?.delegate = self
        productsRequest?.start()
    }
    
    public func buyProduct(_ product: SKProduct) {
        print("Buying \(product.productIdentifier)...")
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    public func isProductPurchased(_ productIdentifier: ProductIdentifier) -> Bool {
        return purchasedProductIdentifiers.contains(productIdentifier)
    }
    
    public class func canMakePayments() -> Bool {
        return true
    }
    
    public func restorePurchases() {
    }
    
    private func _clearRequestAndHandler() {
        productsRequest = nil
        productsRequestCompletionHandler = nil
    }
    
    private func _debugPrint(info: String) {
        print("[IAP MANAGER] " + info)
    }
}

extension IAPManager: SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        print("\nLoaded list of products!")
        let products = response.products
        
        guard products.isEmpty == false else {
            productsRequestCompletionHandler?(false, nil)
            return
        }
        
        products.forEach {
            print("")
            print("  Identifier: \($0.productIdentifier)")
            print("  Title: \($0.localizedTitle)")
            print("  Description: \($0.localizedDescription)")
            print("  Price: \($0.price)")
            
            if #available(iOS 11.2, *), let introductoryPrice = $0.introductoryPrice {
                print("  Introductory price: \(introductoryPrice)")
            } else {
                
            }
        }
        productsRequestCompletionHandler?(true, products)
        NotificationCenter.default.post(name: .IAPManagerPurchasesReceivedNotification, object: products)
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        print("Failed to load list of products.")
        print("Error: \(error.localizedDescription)")
        productsRequestCompletionHandler?(false, nil)
        _clearRequestAndHandler()
    }
    
    func requestDidFinish(_ request: SKRequest) {
        
    }
}

extension IAPManager: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                complete(transaction: transaction)
            case .failed:
                fail(transaction: transaction)
            case .restored:
                restore(transaction: transaction)
            case .purchasing:
                purchasing(transaction: transaction)
            case .deferred:
                deferred(transaction: transaction)
            @unknown default:
                break
            }
        }
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, shouldAddStorePayment payment: SKPayment, for product: SKProduct) -> Bool {
        return true
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, removedTransactions transactions: [SKPaymentTransaction]) {
        transactions.forEach {
            _debugPrint(info: "Transaction for product: \($0.payment.productIdentifier) removed from payment queue")
        }
    }
    
    private func complete(transaction: SKPaymentTransaction) {
        _deliverPurchaseNotification(for: transaction.payment.productIdentifier)
        SKPaymentQueue.default().finishTransaction(transaction)
        _debugPrint(info: "Transaction for product: \(transaction.payment.productIdentifier) completed!")
    }
    
    private func fail(transaction: SKPaymentTransaction) {
        _debugPrint(info: "Transaction for product: \(transaction.payment.productIdentifier) failed")
        if let transactionError = transaction.error as NSError?,
            transactionError.code != SKError.paymentCancelled.rawValue {
            _debugPrint(info: "Transaction Error: \(transactionError.localizedDescription)")
        }
        
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    private func restore(transaction: SKPaymentTransaction) {
        guard let productId = transaction.original?.payment.productIdentifier else {return}
        _debugPrint(info: "Restoring transaction for product: \(transaction.payment.productIdentifier)...")
        
        /// TODO: - Bisogna anche qui chiamare la `finishTransaction()` sulla paymentQueue?
        
        _deliverPurchaseNotification(for: productId)
    }
    
    private func purchasing(transaction: SKPaymentTransaction) {
        _debugPrint(info: "Purchasing product: \(transaction.payment.productIdentifier)...")
    }
    private func deferred(transaction: SKPaymentTransaction) {
        _debugPrint(info: "Transaction for product: \(transaction.payment.productIdentifier) deferred.")
    }
    
    
    private func _deliverPurchaseNotification(for identifier: String?) {
        guard let identifier = identifier else {return}
        
        purchasedProductIdentifiers.insert(identifier)
        _saveProduct(withIdentifier: identifier)
        NotificationCenter.default.post(name: .IAPManagerPurchaseNotification, object: identifier)
    }
    
    private func _saveProduct(withIdentifier key: String) {
        var newProduct: Product?
        
        if let product = try? defaults?.getObject(forKey: key, castTo: Product.self) {
            newProduct = Product(identifier: product.identifier, purchasedTimes: product.purchasedTimes+1)
        } else {
            newProduct = Product(identifier: key, purchasedTimes: 1)
        }
        try? defaults?.setObject(newProduct, forKey: key)
    }
}

enum IAPManagerError: Error {
    case transactionFailed(code: Int)
    case missingProductIdentifier
    case unknown(error: NSError?)
}

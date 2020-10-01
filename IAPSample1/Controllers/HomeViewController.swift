//
//  HomeViewController.swift
//  IAPSample1
//
//  Created by Davide D'Andrea on 30/09/2020.
//  Copyright © 2020 IdeaSolutions. All rights reserved.
//

import UIKit
import StoreKit

class HomeViewController: UIViewController {

    let buttonWidth: CGFloat = 250
    let buttonHeight: CGFloat = 100
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addWelcomeLabel()
        addPurchaseButton(title: "Consumable", backgroundColor: .systemBlue, action: #selector(buyConsumable), centerYOffset: buttonHeight + 10)
        addPurchaseButton(title: "Subscription", backgroundColor: .blue, action: #selector(buySubscription(_:)), centerYOffset: 0)
    }
    
    func addWelcomeLabel() {
        let label = UILabel()
        label.numberOfLines = 0
        label.text = "Choose what product you want to buy"
        label.font = .systemFont(ofSize: 25, weight: .semibold)
        view.addSubview(label)
        
        label.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: view.topAnchor, constant: 100),
            label.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20),
            label.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20)
        ])
    }
    
    func addPurchaseButton(title: String, backgroundColor: UIColor, action: Selector, centerYOffset: CGFloat) {
        let purchaseButton = UIButton(type: .custom)
        purchaseButton.layer.borderWidth = 4
        purchaseButton.layer.borderColor = UIColor.lightGray.cgColor
        purchaseButton.layer.cornerRadius = 16
        purchaseButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
        purchaseButton.setTitle(title, for: .normal)
        purchaseButton.setTitleColor(.white, for: .normal)
        purchaseButton.backgroundColor = backgroundColor
        purchaseButton.addTarget(self, action: action, for: .touchUpInside)
        view.addSubview(purchaseButton)

        purchaseButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            purchaseButton.widthAnchor.constraint(equalToConstant: buttonWidth),
            purchaseButton.heightAnchor.constraint(equalToConstant: buttonHeight),
            purchaseButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            purchaseButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: centerYOffset)
        ])
    }
    
    @objc func buyConsumable(_ sender: UIButton) {
        IAPManager.shared.requestProducts { (result, products) in
            if result {
                guard let consumableProduct = products?.first(where: {$0.productIdentifier.contains("purchase")}) else {
                    print("No consumable items to purchase")
                    return
                }
                IAPManager.shared.buyProduct(consumableProduct)
            }
        }
    }
    
    @objc func buySubscription(_ sender: UIButton) {
        IAPManager.shared.requestProducts { (result, products) in
            if result {
                guard let subscriptionProduct = products?.first(where: {$0.productIdentifier.contains("subscription")}) else {
                    print("No subscription item to purchase")
                    return
                }
                IAPManager.shared.buyProduct(subscriptionProduct)
            }
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

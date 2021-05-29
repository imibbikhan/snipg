//
//  Toast.swift
//  MohaveTV
//
//  Created by Ibbi Khan on 4/18/19.
//  Copyright © 2019 Ibbi Khan. All rights reserved.
//

import Foundation
import Foundation
import Foundation
import UIKit
class Toast {
    static func showToast(viewController: UIViewController, message: String, seconds: Double) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.view.backgroundColor = UIColor.black
        alert.view.alpha = 0.6
        alert.view.layer.cornerRadius = 15
        
        viewController.present(alert, animated: true)
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+seconds) {
            alert.dismiss(animated: true, completion: nil)
        }
    }
    
}
extension URL {
    func valueOf(_ param: String) -> String? {
        guard let url = URLComponents(string: self.absoluteString) else { return nil }
        return url.queryItems?.first(where: { $0.name == param })?.value
    }
}

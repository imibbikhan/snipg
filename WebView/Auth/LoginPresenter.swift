//
//  LoginPresenter.swift
//  WebView
//
//  Created by Ibbi Khan on 19/04/2021.
//  Copyright © 2021 Ibbi Khan. All rights reserved.
//

import Foundation
import Firebase
class LoginPresenter {
    var delegate: LoginDelegates?

    func loginWithCredentails(credential: AuthCredential, network: String) {
        Auth.auth().signIn(with: credential) { (result, error) in
            if let error = error {
                self.delegate?.error(message: error.localizedDescription)
                return
            }
            result?.user.getIDToken(completion: { (token, error) in
                let name = result?.user.displayName ?? ""
                let email = result?.user.email ?? ""
                let photoURL = result?.user.photoURL?.absoluteString ?? ""
                
                self.delegate?.success(name: name, email: email, token: token ?? "", imageLink: photoURL, network: network)
            })
            
        }
    }
}

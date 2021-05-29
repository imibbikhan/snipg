//
//  AuthDelegates.swift
//  WebView
//
//  Created by Ibbi Khan on 19/04/2021.
//  Copyright © 2021 Ibbi Khan. All rights reserved.
//

import Foundation
protocol LoginDelegates {
    func success(name: String, email: String, token: String, imageLink: String, network: String)
    func error(message: String)
}

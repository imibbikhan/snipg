//
//  AppDelegate.swift
//  Elbs
//
//  Created by Ibbi Khan on 9/1/19.
//  Copyright © 2019 Ibbi Khan. All rights reserved.
//

import UIKit
import OneSignal
import Firebase
import FBSDKCoreKit

extension String {
    
    func slice(from: String, to: String) -> String? {
        return (range(of: from)?.upperBound).flatMap { substringFrom in
            (range(of: to, range: substringFrom..<endIndex)?.lowerBound).map { substringTo in
                String(self[substringFrom..<substringTo])
            }
        }
    }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var presenter: LoginPresenter!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        presenter = LoginPresenter()
        presenter.delegate = self
        
        FirebaseApp.configure()
        
        let onesignalInitSettings = [kOSSettingsKeyAutoPrompt: false]
        
        // Replace 'YOUR_APP_ID' with your OneSignal App ID.
        OneSignal.initWithLaunchOptions(launchOptions,
                                        appId: "165735bf-2bf1-4b32-b2c8-c6ff7793e4fa",
                                        handleNotificationAction: nil,
                                        settings: onesignalInitSettings)
        
        OneSignal.inFocusDisplayType = OSNotificationDisplayType.notification;
        
        // Recommend moving the below line to prompt for push after informing the user about
        //   how your app will use them.
        OneSignal.promptForPushNotifications(userResponse: { accepted in
            print("User accepted notifications: \(accepted)")
        })
        
        if let url = launchOptions?[.url] as? URL {
            return self.utilizeURL(urlString: url.absoluteString)
           }
        
        return ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    //fb1640075016195504
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        
        if url.absoluteString.contains("fb164113935537990") {
            ApplicationDelegate.shared.application(
                app,
                open: url,
                sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
                annotation: options[UIApplication.OpenURLOptionsKey.annotation]
            )
            return true
        }
            
        let urlString = url.absoluteString
        return self.utilizeURL(urlString: urlString)
    }
    func utilizeURL(urlString: String)->Bool {
        if let range = urlString.range(of: "=") {
            let id = urlString[range.upperBound...]
            guard let finalURL = URL(string: "https://snipg.com/@\(id)?os=ios") else { return true }
            self.goToSplashNow(url: finalURL)
        }
        return true
    }
    func goToSplashNow(url: URL) {
        guard let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Home") as? WebViewController else {return}
        vc.urlToLoad = url
        self.window?.rootViewController = vc
    }
}
extension AppDelegate: LoginDelegates {
    func success(name: String, email: String, token: String, imageLink: String, network: String) {
        let urlString = "https://snipg.com/mobile-app.php?os=ios&device=iphone&session=1#login?social-login=1&token=\(token)&name=\(name)&email=\(email)&image=\(imageLink)&network=\(network)".replacingOccurrences(of: " ", with: "%20")
        let url = URL(string: urlString)
        self.goToSplashNow(url: url!)
    }
    
    func error(message: String) {
        
    }
    
    
}

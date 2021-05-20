//
//  ViewController.swift
//  MohaveTV
//
//  Created by Ibbi Khan on 4/18/19.
//  Copyright © 2019 Ibbi Khan. All rights reserved.
//

import Foundation
import UIKit
import WebKit
import AVFoundation
import OneSignal
import GoogleSignIn
import Firebase
import FBSDKCoreKit
import FBSDKLoginKit
import CryptoKit
import AuthenticationServices

class WebViewController: UIViewController {
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    var newBackButton: UIBarButtonItem!
    @IBOutlet weak var restartApp: UILabel!

    var urlToLoad: URL!
    
    var presenter: LoginPresenter!
    let loginButton = FBLoginButton()
    let manager = LoginManager()
    // Unhashed nonce.
    fileprivate var currentNonce: String? // for apple login
    
    var loadOnce = false
    override func viewDidLoad() {
        super.viewDidLoad()
        presenter = LoginPresenter()
        presenter.delegate = self
        
        loginButton.delegate = self
        loginButton.permissions = ["public_profile", "email"]
        
        restartApp.isHidden = true
        
        
        
        
        
        checkInternet()
        indicator.color = UIColor.black
        let request = URLRequest(url: urlToLoad!);
        webView.load(request);

        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshWebView(_:)), for: UIControl.Event.valueChanged)
        webView.scrollView.addSubview(refreshControl)
        webView.scrollView.bounces = true
        
//        let panRecognizer = UIPanGestureRecognizer(target: self, action:  #selector(panedView))
//        self.webView.addGestureRecognizer(panRecognizer)
        
        webView.navigationDelegate = self
        webView.configuration.dataDetectorTypes = [.all]
        
        refreshControl.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            refreshControl.centerXAnchor.constraint(equalTo: webView.centerXAnchor),
            refreshControl.topAnchor.constraint(equalTo: webView.topAnchor, constant: 60),
            refreshControl.widthAnchor.constraint(equalToConstant: 30),
            refreshControl.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    @objc func refreshWebView(_ sender: UIRefreshControl) {
        webView?.reload()
        sender.endRefreshing()
    }
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        indicator.startAnimating()
        checkInternet()
        if keyPath == "estimatedProgress" {
            if webView.estimatedProgress == 1.0 {
                self.loadOnce = true
                indicator.stopAnimating()
            }
        }
    }
    func checkInternet() {
        if !Reachability.isConnectedToNetwork() {
            Toast.showToast(viewController: self, message: "Internet connection error", seconds: 2)
            indicator.stopAnimating()
            if !loadOnce {
                self.restartApp.isHidden = false
            }
        }
    }
    @objc func backNow() {
        print("swiped")
        if webView.canGoBack {
            webView.goBack()
        }
    }
    @objc func panedView(sender: UIPanGestureRecognizer) {
        let halfDistance = self.view.bounds.width / 2
        var startLocation = CGPoint()
        if (sender.state == UIGestureRecognizer.State.began) {
            startLocation = sender.location(in: self.view)
        }
        else if (sender.state == UIGestureRecognizer.State.ended) {
            let stopLocation = sender.location(in: self.view)
            let dx = stopLocation.x - startLocation.x;
            let dy = stopLocation.y - startLocation.y;
            let distance = sqrt(dx*dx + dy*dy );
            NSLog("Distance: %f", distance);
            if sender.isLeftToRight(theViewYouArePassing: webView) {
                if distance > halfDistance {
                    self.backNow()
                }
            }
        }
    }
}
// MARK: - LoginDelegates
extension WebViewController: LoginDelegates {
    func success(name: String, email: String, token: String, imageLink: String, network: String) {
        let urlString = "https://snipg.com/mobile-app.php?session=1#login?os=ios&device=iphone&social-login=1&token=\(token)&name=\(name)&email=\(email)&image=\(imageLink)&network=\(network)".replacingOccurrences(of: " ", with: "%20")
        let url = URL(string: urlString)
        let request = URLRequest(url: url!)
        webView.load(request)
    }
    
    func error(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "Ok", style: .cancel, handler: nil)
        alert.addAction(ok)
        self.present(alert, animated: true)
    }
    
}
extension WebViewController: WKNavigationDelegate {
    func loginWithFacebook() {
        loginButton.sendActions(for: .touchUpInside)
    }
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url, url.absoluteString.contains("login=apple") {
            if #available(iOS 13.0, *) {
                self.startSignInWithAppleFlow()
            } else {
                // Fallback on earlier versions
            }
            decisionHandler(.cancel)
            return
        }
        if let url = navigationAction.request.url, url.absoluteString.contains("login=facebook") {
            self.loginWithFacebook()
            decisionHandler(.cancel)
            return
        }
        if let url = navigationAction.request.url, url.absoluteString.contains("login=google") {
            self.loginWithGoogle()
            decisionHandler(.cancel)
            return
        }
        if let url = navigationAction.request.url, url.absoluteString.contains("external=1") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            decisionHandler(.cancel)
            return
        }
        
        if let url = navigationAction.request.url, url.absoluteString.contains("amount=") {
            let urlStr = url.absoluteString
            
            if urlStr.contains("4.99") {
                self.makePaymentNow(index: 0)
            }
            if urlStr.contains("12.99") {
                self.makePaymentNow(index: 1)
            }
            if urlStr.contains("25") {
                self.makePaymentNow(index: 2)
            }
            
            decisionHandler(.cancel)
            return
        }
        
        
        
        if let url = navigationAction.request.url,
            !url.absoluteString.hasPrefix("http://"),
            !url.absoluteString.hasPrefix("https://"),
            UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            decisionHandler(.cancel)
            
        } else {
            decisionHandler(.allow)
        }
    }
    func webView(webView: WKWebView!, createWebViewWithConfiguration configuration: WKWebViewConfiguration!, forNavigationAction navigationAction: WKNavigationAction!, windowFeatures: WKWindowFeatures!) -> WKWebView! {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }
    
}
// Mark:- Payement method
extension WebViewController {
    func makePaymentNow(index: Int) {
        if IAPManager.shared.canMakePayments() {
            IAPManager.shared.getProducts { (result) in
                switch result {
                case .success(let products):
                    print(products)
                    IAPManager.shared.buy(product: products[index]) { (result) in
                        switch result {
                        case .success(_):
                            print("pass")
                            // use pop up in dispatch. crashed once
//                            self.error(message: "Purchase Successful for \(products[index].localizedTitle)")
                        case .failure(let error):
//                            self.error(message: "Purchase failed for \(products[index].localizedTitle): \(error.localizedDescription)")
                            print("failed 1")
                        }
                    }
                case .failure(let error):
//                    self.error(message: "Purchase failed for: \(error.localizedDescription)")
                    print("failed 2 \(error.localizedDescription)")
                }
            }
            
        }else{
//            self.error(message: "You cannot make payment right now")
            print("failed 3")
        }
    }
}
// MARK: - Google Sign in
extension WebViewController: GIDSignInDelegate {
    func loginWithGoogle() {
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
        GIDSignIn.sharedInstance()?.presentingViewController = self
        GIDSignIn.sharedInstance()?.delegate = self
        GIDSignIn.sharedInstance()?.signIn()
    }
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error?) {
            if let error = error {
                self.error(message: error.localizedDescription)
                return
            }
            
            guard let authentication = user.authentication else { return }
            let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken,
                                                           accessToken: authentication.accessToken)
            
        self.presenter.loginWithCredentails(credential: credential, network: "google")
            
        }
        
        func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
            self.error(message: error.localizedDescription)
        }
}

// MARK: - Login with Facebook
extension WebViewController: LoginButtonDelegate {
    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        
    }
    // when user login complete or cancel
    func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
        
        if let error = error {
            self.error(message: error.localizedDescription)
            return
        }
        if result!.isCancelled {
            return
        }
        
        
    
        let credential = FacebookAuthProvider.credential(withAccessToken: AccessToken.current!.tokenString)
        self.presenter.loginWithCredentails(credential: credential, network: "facebook")
    }
}
// MARK: - Login with Apple
@available(iOS 13.0, *)
extension WebViewController: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: Array<Character> =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    func startSignInWithAppleFlow() {
        let nonce = randomNonceString()
        currentNonce = nonce
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            return String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = currentNonce else {
                fatalError("Invalid state: A login callback was received, but no login request was sent.")
            }
            guard let appleIDToken = appleIDCredential.identityToken else {
                print("Unable to fetch identity token")
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                return
            }
            // Initialize a Firebase credential.
            
            let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: idTokenString, rawNonce: nonce)
            self.presenter.loginWithCredentails(credential: credential, network: "apple")
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        self.error(message: error.localizedDescription)
    }
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
}

extension UIPanGestureRecognizer {
    func isLeftToRight(theViewYouArePassing: UIView) -> Bool {
        let detectionLimit: CGFloat = 50
        let velocityy : CGPoint = velocity(in: theViewYouArePassing)
        if velocityy.x > detectionLimit {
            return true
        } else if velocityy.x < -detectionLimit {
            return false
        }else{
            return false
        }
    }
}


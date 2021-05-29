//
//  SplashViewController.swift
//  WebView
//
//  Created by Ibbi Khan on 02/06/2020.
//  Copyright © 2020 Ibbi Khan. All rights reserved.
//

import UIKit
import AVFoundation
import OneSignal

class SplashViewController: UIViewController {
    @IBOutlet weak var playerView: PlayerView!
    
    var urlToLoad: URL!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.playVideo()
    }

    @objc func playerDidFinishPlaying(note: NSNotification) {
        let status: OSPermissionSubscriptionState = OneSignal.getPermissionSubscriptionState()
        let id = status.subscriptionStatus.userId
        
        if urlToLoad == nil {
            urlToLoad = URL(string: "https://snipg.com/mobile-app.php?device-id=\(id ?? "")&os=ios&device=iphone")
        }
        
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Home") as? WebViewController
        vc?.urlToLoad = urlToLoad
        self.view.window?.rootViewController = vc
    }
    func playVideo() {
        if let filePath = Bundle.main.path(forResource: "Splash", ofType: "mp4") {
            let fileURL = URL(fileURLWithPath: filePath)
            let player = AVPlayer(url: fileURL)
            
            playerView.player = player
            playerView.playerLayer.videoGravity = .resizeAspectFill
            playerView.player?.play()
            
            
            NotificationCenter.default.addObserver(self, selector: #selector(self.playerDidFinishPlaying(note:)),
                                                   name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: self.playerView.player!.currentItem)
            
        }else{
            print("no vid found.")
        }
    }
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    
}

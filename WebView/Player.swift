//
//  Player.swift
//  WebView
//
//  Created by Ibbi Khan on 02/06/2020.
//  Copyright © 2020 Ibbi Khan. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
class PlayerView: UIView {
    override static var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }
    var player: AVPlayer? {
        get {
            return playerLayer.player
        }
        set {
            playerLayer.player = newValue
        }
    }
}

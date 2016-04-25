//
//  MetalView.swift
//  AdvancedGraphicsProject
//
//  Created by Mountain on 4/20/16.
//  Copyright © 2016 Ryan Milvenan. All rights reserved.
//

import Foundation
import UIKit
import MetalKit

class MetalView: MTKView {
    
    var currentTouch:UITouch? = nil
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if let touch = touches.first {
            currentTouch = touch
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        currentTouch = nil
    }
    
    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        currentTouch = nil
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if let touch = touches.first {
            currentTouch = touch
        }
    }
    
//    override var frame: CGRect {
//        didSet(frame) {
//            super.frame = frame
//            var scale:CGFloat = UIScreen.mainScreen().scale
//            
//            if let window = self.window {
//                scale = window.screen.scale
//            }
//            
//            var drawableSize:CGSize = self.bounds.size
//            drawableSize.width *= scale
//            drawableSize.height *= scale
//            
//            self.metalLayer().drawableSize = drawableSize
//        }
//    }
}
//
//  MetalViewController.swift
//  AdvancedGraphicsProject
//
//  Created by Mountain on 4/20/16.
//  Copyright © 2016 Ryan Milvenan. All rights reserved.
//

import UIKit

let rotationSpeed:Float = 3

class MetalViewController: UIViewController {
    
    var renderer:Renderer! = nil
    var displayLink:CADisplayLink! = nil
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.renderer = Renderer(layer: self.metalView().metalLayer())
        self.displayLink = CADisplayLink(target: self, selector: #selector(MetalViewController.displayLinkDidFire))
        self.displayLink.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSRunLoopCommonModes)
    }
    
    func metalView() -> MetalView {
        return self.view as! MetalView
    }
    
    func updateMotion() {
        self.renderer.updateFrameDuration(Float(self.displayLink.duration))
        
        if let touch = self.metalView().currentTouch {
            let bounds:CGRect = self.view.bounds
            let rotationScale = (CGRectGetMidX(bounds) - touch.locationInView(self.view).x) / bounds.size.width
            
            self.renderer.updateVelocity(2)
            self.renderer.updateAngularVelocity(Float(rotationScale) * rotationSpeed)
        } else {
            self.renderer.updateVelocity(0)
            self.renderer.updateAngularVelocity(0)
        }
        
    }
    
    func displayLinkDidFire() {
        self.updateMotion()
        self.renderer.draw()
    }
}
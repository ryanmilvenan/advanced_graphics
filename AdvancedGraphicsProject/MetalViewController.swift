//
//  MetalViewController.swift
//  AdvancedGraphicsProject
//
//  Created by Mountain on 4/10/16.
//  Copyright © 2016 Ryan Milvenan. All rights reserved.
//

import UIKit
import MetalKit

let rotationSpeed:Float = 3

class MetalViewController: UIViewController, MTKViewDelegate {
    
    var renderer:Renderer! = nil
    var frameDuration:CFTimeInterval! = 0
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.renderer = Renderer(view: self.view as! MTKView, delegate:self)
    }
    
    func updateMotion() {
//        self.renderer.updateFrameDuration(Float((self.view as? MTKView).))
        
        if let touch = (self.view as! MetalView).currentTouch {
            let bounds:CGRect = self.view.bounds
            let rotationScale = (CGRectGetMidX(bounds) - touch.locationInView(self.view).x) / bounds.size.width
            
            self.renderer.updateVelocity(2)
            self.renderer.updateAngularVelocity(Float(rotationScale) * rotationSpeed)
        } else {
            self.renderer.updateVelocity(0)
            self.renderer.updateAngularVelocity(0)
        }
        
    }
    
    func drawInMTKView(view: MTKView) {
        self.renderer.draw()
        self.updateMotion()
    }
    
    func mtkView(view: MTKView, drawableSizeWillChange size: CGSize) {
        self.renderer.reshape()
    }
    
    func view(view: MTKView, willLayoutWithSize size: CGSize) {
        self.renderer.reshape()
    }
}
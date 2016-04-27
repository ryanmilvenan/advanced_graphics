//
//  MetalViewController.swift
//  AdvancedGraphicsProject
//
//  Created by Mountain on 4/10/16.
//  Copyright © 2016 Ryan Milvenan. All rights reserved.
//

import UIKit
import CoreMotion
import MetalKit

let rotationSpeed:Float = 3

class MetalViewController: UIViewController, MTKViewDelegate {
    
    var renderer:Renderer! = nil
    var frameDuration:CFTimeInterval! = 0
    lazy var motionManager = CMMotionManager()
    var accelX:Double = 0.0
    var accelY:Double = 0.0
    var accelZ:Double = 0.0
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        if motionManager.accelerometerAvailable{
            let queue = NSOperationQueue()
            motionManager.startAccelerometerUpdatesToQueue(queue, withHandler:
                {data, error in
                    
                    guard let data = data else{
                        return
                    }
                    self.accelX = data.acceleration.x
                    self.accelY = data.acceleration.y
                    self.accelZ = data.acceleration.z
                }
            )
        } else {
            print("Accelerometer is not available")
        }
        
        self.renderer = Renderer(view: self.view as! MTKView, delegate:self)
    }
    
    func updateMotion() {
//        self.renderer.updateFrameDuration(Float((self.view as? MTKView).))
        
        if let touch = (self.view as! MetalView).lastTouch {
            let bounds:CGRect = self.view.bounds
            let rotationScale = (CGRectGetMidX(bounds) - touch.locationInView(self.view).x) / bounds.size.width
            
            self.renderer.updateVelocity(2)
            self.renderer.updateAngularVelocity(Float(rotationScale) * rotationSpeed)
        } else {
            self.renderer.updateVelocity(0)
            self.renderer.updateAngularVelocity(0)
        }
        
        if self.view.bounds.width > self.view.bounds.height {
            if(accelX > -0.75) {
                let p = percent((1 - Float(abs(accelX))), end: 1)
                let val = lerp(p, start: 0, end: 2)
                self.renderer.updateVelocity(val)
            }
            
            if(accelY > 0.2) {
                let p = percent((1 - Float(abs(accelY))), end: 1)
                let val = lerp(p, start:0, end: 0.4)
                self.renderer.updateAngularVelocity(val * rotationSpeed)
            }
            
            if(accelY < -0.2) {
                let p = percent((1 - Float(abs(accelY))), end: 1)
                let val = lerp(p, start:0, end: -0.4)
                self.renderer.updateAngularVelocity(val * rotationSpeed)
            }
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
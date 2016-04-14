//
//  Vertex.swift
//  AdvancedGraphicsProject
//
//  Created by Mountain on 4/13/16.
//  Copyright © 2016 Ryan Milvenan. All rights reserved.
//

struct Vertex {
    var x,y,z: Float     // position data
    var r,g,b,a: Float   // color data
    
    func floatBuffer() -> [Float] {
        return [x,y,z,r,g,b,a]
    }
}
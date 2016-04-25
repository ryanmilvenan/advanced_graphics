//
//  Mesh.swift
//  AdvancedGraphicsProject
//
//  Created by Mountain on 4/20/16.
//  Copyright © 2016 Ryan Milvenan. All rights reserved.
//

import Metal
class Mesh {
    var vertexBuffer:MTLBuffer! = nil
    var indexBuffer:MTLBuffer! = nil
    var name:String = ""
    
    func checkBuffers(vertexCount:Int, indexCount:Int) {
        if let vB = self.vertexBuffer {
            for index in 0 ..< vertexCount {
                let vertex = UnsafeMutablePointer<Vertex>(vB.contents()).advancedBy(index).memory
                print("\(name) Vertex: \(index): \(vertex)")
                
            }
        }
        
        if let iB = self.indexBuffer {
            for index in 0 ..< indexCount {
                let index = UnsafeMutablePointer<Index>(iB.contents()).advancedBy(index).memory
                print("\(name) Index: \(index)")
                
            }
        }
    }
}
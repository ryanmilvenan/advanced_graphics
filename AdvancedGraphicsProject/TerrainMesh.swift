//
//  TerrainMesh.swift
//  AdvancedGraphicsProject
//
//  Created by Mountain on 4/20/16.
//  Copyright © 2016 Ryan Milvenan. All rights reserved.
//

import Foundation
import Metal
import simd

let colorWhite:vector_float4 = vector_float4(1, 1, 1, 1)
let texScale:Float = 50

class TerrainMesh:Mesh {
    var device:MTLDevice
    var smoothness:Float
    var iterations:UInt16
    var stride:size_t
    var vertexCount:size_t
    var indexCount:size_t
    internal private(set) var width:Float
    internal private(set) var depth:Float
    internal private(set) var height:Float
    
    init(width:Float, height:Float, iterations:UInt16, smoothness:Float, device:MTLDevice) {
        self.width = width
        self.height = height
        self.depth = 0
        self.iterations = iterations
        self.smoothness = smoothness
        self.device = device
        self.vertexCount = 0
        self.indexCount = 0
        self.stride = 0
        super.init()
        
        self.generateTerrain()
    }
    
    func generateTerrain() {
        let shiftBits:UInt16 = 1
        self.stride = Int((shiftBits << self.iterations) + 1)
        self.vertexCount = self.stride * self.stride
        self.indexCount = (self.stride - 1) * (self.stride - 1) * 6
        
        let variance:Float = 1.0
        let smoothingFactor:Float = powf(2, -self.smoothness)
        
        self.vertexBuffer = device.newBufferWithLength((sizeof(Vertex) * vertexCount), options: MTLResourceOptions.CPUCacheModeDefaultCache)
        self.indexBuffer = device.newBufferWithLength((sizeof(Index) * indexCount), options: MTLResourceOptions.CPUCacheModeDefaultCache)
        
        if let vB = vertexBuffer {
            let corners = [0, (self.stride), ((self.stride-1) * self.stride), ((self.stride * self.stride) - 1)]
            for offset in corners {
                var vertex = UnsafeMutablePointer<Vertex>(vB.contents() + offset).memory
                vertex.position.y = 0.0
            }
        }
    }
}

//
//  PlaneMesh.swift
//  AdvancedGraphicsProject
//
//  Created by Mountain on 4/20/16.
//  Copyright © 2016 Ryan Milvenan. All rights reserved.
//

import Metal
import simd

class PlaneMesh: Mesh {
    init(width:Float, depth:Float, divX:Int, divZ:Int, texScale:Float, opacity:Float, device:MTLDevice) {
        super.init()
        self.name = "Plane Mesh"
        self.generateBuffers(width, depth: depth, divX: divX, divZ: divZ, texScale: texScale, opacity: opacity, device: device)
    }
    
    func generateBuffers(width:Float, depth:Float, divX:Int, divZ:Int, texScale:Float, opacity:Float, device:MTLDevice) {
        let vertexCount:size_t = (divX + 1) * (divZ + 1)
        let indexCount:size_t = divX * divZ * 6
        
        self.vertexBuffer = device.newBufferWithLength((sizeof(Vertex) * vertexCount), options: MTLResourceOptions.CPUCacheModeDefaultCache)
        self.indexBuffer = device.newBufferWithLength((sizeof(Index) * indexCount), options: MTLResourceOptions.CPUCacheModeDefaultCache)

        if let vB = self.vertexBuffer {
            
            let dx:Float = width / (Float(divX) + 1)
            let dz:Float = depth / (Float(divZ) + 1)
            
            let y:Float = 0
            var z:Float = depth * -0.5
            
            var current:Int = 0
            for _ in 0 ..< (divZ) {
                
                var x:Float = width * -0.5
                for _ in 0 ..< (divX)  {
                    let vertexPointer = UnsafeMutablePointer<Vertex>(vB.contents()).advancedBy(current)
                    var vertexData = vertexPointer.memory
                    vertexData.position = vector_float4(x, y, z, 1)
                    vertexData.normal = vector_float4(0, 1, 0, 0)
                    
                    let s:Float = ((x / width) + 0.5) * texScale
                    let t:Float = ((z / depth) + 0.5) * texScale
                    vertexData.texCoords = vector_float2(s, t)
                    vertexData.diffuseColor = vector_float4(1, 1, 1, opacity)
                    vertexPointer.memory = vertexData
                    
                    x += dx
                    current += 1
                }
                z += dz
            }
        }
        
        if let iB = self.indexBuffer {
            var index:Int = 0
            for currentZ in 0 ..< divZ {
                for currentX in 0 ..< divX {
                    let v:Int = (currentX * divX) + currentZ
                    UnsafeMutablePointer<Index>(iB.contents()).advancedBy(index).memory = UInt16(v); index += 1
                    UnsafeMutablePointer<Index>(iB.contents()).advancedBy(index).memory = UInt16(v + divX); index += 1
                    UnsafeMutablePointer<Index>(iB.contents()).advancedBy(index).memory = UInt16(v + divX + 1); index += 1
                    UnsafeMutablePointer<Index>(iB.contents()).advancedBy(index).memory = UInt16(v + divX + 1); index += 1
                    UnsafeMutablePointer<Index>(iB.contents()).advancedBy(index).memory = UInt16(v + 1); index += 1
                    UnsafeMutablePointer<Index>(iB.contents()).advancedBy(index).memory = UInt16(v); index += 1
                }
            }
        }
    }
    
    
}
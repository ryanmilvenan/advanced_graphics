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
            for _ in 0...divZ {
                
                var x:Float = width * -0.5
                
                for _ in 0...divX  {
                    let offset:Int = sizeof(Vertex)*current
                    var vertex = UnsafeMutablePointer<Vertex>(vB.contents() + offset).memory
                    vertex.position = vector_float4(x, y, z, 1)
                    vertex.normal = vector_float4(0, 1, 0, 0)
                    
                    let s:Float = ((x / width) + 0.5) * texScale
                    let t:Float = ((z / depth) + 0.5) * texScale
                    vertex.texCoords = vector_float2(s, t)
                    
                    vertex.diffuseColor = vector_float4(1, 1, 1, opacity)
                    
                    x += dx
                    current += 1
                }
                z += dz
            }
        }
        
        if let iB = self.indexBuffer {
            var index:Int = 1
            for currentZ in 0 ..< divZ {
                for currentX in 0 ..< divX {
                    let v:Int = (currentX * divX) + currentZ
                    var indexMemory = setIndexValue(iB, index: index); index += 1
                    indexMemory.memory = UInt16(v)
                    indexMemory = setIndexValue(iB, index: index); index += 1
                    indexMemory.memory = UInt16(v + divX)
                    indexMemory = setIndexValue(iB, index: index); index += 1
                    indexMemory.memory = UInt16(v + divX + 1)
                    indexMemory = setIndexValue(iB, index: index); index += 1
                    indexMemory.memory = UInt16(v + divX + 1)
                    indexMemory = setIndexValue(iB, index: index); index += 1
                    indexMemory.memory = UInt16(v + 1)
                    indexMemory = setIndexValue(iB, index: index); index += 1
                    indexMemory.memory = UInt16(v)
                }
            }
        }
    }
    
    func setIndexValue(buffer:MTLBuffer, index:Int) -> UnsafeMutablePointer<Index> {
        let offset:Int = sizeof(Index) * index
        return UnsafeMutablePointer<Index>(buffer.contents() + offset)
    }
}
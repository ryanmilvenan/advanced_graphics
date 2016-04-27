//
//  PlaneMesh.swift
//  AdvancedGraphicsProject
//
//  Created by Mountain on 4/10/16.
//  Copyright © 2016 Ryan Milvenan. All rights reserved.
//

import Metal
import simd

class WaterMesh: Mesh {
    
    var vertices:[Vertex]
    var indices:[Index]
    
    init(width:Float, depth:Float, divX:Int, divZ:Int, texScale:Float, opacity:Float, device:MTLDevice) {
        self.vertices = []
        self.indices = []
        super.init()
        self.name = "Water Mesh"
        self.initBuffers(width, depth: depth, divX: divX, divZ: divZ, texScale: texScale, opacity: opacity, device: device)
    }
    
    //Generate the water vertices, and determine their texture coordinates based on the provided number of repetitions of the texture
    func initBuffers(width:Float, depth:Float, divX:Int, divZ:Int, texScale:Float, opacity:Float, device:MTLDevice) {
        let vertexCount:size_t = (divX + 1) * (divZ + 1)
        
        for _ in 0 ..< vertexCount {
            let pos = float4(0, 0, 0, 0)
            let col = float4(0, 0, 0, 0)
            let norm = float4(0, 0, 0, 0)
            let tex = float2(0, 0)
            
            let emptyVertex:Vertex = Vertex(pos: pos, norm: norm, diffColor: col, tex: tex)
            self.vertices.append(emptyVertex)
        }
        

        let dx:Float = width / (Float(divX) + 1)
        let dz:Float = depth / (Float(divZ) + 1)
        
        let y:Float = 0
        var z:Float = depth * -0.5
        
        var current:Int = 0
        for _ in 0 ..< (divZ + 1) {
            
            var x:Float = width * -0.5
            for _ in 0 ..< (divX + 1)  {
                
                self.vertices[current].position = float4(x, y, z, 1);
                
                self.vertices[current].normal = float4(0, 1, 0, 0);
                
                let s:Float = ((x / width) + 0.5) * texScale;
                let t:Float = ((z / depth) + 0.5) * texScale;
                self.vertices[current].texCoords = float2(s, t);
                
                self.vertices[current].diffuseColor = float4(1, 1, 1, opacity );
                
                x += dx;
                current += 1

            }
            z += dz
        }
        
        for currentZ in 0 ..< divZ {
            for currentX in 0 ..< divX {
                let v:Int = (currentX * divX) + currentZ
                self.indices.append(Index(v));
                self.indices.append(Index(v + divX));
                self.indices.append(Index(v + divX + 1));
                self.indices.append(Index(v + divX + 1));
                self.indices.append(Index(v + 1));
                self.indices.append(Index(v));
            }
        }
        
        self.vertexBuffer = device.newBufferWithBytes(self.vertices, length: sizeof(Vertex) * self.vertices.count, options: MTLResourceOptions.OptionCPUCacheModeDefault)
        self.vertexBuffer.label = "Water (Vertices)"
        
        self.indexBuffer = device.newBufferWithBytes(self.indices, length: sizeof(Index) * self.indices.count, options: MTLResourceOptions.OptionCPUCacheModeDefault)
        self.indexBuffer.label = "Water (Indicies)"
    }
}
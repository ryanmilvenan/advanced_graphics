//
//  TerrainMesh.swift
//  AdvancedGraphicsProject
//
//  Created by Mountain on 4/10/16.
//  Copyright © 2016 Ryan Milvenan. All rights reserved.
//

import Foundation
import Darwin
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
    var vertices:[Vertex]
    var indices:[Index]
    internal private(set) var width:Float
    internal private(set) var depth:Float
    internal private(set) var height:Float
    
    init(width:Float, height:Float, iterations:UInt16, smoothness:Float, device:MTLDevice) {
        self.width = width
        self.height = height
        self.depth = width
        self.iterations = iterations
        self.smoothness = smoothness
        self.device = device
        self.vertexCount = 0
        self.indexCount = 0
        self.stride = 0
        self.vertices = []
        self.indices = []
        super.init()
        self.name = "Terrain Mesh"

        
        self.generateTerrain()
    }
    
    func generateTerrain() {
        let shiftBits:UInt16 = 1
        self.stride = Int((shiftBits << self.iterations) + 1)
        self.vertexCount = self.stride * self.stride
        self.indexCount = (self.stride - 1) * (self.stride - 1) * 6
        
        var variance:Float = 1.0
        let smoothingFactor:Float = powf(2, -self.smoothness)
        
        for _ in 0 ..< self.vertexCount {
            let pos = float4(0, 0, 0, 0)
            let col = float4(0, 0, 0, 0)
            let norm = float4(0, 0, 0, 0)
            let tex = float2(0, 0)

            let emptyVertex:Vertex = Vertex(pos: pos, norm: norm, diffColor: col, tex: tex)
            self.vertices.append(emptyVertex)
        }
        
        let corners = [0, (self.stride), ((self.stride-1) * self.stride), ((self.stride * self.stride) - 1)]
        for corner in corners {
            self.vertices[corner].position.y = 0.0
        }
        
        for index in 0 ..< self.iterations {
            let numSquares:Int = Int(shiftBits << index)
            let squareSize:Int = Int(shiftBits << (self.iterations - index))
            
            for squareX in 0 ..< numSquares {
                for squareY in 0 ..< numSquares {
                    let r:Int = squareY * squareSize
                    let c:Int = squareX * squareSize
                    self.performSquareStepWithRow(r, column:c, squareSize:squareSize, variance:variance)
                    self.performDiamondStepWithRow(r, column:c, squareSize:squareSize, variance:variance)
                }
            }
            
            variance *= smoothingFactor
        }
        
        self.computeMeshCoords()
        self.computeMeshNormals()
        self.generateIndices()
        
        self.vertexBuffer = device.newBufferWithBytes(self.vertices, length: sizeof(Vertex) * self.vertexCount, options: MTLResourceOptions.OptionCPUCacheModeDefault)
        self.vertexBuffer.label = "Vertices (Terrain)"
        
        self.indexBuffer = device.newBufferWithBytes(self.indices, length: sizeof(Index) * self.indexCount, options: MTLResourceOptions.OptionCPUCacheModeDefault)
        self.indexBuffer.label = "Indices (Terrain)"
    }
    
    func performSquareStepWithRow(row:Int, column:Int, squareSize:Int, variance:Float) {
        let r0:size_t = row
        let c0:size_t = column
        let r1:size_t = (r0 + squareSize) % self.stride
        let c1:size_t = (c0 + squareSize) % self.stride
        let rmid:size_t = r0 + (squareSize / 2)
        let cmid:size_t = c0 + (squareSize / 2)
        
        let y00:Float = self.vertices[r0 * self.stride + c0].position.y;
        let y01:Float = self.vertices[r0 * self.stride + c1].position.y;
        let y11:Float = self.vertices[r1 * self.stride + c1].position.y;
        let y10:Float = self.vertices[r1 * self.stride + c0].position.y;
        
        let yMean:Float = (y00 + y01 + y11 + y10) * 0.25
        let error = (((Float(arc4random()) / Float(UInt32.max)) - 0.5) * 2) * variance
        let y:Float = yMean + error
        
        self.vertices[rmid * self.stride + cmid].position.y = y
    }
    
    
    
    func performDiamondStepWithRow(row:Int, column:Int, squareSize:Int, variance:Float) {
        let r0:size_t = row
        let c0:size_t = column
        let r1:size_t = (r0 + squareSize) % self.stride
        let c1:size_t = (c0 + squareSize) % self.stride
        let rmid:size_t = r0 + (squareSize / 2)
        let cmid:size_t = c0 + (squareSize / 2)
        
        let y00:Float = self.vertices[r0 * self.stride + c0].position.y;
        let y01:Float = self.vertices[r0 * self.stride + c1].position.y;
        let y11:Float = self.vertices[r1 * self.stride + c1].position.y;
        let y10:Float = self.vertices[r1 * self.stride + c0].position.y;

        var error:Float = 0
        error = (((Float(arc4random()) / Float(UInt32.max)) - 0.5) * 2) * variance
        self.vertices[r0 * self.stride + cmid].position.y = (y00 + y01) * 0.5 + error;
        error = (((Float(arc4random()) / Float(UInt32.max)) - 0.5) * 2) * variance
        self.vertices[rmid * self.stride + c0].position.y = (y00 + y10) * 0.5 + error;
        error = (((Float(arc4random()) / Float(UInt32.max)) - 0.5) * 2) * variance
        self.vertices[rmid * self.stride + c1].position.y = (y01 + y11) * 0.5 + error
        error = (((Float(arc4random()) / Float(UInt32.max)) - 0.5) * 2) * variance
        self.vertices[r1 * self.stride + cmid].position.y = (y01 + y11) * 0.5 + error;


    }
    
    func computeMeshCoords() {
        for row in 0 ..< self.stride {
            for column in 0 ..< self.stride {
                let index:size_t = (row * self.stride + column)
                let x:Float = (Float(column) / Float((self.stride - 1)) - 0.5) * self.width
                let y:Float = self.vertices[row * self.stride + column].position.y * self.height;
                let z:Float = (Float(row) / Float((self.stride - 1)) - 0.5) * self.depth
                self.vertices[index].position = float4(x, y, z, 1);
                let s:Float = (Float(column) / Float((self.stride - 1))) * texScale
                let t:Float = (Float(row) / Float((self.stride - 1))) * texScale
                self.vertices[index].texCoords = float2(s, t)
                self.vertices[index].diffuseColor = colorWhite
            }
        }
    }
    
    func computeMeshNormals() {
        let yScale:Float = 4
        for row in 0 ..< self.stride {
            for column in 0 ..< self.stride {
                if row > 0 && column > 0 && row < (self.stride - 1) && column < (self.stride - 1) {
                    let leftAdj:float4 = self.vertices[row * self.stride + (column - 1)].position;
                    let rightAdj:float4 = self.vertices[row * self.stride + (column + 1)].position;
                    let upAdj:float4 = self.vertices[(row - 1) * self.stride + column].position;
                    let downAdj:float4 = self.vertices[(row + 1) * self.stride + column].position;
                    let top:float3 = float3(rightAdj.x - leftAdj.x, (rightAdj.y - leftAdj.y) * yScale, 0);
                    let bottom:float3 = float3(0, (downAdj.y - upAdj.y) * yScale, downAdj.z - upAdj.z);
                    let btCross:float3 = vector_cross(bottom, top);
                    var normal:float4 = float4(btCross.x, btCross.y, btCross.z, 0);
                    normal = vector_normalize(normal);
                    self.vertices[row * self.stride + column].normal = normal;
                } else {
                    let normal:float4 = float4(0, 1, 0, 0);
                    self.vertices[row * self.stride + column].normal = normal;
                }
            }
        }
    }
    
    func generateIndices() {
        for row in 0 ..< (self.stride - 1) {
            for column in 0 ..< (self.stride - 1) {
                self.indices.append(Index(row * self.stride + column));
                self.indices.append(Index(((row + 1) * self.stride + column)));
                self.indices.append(Index((row + 1) * self.stride + (column + 1)))
                self.indices.append(Index((row + 1) * self.stride + (column + 1)))
                self.indices.append(Index((row * self.stride + (column + 1))))
                self.indices.append(Index((row * self.stride + column)));
            }
        }
    }
    
    func heightAtPositionX(x:Float, z:Float) -> Float {
        let halfSize = self.width / 2
        
        if (x < -halfSize || x > halfSize || z < -halfSize || z > halfSize) {
            return 0.0
        }
        
        let nx:Float = (x / self.width) + 0.5
        let nz:Float = (z / self.depth) + 0.5
        
        let fx:Float = nx * Float(self.stride - 1)
        let fz:Float = nz * Float(self.stride - 1)
        
        let ix:Int = Int(floorf(fx))
        let iz:Int = Int(floorf(fz))
        
        let dx:Float = fx - Float(ix)
        let dz:Float = fz - Float(iz)
        
        let y00:Float = self.vertices[(iz * self.stride + ix)].position.y
        let y01:Float = self.vertices[(iz * self.stride + (ix + 1))].position.y
        let y10:Float = self.vertices[((iz + 1) * self.stride + ix)].position.y
        let y11:Float = self.vertices[((iz + 1) * self.stride + (ix + 1))].position.y
        
        let yTop:Float = ((1 - dx) * y00) + (dx * y01)
        let yBot:Float = ((1 - dx) * y10) + (dx * y11)
        let y:Float = ((1 - dz) * yTop) + (dz * yBot)
        
        return y
    }
}

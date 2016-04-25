//
//  TerrainMesh.swift
//  AdvancedGraphicsProject
//
//  Created by Mountain on 4/20/16.
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
        
        self.vertexBuffer = device.newBufferWithLength((sizeof(Vertex) * vertexCount), options: MTLResourceOptions.CPUCacheModeDefaultCache)
        self.indexBuffer = device.newBufferWithLength((sizeof(Index) * indexCount), options: MTLResourceOptions.CPUCacheModeDefaultCache)
        
        if let vB = self.vertexBuffer {
            let corners = [0, (self.stride), ((self.stride-1) * self.stride), ((self.stride * self.stride) - 1)]
            for offset in corners {
                let vertexPointer = UnsafeMutablePointer<Vertex>(vB.contents()).advancedBy(offset)
                var vertexData = vertexPointer.memory
                vertexData.position.y = 0.0
                vertexPointer.memory = vertexData
            }
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
        
        self.vertexBuffer.label = "Vertices (Terrain)"
        self.indexBuffer.label = "Vertices (Terrain)"
    }
    
    func performSquareStepWithRow(row:Int, column:Int, squareSize:Int, variance:Float) {
        let r0:size_t = row
        let c0:size_t = column
        let r1:size_t = (r0 + squareSize) % self.stride
        let c1:size_t = (c0 + squareSize) % self.stride
        let rmid:size_t = r0 + (squareSize / 2)
        let cmid:size_t = c0 + (squareSize / 2)
        
        if let vB = self.vertexBuffer {
            var corners = [Float]()
            let offsets = [(r0 * self.stride + c0), (r0 * self.stride + c1) + (r1 * self.stride + c1), (r1 * self.stride + c0)]
            
            for offset in offsets {
                var vertex = UnsafeMutablePointer<Vertex>(vB.contents()).advancedBy(offset).memory
                corners.append(vertex.position.y)
            }
            
            let yMean:Float = (corners.reduce(0, combine: +) / Float(corners.count))
            let error = (Float(((Double((arc4random() / UInt32.max))) - 0.5) * 2)) * variance
            let y:Float = yMean + error
            
            let vertexPointer = UnsafeMutablePointer<Vertex>(vB.contents()).advancedBy(rmid * self.stride + cmid)
            var vertexData = vertexPointer.memory
            vertexData.position.y = y
            vertexPointer.memory = vertexData
        }
    }
    
    
    
    func performDiamondStepWithRow(row:Int, column:Int, squareSize:Int, variance:Float) {
        let r0:size_t = row
        let c0:size_t = column
        let r1:size_t = (r0 + squareSize) % self.stride
        let c1:size_t = (c0 + squareSize) % self.stride
        let rmid:size_t = r0 + (squareSize / 2)
        let cmid:size_t = c0 + (squareSize / 2)
        if let vB = self.vertexBuffer {
            var corners = [Float]()
            let offsets = [(r0 * self.stride + c0), (r0 * self.stride + c1), (r1 * self.stride + c1), (r1 * self.stride + c0)]
            
            for offset in offsets {
                var vertex = UnsafeMutablePointer<Vertex>(vB.contents()).advancedBy(offset).memory
                corners.append(vertex.position.y)
            }
            
            var error:Float = 0
            error = (Float(((Double((arc4random() / UInt32.max))) - 0.5) * 2)) * variance
            var vertexPointer = UnsafeMutablePointer<Vertex>(vB.contents()).advancedBy((r0 * self.stride + cmid))
            var vertexData = vertexPointer.memory
            vertexData.position.y = (corners[0] + corners[1]) * 0.5 + error
            vertexPointer.memory = vertexData
            
            error = (Float(((Double((arc4random() / UInt32.max))) - 0.5) * 2)) * variance
            vertexPointer = UnsafeMutablePointer<Vertex>(vB.contents()).advancedBy((rmid * self.stride + c0))
            vertexData = vertexPointer.memory
            vertexData.position.y = (corners[0] + corners[3]) * 0.5 + error
            vertexPointer.memory = vertexData
            
            error = (Float(((Double((arc4random() / UInt32.max))) - 0.5) * 2)) * variance
            vertexPointer = UnsafeMutablePointer<Vertex>(vB.contents()).advancedBy((rmid * self.stride + c1))
            vertexData = vertexPointer.memory
            vertexData.position.y = (corners[1] + corners[2]) * 0.5 + error
            vertexPointer.memory = vertexData
            
            error = (Float(((Double((arc4random() / UInt32.max))) - 0.5) * 2)) * variance
            vertexPointer = UnsafeMutablePointer<Vertex>(vB.contents()).advancedBy((r1 * self.stride + cmid))
            vertexData = vertexPointer.memory
            vertexData.position.y = (corners[1] + corners[2]) * 0.5 + error
            vertexPointer.memory = vertexData
        }
    }
    
    func computeMeshCoords() {
        for row in 0 ..< self.stride {
            for column in 0 ..< self.stride {
                if let vB = self.vertexBuffer {
                    let offset:size_t = (row * self.stride + column)
                    let vertexPointer = UnsafeMutablePointer<Vertex>(vB.contents()).advancedBy(offset)
                    var vertexData = vertexPointer.memory
                    let x:Float = (Float(column) / Float((self.stride - 1)) - 0.5) * self.width
                    let y = vertexData.position.y * self.height
                    let z:Float = (Float(row) / Float((self.stride - 1)) - 0.5) * self.depth
                    vertexData.position = vector_float4(x, y, z, 1)
                    
                    let s:Float = (Float(column) / Float((self.stride - 1))) * texScale
                    let t:Float = (Float(row) / Float((self.stride - 1))) * texScale
                    vertexData.texCoords = vector_float2(s, t)
                    vertexData.diffuseColor = colorWhite
                    vertexPointer.memory = vertexData
                }
            }
        }
    }
    
    func computeMeshNormals() {
        let yScale:Float = 4
        for row in 0 ..< self.stride {
            for column in 0 ..< self.stride {
                if let vB = self.vertexBuffer {
                    if row > 0 && column > 0 && row < (self.stride - 1) && column < (self.stride - 1) {
                        var offset:size_t = (row * self.stride + (column - 1))
                        var vertexPointer = UnsafeMutablePointer<Vertex>(vB.contents()).advancedBy(offset)
                        var vertexData = vertexPointer.memory
                        let L:vector_float4 = vertexData.position
                        
                        offset = (row * self.stride + (column + 1))
                        vertexPointer = UnsafeMutablePointer<Vertex>(vB.contents()).advancedBy(offset)
                        vertexData = vertexPointer.memory
                        let R:vector_float4 = vertexData.position
                        
                        offset = (row - 1) * self.stride + column
                        vertexPointer = UnsafeMutablePointer<Vertex>(vB.contents()).advancedBy(offset)
                        vertexData = vertexPointer.memory
                        let U:vector_float4 = vertexData.position
                        
                        offset = (row + 1) * self.stride + column
                        vertexPointer = UnsafeMutablePointer<Vertex>(vB.contents()).advancedBy(offset)
                        vertexData = vertexPointer.memory
                        let D:vector_float4 = vertexData.position
                        
                        let T:vector_float3 = vector_float3((R.x - L.x), (R.y - L.y) * yScale, 0)
                        let B:vector_float3 = vector_float3(0, (D.y - U.y) * yScale, D.z - U.z)
                        let N:vector_float3 = vector_cross(B, T)
                        var normal:vector_float4 = vector_float4(N.x, N.y, N.z, 0)
                        normal = vector_normalize(normal)
                        
                        offset = row * self.stride + column
                        vertexPointer = UnsafeMutablePointer<Vertex>(vB.contents()).advancedBy(offset)
                        vertexData = vertexPointer.memory
                        vertexData.normal = normal
                        vertexPointer.memory = vertexData
                    } else {
                        let offset:size_t = (row * self.stride + column)
                        let vertexPointer = UnsafeMutablePointer<Vertex>(vB.contents()).advancedBy(offset)
                        var vertexData = vertexPointer.memory
                        let N:vector_float4 = vector_float4(0, 1, 0, 0)
                        vertexData.normal = N
                        vertexPointer.memory = vertexData
                    }
                }
            }
        }
    }
    
    func generateIndices() {
        if let iB = self.indexBuffer {
            var index:Int = 0
            for row in 0 ..< (self.stride - 1) {
                for column in 0 ..< (self.stride - 1) {
                    UnsafeMutablePointer<Index>(iB.contents()).advancedBy(index).memory = UInt16(row * self.stride + column); index += 1
                    UnsafeMutablePointer<Index>(iB.contents()).advancedBy(index).memory = UInt16((row + 1) * self.stride + column); index += 1
                    UnsafeMutablePointer<Index>(iB.contents()).advancedBy(index).memory = UInt16((row + 1) * self.stride + (column + 1)); index += 1
                    UnsafeMutablePointer<Index>(iB.contents()).advancedBy(index).memory = UInt16((row + 1) * self.stride + (column + 1)); index += 1
                    UnsafeMutablePointer<Index>(iB.contents()).advancedBy(index).memory = UInt16(row * self.stride + (column + 1)); index += 1
                    UnsafeMutablePointer<Index>(iB.contents()).advancedBy(index).memory = UInt16(row * self.stride + column); index += 1
                }
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
        
        if let vB = self.vertexBuffer {
            var offset:Int = (iz * self.stride + ix)
            var vertex = UnsafeMutablePointer<Vertex>(vB.contents()).advancedBy(offset).memory
            let y00:Float = vertex.position.y
            
            offset = (iz * self.stride + (ix + 1))
            vertex = UnsafeMutablePointer<Vertex>(vB.contents()).advancedBy(offset).memory
            let y01:Float = vertex.position.y
            
            offset = (iz + 1) * self.stride + ix
            vertex = UnsafeMutablePointer<Vertex>(vB.contents()).advancedBy(offset).memory
            let y10:Float = vertex.position.y
            
            offset = (iz + 1) * self.stride + (ix + 1)
            vertex = UnsafeMutablePointer<Vertex>(vB.contents()).advancedBy(offset).memory
            let y11:Float = vertex.position.y
            
            let yTop:Float = ((1 - dx) * y00) + (dx * y01)
            let yBot:Float = ((1 - dx) * y10) + (dx * y11)
            let y:Float = ((1 - dz) * yTop) + (dz * yBot)
            
            return y
        }
        
        return 0
    }
}

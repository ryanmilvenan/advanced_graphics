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
                var vertex = UnsafeMutablePointer<Vertex>(vB.contents() + offset).memory
                vertex.position.y = 0.0
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
                let adjOffset:Int = sizeof(Vertex) * offset
                var vertex = UnsafeMutablePointer<Vertex>(vB.contents() + adjOffset).memory
                corners.append(vertex.position.y)
            }
            
            let yMean:Float = (corners.reduce(0, combine: +) / Float(corners.count))
            let error = (Float(((Double((arc4random() / UInt32.max))) - 0.5) * 2)) * variance
            let y:Float = yMean + error
            
            var vertex = UnsafeMutablePointer<Vertex>(vB.contents() + (rmid * self.stride + cmid)).memory
            vertex.position.y = y
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
                let adjOffset = sizeof(Vertex) * offset
                var vertex = UnsafeMutablePointer<Vertex>(vB.contents() + adjOffset).memory
                corners.append(vertex.position.y)
            }
            
            var error:Float = 0
            error = (Float(((Double((arc4random() / UInt32.max))) - 0.5) * 2)) * variance
            var vertex = UnsafeMutablePointer<Vertex>(vB.contents() + (sizeof(Vertex) * (r0 * self.stride + cmid))).memory
            vertex.position.y = (corners[0] + corners[1]) * 0.5 + error
            
            error = (Float(((Double((arc4random() / UInt32.max))) - 0.5) * 2)) * variance
            vertex = UnsafeMutablePointer<Vertex>(vB.contents() + (sizeof(Vertex) * (rmid * self.stride + c0))).memory
            vertex.position.y = (corners[0] + corners[3]) * 0.5 + error
            
            error = (Float(((Double((arc4random() / UInt32.max))) - 0.5) * 2)) * variance
            vertex = UnsafeMutablePointer<Vertex>(vB.contents() + (sizeof(Vertex) * (rmid * self.stride + c1))).memory
            vertex.position.y = (corners[1] + corners[2]) * 0.5 + error
            
            error = (Float(((Double((arc4random() / UInt32.max))) - 0.5) * 2)) * variance
            vertex = UnsafeMutablePointer<Vertex>(vB.contents() + (sizeof(Vertex) * (r1 * self.stride + cmid))).memory
            vertex.position.y = (corners[1] + corners[2]) * 0.5 + error
        }
    }
    
    func computeMeshCoords() {
        for row in 0 ..< self.stride {
            for column in 0 ..< self.stride {
                if let vB = self.vertexBuffer {
                    let offset:size_t = (sizeof(Vertex) * (row * self.stride + column))
                    var vertex = UnsafeMutablePointer<Vertex>(vB.contents() + offset).memory
                    let x:Float = (Float(column) / Float((self.stride - 1)) - 0.5) * self.width
                    let y = vertex.position.y * self.height
                    let z:Float = (Float(row) / Float((self.stride - 1)) - 0.5) * self.depth
                    vertex.position = vector_float4(x, y, z, 1)
                    
                    let s:Float = (Float(column) / Float((self.stride - 1))) * texScale
                    let t:Float = (Float(row) / Float((self.stride - 1))) * texScale
                    vertex.texCoords = vector_float2(s, t)
                    vertex.diffuseColor = colorWhite
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
                        var offset:size_t = (sizeof(Vertex) * (row * self.stride + (column - 1)))
                        var vertex = UnsafeMutablePointer<Vertex>(vB.contents() + offset).memory
                        let L:vector_float4 = vertex.position
                        
                        offset = (sizeof(Vertex) * (row * self.stride + (column + 1)))
                        vertex = UnsafeMutablePointer<Vertex>(vB.contents() + offset).memory
                        let R:vector_float4 = vertex.position
                        
                        offset = (sizeof(Vertex) * ((row - 1) * self.stride + column))
                        vertex = UnsafeMutablePointer<Vertex>(vB.contents() + offset).memory
                        let U:vector_float4 = vertex.position
                        
                        offset = (sizeof(Vertex) * ((row + 1) * self.stride + column))
                        vertex = UnsafeMutablePointer<Vertex>(vB.contents() + offset).memory
                        let D:vector_float4 = vertex.position
                        
                        let T:vector_float3 = vector_float3((R.x - L.x), (R.y - L.y) * yScale, 0)
                        let B:vector_float3 = vector_float3(0, (D.y - U.y) * yScale, D.z - U.z)
                        let N:vector_float3 = vector_cross(B, T)
                        var normal:vector_float4 = vector_float4(N.x, N.y, N.z, 0)
                        normal = vector_normalize(normal)
                        
                        offset = (sizeof(Vertex) * (row * self.stride + column))
                        vertex = UnsafeMutablePointer<Vertex>(vB.contents() + offset).memory
                        vertex.normal = normal
                    } else {
                        let offset:size_t = (sizeof(Vertex) * (row * self.stride + column))
                        var vertex = UnsafeMutablePointer<Vertex>(vB.contents() + offset).memory
                        let N:vector_float4 = vector_float4(0, 1, 0, 0)
                        vertex.normal = N
                    }
                }
            }
        }
    }
    
    func generateIndices() {
        if let iB = self.indexBuffer {
            var index:Int = 1
            for row in 0 ..< (self.stride - 1) {
                for column in 0 ..< (self.stride - 1) {
                    var indexMemory = setIndexValue(iB, index: index); index += 1
                    indexMemory.memory = UInt16(row * self.stride + column)
                    indexMemory = setIndexValue(iB, index: index); index += 1
                    indexMemory.memory = UInt16((row + 1) * self.stride + column)
                    indexMemory = setIndexValue(iB, index: index); index += 1
                    indexMemory.memory = UInt16((row + 1) * self.stride + (column + 1))
                    indexMemory = setIndexValue(iB, index: index); index += 1
                    indexMemory.memory = UInt16((row + 1) * self.stride + (column + 1))
                    indexMemory = setIndexValue(iB, index: index); index += 1
                    indexMemory.memory = UInt16((row + 1) * self.stride + column)
                    indexMemory = setIndexValue(iB, index: index); index += 1
                    indexMemory.memory = UInt16(row * self.stride + column)
                }
            }
        }
    }
    
    func setIndexValue(buffer:MTLBuffer, index:Int) -> UnsafeMutablePointer<Index> {
        let offset:Int = sizeof(Index) * index
        return UnsafeMutablePointer<Index>(buffer.contents() + offset)
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
            var offset:Int = sizeof(Vertex) * (iz * self.stride + ix)
            var vertex = UnsafeMutablePointer<Vertex>(vB.contents() + offset).memory
            let y00:Float = vertex.position.y
            
            offset = sizeof(Vertex) * (iz * self.stride + (ix + 1))
            vertex = UnsafeMutablePointer<Vertex>(vB.contents() + offset).memory
            let y01:Float = vertex.position.y
            
            offset = (sizeof(Vertex) * ((iz + 1) * self.stride + ix))
            vertex = UnsafeMutablePointer<Vertex>(vB.contents() + offset).memory
            let y10:Float = vertex.position.y
            
            offset = (sizeof(Vertex) * ((iz + 1) * self.stride + (ix + 1)))
            vertex = UnsafeMutablePointer<Vertex>(vB.contents() + offset).memory
            let y11:Float = vertex.position.y
            
            let yTop:Float = ((1 - dx) * y00) + (dx * y01)
            let yBot:Float = ((1 - dx) * y10) + (dx * y11)
            let y:Float = ((1 - dz) * yTop) + (dz * yBot)
            
            return y
        }
        
        return 0
    }
}

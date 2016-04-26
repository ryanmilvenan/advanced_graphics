//
//  SkyboxMesh.swift
//  AdvancedGraphicsProject
//
//  Created by Wind on 4/26/16.
//  Copyright © 2016 Ryan Milvenan. All rights reserved.
//

import Foundation
import Metal
import simd

class Skybox: Mesh {
    let vertices:[Float] =
    [
        -0.5,  0.5,  0.5, 1.0,  0.0, -1.0,  0.0, 0.0,
        0.5,  0.5,  0.5, 1.0,  0.0, -1.0,  0.0, 0.0,
        0.5,  0.5, -0.5, 1.0,  0.0, -1.0,  0.0, 0.0,
        -0.5,  0.5, -0.5, 1.0,  0.0, -1.0,  0.0, 0.0,
        
        -0.5, -0.5, -0.5, 1.0,  0.0,  1.0,  0.0, 0.0,
        0.5, -0.5, -0.5, 1.0,  0.0,  1.0,  0.0, 0.0,
        0.5, -0.5,  0.5, 1.0,  0.0,  1.0,  0.0, 0.0,
        -0.5, -0.5,  0.5, 1.0,  0.0,  1.0,  0.0, 0.0,
        
        -0.5, -0.5,  0.5, 1.0,  0.0,  0.0, -1.0, 0.0,
        0.5, -0.5,  0.5, 1.0,  0.0,  0.0, -1.0, 0.0,
        0.5,  0.5,  0.5, 1.0,  0.0,  0.0, -1.0, 0.0,
        -0.5,  0.5,  0.5, 1.0,  0.0,  0.0, -1.0, 0.0,
        
        0.5, -0.5, -0.5, 1.0,  0.0,  0.0,  1.0, 0.0,
        -0.5, -0.5, -0.5, 1.0,  0.0,  0.0,  1.0, 0.0,
        -0.5,  0.5, -0.5, 1.0,  0.0,  0.0,  1.0, 0.0,
        0.5,  0.5, -0.5, 1.0,  0.0,  0.0,  1.0, 0.0,
        
        -0.5, -0.5, -0.5, 1.0,  1.0,  0.0,  0.0, 0.0,
        -0.5, -0.5,  0.5, 1.0,  1.0,  0.0,  0.0, 0.0,
        -0.5,  0.5,  0.5, 1.0,  1.0,  0.0,  0.0, 0.0,
        -0.5,  0.5, -0.5, 1.0,  1.0,  0.0,  0.0, 0.0,
        
        0.5, -0.5,  0.5, 1.0, -1.0,  0.0,  0.0, 0.0,
        0.5, -0.5, -0.5, 1.0, -1.0,  0.0,  0.0, 0.0,
        0.5,  0.5, -0.5, 1.0, -1.0,  0.0,  0.0, 0.0,
        0.5,  0.5,  0.5, 1.0, -1.0,  0.0,  0.0, 0.0,
    ]
    
    let indices:[Index] =
    [
        0,  3,  2,  2,  1,  0,
        4,  7,  6,  6,  5,  4,
        8, 11, 10, 10,  9,  8,
        12, 15, 14, 14, 13, 12,
        16, 19, 18, 18, 17, 16,
        20, 23, 22, 22, 21, 20,
    ]
    
    var device:MTLDevice! = nil
    
    init(device:MTLDevice) {
        self.device = device
        super.init()
        
        self.vertexBuffer = device.newBufferWithBytes(vertices, length: 24 * 8 * sizeof(Float), options: [])
        self.indexBuffer = device.newBufferWithBytes(indices, length: 36 * sizeof(Index), options: [])
    }
    
    func getPipeline() -> MTLRenderPipelineState? {
        
        let vertexDescriptor:MTLVertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = MTLVertexFormat.Float4
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.attributes[0].offset = 0
        
        vertexDescriptor.attributes[1].format = MTLVertexFormat.Float4
        vertexDescriptor.attributes[1].offset = sizeof(float4)
        vertexDescriptor.attributes[1].bufferIndex = 0
        
        vertexDescriptor.layouts[0].stepFunction = MTLVertexStepFunction.PerVertex
        vertexDescriptor.layouts[0].stride = sizeof(SkyVertex)
        
        let library:MTLLibrary = self.device.newDefaultLibrary()!
        
        let pipelineDescriptor:MTLRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = library.newFunctionWithName("vertex_skybox")
        pipelineDescriptor.fragmentFunction = library.newFunctionWithName("fragment_cube_lookup")
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.BGRA8Unorm
        pipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormat.Depth32Float
        
        var pipelineState:MTLRenderPipelineState? = nil
        do {
            try pipelineState = device.newRenderPipelineStateWithDescriptor(pipelineDescriptor)
        } catch let error {
            print("Failed to create pipeline state, error \(error)")
        }
        
        return pipelineState
    }
}
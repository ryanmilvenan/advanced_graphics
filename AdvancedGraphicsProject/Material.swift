//
//  Material.swift
//  AdvancedGraphicsProject
//
//  Created by Mountain on 4/21/16.
//  Copyright © 2016 Ryan Milvenan. All rights reserved.
//

import Foundation
import Metal
import simd

class Material {
    var diffuseTexture:MTLTexture! = nil
    var depthState:MTLDepthStencilState! = nil
    var pipelineState:MTLRenderPipelineState! = nil
    
    init(diffuseTexture:MTLTexture, alphaTestEnabled:Bool, blendEnabled:Bool, depthWriteEnabled:Bool, device:MTLDevice) {
        self.diffuseTexture = diffuseTexture
        let fragmentFunction:String = "fragmentShader"
        
        let library:MTLLibrary = device.newDefaultLibrary()!
        
        let pipelineDescriptor:MTLRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = library.newFunctionWithName("vertexShader")
        pipelineDescriptor.fragmentFunction = library.newFunctionWithName(fragmentFunction)
        
        
        let vertexDescriptor:MTLVertexDescriptor = MTLVertexDescriptor()
        //Position
        vertexDescriptor.attributes[0].format = MTLVertexFormat.Float4
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        
        //Normal
        vertexDescriptor.attributes[1].format = MTLVertexFormat.Float4
        vertexDescriptor.attributes[1].offset = 16
        vertexDescriptor.attributes[1].bufferIndex = 0
        
        //Color
        vertexDescriptor.attributes[2].format = MTLVertexFormat.Float4
        vertexDescriptor.attributes[2].offset = 32
        vertexDescriptor.attributes[2].bufferIndex = 0
        
        //Tex Coord
        vertexDescriptor.attributes[3].format = MTLVertexFormat.Float2
        vertexDescriptor.attributes[3].offset = 48
        vertexDescriptor.attributes[3].bufferIndex = 0
        
        vertexDescriptor.layouts[0].stepFunction = MTLVertexStepFunction.PerVertex
        vertexDescriptor.layouts[0].stride = sizeof(Vertex)
        
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        
        let renderBufferAttachment:MTLRenderPipelineColorAttachmentDescriptor = pipelineDescriptor.colorAttachments[0]
        renderBufferAttachment.pixelFormat = MTLPixelFormat.BGRA8Unorm
        
        if(blendEnabled) {
            renderBufferAttachment.blendingEnabled = true
            renderBufferAttachment.rgbBlendOperation = MTLBlendOperation.Add
            renderBufferAttachment.alphaBlendOperation = MTLBlendOperation.Add
            renderBufferAttachment.sourceRGBBlendFactor = MTLBlendFactor.SourceAlpha
            renderBufferAttachment.destinationRGBBlendFactor = MTLBlendFactor.OneMinusSourceAlpha
            renderBufferAttachment.sourceAlphaBlendFactor = MTLBlendFactor.SourceAlpha
            renderBufferAttachment.destinationAlphaBlendFactor = MTLBlendFactor.OneMinusSourceAlpha
        }
        
        pipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormat.Depth32Float
        do {
            try self.pipelineState = device.newRenderPipelineStateWithDescriptor(pipelineDescriptor)
        } catch let error {
            print("Failed to create pipeline state, error \(error)")
        }
        
        let depthDescriptor:MTLDepthStencilDescriptor = MTLDepthStencilDescriptor()
        depthDescriptor.depthWriteEnabled = depthWriteEnabled
        depthDescriptor.depthCompareFunction = MTLCompareFunction.Less
        
        self.depthState = device.newDepthStencilStateWithDescriptor(depthDescriptor)
        

    }
    
}
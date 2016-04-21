//
//  Renderer.swift
//  AdvancedGraphicsProject
//
//  Created by Mountain on 4/20/16.
//  Copyright © 2016 Ryan Milvenan. All rights reserved.
//

import Foundation
import QuartzCore.CAMetalLayer
import Metal
import UIKit
import simd


let terrainSize:Float = 64

let waterLevel:Float = -0.5

let cameraHeight:Float = 0.3

let sharedUniformOffset:size_t = 0
let waterUniformOffset:size_t = sharedUniformOffset + sizeof(Uniforms)


class Renderer {
    
    var layer:CAMetalLayer! = nil
    
    var device:MTLDevice! = nil
    var commandQueue: MTLCommandQueue! = nil
    var depthTexture:MTLTexture! = nil
    var sampler: MTLSamplerState! = nil
    
    var pipelineState: MTLRenderPipelineState! = nil
    var defaultLibrary: MTLLibrary! = nil
    var depthState: MTLDepthStencilState! = nil
    
    var uniformBuffer:MTLBuffer! = nil
    
    var cameraPosition:vector_float3 = vector_float3()
    var cameraHeading:Float = 0
    var angularVelocity:Float = 0
    var velocity:Float = 0
    var frameDuration:Float = 1
    
    var waterMesh:Mesh! = nil
    var waterMaterial:Material! = nil

    init(layer:CAMetalLayer) {
        self.layer = layer
        self.buildMetal()
        self.buildResources()
    }
    
    func buildMetal() {
        self.device = MTLCreateSystemDefaultDevice()
        guard device != nil else {
            print("Metal is not supported on this device")
            return
        }
        self.layer.device = self.device
        self.layer.pixelFormat = MTLPixelFormat.BGRA8Unorm
        
        self.commandQueue = self.device.newCommandQueue()
        
        let samplerDescriptor:MTLSamplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.minFilter = MTLSamplerMinMagFilter.Nearest
        samplerDescriptor.magFilter = MTLSamplerMinMagFilter.Linear
        samplerDescriptor.mipFilter = MTLSamplerMipFilter.Linear
        
        samplerDescriptor.sAddressMode = MTLSamplerAddressMode.Repeat
        samplerDescriptor.tAddressMode = MTLSamplerAddressMode.Repeat
        
        self.sampler = device.newSamplerStateWithDescriptor(samplerDescriptor)
    }
    
    func buildResources() {
        self.loadMeshes()
        self.loadTextures()
        self.buildUniformBuffer()
        self.populateWaterUniforms()
    }
    
    func loadMeshes() {
        self.waterMesh = PlaneMesh(width: terrainSize, depth: terrainSize, divX: 32, divZ: 32, texScale: 10, opacity: 0.2, device: self.device)
    }
    
    func loadTextures() {
        let textureLoader:TextureLoader = TextureLoader.sharedInstance
        
        let waterTexture:MTLTexture = textureLoader.texture2D("water", mipmapped:true, device:self.device)
        waterMaterial = Material(diffuseTexture: waterTexture, alphaTestEnabled: false, blendEnabled: true, depthWriteEnabled: false, device: self.device)
    }
    
    func buildUniformBuffer() {
        let uniformBufferLength = waterUniformOffset + sizeof(InstanceUniforms)
        self.uniformBuffer = self.device.newBufferWithLength(uniformBufferLength, options: MTLResourceOptions.CPUCacheModeDefaultCache)
        self.uniformBuffer.label = "Uniforms"
    }
    
    func populateWaterUniforms() {
        let waterOffsetVec:vector_float3 = vector_float3(0, waterLevel, 0)
        let waterModelMatrix = matrix_translation(waterOffsetVec)
        let waterNormalMatrix = matrix_transpose(matrix_invert(matrix_extract_linear(waterModelMatrix)))
        var waterUniforms:InstanceUniforms = InstanceUniforms(modelMatrix: waterModelMatrix, normalMatrix: waterNormalMatrix)
        memcpy(self.uniformBuffer.contents() + waterUniformOffset, &waterUniforms, sizeof(InstanceUniforms))
    }
    
    func updateCamera() {
        var camPosition:vector_float3 = self.cameraPosition
        
        self.cameraHeading += self.angularVelocity * self.frameDuration
        camPosition.x += -sin(self.cameraHeading) * self.velocity * self.frameDuration
        camPosition.z += -cos(self.cameraHeading) * self.velocity * self.frameDuration
        camPosition.y += cameraHeight
        
        self.cameraPosition = camPosition
        
        let Y:vector_float3 = vector_float3( 0, 1, 0)
        let viewMatrix:matrix_float4x4 = matrix_multiply(matrix_rotation(Y, angle: self.cameraHeading), matrix_translation(-self.cameraPosition))
        let aspect:Float = Float(self.layer.drawableSize.width) / Float(self.layer.drawableSize.height)
        let fov:Float = (aspect > 1) ? Float(M_PI / 4) : Float(M_PI / 3)
        let projectionMatrix:matrix_float4x4 = matrix_perspective_projection(aspect, fovy: fov, near: 0.1, far: 100)
        let viewProjectionMatrix = matrix_multiply(projectionMatrix, viewMatrix)
        var uniforms:Uniforms = Uniforms(viewProjection: viewProjectionMatrix)
        memcpy(self.uniformBuffer.contents() + sharedUniformOffset, &uniforms, sizeof(Uniforms))
    }
    
    func buildDepthTexture() {
        let drawableSize:CGSize = self.layer.drawableSize
        let descriptor:MTLTextureDescriptor = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(MTLPixelFormat.Depth32Float, width: Int(drawableSize.width), height: Int(drawableSize.height), mipmapped: false)
        self.depthTexture = self.device.newTextureWithDescriptor(descriptor)
        self.depthTexture.label = "Depth Texture"
        
    }
    
    func newRenderPassDescriptorWithColorAttachmentTexture(texture:MTLTexture) -> MTLRenderPassDescriptor {
        let renderPassDescriptor:MTLRenderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = texture
        renderPassDescriptor.colorAttachments[0].loadAction = .Clear
        renderPassDescriptor.colorAttachments[0].storeAction = .Store
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.2, 0.5, 0.95, 1.0)
        
        renderPassDescriptor.depthAttachment.texture = self.depthTexture
        renderPassDescriptor.depthAttachment.loadAction = .Clear
        renderPassDescriptor.depthAttachment.storeAction = .Store
        renderPassDescriptor.depthAttachment.clearDepth = 1.0
        
        return renderPassDescriptor
    }
    
    func drawInstancedMesh(mesh:Mesh, encoder:MTLRenderCommandEncoder, material:Material, instanceCount:Int) {
        encoder.setRenderPipelineState(material.pipelineState)
        encoder.setDepthStencilState(material.depthState)
        encoder.setFragmentSamplerState(self.sampler, atIndex: 0)
        encoder.setVertexBuffer(mesh.vertexBuffer, offset: 0, atIndex: 0)
        encoder.setFragmentTexture(material.diffuseTexture, atIndex: 0)
        encoder.drawIndexedPrimitives(MTLPrimitiveType.Triangle, indexCount: mesh.indexBuffer.length / sizeof(Index), indexType: MTLIndexType.UInt16, indexBuffer: mesh.indexBuffer, indexBufferOffset: 0, instanceCount: instanceCount)
    }
    
    func updateFrameDuration(duration:Float) {
        self.frameDuration = duration
    }
    
    func updateVelocity(v:Float) {
        self.velocity = v
    }
    
    func updateAngularVelocity(v:Float) {
        self.angularVelocity = v
    }
    
    func draw() {
        self.updateCamera()
        
        if let drawable:CAMetalDrawable = self.layer.nextDrawable() {
            if let depthTex = self.depthTexture {
                if depthTex.width != Int(self.layer.drawableSize.width) || self.depthTexture.height != Int(self.layer.drawableSize.height) {
                    self.buildDepthTexture()
                }
            } else {
                self.buildDepthTexture()
            }
            
            let renderPassDescriptor = self.newRenderPassDescriptorWithColorAttachmentTexture(drawable.texture)
            
            let commandBuffer:MTLCommandBuffer = self.commandQueue.commandBuffer()
            
            let encoder:MTLRenderCommandEncoder = commandBuffer.renderCommandEncoderWithDescriptor(renderPassDescriptor)
            encoder.setFrontFacingWinding(MTLWinding.CounterClockwise)
            encoder.setCullMode(MTLCullMode.None)
            
            encoder.setVertexBuffer(self.uniformBuffer, offset: sharedUniformOffset, atIndex: 1)
            
            encoder.endEncoding()
            commandBuffer.presentDrawable(drawable)
            commandBuffer.commit()
        }
    }

}



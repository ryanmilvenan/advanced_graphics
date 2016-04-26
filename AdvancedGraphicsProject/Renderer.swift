//
//  Renderer.swift
//  AdvancedGraphicsProject
//
//  Created by Mountain on 4/10/16.
//  Copyright © 2016 Ryan Milvenan. All rights reserved.
//

import Foundation
import QuartzCore.CAMetalLayer
import Metal
import MetalKit
import UIKit
import simd


let terrainSize:Float = 64
let terrainHeight:Float = 2.5
let terrainSmoothness:Float = 0.95

let waterLevel:Float = -0.5

let cameraHeight:Float = 0.3

let sharedUniformOffset:size_t = 0
let terrainUniformOffset:size_t = sharedUniformOffset + sizeof(Uniforms)
let waterUniformOffset:size_t = terrainUniformOffset + sizeof(InstanceUniforms)


class Renderer {
    
    var mtkView:MTKView! = nil
    var mtkViewDelegate:MTKViewDelegate! = nil
    
    var device:MTLDevice! = nil
    var commandQueue: MTLCommandQueue! = nil
    var depthTexture:MTLTexture! = nil
    var sampler: MTLSamplerState! = nil
    
    var pipelineState: MTLRenderPipelineState! = nil
    var defaultLibrary: MTLLibrary! = nil
    var depthState: MTLDepthStencilState! = nil
    
    var uniformBuffer:MTLBuffer! = nil
    var projMatrix:float4x4! = nil
    var viewMatrix:float4x4! = nil
    
    var cameraPosition:vector_float3 = vector_float3()
    var cameraHeading:Float = 0
    var angularVelocity:Float = 0
    var velocity:Float = 0
    var frameDuration:Float = 0.016
    
    var waterMesh:Mesh! = nil
    var waterMaterial:Material! = nil
    
    var terrainMesh:Mesh! = nil
    var terrainMaterial:Material! = nil

    init(view:MTKView, delegate:MTKViewDelegate) {
        self.mtkView = view
        self.mtkViewDelegate = delegate
        self.setupMetal()
        self.buildResources()
        self.reshape()
    }
    
    func setupMetal() {
        self.device = MTLCreateSystemDefaultDevice()
        guard device != nil else {
            print("Metal is not supported on this device")
            return
        }
            
        self.commandQueue = self.device.newCommandQueue()
        
        let samplerDescriptor:MTLSamplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.minFilter = MTLSamplerMinMagFilter.Nearest
        samplerDescriptor.magFilter = MTLSamplerMinMagFilter.Linear
        samplerDescriptor.mipFilter = MTLSamplerMipFilter.Linear
        
        samplerDescriptor.sAddressMode = MTLSamplerAddressMode.Repeat
        samplerDescriptor.tAddressMode = MTLSamplerAddressMode.Repeat
        
        self.sampler = device.newSamplerStateWithDescriptor(samplerDescriptor)
        
        guard let metalView = self.mtkView else {print("MTKView not found"); return}
        metalView.delegate = self.mtkViewDelegate
        metalView.device = self.device
        metalView.colorPixelFormat = MTLPixelFormat.BGRA8Unorm
        self.mtkView = metalView
    }
    
    func buildResources() {
        self.loadMeshes()
        self.loadTextures()
        self.buildUniformBuffer()
        self.populateTerrainUniforms()
        self.populateWaterUniforms()
    }
    
    func loadMeshes() {
        self.terrainMesh = TerrainMesh(width:terrainSize, height: terrainHeight, iterations: 6, smoothness: terrainSmoothness, device: self.device)
        
        self.waterMesh = WaterMesh(width: terrainSize, depth: terrainSize, divX: 32, divZ: 32, texScale: 10, opacity: 0.2, device: self.device)
    }
    
    func loadTextures() {
        let textureLoader:TextureLoader = TextureLoader.sharedInstance
        
        let terrainTexture:MTLTexture? = textureLoader.loadTexture("sand", mipmapped: true, device: device)
        if let terrainTex = terrainTexture {
            self.terrainMaterial = Material(diffuseTexture: terrainTex, blendEnabled: false, depthWriteEnabled: true, device: self.device)
        } else {
            print("Error loading terrain texture")
        }
        
        let waterTexture:MTLTexture? = textureLoader.loadTexture("water", mipmapped:true, device: device)
        
        if let waterTex = waterTexture {
            self.waterMaterial = Material(diffuseTexture: waterTex, blendEnabled: true, depthWriteEnabled: false, device: self.device)
        } else {
            print("Error loading water texture")
        }
        
    }
    
    func buildUniformBuffer() {
        let uniformBufferLength = waterUniformOffset + sizeof(InstanceUniforms)
        self.uniformBuffer = self.device.newBufferWithLength(uniformBufferLength, options: MTLResourceOptions.OptionCPUCacheModeDefault)
        self.uniformBuffer.label = "Uniforms"
    }
    
    func populateTerrainUniforms() {
        let terrainModelMatrix:float4x4 = matrix_identity()
        let terrainNormalMatrix = terrainModelMatrix.transpose.inverse
        var terrainUniforms:InstanceUniforms = InstanceUniforms(modelMatrix: terrainModelMatrix, normalMatrix: terrainNormalMatrix)
        memcpy(self.uniformBuffer.contents() + terrainUniformOffset, &terrainUniforms, sizeof(InstanceUniforms))
    }
    
    func populateWaterUniforms() {
        let waterOffsetVec:float3 = float3(0, waterLevel, 0)
        let waterModelMatrix = translationMatrix(waterOffsetVec)
        let waterNormalMatrix = waterModelMatrix.transpose.inverse
        var waterUniforms:InstanceUniforms = InstanceUniforms(modelMatrix: waterModelMatrix, normalMatrix: waterNormalMatrix)

        memcpy(self.uniformBuffer.contents() + waterUniformOffset, &waterUniforms, sizeof(InstanceUniforms))
    }
    
    func constrainToTerrain(position:float3) -> float3 {
        var newPosition:float3 = position
        let halfWidth:Float = (self.terrainMesh as! TerrainMesh).width * 0.5
        let halfDepth:Float = (self.terrainMesh as! TerrainMesh).depth * 0.5
        
        if(newPosition.x < -halfWidth) {
            newPosition.x = -halfWidth
        } else if (newPosition.x > halfWidth) {
            newPosition.x = halfWidth
        }
        
        if(newPosition.z < -halfDepth) {
            newPosition.z = -halfDepth
        } else if (newPosition.z > halfDepth) {
            newPosition.z = halfDepth
        }
        
        newPosition.y = (self.terrainMesh as! TerrainMesh).heightAtPositionX(newPosition.x, z: newPosition.z)
        
        if(newPosition.y < waterLevel) {
            newPosition.y  = waterLevel
        }
        
        return newPosition
    }
    
    func updateCamera() {
        var camPosition:float3 = self.cameraPosition
        
        self.cameraHeading += self.angularVelocity * self.frameDuration
        camPosition.x += -sin(self.cameraHeading) * self.velocity * self.frameDuration
        camPosition.z += -cos(self.cameraHeading) * self.velocity * self.frameDuration
        camPosition = self.constrainToTerrain(camPosition)
        camPosition.y += cameraHeight
        
        self.cameraPosition = camPosition
        //print("Cam Position: \(self.cameraPosition)")
        self.reshape()
        
        let viewProjectionMatrix = projMatrix * viewMatrix
        var uniforms:Uniforms = Uniforms(viewProjection: viewProjectionMatrix)
        memcpy(self.uniformBuffer.contents() + sharedUniformOffset, &uniforms, sizeof(Uniforms))
    }
    
    func buildDepthTexture() {
        let drawableSize:CGSize = self.mtkView.drawableSize
        let descriptor:MTLTextureDescriptor = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(MTLPixelFormat.Depth32Float, width: Int(drawableSize.width), height: Int(drawableSize.height), mipmapped: false)
        self.depthTexture = self.device.newTextureWithDescriptor(descriptor)
        self.depthTexture.label = "Depth Texture"
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
    
    func reshape() {
        
        self.viewMatrix = createViewMatrix()
        if let drawable = self.mtkView.currentDrawable {
            let aspect = Float(drawable.layer.drawableSize.width / drawable.layer.drawableSize.height)
            let fov:Float = (aspect > 1) ? Float(M_PI / 4) : Float(M_PI / 3)
            self.projMatrix = projectionMatrix(0.1, far: 100, aspect: aspect, fovy: fov)
        }
    }
    
    func createViewMatrix() -> float4x4 {
        let Y:vector_float3 = vector_float3(0, 1, 0)
        let cameraPosition = self.cameraPosition
        return rotationMatrix(self.cameraHeading, Y) * translationMatrix(-cameraPosition)
    }
    
    
    func draw() {
        self.updateCamera()
        
        if let drawable = self.mtkView.currentDrawable, renderPassDescriptor = self.mtkView.currentRenderPassDescriptor {
            if let depthTex = self.depthTexture {
                if depthTex.width != Int(self.mtkView.drawableSize.width) || self.depthTexture.height != Int(self.mtkView.drawableSize.height) {
                    self.buildDepthTexture()
                }
            } else {
                self.buildDepthTexture()
            }
            
            renderPassDescriptor.colorAttachments[0].texture = drawable.texture
            renderPassDescriptor.colorAttachments[0].loadAction = .Clear
            renderPassDescriptor.colorAttachments[0].storeAction = .Store
            renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.2, 0.5, 0.95, 1.0)
            
            renderPassDescriptor.depthAttachment.texture = self.depthTexture
            renderPassDescriptor.depthAttachment.loadAction = .Clear
            renderPassDescriptor.depthAttachment.storeAction = .Store
            renderPassDescriptor.depthAttachment.clearDepth = 1.0
            
            let commandBuffer:MTLCommandBuffer = self.commandQueue.commandBuffer()
            
            let encoder:MTLRenderCommandEncoder = commandBuffer.renderCommandEncoderWithDescriptor(renderPassDescriptor)
            encoder.setFrontFacingWinding(MTLWinding.CounterClockwise)
            encoder.setCullMode(MTLCullMode.Back)
            
            encoder.setVertexBuffer(self.uniformBuffer, offset: sharedUniformOffset, atIndex: 1)
            
            encoder.setVertexBuffer(self.uniformBuffer, offset: terrainUniformOffset, atIndex: 2)
            self.drawInstancedMesh(self.terrainMesh, encoder: encoder, material: self.terrainMaterial, instanceCount: 1)
            
            encoder.setVertexBuffer(self.uniformBuffer, offset: waterUniformOffset, atIndex: 2)
            self.drawInstancedMesh(self.waterMesh, encoder: encoder, material: self.waterMaterial, instanceCount: 1)
            
            encoder.endEncoding()
            commandBuffer.presentDrawable(drawable)
            commandBuffer.commit()
        }
    }
}



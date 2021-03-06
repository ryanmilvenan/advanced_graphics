//
//  Renderer.swift
//  AdvancedGraphicsProject
//
//  Created by Mountain on 4/10/16.
//  Copyright © 2016 Ryan Milvenan. All rights reserved.
//

import Foundation
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
let skyboxUniformOffset:size_t = sharedUniformOffset + sizeof(Uniforms)
let terrainUniformOffset:size_t = skyboxUniformOffset + sizeof(InstanceUniforms)
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
    
    var skyboxMesh:Skybox! = nil
    var skyboxTexture:MTLTexture? = nil

    init(view:MTKView, delegate:MTKViewDelegate) {
        self.mtkView = view
        self.mtkViewDelegate = delegate
        self.setupMetal()
        self.buildResources()
        self.reshape()
    }
    
    //Initialize metal as much as possible
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
        self.populateSkyboxUniforms()
        self.populateTerrainUniforms()
        self.populateWaterUniforms()
    }
    
    //Create all the neccessary geometry for the meshes
    func loadMeshes() {
        self.skyboxMesh = Skybox(device: self.device)
        
        self.terrainMesh = TerrainMesh(width:terrainSize, height: terrainHeight, iterations: 4, smoothness: terrainSmoothness, device: self.device)
        
        self.waterMesh = WaterMesh(width: terrainSize, depth: terrainSize, divX: 32, divZ: 32, texScale: 10, opacity: 0.20, device: self.device)
    }
    
    //Load textures for all the meshes
    func loadTextures() {
        let textureLoader:TextureLoader = TextureLoader.sharedInstance
        
        let skyImages:[String] = ["cloudtop_lf", "cloudtop_rt","cloudtop_up", "cloudtop_dn", "cloudtop_ft", "cloudtop_bk"]
        self.skyboxTexture = textureLoader.loadCubeTexture(skyImages, device: self.device)
        
        let terrainTexture:MTLTexture? = textureLoader.load2DTexture("rippled", mipmapped: true, device: self.device)
        if let terrainTex = terrainTexture {
            self.terrainMaterial = Material(diffuseTexture: terrainTex, blendEnabled: false, depthWriteEnabled: true, device: self.device)
        } else {
            print("Error loading terrain texture")
        }
        
        let waterTexture:MTLTexture? = textureLoader.load2DTexture("water", mipmapped:true, device: self.device)
        
        if let waterTex = waterTexture {
            self.waterMaterial = Material(diffuseTexture: waterTex, blendEnabled: true, depthWriteEnabled: false, device: self.device)
        } else {
            print("Error loading water texture")
        }
        
    }
    
    //Create the uniform buffer with enough size to hold data relating to the terrain, water, and skybox
    func buildUniformBuffer() {
        let uniformBufferLength = waterUniformOffset + sizeof(InstanceUniforms)
        self.uniformBuffer = self.device.newBufferWithLength(uniformBufferLength, options: MTLResourceOptions.CPUCacheModeDefaultCache)
        self.uniformBuffer.label = "Uniforms"
    }
    
    //Populate the uniform buffer with the data associated with the skybox
    func populateSkyboxUniforms() {
        let Z:float3 = float3(0, 0, 1)
        let skyboxModelMatrix:float4x4 = scalingMatrix(100.0) * rotationMatrix(Float(M_PI), Z) * matrix_identity()
        let skyboxNormalMatrix = skyboxModelMatrix.transpose.inverse
        var skyboxUniforms:InstanceUniforms = InstanceUniforms(modelMatrix: skyboxModelMatrix, normalMatrix: skyboxNormalMatrix)
        memcpy(self.uniformBuffer.contents() + skyboxUniformOffset, &skyboxUniforms, sizeof(InstanceUniforms))
    }
    
    //Pouplate the uniform buffer with the data associated with the terrain mesh
    func populateTerrainUniforms() {
        let terrainModelMatrix:float4x4 = matrix_identity()
        let terrainNormalMatrix = terrainModelMatrix.transpose.inverse
        var terrainUniforms:InstanceUniforms = InstanceUniforms(modelMatrix: terrainModelMatrix, normalMatrix: terrainNormalMatrix)
        memcpy(self.uniformBuffer.contents() + terrainUniformOffset, &terrainUniforms, sizeof(InstanceUniforms))
    }
    
    //Populate the uniform buffer with the data associated with the water mesh
    func populateWaterUniforms() {
        let waterOffsetVec:float3 = float3(0, waterLevel, 0)
        let waterModelMatrix = translationMatrix(waterOffsetVec)
        let waterNormalMatrix = waterModelMatrix.transpose.inverse
        var waterUniforms:InstanceUniforms = InstanceUniforms(modelMatrix: waterModelMatrix, normalMatrix: waterNormalMatrix)

        memcpy(self.uniformBuffer.contents() + waterUniformOffset, &waterUniforms, sizeof(InstanceUniforms))
    }
    
    //Make sure the camera sticks to the ground and can't go below it
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
    
    //Update the camera's position based on user input, update the viewProjection matrix accordingly
    func updateCamera() {
        var camPosition:float3 = self.cameraPosition
        
        self.cameraHeading += self.angularVelocity * self.frameDuration
        camPosition.x += -sin(self.cameraHeading) * self.velocity * self.frameDuration
        camPosition.z += -cos(self.cameraHeading) * self.velocity * self.frameDuration
        camPosition = self.constrainToTerrain(camPosition)
        camPosition.y += cameraHeight
        
        self.cameraPosition = camPosition
        self.reshape()
        
        let viewProjectionMatrix = projMatrix * viewMatrix
        var uniforms:Uniforms = Uniforms(viewProjection: viewProjectionMatrix)
        memcpy(self.uniformBuffer.contents() + sharedUniformOffset, &uniforms, sizeof(Uniforms))
    }
    
    //Build depth texture
    func buildDepthTexture() {
        let drawableSize:CGSize = self.mtkView.drawableSize
        let descriptor:MTLTextureDescriptor = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(MTLPixelFormat.Depth32Float, width: Int(drawableSize.width), height: Int(drawableSize.height), mipmapped: false)
        self.depthTexture = self.device.newTextureWithDescriptor(descriptor)
        self.depthTexture.label = "Depth Texture"
    }
    
    //Draw a mesh
    func drawInstancedMesh(mesh:Mesh, encoder:MTLRenderCommandEncoder, material:Material, instanceCount:Int) {
        encoder.setRenderPipelineState(material.pipelineState)
        encoder.setDepthStencilState(material.depthState)
        encoder.setFragmentSamplerState(self.sampler, atIndex: 0)
        encoder.setVertexBuffer(mesh.vertexBuffer, offset: 0, atIndex: 0)
        encoder.setFragmentTexture(material.diffuseTexture, atIndex: 0)
        encoder.drawIndexedPrimitives(MTLPrimitiveType.Triangle, indexCount: mesh.indexBuffer.length / sizeof(Index), indexType: MTLIndexType.UInt16, indexBuffer: mesh.indexBuffer, indexBufferOffset: 0, instanceCount: instanceCount)
    }
    
    //Draw the skybox
    func drawSkybox(encoder:MTLRenderCommandEncoder) {
        encoder.setRenderPipelineState(self.skyboxMesh.pipelineState)
        encoder.setDepthStencilState(self.skyboxMesh.depthState)
        encoder.setVertexBuffer(self.skyboxMesh.vertexBuffer, offset: 0, atIndex: 0)
        encoder.setVertexBuffer(self.uniformBuffer, offset: sharedUniformOffset, atIndex: 1)
        encoder.setVertexBuffer(self.uniformBuffer, offset: skyboxUniformOffset, atIndex: 2)
        encoder.setFragmentBuffer(self.uniformBuffer, offset: sharedUniformOffset, atIndex: 0)
        encoder.setFragmentTexture(self.skyboxTexture, atIndex: 0)
        encoder.setFragmentSamplerState(self.sampler, atIndex: 0)
        encoder.drawIndexedPrimitives(.Triangle, indexCount: self.skyboxMesh.indexBuffer.length / sizeof(Index), indexType: MTLIndexType.UInt16, indexBuffer: self.skyboxMesh.indexBuffer, indexBufferOffset: 0, instanceCount: 1)
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

    //Update view/projection matrix based on a change in orientation or initialization
    func reshape() {
        self.viewMatrix = createViewMatrix()
        if let drawable = self.mtkView.currentDrawable {
            let aspect = Float(drawable.layer.drawableSize.width / drawable.layer.drawableSize.height)
            let fov:Float = (aspect > 1) ? Float(M_PI / 4) : Float(M_PI / 3)
            self.projMatrix = projectionMatrix(0.1, far: 1000, aspect: aspect, fovy: fov)
        }
    }
    
    //Create a view matrix adjusted for camera height
    func createViewMatrix() -> float4x4 {
        let Y:vector_float3 = float3(0, 1, 0)
        let cameraPosition = self.cameraPosition
        return rotationMatrix(self.cameraHeading, Y) * translationMatrix(-cameraPosition)
    }
    
    //Draw the scene
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
            encoder.setCullMode(MTLCullMode.None)
            
            self.drawSkybox(encoder)
            
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



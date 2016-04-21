//
//  Node.swift
//  AdvancedGraphicsProject
//
//  Created by Mountain on 4/13/16.
//  Copyright © 2016 Ryan Milvenan. All rights reserved.
//

import Foundation
import Metal
import MetalKit
import GLKit

class Node {
    
    let name: String
    var meshes: [Mesh] = []
    var vertexDescriptor:MTLVertexDescriptor
    var device:MTLDevice
    
    
    var position: GLKVector3
    var rotateX:Float
    var rotateY:Float
    var rotateZ:Float
    var scale:Float
    var children:[Node] = []
    
    init(name: String, device:MTLDevice, assetPath:String, vertexDescriptor:MTLVertexDescriptor){
        self.name = name
        self.device = device
        self.vertexDescriptor = vertexDescriptor
        
        self.position = GLKVector3Make(0, 0, 0)
        self.rotateX = 0
        self.rotateY = 0
        self.rotateZ = 0
        self.scale = 1.0
        
        self.loadMeshesFromAsset(assetPath)

    }
    
    func loadMeshesFromAsset(assetPath:String)
    {
        
        let vertexAttributePosition:Int = VertexAttributes.VertexAttributePosition.rawValue
        let normalAttributePosition:Int = VertexAttributes.VertexAttributeNormal.rawValue
        let texcoordAttribute:Int = VertexAttributes.VertexAttributeTexcoord.rawValue
        
        let mdlVertexDescriptor:MDLVertexDescriptor = MTKModelIOVertexDescriptorFromMetal(self.vertexDescriptor)
        (mdlVertexDescriptor.attributes[vertexAttributePosition] as! MDLVertexAttribute).name = MDLVertexAttributePosition
        (mdlVertexDescriptor.attributes[normalAttributePosition] as! MDLVertexAttribute).name = MDLVertexAttributeNormal
        (mdlVertexDescriptor.attributes[texcoordAttribute] as! MDLVertexAttribute).name = MDLVertexAttributeTextureCoordinate
        
        let bufferAllocator:MTKMeshBufferAllocator = MTKMeshBufferAllocator(device: self.device)
        
        let assetURL:NSURL = NSBundle.mainBundle().URLForResource(assetPath, withExtension: ".obj")!
        
        let asset:MDLAsset = MDLAsset(URL: assetURL, vertexDescriptor: mdlVertexDescriptor, bufferAllocator: bufferAllocator)
        
        var mtkMeshes:NSArray?
        var mdlMeshes:NSArray?
        
        do {
            mtkMeshes = try MTKMesh.newMeshesFromAsset(asset, device: self.device, sourceMeshes: &mdlMeshes)
        } catch {
            print("Failed to create mesh")
        }
        
        for index in 0 ..< mtkMeshes!.count {
            let mtkMesh: MTKMesh = mtkMeshes![index] as! MTKMesh
            let mdlMesh: MDLMesh = mdlMeshes![index] as! MDLMesh
            let newMesh = Mesh(mtkMesh: mtkMesh, mdlMesh: mdlMesh, device: device)
            self.meshes.append(newMesh)
        }
    }
    
    func modelMatrix() -> GLKMatrix4 {
        var modelMatrix:GLKMatrix4 = GLKMatrix4Identity
        modelMatrix = GLKMatrix4Translate(modelMatrix, self.position.x, self.position.y, self.position.z)
        modelMatrix = GLKMatrix4Rotate(modelMatrix, self.rotateX, 1, 0, 0)
        modelMatrix = GLKMatrix4Rotate(modelMatrix, self.rotateY, 0, 1, 0)
        modelMatrix = GLKMatrix4Rotate(modelMatrix, self.rotateZ, 0, 0, 1)
        modelMatrix = GLKMatrix4Scale(modelMatrix, self.scale, self.scale, self.scale)
        
        return modelMatrix
    }
    
    func updateFrameUniforms(parentModelViewMatrix:float4x4, projectionMatrix:float4x4, frameUniformBuffers:[MTLBuffer], bufferIndex:Int) {
        let frameContentsPointer = UnsafeMutablePointer<FrameUniforms>(
            frameUniformBuffers[bufferIndex].contents()
        )
        var frameData = frameContentsPointer.memory
        frameData.model = convertToFloat4x4FromGLKMatrix(modelMatrix())
        frameData.view = parentModelViewMatrix
        let modelViewMatrix = frameData.view * frameData.model
        frameData.projectionView = projectionMatrix * modelViewMatrix
        frameData.normal = modelViewMatrix.transpose.inverse
        
        frameContentsPointer.memory = frameData
        
    }
    
    func renderWithParentModelViewMatrix(parentModelViewMatrix:float4x4, projectionMatrix:float4x4, encoder:MTLRenderCommandEncoder, frameBuffer:[MTLBuffer], bufferIdx:Int) {
        
        for child in self.children {
            child.renderWithParentModelViewMatrix(parentModelViewMatrix, projectionMatrix: projectionMatrix, encoder: encoder, frameBuffer: frameBuffer, bufferIdx: bufferIdx)
        }
        

        self.updateFrameUniforms(parentModelViewMatrix, projectionMatrix: projectionMatrix, frameUniformBuffers: frameBuffer, bufferIndex: bufferIdx)
        encoder.setVertexBuffer(
            frameBuffer[bufferIdx],
            offset: 0, atIndex: BufferIndex.FrameUniformBuffer.rawValue
        )
        encoder.pushDebugGroup("Rendering \(self.name)")
        for mesh in self.meshes {
            mesh.renderWithEncoder(encoder)
        }
        


    
        encoder.popDebugGroup()
    }
    
    func updateWithDelta(dt:NSTimeInterval) {
        for child in children {
            child.updateWithDelta(dt)
        }
    }
}
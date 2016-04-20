//
//  Sub.swift
//  AdvancedGraphicsProject
//
//  Created by Mountain on 4/20/16.
//  Copyright © 2016 Ryan Milvenan. All rights reserved.
//

import MetalKit
import Metal
import GLKit

class Sub:Node {
    override init(name: String, device: MTLDevice, assetPath: String, vertexDescriptor: MDLVertexDescriptor, bufferAllocator: MTKMeshBufferAllocator) {
        super.init(name: name, device: device, assetPath: assetPath, vertexDescriptor: vertexDescriptor, bufferAllocator: bufferAllocator)
        
        
        self.position = GLKVector3Make(0, 0, 7)
        self.scale = 0.2
        
    }
}
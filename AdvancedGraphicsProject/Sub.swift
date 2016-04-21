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
    override init(name: String, device: MTLDevice, assetPath: String, vertexDescriptor: MTLVertexDescriptor) {
        super.init(name: name, device: device, assetPath: assetPath, vertexDescriptor: vertexDescriptor)
        
        self.position = GLKVector3Make(0, 0, 7)
        self.scale = 0.2
        
        let sub = "models/tree/palm"
        
        let childSub = Tree(name: "Child Tree", device: device, assetPath: sub, vertexDescriptor: vertexDescriptor)
        
        childSub.position = GLKVector3Make(2, 3, 9)
        childSub.scale = 2

        self.children.append(childSub)
    }
}
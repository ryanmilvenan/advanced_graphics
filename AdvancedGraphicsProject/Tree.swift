//
//  Tree.swift
//  AdvancedGraphicsProject
//
//  Created by Mountain on 4/20/16.
//  Copyright © 2016 Ryan Milvenan. All rights reserved.
//

import MetalKit
import Metal
import GLKit

class Tree:Node {
    override init(name: String, device: MTLDevice, assetPath: String, vertexDescriptor: MTLVertexDescriptor) {
        super.init(name: name, device: device, assetPath: assetPath, vertexDescriptor: vertexDescriptor)
    }
}
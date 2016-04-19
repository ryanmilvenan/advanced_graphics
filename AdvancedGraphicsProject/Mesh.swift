//
//  Mesh.swift
//  AdvancedGraphicsProject
//
//  Created by Wind on 3/20/16.
//  Copyright © 2016 Ryan Milvenan. All rights reserved.
//


import Metal
import MetalKit

class Mesh {
    var mesh:MTKMesh?
    var submeshes: [Submesh] = []
    
    init(mtkMesh: MTKMesh, mdlMesh:MDLMesh, device:MTLDevice) {
        mesh = mtkMesh
        for i in 0 ..< mtkMesh.submeshes.count {
            let submesh = Submesh(mtkSubmesh: mtkMesh.submeshes[i], mdlSubmesh:mdlMesh.submeshes[i] as! MDLSubmesh, device: device)
            submeshes.append(submesh)
        }
    }
    
    func renderWithEncoder(encoder:MTLRenderCommandEncoder) {
        if let mesh = mesh {
            var bufferIndex = 0
            for vertexBuffer in mesh.vertexBuffers {
                encoder.setVertexBuffer(vertexBuffer.buffer, offset: vertexBuffer.offset, atIndex: bufferIndex)
                bufferIndex += 1
            }
            
            for submesh in submeshes {
                submesh.renderWithEncoder(encoder)
            }
        }
    }
}

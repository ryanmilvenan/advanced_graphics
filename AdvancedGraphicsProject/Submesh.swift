//
//  Submesh.swift
//  AdvancedGraphicsProject
//
//  Created by Wind on 3/20/16.
//  Copyright © 2016 Ryan Milvenan. All rights reserved.
//

import Metal
import MetalKit

class Submesh {
    
    var materialUniforms:MTLBuffer?
    var diffuseTexture:MTLTexture?
    var submesh:MTKSubmesh?
    
    init(mtkSubmesh:MTKSubmesh, mdlSubmesh:MDLSubmesh, device:MTLDevice) {
        materialUniforms = device.newBufferWithLength(sizeof(MaterialUniforms), options: MTLResourceOptions.CPUCacheModeDefaultCache)
        
        if let mu = materialUniforms {
            var matUni = UnsafeMutablePointer<MaterialUniforms>(mu.contents()).memory
            submesh = mtkSubmesh
            
            if let material = mdlSubmesh.material {
                if let property = material.propertyNamed("baseColorMap") {
                    if property.type == MDLMaterialPropertyType.String {
                        if let fileString = property.stringValue {
                            let file = "file://\(fileString)"
                            if let textureURL = NSURL(string:file) {
                                let textureLoader = MTKTextureLoader(device: device)
                                do {
                                    diffuseTexture = try textureLoader.newTextureWithContentsOfURL(textureURL, options: nil)
                                } catch _ {
                                    print("Failure loading diffuse texture")
                                }
                            }
                            
                        }
                    }
                } else if let property = material.propertyNamed("specular") {
                    if property.type == MDLMaterialPropertyType.Float4 {
                        matUni.specularColor = property.float4Value
                    } else if property.type == MDLMaterialPropertyType.Float3 {
                        let color = property.float3Value
                        matUni.specularColor = float4(color.x, color.y, color.z, 1.0)
                    }
                    
                } else if let property = material.propertyNamed("emission") {
                    if property.type == MDLMaterialPropertyType.Float4 {
                        matUni.emissiveColor = property.float4Value
                    } else if property.type == MDLMaterialPropertyType.Float3 {
                        let color = property.float3Value
                        matUni.emissiveColor = float4(color.x, color.y, color.z, 1.0)
                    }
                }
            }
        }
    }
    
    func renderWithEncoder(encoder:MTLRenderCommandEncoder) {
        if let dt = diffuseTexture {
            encoder.setFragmentTexture(dt, atIndex: TextureIndex.DiffuseTextureIndex.rawValue)
        }
        
        if let mat = materialUniforms {
            let index = BufferIndex.MaterialUniformBuffer.rawValue
            encoder.setFragmentBuffer(mat, offset: 0, atIndex: index)
            encoder.setVertexBuffer(mat, offset: 0, atIndex: index)
        }
        
        if let sub = submesh {
            encoder.drawIndexedPrimitives(sub.primitiveType,
                                          indexCount: sub.indexCount,
                                          indexType: sub.indexType,
                                          indexBuffer: sub.indexBuffer.buffer,
                                          indexBufferOffset: sub.indexBuffer.offset)
        }
    }
    
}
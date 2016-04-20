//
//  ShaderTypes.swift
//  AdvancedGraphicsProject
//
//  Created by Wind on 4/14/16.
//  Copyright © 2016 Ryan Milvenan. All rights reserved.
//

import Foundation
import simd

enum VertexAttributes:Int {
    case VertexAttributePosition = 0
    case VertexAttributeNormal = 1
    case VertexAttributeTexcoord = 2
}

/// Indices for texture bind points.
enum TextureIndex:Int {
    case DiffuseTextureIndex = 0
}

/// Indices for buffer bind points.
enum BufferIndex:Int  {
    case MeshVertexBuffer = 0
    case FrameUniformBuffer = 1
    case MaterialUniformBuffer = 2
}

/// Per frame uniforms.
struct FrameUniforms {
    var model:float4x4
    var view:float4x4
    var projection:float4x4
    var projectionView:float4x4
    var normal:float4x4
}

/// Material uniforms.
struct MaterialUniforms {
    var emissiveColor:float4
    var diffuseColor:float4
    var specularColor:float4
    
    var specularIntensity:Float
    var pad1:Float
    var pad2:Float
    var pad3:Float
}
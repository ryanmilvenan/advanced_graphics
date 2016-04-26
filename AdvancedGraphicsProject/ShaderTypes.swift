//
//  ShaderTypes.swift
//  AdvancedGraphicsProject
//
//  Created by Mountain on 4/10/16.
//  Copyright © 2016 Ryan Milvenan. All rights reserved.
//

import simd

typealias Index = UInt16

struct Uniforms {
    var viewProjection:float4x4
}

struct InstanceUniforms {
    var modelMatrix:float4x4
    var normalMatrix:float4x4
}

struct Vertex {
    var position:float4
    var normal:float4
    var diffuseColor:float4
    var texCoords:float2

    init(pos:float4, norm:float4, diffColor:float4, tex:float2) {
        position = pos
        normal = norm
        diffuseColor = diffColor
        texCoords = tex
    }
}

struct SkyVertex {
    var position:float4
    var normal:float4
}
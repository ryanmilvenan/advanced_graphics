//
//  ShaderTypes.swift
//  AdvancedGraphicsProject
//
//  Created by Mountain on 4/20/16.
//  Copyright © 2016 Ryan Milvenan. All rights reserved.
//

import Foundation
import simd

typealias Index = __uint16_t

struct Uniforms {
    var viewProjection:float4x4
}

struct InstanceUniforms {
    var modelMatrix:float4x4
    var normalMatrix:float4x4
}

struct Vertex {
    var position:packed_float4
    var normal:packed_float4
    var diffuseColor:packed_float4
    var texCoords:packed_float2

    init(pos:float4, norm:float4, diffColor:float4, tex:float2) {
        position = pos
        normal = norm
        diffuseColor = diffColor
        texCoords = tex
    }
}
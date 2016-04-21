//
//  Math.swift
//  AdvancedGraphicsProject
//
//  Created by Mountain on 4/21/16.
//  Copyright © 2016 Ryan Milvenan. All rights reserved.
//

import Foundation
import simd

func vector_orthogonal(v:vector_float3) -> vector_float3 {
    return fabsf(v.x) > fabsf(v.z) ? vector_float3(-v.y, v.x, 0.0) : vector_float3(0.0, -v.z, v.y)
}

func matrix_identity() -> matrix_float4x4 {
    return matrix_identity_float4x4
}

func matrix_rotation(axis:vector_float3, angle:Float) -> matrix_float4x4 {
    let c:Float = cos(angle)
    let s:Float = sin(angle)
    
    var X:vector_float4 = vector_float4()
    X.x = axis.x * axis.x + (1 - axis.x * axis.x) * c;
    X.y = axis.x * axis.y * (1 - c) - axis.z*s;
    X.z = axis.x * axis.z * (1 - c) + axis.y * s;
    X.w = 0.0;
    
    var Y:vector_float4 = vector_float4()
    Y.x = axis.x * axis.y * (1 - c) + axis.z * s;
    Y.y = axis.y * axis.y + (1 - axis.y * axis.y) * c;
    Y.z = axis.y * axis.z * (1 - c) - axis.x * s;
    Y.w = 0.0;
    
    var Z:vector_float4 = vector_float4()
    Z.x = axis.x * axis.z * (1 - c) - axis.y * s;
    Z.y = axis.y * axis.z * (1 - c) + axis.x * s;
    Z.z = axis.z * axis.z + (1 - axis.z * axis.z) * c;
    Z.w = 0.0;
    
    var W:vector_float4 = vector_float4()
    W.x = 0.0;
    W.y = 0.0;
    W.z = 0.0;
    W.w = 1.0;
    
    let m:matrix_float4x4 = matrix_float4x4(columns: (X, Y, Z, W))
    return m
}

func matrix_translation(t:vector_float3) -> matrix_float4x4 {
    let X:vector_float4 = vector_float4(1, 0, 0 ,0)
    let Y:vector_float4 = vector_float4(0, 1, 0 ,0)
    let Z:vector_float4 = vector_float4(0, 0, 1 ,0)
    let W:vector_float4 = vector_float4(t.x, t.y, t.z ,1)
    
    let m:matrix_float4x4 = matrix_float4x4(columns: (X, Y, Z, W))
    return m
}

func matrix_scale(s:vector_float3) -> matrix_float4x4 {
    let X:vector_float4 = vector_float4(s.x,   0,   0, 0)
    let Y:vector_float4 = vector_float4(  0, s.y,   0, 0)
    let Z:vector_float4 = vector_float4(  0,   0, s.z, 0)
    let W:vector_float4 = vector_float4(  0,   0,   0, 1)
    
    let m:matrix_float4x4 = matrix_float4x4(columns: (X, Y, Z, W))
    return m
}

func matrix_scale_uniform(s:Float) -> matrix_float4x4 {
    let X:vector_float4 = vector_float4(s, 0, 0, 0)
    let Y:vector_float4 = vector_float4(0, s, 0, 0)
    let Z:vector_float4 = vector_float4(0, 0, s, 0)
    let W:vector_float4 = vector_float4(0, 0, 0, 1)
    
    let m:matrix_float4x4 = matrix_float4x4(columns: (X, Y, Z, W))
    return m
}

func matrix_perspective_projection(aspect:Float, fovy:Float, near:Float, far:Float) -> matrix_float4x4 {
    let yScale:Float = 1 / tan(fovy * 0.5)
    let xScale:Float = yScale / aspect
    let zRange:Float = far - near
    let zScale:Float = -(far + near) / zRange
    let wzScale:Float = -2 * far * near / zRange
    
    let P:vector_float4 = vector_float4(xScale, 0, 0, 0)
    let Q:vector_float4 = vector_float4(0, yScale, 0, 0)
    let R:vector_float4 = vector_float4(0, 0, zScale, 0)
    let S:vector_float4 = vector_float4(0, 0, wzScale,0)
    
    let m:matrix_float4x4 = matrix_float4x4(columns: (P, Q, R, S))
    return m
}

func matrix_extract_linear(matrix:matrix_float4x4) -> matrix_float4x4 {
    var lin:matrix_float4x4 = matrix
    lin.columns.0.z = 0
    lin.columns.1.z = 0
    lin.columns.2.z = 0
    lin.columns.3 = vector_float4(0, 0, 0, 1)
    return lin
}

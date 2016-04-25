//
//  Math.swift
//  AdvancedGraphicsProject
//
//  Created by Mountain on 4/21/16.
//  Copyright © 2016 Ryan Milvenan. All rights reserved.
//

import Foundation
import simd

func vector_orthogonal(v:float3) -> float3 {
    return fabsf(v.x) > fabsf(v.z) ? float3(-v.y, v.x, 0.0) : float3(0.0, -v.z, v.y)
}

func matrix_identity() -> float4x4 {
    return float4x4(matrix_identity_float4x4)
}

func matrix_rotation(axis:float3, angle:Float) -> float4x4 {
    let c:Float = cos(angle)
    let s:Float = sin(angle)
    
    var X:float4 = float4()
    X.x = axis.x * axis.x + (1 - axis.x * axis.x) * c;
    X.y = axis.x * axis.y * (1 - c) - axis.z*s;
    X.z = axis.x * axis.z * (1 - c) + axis.y * s;
    X.w = 0.0;
    
    var Y:float4 = float4()
    Y.x = axis.x * axis.y * (1 - c) + axis.z * s;
    Y.y = axis.y * axis.y + (1 - axis.y * axis.y) * c;
    Y.z = axis.y * axis.z * (1 - c) - axis.x * s;
    Y.w = 0.0;
    
    var Z:float4 = float4()
    Z.x = axis.x * axis.z * (1 - c) - axis.y * s;
    Z.y = axis.y * axis.z * (1 - c) + axis.x * s;
    Z.z = axis.z * axis.z + (1 - axis.z * axis.z) * c;
    Z.w = 0.0;
    
    var W:float4 = float4()
    W.x = 0.0;
    W.y = 0.0;
    W.z = 0.0;
    W.w = 1.0;
    
    let m:float4x4 = float4x4([X, Y, Z, W])
    return m
}

func matrix_translation(t:float3) -> float4x4 {
    let X:float4 = float4(1, 0, 0 ,0)
    let Y:float4 = float4(0, 1, 0 ,0)
    let Z:float4 = float4(0, 0, 1 ,0)
    let W:float4 = float4(t.x, t.y, t.z ,1)
    
    let m:float4x4 = float4x4([X, Y, Z, W])
    return m
}

func matrix_scale(s:float3) -> float4x4 {
    let X:float4 = float4(s.x,   0,   0, 0)
    let Y:float4 = float4(  0, s.y,   0, 0)
    let Z:float4 = float4(  0,   0, s.z, 0)
    let W:float4 = float4(  0,   0,   0, 1)
    
    let m:float4x4 = float4x4([X, Y, Z, W])
    return m
}

func matrix_scale_uniform(s:Float) -> float4x4 {
    let X:float4 = float4(s, 0, 0, 0)
    let Y:float4 = float4(0, s, 0, 0)
    let Z:float4 = float4(0, 0, s, 0)
    let W:float4 = float4(0, 0, 0, 1)
    
    let m:float4x4 = float4x4([X, Y, Z, W])
    return m
}

func matrix_perspective_projection(aspect:Float, fovy:Float, near:Float, far:Float) -> float4x4 {
    let yScale:Float = 1 / tan(fovy * 0.5)
    let xScale:Float = yScale / aspect
    let zRange:Float = far - near
    let zScale:Float = -(far + near) / zRange
    let wzScale:Float = -2 * far * near / zRange
    
    let P:float4 = float4(xScale, 0, 0, 0)
    let Q:float4 = float4(0, yScale, 0, 0)
    let R:float4 = float4(0, 0, zScale, 0)
    let S:float4 = float4(0, 0, wzScale,0)
    
    let m:float4x4 = float4x4([P, Q, R, S])
    return m
}

func matrix_extract_linear(matrix:float4x4) -> float4x4 {
    let row1 = float4(matrix.cmatrix.columns.0.x, matrix.cmatrix.columns.1.x, matrix.cmatrix.columns.2.x, 0)
    let row2 = float4(matrix.cmatrix.columns.0.y, matrix.cmatrix.columns.1.y, matrix.cmatrix.columns.2.y, 0)
    let row3 = float4(matrix.cmatrix.columns.0.z, matrix.cmatrix.columns.1.z, matrix.cmatrix.columns.2.z, 0)
    let row4 = float4(0, 0, 0, 1)
    
    let m:float4x4 = float4x4([row1, row2, row3, row4])
    return m
}

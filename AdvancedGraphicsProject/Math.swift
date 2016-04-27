//
//  Math.swift
//  AdvancedGraphicsProject
//
//  Created by Mountain on 4/11/16.
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

func translationMatrix(position: float3) -> float4x4 {
    let X = vector_float4(1, 0, 0, 0)
    let Y = vector_float4(0, 1, 0, 0)
    let Z = vector_float4(0, 0, 1, 0)
    let W = vector_float4(position.x, position.y, position.z, 1)
    return float4x4([X, Y, Z, W])
}

func scalingMatrix(scale: Float) -> float4x4 {
    let X = vector_float4(scale, 0, 0, 0)
    let Y = vector_float4(0, scale, 0, 0)
    let Z = vector_float4(0, 0, scale, 0)
    let W = vector_float4(0, 0, 0, 1)
    return float4x4([X, Y, Z, W])
}

func rotationMatrix(angle: Float, _ axis: float3) -> float4x4 {
    var X = vector_float4(0, 0, 0, 0)
    X.x = axis.x * axis.x + (1 - axis.x * axis.x) * cos(angle)
    X.y = axis.x * axis.y * (1 - cos(angle)) - axis.z * sin(angle)
    X.z = axis.x * axis.z * (1 - cos(angle)) + axis.y * sin(angle)
    X.w = 0.0
    var Y = vector_float4(0, 0, 0, 0)
    Y.x = axis.x * axis.y * (1 - cos(angle)) + axis.z * sin(angle)
    Y.y = axis.y * axis.y + (1 - axis.y * axis.y) * cos(angle)
    Y.z = axis.y * axis.z * (1 - cos(angle)) - axis.x * sin(angle)
    Y.w = 0.0
    var Z = vector_float4(0, 0, 0, 0)
    Z.x = axis.x * axis.z * (1 - cos(angle)) - axis.y * sin(angle)
    Z.y = axis.y * axis.z * (1 - cos(angle)) + axis.x * sin(angle)
    Z.z = axis.z * axis.z + (1 - axis.z * axis.z) * cos(angle)
    Z.w = 0.0
    let W = vector_float4(0, 0, 0, 1)
    return float4x4([X, Y, Z, W])
}

func projectionMatrix(near: Float, far: Float, aspect: Float, fovy: Float) ->float4x4 {
    let scaleY = 1 / tan(fovy * 0.5)
    let scaleX = scaleY / aspect
    let scaleZ = -(far + near) / (far - near)
    let scaleW = -2 * far * near / (far - near)
    let X = vector_float4(scaleX, 0, 0, 0)
    let Y = vector_float4(0, scaleY, 0, 0)
    let Z = vector_float4(0, 0, scaleZ, -1)
    let W = vector_float4(0, 0, scaleW, 0)
    return float4x4([X, Y, Z, W])
}

func percent(start:Float, end:Float) -> Float {
    return start / end
}

func lerp( percent: Float, start: Float, end: Float ) -> Float {
    return start + ( percent * ( end - start ) )
}

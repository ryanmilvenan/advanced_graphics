//
//  Shaders.metal
//  AdvancedGraphicsProject
//
//  Created by Wind on 3/20/16.
//  Copyright © 2016 Ryan Milvenan. All rights reserved.
//

#include <metal_stdlib>
#include <simd/simd.h>
#include <metal_texture>
#include <metal_matrix>
#include <metal_geometric>
#include <metal_math>
#include <metal_graphics>

using namespace simd;
using namespace metal;

enum VertexAttributes {
    VertexAttributePosition = 0,
    VertexAttributeNormal   = 1,
    VertexAttributeTexcoord = 2,
};
    
enum TextureIndex {
    DiffuseTextureIndex = 0
};

enum BufferIndex  {
    MeshVertexBuffer      = 0,
    FrameUniformBuffer    = 1,
    MaterialUniformBuffer = 2,
};
            
struct FrameUniforms {
    float4x4 model;
    float4x4 view;
    float4x4 projection;
    float4x4 projectionView;
    float4x4 normal;
};
            
struct MaterialUniforms {
    float4 emissiveColor;
    float4 diffuseColor;
    float4 specularColor;
    
    float specularIntensity;
    float pad1;
    float pad2;
    float pad3;
};
            

// Variables in constant address space.
constant float3 lightPosition = float3(0.0, 0.0, -1.0);

// Per-vertex input structure
struct VertexInput {
    float3 position [[attribute(VertexAttributePosition)]];
    float3 normal   [[attribute(VertexAttributeNormal)]];
    half2  texcoord [[attribute(VertexAttributeTexcoord)]];
};

// Per-vertex output and per-fragment input
typedef struct {
    float4 position [[position]];
    half2  texcoord;
    half4  color;
} ShaderInOut;

// Vertex shader function
vertex ShaderInOut vertexShader(VertexInput in [[stage_in]],
                               constant FrameUniforms& frameUniforms [[ buffer(FrameUniformBuffer) ]],
                               constant MaterialUniforms& materialUniforms [[ buffer(MaterialUniformBuffer) ]]) {
    ShaderInOut out;
    
    // Vertex projection and translation
    float4 in_position = float4(in.position, 1.0);
    out.position = frameUniforms.projectionView * in_position;
    
    // Per vertex lighting calculations
    float4 eye_normal = normalize(frameUniforms.normal * float4(in.normal, 0.0));
    float n_dot_l = dot(eye_normal.rgb, normalize(lightPosition));
    n_dot_l = fmax(0.0, n_dot_l);
    out.color = half4(materialUniforms.emissiveColor + n_dot_l +1.0);
    
    // Pass through texture coordinate
    out.texcoord = in.texcoord;
    
    return out;
}

// Fragment shader function
fragment half4 fragmentShader(ShaderInOut in [[stage_in]],
                             texture2d<half>  diffuseTexture [[ texture(DiffuseTextureIndex) ]]) {
    constexpr sampler defaultSampler;
    
    // Blend texture color with input color and output to framebuffer
    half4 color =  diffuseTexture.sample(defaultSampler, float2(in.texcoord)) * in.color;
    
    return color;
}
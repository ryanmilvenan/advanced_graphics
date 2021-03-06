//
//  Shaders.metal
//  AdvancedGraphicsProject
//
//  Created by Mountain on 4/21/16.
//  Copyright © 2016 Ryan Milvenan. All rights reserved.
//
#include <metal_stdlib>
using namespace metal;

constant float3 kLightDirection(0.2, -0.96, 0.2);

constant float kMinDiffuseIntensity = 0.5;

struct Vertex
{
    float4 position [[attribute(0)]];
    float4 normal [[attribute(1)]];
    float4 diffuseColor [[attribute(2)]];
    float2 texCoords [[attribute(3)]];
};

struct VertexOut
{
    float4 position [[position]];
    float4 normal;
    float4 diffuseColor;
    float2 texCoords;
};

struct SkyVertex
{
    float4 position [[position]];
    float4 normal;
};

struct SkyVertOut
{
    float4 position [[position]];
    float4 texCoords;
};

struct Uniforms
{
    float4x4 viewProjectionMatrix;
};

struct InstanceUniforms
{
    float4x4 modelMatrix;
    float4x4 normalMatrix;
};

vertex VertexOut vertexShader(constant Vertex *vertices [[buffer(0)]],
                                      constant Uniforms &uniforms [[buffer(1)]],
                                      constant InstanceUniforms *instanceUniforms [[buffer(2)]],
                                      ushort vid [[vertex_id]],
                                      ushort iid [[instance_id]])
{
    float4x4 modelMatrix = instanceUniforms[iid].modelMatrix;
    float4x4 normalMatrix = instanceUniforms[iid].normalMatrix;
    
    VertexOut outVert;
    outVert.position = uniforms.viewProjectionMatrix * modelMatrix * float4(vertices[vid].position);
    outVert.normal = normalMatrix * float4(vertices[vid].normal);
    outVert.diffuseColor = vertices[vid].diffuseColor;
    outVert.texCoords = vertices[vid].texCoords;
    
    return outVert;
}

fragment half4 fragmentShader(VertexOut vert [[stage_in]],
                                texture2d<float, access::sample> texture [[texture(0)]],
                                sampler texSampler [[sampler(0)]])
{
    float4 vertexColor = vert.diffuseColor;
    if(vertexColor.a <= 0.05) {
        discard_fragment();
    }
    float4 textureColor = texture.sample(texSampler, vert.texCoords);

    
    float diffuseIntensity = max(kMinDiffuseIntensity, dot(normalize(vert.normal.xyz), -kLightDirection));
    float4 color = diffuseIntensity * textureColor * vertexColor;
    
    return half4(color.r, color.g, color.b, vertexColor.a);
}

vertex SkyVertOut vertex_skybox(device SkyVertex *vertices     [[buffer(0)]],
                                     constant Uniforms &uniforms [[buffer(1)]],
                                     constant InstanceUniforms *instanceUniforms [[buffer(2)]],
                                     ushort vid [[vertex_id]],
                                     ushort iid [[instance_id]])
{
    float4 position = vertices[vid].position;
    float4x4 modelMatrix = instanceUniforms[iid].modelMatrix;
    float4x4 normalMatrix = instanceUniforms[iid].normalMatrix;
    
    SkyVertOut outVert;
    outVert.position = uniforms.viewProjectionMatrix * modelMatrix * position;
    outVert.texCoords = position;
    return outVert;
}

fragment half4 fragment_cube_lookup(SkyVertOut vert          [[stage_in]],
                                    constant Uniforms &uniforms   [[buffer(0)]],
                                    texturecube<half> cubeTexture [[texture(0)]],
                                    sampler cubeSampler           [[sampler(0)]])
{
    float3 texCoords = float3(vert.texCoords.x, vert.texCoords.y, -vert.texCoords.z);
    return cubeTexture.sample(cubeSampler, texCoords);
}

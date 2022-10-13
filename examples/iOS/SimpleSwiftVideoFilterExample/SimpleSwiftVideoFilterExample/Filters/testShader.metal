//
//  test.swift
//  alfred
//
//  Created by Hongten Ko on 2022/10/5.
//  Copyright © 2022 Alfred Labs Inc. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float4 position [[position]];
    float2 texCoord;
};

struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
};

vertex VertexOut vertex_func(constant VertexIn *vertices [[buffer(0)]],
                          uint vid [[vertex_id]]) {
    VertexOut out;
    out.position = vertices[vid].position;
    out.texCoord = vertices[vid].texCoord;
    return out;
}

fragment half4 fragment_func(VertexOut in [[stage_in]],
                              texture2d<half> texture [[texture(0)]]) {
    constexpr sampler sampler(min_filter::nearest,
                              mag_filter::linear,
                              mip_filter::linear);
    half4 color = texture.sample(sampler, in.texCoord.xy);
    return color;
}


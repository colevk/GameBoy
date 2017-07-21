//
//  Shaders.metal
//  GameBoy
//
//  Created by Cole van Krieken on 7/14/17.
//  Copyright (c) 2017 Cole van Krieken. All rights reserved.
//

#include <metal_stdlib>

using namespace metal;

struct Vertex
{
    float4 position [[position]];
};

vertex Vertex passThroughVertex(uint vid [[ vertex_id ]],
                                constant packed_float4* position  [[ buffer(0) ]])
{
    Vertex outVertex;
    outVertex.position = position[vid];
    return outVertex;
};

fragment half4 passThroughFragment(Vertex inFrag [[stage_in]],
                                   constant uchar* pixels [[ buffer(0) ]]) {
    uchar color = pixels[int(inFrag.position.x / 6) + int(inFrag.position.y / 6) * 160];
    if (color == 0) {
        return half4(1.0 , 1.0 , 1.0, 1.0);
    } else if (color == 1) {
        return half4(0.66 , 0.66 , 0.66, 1.0);
    } else if (color == 2) {
        return half4(0.33 , 0.33 , 0.33, 1.0);
    } else {
        return half4(0.0 , 0.0 , 0.0, 1.0);
    }
};

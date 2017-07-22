//
//  Shaders.metal
//  GameBoy
//
//  Created by Cole van Krieken on 7/14/17.
//  Copyright (c) 2017 Cole van Krieken. All rights reserved.
//

#include <metal_stdlib>

#define BACKGROUND_ON   0b00000001
#define SPRITES_ON      0b00000010
#define SPRITE_SIZE     0b00000100
#define BG_TILE_MAP     0b00001000
#define BG_TILE_SET     0b00010000
#define WINDOW_ON       0b00100000
#define WINDOW_TILE_MAP 0b01000000
#define DISPLAY_ON      0b10000000


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
                                   constant uchar* ram [[ buffer(0) ]],
                                   constant uchar* oam [[ buffer(1) ]],
                                   constant uchar* attributes [[ buffer(2) ]]) {
    int x = int(inFrag.position.x / 6);
    int y = int(inFrag.position.y / 6);
    uchar attr = attributes[y * 4];
    uchar scy = attributes[y * 4 + 1];
    uchar scx = attributes[y * 4 + 2];
    uchar palette = attributes[y * 4 + 3];

    // If display off, return white
    if (!(attr & DISPLAY_ON)) {
        return half4(1.0 , 1.0 , 1.0, 1.0);
    }

    // if background on
    if (attr & BACKGROUND_ON) {
        uchar bgy = y + scy;
        uchar bgx = x + scx;
        uchar tiley = bgy / 8 % 32;
        uchar tilex = bgx / 8 % 32;
        int tilenum = tilex + tiley * 32;

        uchar tileaddr = 0;
        // check which tile map to use
        if (attr & BG_TILE_MAP) {
            // tile map 1 starts at 0x1C00
            tileaddr = ram[0x1C00 + tilenum];
        } else {
            // tile map 0 starts at 0x1800
            tileaddr = ram[0x1800 + tilenum];
        }

        int tilestart = 0;
        // check which tileset to use
        if (attr & BG_TILE_SET || tileaddr > 127) {
            tilestart = tileaddr * 16;
        } else {
            tilestart = 0x1000 + tileaddr * 16;
        }

        uchar pixely = bgy % 8;
        uchar pixelx = bgx % 8;
        uchar paletteidx =
            ((ram[tilestart + pixely * 2] & (0b10000000 >> pixelx)) >> (7 - pixelx)) +
            ((ram[tilestart + pixely * 2 + 1] & (0b10000000 >> pixelx)) >> (7 - pixelx) << 1);

        uchar color = (palette >> (paletteidx * 2)) & 0b00000011;

        if (color == 0) {
            return half4(1.0 , 1.0 , 1.0, 1.0);
        } else if (color == 1) {
            return half4(0.66 , 0.66 , 0.66, 1.0);
        } else if (color == 2) {
            return half4(0.33 , 0.33 , 0.33, 1.0);
        } else {
            return half4(0.0 , 0.0 , 0.0, 1.0);
        }
    }

    // Nothing at this pixel, return white
    return half4(1.0 , 1.0 , 1.0, 1.0);
};

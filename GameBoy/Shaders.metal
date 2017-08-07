//
//  Shaders.metal
//  GameBoy
//
//  Created by Cole van Krieken on 7/14/17.
//  Copyright (c) 2017 Cole van Krieken. All rights reserved.
//

#include <metal_stdlib>

//#define GB_COLOR_0 half4(0.608, 0.737, 0.059, 1.0)
//#define GB_COLOR_1 half4(0.545, 0.675, 0.059, 1.0)
//#define GB_COLOR_2 half4(0.188, 0.384, 0.188, 1.0)
//#define GB_COLOR_3 half4(0.059, 0.220, 0.059, 1.0)

#define GB_COLOR_0 half4(1.0, 1.0, 1.0, 1.0)
#define GB_COLOR_1 half4(0.66, 0.66, 0.66, 1.0)
#define GB_COLOR_2 half4(0.33, 0.33, 0.33, 1.0)
#define GB_COLOR_3 half4(0.0, 0.0, 0.0, 1.0)

#define BACKGROUND_ON   0b00000001
#define SPRITES_ON      0b00000010
#define SPRITE_SIZE     0b00000100
#define BG_TILE_MAP     0b00001000
#define TILE_SET        0b00010000
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

    uchar control = attributes[y * 8];
    uchar scrollY = attributes[y * 8 + 1];
    uchar scrollX = attributes[y * 8 + 2];
//    uchar spritePalette0 = attributes[y * 8 + 3];
//    uchar spritePalette1 = attributes[y * 8 + 4];
    uchar windowY = attributes[y * 8 + 5];
    uchar windowX = attributes[y * 8 + 6];
    uchar bgPalette = attributes[y * 8 + 7];

    // If display off, return color 0
    if (!(control & DISPLAY_ON)) {
        return GB_COLOR_0;
    }

    // If sprites on, handle foreground sprites
    if (control & SPRITES_ON) {
        // TODO: implement sprites
    }

    // If window or background on
    bool windowPixel = control & WINDOW_ON && y >= windowY && x >= windowX;
    if (windowPixel || control & BACKGROUND_ON) {
        uchar posY;
        uchar posX;
        if (windowPixel) {
            posY = y - windowY;
            posX = x - windowX;
        } else {
            posY = (y + scrollY) % 256;
            posX = (x + scrollX) % 256;
        }

        int tileY = posY / 8;
        int tileX = posX / 8;
        int tilenum = tileX + tileY * 32;

        int tileAddr;
        // check which tile map to use
        if ((windowPixel && control & WINDOW_TILE_MAP) ||
            (!windowPixel && control & BG_TILE_MAP)) {
            // tile map 1 starts at 0x1C00
            tileAddr = ram[0x1C00 + tilenum];
        } else {
            // tile map 0 starts at 0x1800
            tileAddr = ram[0x1800 + tilenum];
        }

        int tileStart;
        // check which tileset to use
        if (control & TILE_SET || tileAddr > 127) {
            tileStart = tileAddr * 16;
        } else {
            tileStart = 0x1000 + tileAddr * 16;
        }

        uchar pixelY = posY % 8;
        uchar pixelX = posX % 8;
        uchar paletteIdx =
            ((ram[tileStart + pixelY * 2] & (0x80 >> pixelX)) >> (7 - pixelX)) +
            ((ram[tileStart + pixelY * 2 + 1] & (0x80 >> pixelX)) >> (7 - pixelX) << 1);

        uchar color = (bgPalette >> (paletteIdx * 2)) & 0b11;

        switch (color) {
        case 1: return GB_COLOR_1;
        case 2: return GB_COLOR_2;
        case 3: return GB_COLOR_3;
        }
        // Color 0 is transparent, check for sprites underneath
    }

    // If sprites on, handle background sprites
    if (control & SPRITES_ON) {
        // TODO: implement sprites
    }

    // Nothing at this pixel, return color 0
    return GB_COLOR_0;
};

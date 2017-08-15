//
//  Shaders.metal
//  GameBoy
//
//  Created by Cole van Krieken on 7/14/17.
//  Copyright (c) 2017 Cole van Krieken. All rights reserved.
//

#include <metal_stdlib>

#define COLOR_0 half4(1.0, 1.0, 1.0, 1.0)
#define COLOR_1 half4(0.66, 0.66, 0.66, 1.0)
#define COLOR_2 half4(0.33, 0.33, 0.33, 1.0)
#define COLOR_3 half4(0.0, 0.0, 0.0, 1.0)

#define BACKGROUND_ON   0x01
#define SPRITES_ON      0x02
#define SPRITE_SIZE     0x04
#define BG_TILE_MAP     0x08
#define TILE_SET        0x10
#define WINDOW_ON       0x20
#define WINDOW_TILE_MAP 0x40
#define DISPLAY_ON      0x80

#define SPRITE_PALETTE  0x10
#define SPRITE_X_FLIP   0x20
#define SPRITE_Y_FLIP   0x40
#define SPRITE_PRIORITY 0x80

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
                                   constant uchar* spriteOrder [[ buffer(2) ]],
                                   constant uchar* attributes [[ buffer(3) ]]) {
    int x = int(inFrag.position.x / 6);
    int y = int(inFrag.position.y / 6);

    uchar control = attributes[y * 8];
    uchar scrollY = attributes[y * 8 + 1];
    uchar scrollX = attributes[y * 8 + 2];
    uchar spritePalette0 = attributes[y * 8 + 3];
    uchar spritePalette1 = attributes[y * 8 + 4];
    uchar windowY = attributes[y * 8 + 5];
    uchar windowX = attributes[y * 8 + 6];
    uchar bgPalette = attributes[y * 8 + 7];

    // If display off, return color 0
    if (!(control & DISPLAY_ON)) {
        return COLOR_0;
    }

    // If sprites on, handle foreground sprites
    bool foundBackgroundSprite = false;
    uchar backgroundSpriteColor = 0;
    if (control & SPRITES_ON) {
        bool bigSprites = control & SPRITE_SIZE;
        for (int i = 0; i < 40; i++) {
            int spriteIdx = spriteOrder[i];
            uchar spriteY = oam[spriteIdx * 4];
            uchar spriteX = oam[spriteIdx * 4 + 1];
            uchar spriteTile = oam[spriteIdx * 4 + 2];
            uchar spriteFlags = oam[spriteIdx * 4 + 3];

            if (x >= spriteX || x < spriteX - 8 || y >= spriteY - (bigSprites ? 0 : 8) || y < spriteY - 16) {
                continue;
            }

            uchar tileX = x - spriteX + 8;
            uchar tileY = y - spriteY + 16;
            if (spriteFlags & SPRITE_X_FLIP) {
                tileX = 8 - tileX;
            }
            if (spriteFlags & SPRITE_Y_FLIP) {
                tileY = (bigSprites ? 16 : 8) - tileY;
            }

            int tileStart;
            if (bigSprites) {
                tileStart = ((spriteTile & 0xFE) + (tileY >= 8 ? 0 : 1)) * 16;
            } else {
                tileStart = spriteTile * 16;
            }

            uchar paletteIdx =
                ((ram[tileStart + tileY * 2] & (0x80 >> tileX)) >> (7 - tileX)) +
                ((ram[tileStart + tileY * 2 + 1] & (0x80 >> tileX)) >> (7 - tileX) << 1);
            if (paletteIdx == 0) {
                continue;
            }

            uchar palette = (spriteFlags & SPRITE_PALETTE) ? spritePalette1 : spritePalette0;
            uchar color = (palette >> (paletteIdx * 2)) & 0b11;
            if (spriteFlags & SPRITE_PRIORITY) {
                foundBackgroundSprite = true;
                backgroundSpriteColor = color;
                break;
            } else {
                switch (color) {
                    case 0: return COLOR_0;
                    case 1: return COLOR_1;
                    case 2: return COLOR_2;
                    case 3: return COLOR_3;
                }
            }
        }
    }

    // If window or background on
    bool windowPixel = control & WINDOW_ON && y >= windowY && x >= windowX;
    if (windowPixel || control & BACKGROUND_ON) {
        uchar posY;
        uchar posX;
        if (windowPixel) {
            posY = y - windowY;
            posX = x - windowX + 7;
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
        case 1: return COLOR_1;
        case 2: return COLOR_2;
        case 3: return COLOR_3;
        }
        // Color 0 is transparent, check for sprites underneath
    }

    if (foundBackgroundSprite) {
        switch (backgroundSpriteColor) {
            case 0: return COLOR_0;
            case 1: return COLOR_1;
            case 2: return COLOR_2;
            case 3: return COLOR_3;
        }
    }

    // Nothing at this pixel, return color 0
    return COLOR_0;
};


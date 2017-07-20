//
//  GPU.swift
//  GameBoy
//
//  Created by Cole van Krieken on 7/20/17.
//  Copyright © 2017 Cole van Krieken. All rights reserved.
//

import Foundation

public class GPU {
    
    unowned let mem: Memory
    public var screen: [UInt8]
    
    public init(withMemory memory: Memory) {
        mem = memory
        screen = [UInt8](repeating: 0, count: 160 * 144)
        for x in 0..<screen.count {
            screen[x] = UInt8(x % 4)
        }
    }
    
    let controlBitsAddr: UInt16 = 0xFF40
    let scyAddr: UInt16 = 0xFF42
    let scxAddr: UInt16 = 0xFF43
    let scanlineAddr: UInt16 = 0xFF44
    let paletteAddr: UInt16 = 0xFF47
    
    private var scx: UInt8 = 0
    private var scy: UInt8 = 0
    private var line: UInt8 = 0
    
    private var background: Bool = false
    private var sprites: Bool = false
    private var spriteSize: SpriteSize = .eightByEight
    private var bgTileMap: UInt8 = 0
    private var bgTileSet: UInt8 = 0
    private var window: Bool = false
    private var windowTileMap: UInt8 = 0
    private var display: Bool = false
    
    private var palette: [UInt8] = [0, 1, 2, 3]
    
    private enum SpriteSize {
        case eightByEight
        case eightBySixteen
    }
    
    private func updateRegisters() {
        scx = mem.bytes[scxAddr]
        scy = mem.bytes[scyAddr]
        line = mem.bytes[scanlineAddr]
        
        let controlBits = mem.bytes[controlBitsAddr]
        background = (controlBits >> 0) & 0x01 == 0x01
        sprites = (controlBits >> 1) & 0x01 == 0x01
        spriteSize = (controlBits >> 2) & 0x01 == 0x01 ? .eightByEight : .eightBySixteen
        bgTileMap = (controlBits >> 3) & 0x01
        bgTileSet = (controlBits >> 4) & 0x01
        window = (controlBits >> 5) & 0x01 == 0x01
        windowTileMap = (controlBits >> 6) & 0x01
        display = (controlBits >> 7) & 0x01 == 0x01
        
        let paletteBits = mem.bytes[paletteAddr]
        palette = [
            ((paletteBits >> 0) & 0x03),
            ((paletteBits >> 2) & 0x03),
            ((paletteBits >> 4) & 0x03),
            ((paletteBits >> 6) & 0x03)
        ]
    }
    
    public func renderLine() {
        for _ in 0..<144 {
//            let pixel = getPixel(x: UInt8(x), y: line)
//            screen[x + Int(160 * line)] = pixel
        }
    }
    
    private func getPixel(x: UInt8, y: UInt8) -> UInt8 {
        let tileX = UInt16((x + scx) / 8 % 32)
        let tileY = UInt16((y + scy) / 8 % 32)
        
        let tileNum: UInt8
        if bgTileMap != 0 {
            tileNum = mem.bytes[0x9800 + tileX + tileY * 32]
        } else {
            tileNum = mem.bytes[0x9C00 + tileX + tileY * 32]
        }
        
        let tileStartAddr: UInt16
        if bgTileSet != 0 {
            tileStartAddr = UInt16(0x9000 + Int(Int8(bitPattern: tileNum)) * 16)
        } else {
            tileStartAddr = 0x8000 + UInt16(tileNum * 16)
        }
        
        let tileRow = mem.words[tileStartAddr + UInt16((y + scy) % 8)]
        
        return palette[Int((tileRow >> ((x + scx) % 8)) & 0x02 + (tileRow >> (((x + scx) % 8) + 8)) & 0x01)]
    }
}

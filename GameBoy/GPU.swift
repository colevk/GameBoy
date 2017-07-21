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
    public private(set)var screen: Screen
    
    public struct Screen {
        public let pointer: UnsafeMutableRawPointer
        
        public let width: Int
        public let height: Int
        public let count: Int
        
        public init(width: Int, height: Int) {
            self.width = width
            self.height = height
            
            // Pointer must be aligned with and a multiple of 0x1000 if we want to share it with metalkit
            let alignment = 0x1000
            count = (width * height) - (width * height % alignment) + alignment
            var ptr: UnsafeMutableRawPointer? = UnsafeMutableRawPointer.allocate(bytes: count, alignedTo: alignment)
            posix_memalign(&ptr, alignment, count)
            pointer = ptr!
        }
    
        public subscript(index: Int) -> UInt8 {
            get {
                return pointer.load(fromByteOffset: index, as: UInt8.self)
            }
            set {
                pointer.storeBytes(of: newValue, toByteOffset: index, as: UInt8.self)
            }
        }
    }
    
    public init(withMemory memory: Memory) {
        mem = memory
        screen = Screen(width: 160, height: 144)
    }
    
    let controlBitsAddr: UInt16 = 0xFF40
    let scyAddr: UInt16 = 0xFF42
    let scxAddr: UInt16 = 0xFF43
    let scanlineAddr: UInt16 = 0xFF44
    let paletteAddr: UInt16 = 0xFF47
    
    public var controlBits: UInt8 = 0
    public var scx: UInt8 = 0
    public var scy: UInt8 = 0
    public var line: UInt8 = 0
    public var palette: UInt8 = 0
    
    private var background: Bool = false
    private var sprites: Bool = false
    private var spriteSize: SpriteSize = .eightByEight
    private var bgTileMap: UInt8 = 0
    private var bgTileSet: UInt8 = 0
    private var window: Bool = false
    private var windowTileMap: UInt8 = 0
    private var display: Bool = false
    
    private var paletteArr: [UInt8] = [0, 1, 2, 3]
    
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
        paletteArr = [
            ((paletteBits >> 0) & 0x03),
            ((paletteBits >> 2) & 0x03),
            ((paletteBits >> 4) & 0x03),
            ((paletteBits >> 6) & 0x03)
        ]
    }
    
    public func renderLine() {
        if line >= 144 {
            return
        }
        updateRegisters()
        for x in 0..<160 {
            let pixel = getPixel(x: UInt8(x), y: line)
            screen[x + 160 * Int(line)] = pixel
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
        
        return paletteArr[Int((tileRow >> ((x + scx) % 8)) & 0x02 + (tileRow >> (((x + scx) % 8) + 8)) & 0x01)]
    }
}

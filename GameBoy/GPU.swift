//
//  GPU.swift
//  GameBoy
//
//  Created by Cole van Krieken on 7/20/17.
//  Copyright © 2017 Cole van Krieken. All rights reserved.
//

import Foundation
import MetalKit

public class GPU {

    private unowned let gb: GameBoyRunner

    public var lineAttributes: AlignedArray<UInt8>

    public var timer: Int = 0
    public var mode: GPUMode = .readingOAM

    public func ramAccessible() -> Bool {
        return mode != .readingVRAM || !gb.memory.LCDC.checkBit(7)
    }

    public func oamAccessible() -> Bool {
        return (mode != .readingOAM && mode != .readingVRAM) || !gb.memory.LCDC.checkBit(7)
    }

    private func setMode(_ newValue: GPUMode) {
        mode = newValue
        gb.memory.STAT &= ~0x03
        switch newValue {
        case .hBlank:
            gb.memory.STAT |= 0b00
        case .vBlank:
            gb.memory.STAT |= 0b01
        case .readingOAM:
            gb.memory.STAT |= 0b10
        case .readingVRAM:
            gb.memory.STAT |= 0b11
        }
    }


    private let numAttributes: Int = 8

    public init(withParent parent: GameBoyRunner) {
        gb = parent

        lineAttributes = AlignedArray<UInt8>(withCapacity: numAttributes * 144, alignedTo: 0x1000)
    }

    public func storeLineAttributes(line: Int) {
        if line >= 144 { return }
        lineAttributes[line * numAttributes + 0] = gb.memory.LCDC
        lineAttributes[line * numAttributes + 1] = gb.memory.SCY
        lineAttributes[line * numAttributes + 2] = gb.memory.SCX
        lineAttributes[line * numAttributes + 3] = gb.memory.OBP0
        lineAttributes[line * numAttributes + 4] = gb.memory.OBP1
        lineAttributes[line * numAttributes + 5] = gb.memory.WY
        lineAttributes[line * numAttributes + 6] = gb.memory.WX
        lineAttributes[line * numAttributes + 7] = gb.memory.BGP
    }

    public func step() {
        if timer >= 114 {
            timer = 0
            gb.memory.LY = (gb.memory.LY + 1) % 154
            if gb.memory.LY == gb.memory.LYC {
                gb.memory.STAT |= 0x04
                if gb.memory.STAT.checkBit(6) {
                    gb.memory.IF |= gb.interrupts.IE_STAT
                }
            } else {
                gb.memory.STAT &= ~0x04
            }
        }

        switch gb.memory.LY {
        case 0...143:
            switch timer {
            case 0:
                setMode(.readingOAM)
                if gb.memory.STAT.checkBit(5) {
                    gb.memory.IF |= gb.interrupts.IE_STAT
                }
                readOAM()
            case 20:
                setMode(.readingVRAM)
                readVRAM()
            case 63:
                setMode(.hBlank)
                storeLineAttributes(line: Int(gb.memory.LY))
                if gb.memory.STAT.checkBit(3) {
                    gb.memory.IF |= gb.interrupts.IE_STAT
                }
            default:
                break
            }
        case 144:
            if timer == 0 {
                setMode(.vBlank)
                if gb.memory.LCDC.checkBit(7) {
                    gb.memory.IF |= gb.interrupts.IE_VBLANK
                }
                if gb.memory.STAT.checkBit(4) {
                    gb.memory.IF |= gb.interrupts.IE_STAT
                }
            }
        default:
            break
        }

        timer += 1
    }

    private func readOAM() {

    }

    private func readVRAM() {

    }
}

public enum GPUMode {
    case hBlank
    case vBlank
    case readingOAM
    case readingVRAM
}
